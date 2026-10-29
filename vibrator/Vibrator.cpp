/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * IVibrator for an input device with FF_RUMBLE, as created by the mainline
 * haptics drivers through ff-memless. Every vibration is a single rumble
 * effect: on() plays it for the requested time, perform() plays a short one
 * for the click effects, and the amplitude scales the magnitude.
 */

#include <aidl/android/hardware/vibrator/BnVibrator.h>
#include <android-base/logging.h>
#include <android-base/unique_fd.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <chrono>
#include <cstring>
#include <mutex>
#include <string>
#include <thread>

namespace aidl::android::hardware::vibrator {

using ::android::base::unique_fd;
using ndk::ScopedAStatus;

static ScopedAStatus unsupported() {
    return ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
}

static bool testBit(int bit, const uint8_t* bits) {
    return bits[bit / 8] & (1 << (bit % 8));
}

static unique_fd openRumbleDevice() {
    std::unique_ptr<DIR, int (*)(DIR*)> dir(opendir("/dev/input"), closedir);
    if (!dir) return {};
    while (dirent* entry = readdir(dir.get())) {
        if (strncmp(entry->d_name, "event", 5)) continue;
        std::string path = std::string("/dev/input/") + entry->d_name;
        unique_fd fd(TEMP_FAILURE_RETRY(open(path.c_str(), O_RDWR | O_CLOEXEC)));
        if (fd < 0) continue;
        uint8_t ff[FF_CNT / 8 + 1] = {};
        char name[64] = {};
        if (ioctl(fd, EVIOCGBIT(EV_FF, sizeof(ff)), ff) < 0 || !testBit(FF_RUMBLE, ff)) continue;
        ioctl(fd, EVIOCGNAME(sizeof(name) - 1), name);
        LOG(INFO) << "Using " << name << " at " << path;
        return fd;
    }
    LOG(ERROR) << "No FF_RUMBLE input device found";
    return {};
}

class Vibrator : public BnVibrator {
  public:
    Vibrator() : mFd(openRumbleDevice()) {}

    ScopedAStatus getCapabilities(int32_t* caps) override {
        *caps = IVibrator::CAP_ON_CALLBACK | IVibrator::CAP_PERFORM_CALLBACK |
                IVibrator::CAP_AMPLITUDE_CONTROL;
        return ScopedAStatus::ok();
    }

    ScopedAStatus off() override {
        std::lock_guard lock(mMutex);
        stopLocked();
        return ScopedAStatus::ok();
    }

    ScopedAStatus on(int32_t timeoutMs, const std::shared_ptr<IVibratorCallback>& cb) override {
        std::lock_guard lock(mMutex);
        return playLocked(timeoutMs, mAmplitude, cb);
    }

    ScopedAStatus perform(Effect effect, EffectStrength strength,
                          const std::shared_ptr<IVibratorCallback>& cb, int32_t* ms) override {
        int32_t duration;
        switch (effect) {
            case Effect::TICK: duration = 10; break;
            case Effect::CLICK: duration = 20; break;
            case Effect::HEAVY_CLICK: duration = 30; break;
            case Effect::DOUBLE_CLICK: duration = 40; break;
            default: return unsupported();
        }
        float scale;
        switch (strength) {
            case EffectStrength::LIGHT: scale = 0.5f; break;
            case EffectStrength::MEDIUM: scale = 0.75f; break;
            case EffectStrength::STRONG: scale = 1.0f; break;
            default: return unsupported();
        }
        std::lock_guard lock(mMutex);
        ScopedAStatus status = playLocked(duration, scale, cb);
        if (status.isOk()) *ms = duration;
        return status;
    }

    ScopedAStatus getSupportedEffects(std::vector<Effect>* effects) override {
        *effects = {Effect::TICK, Effect::CLICK, Effect::HEAVY_CLICK, Effect::DOUBLE_CLICK};
        return ScopedAStatus::ok();
    }

    ScopedAStatus setAmplitude(float amplitude) override {
        if (amplitude <= 0.0f || amplitude > 1.0f)
            return ScopedAStatus::fromExceptionCode(EX_ILLEGAL_ARGUMENT);
        std::lock_guard lock(mMutex);
        mAmplitude = amplitude;
        return ScopedAStatus::ok();
    }

