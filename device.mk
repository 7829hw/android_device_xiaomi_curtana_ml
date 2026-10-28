DRAGONBOARD := device/linaro/dragonboard
LOCAL_PATH := device/xiaomi/curtana_ml

PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_FULL_TREBLE_OVERRIDE := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
PRODUCT_RUNTIMES := runtime_libart_default
TARGET_HARDWARE := curtana_ml

$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# Graphics: drm_hwcomposer + minigbm_msm + software GLES (ANGLE on
# SwiftShader). AOSP external/mesa3d does not build freedreno with Soong, so
# Mesa for the Adreno 618 has to come in as a separately built prebuilt.
# The dragonboard swangle makefile is not inherited because it sets
# ro.sf.lcd_density=160 and persist.demo.rotationlock=1 for a landscape
# monitor; its package and feature lists are repeated here instead.
TARGET_USES_SWR := true
$(call inherit-product, $(DRAGONBOARD)/shared/graphics/drm_hwcomposer/device.mk)
$(call inherit-product, $(DRAGONBOARD)/shared/graphics/minigbm_msm/device.mk)

PRODUCT_REQUIRES_INSECURE_EXECMEM_FOR_SWIFTSHADER := true
PRODUCT_PACKAGES += \
    libEGL_angle \
    libGLESv1_CM_angle \
    libGLESv2_angle \
    vulkan.pastel

PRODUCT_VENDOR_PROPERTIES += \
    ro.sf.lcd_density=440 \
    ro.hardware.egl=angle \
    ro.hardware.vulkan=pastel \
    ro.opengles.version=196608 \
    debug.hwui.renderer=skiagl

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2022-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

TARGET_VULKAN_SUPPORT := true
TARGET_USES_VULKAN := true

# Storage and init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/fstab.curtana_ml:$(TARGET_COPY_OUT_RAMDISK)/first_stage_ramdisk/fstab.curtana_ml \
    $(LOCAL_PATH)/fstab.curtana_ml:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.curtana_ml \
    $(DRAGONBOARD)/init.common.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.rc \
    $(LOCAL_PATH)/init.curtana_ml.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.usb.rc \
    $(LOCAL_PATH)/init.curtana_ml.remoteproc.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.remoteproc.rc \
    $(DRAGONBOARD)/ueventd.common.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc \
    frameworks/base/data/keyboards/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/curtana_ml.kl

# Firmware loaded by the 6.18 kernel (firmware_class.path=/vendor/firmware/).
# The files are copied from the pinned RAM-test payloads by
# miatoll/android/prepare_vendor_firmware.py; they are not kept in Git.
CURTANA_ML_FIRMWARE := vendor/xiaomi/curtana_ml-firmware
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(CURTANA_ML_FIRMWARE)/firmware,$(TARGET_COPY_OUT_VENDOR)/firmware)

# HALs and services (software implementations from AOSP)
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service \
    android.hardware.gatekeeper@1.0-service.software \
    com.google.cf.health \
    com.android.hardware.thermal \
    android.hardware.power-service.example \
    android.hardware.audio.service \
    android.hardware.audio@7.0-impl \
    android.hardware.audio.effect@7.0-impl \
    android.hardware.soundtrigger@2.3-impl \
    audio.primary.default \
    audio.r_submix.default \
    audio.usb.default \
    suspend_blocker \
    tinyplay tinycap tinymix tinypcminfo

USE_XML_AUDIO_POLICY_CONF := 1
PRODUCT_COPY_FILES += \
    $(DRAGONBOARD)/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/media/libeffects/data/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(DRAGONBOARD)/etc/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    $(DRAGONBOARD)/seccomp_policy/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \
    $(DRAGONBOARD)/seccomp_policy/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaswcodec.policy \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

PRODUCT_SOONG_NAMESPACES += $(DRAGONBOARD)

# Bring-up: make adb available without a device-side prompt on userdebug.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.usb.config=adb
PRODUCT_PRODUCT_PROPERTIES += \
    persist.adb.nonblocking_ffs=0 \
    ro.adb.nonblocking_ffs=0