    ScopedAStatus setExternalControl(bool) override { return unsupported(); }
    ScopedAStatus getCompositionDelayMax(int32_t*) override { return unsupported(); }
    ScopedAStatus getCompositionSizeMax(int32_t*) override { return unsupported(); }
    ScopedAStatus getSupportedPrimitives(std::vector<CompositePrimitive>* p) override {
        p->clear();
        return ScopedAStatus::ok();
    }
    ScopedAStatus getPrimitiveDuration(CompositePrimitive, int32_t*) override {
        return unsupported();
    }
    ScopedAStatus compose(const std::vector<CompositeEffect>&,
                          const std::shared_ptr<IVibratorCallback>&) override {
        return unsupported();
    }
    ScopedAStatus getSupportedAlwaysOnEffects(std::vector<Effect>* e) override {
        e->clear();
        return ScopedAStatus::ok();
    }
    ScopedAStatus alwaysOnEnable(int32_t, Effect, EffectStrength) override {
        return unsupported();
    }
    ScopedAStatus alwaysOnDisable(int32_t) override { return unsupported(); }
    ScopedAStatus getResonantFrequency(float*) override { return unsupported(); }
    ScopedAStatus getQFactor(float*) override { return unsupported(); }
    ScopedAStatus getFrequencyResolution(float*) override { return unsupported(); }
    ScopedAStatus getFrequencyMinimum(float*) override { return unsupported(); }
    ScopedAStatus getBandwidthAmplitudeMap(std::vector<float>*) override { return unsupported(); }
    ScopedAStatus getPwlePrimitiveDurationMax(int32_t*) override { return unsupported(); }
    ScopedAStatus getPwleCompositionSizeMax(int32_t*) override { return unsupported(); }
    ScopedAStatus getSupportedBraking(std::vector<Braking>* b) override {
        b->clear();
        return ScopedAStatus::ok();
    }
    ScopedAStatus composePwle(const std::vector<PrimitivePwle>&,
                              const std::shared_ptr<IVibratorCallback>&) override {
        return unsupported();
    }

  private:
    ScopedAStatus playLocked(int32_t ms, float scale,
                             const std::shared_ptr<IVibratorCallback>& cb) {
        if (mFd < 0 || ms <= 0) return ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
        stopLocked();
        ff_effect effect = {};
        effect.type = FF_RUMBLE;
        effect.id = -1;
        effect.replay.length = ms > 0xffff ? 0xffff : ms;
        effect.u.rumble.strong_magnitude = static_cast<uint16_t>(scale * 0xffff);
        if (ioctl(mFd, EVIOCSFF, &effect) < 0) {
            PLOG(ERROR) << "EVIOCSFF";
            return ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);
        }
        mEffectId = effect.id;
        if (!writeEvent(mEffectId, 1)) return ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);
        uint64_t generation = ++mGeneration;
        if (cb) {
            std::thread([this, ms, cb, generation] {
                std::this_thread::sleep_for(std::chrono::milliseconds(ms));
                {
                    std::lock_guard lock(mMutex);
                    if (generation != mGeneration) return;
                }
                cb->onComplete();
            }).detach();
        }
        return ScopedAStatus::ok();
    }

    void stopLocked() {
        ++mGeneration;
        if (mFd < 0 || mEffectId < 0) return;
        writeEvent(mEffectId, 0);
        ioctl(mFd, EVIOCRMFF, mEffectId);
        mEffectId = -1;
    }

    bool writeEvent(int code, int value) {
        input_event ev = {};
        ev.type = EV_FF;
        ev.code = code;
        ev.value = value;
        if (TEMP_FAILURE_RETRY(write(mFd, &ev, sizeof(ev))) != sizeof(ev)) {
            PLOG(ERROR) << "write EV_FF";
            return false;
        }
        return true;
    }

    std::mutex mMutex;
    unique_fd mFd;
    int mEffectId = -1;
    float mAmplitude = 1.0f;
    uint64_t mGeneration = 0;
};

}  // namespace aidl::android::hardware::vibrator

int main() {
    using aidl::android::hardware::vibrator::Vibrator;
    ABinderProcess_setThreadPoolMaxThreadCount(0);
    auto vibrator = ndk::SharedRefBase::make<Vibrator>();
    const std::string instance = std::string(Vibrator::descriptor) + "/default";
    CHECK_EQ(AServiceManager_addService(vibrator->asBinder().get(), instance.c_str()), STATUS_OK);
    ABinderProcess_joinThreadPool();
    return EXIT_FAILURE;
}
