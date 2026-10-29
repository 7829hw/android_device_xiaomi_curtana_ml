# device/xiaomi/curtana_ml

LineageOS 22.2 device tree for the Xiaomi Redmi Note 9S (curtana) running the
mainline Linux 6.18 kernel from `miatoll-6.18` (branch `miatoll/6.18-lineage1`).

- Android runs entirely from the SM32G microSD (`soc@0/8804000.mmc`):
  `androidboot.boot_devices` points at the SD controller and the lineage1 kernel
  DT probes the internal UFS only for the modem EFS: curtana-efs-readonly.sh
  marks every UFS block device read-only before rmtfs (RAM shadows) starts,
  and nothing mounts it. The SD partitions are named los_* because the UFS
  has its own super/metadata/userdata/misc. The kernel is sent with
  `fastboot boot` only.
- Based on AOSP `device/linaro/dragonboard` at android-15.0.0_r32 (57fc686a):
  SD-card boot layout, drm_hwcomposer and minigbm_msm. GLES and Vulkan come
  from Mesa 26.2.5 freedreno/Turnip for the Adreno 618, cross-built with the
  NDK (AOSP external/mesa3d does not build freedreno with Soong) and unpacked
  to `vendor/xiaomi/curtana_ml-mesa`, which is not in this repository. The
  first boots used ANGLE/SwiftShader, which was very slow. The dragonboard
  graphics makefiles are not inherited because they force a 160 dpi landscape
  monitor setup.
  Non-A/B, super on the SD card.
- Firmware under `vendor/xiaomi/curtana_ml-firmware` is not in this repository either;
  it comes from the pinned RAM-test payloads of miatoll-6.18
  through `prepare_vendor_firmware.py` in `android/lineage-tools`.

Workflow: edit here on the WSL host, commit, `git push buildhost lineage-22.2`,
then build on the build host with `build_lineage_remote.sh` from the separate
`android/lineage-tools` repository, which
checks out the pushed commit into `lineage/device/xiaomi/curtana_ml`.

Overlays: `overlay/CurtanaMLFrameworks` and `overlay/CurtanaMLSystemUI` are
taken from LineageOS `android_device_xiaomi_sm6250-common` (lineage-22.2,
45b3b7dab47ac792be975fb7623f03268c4a6dc2), Apache-2.0: display cutout,
rounded corners, status bar heights, navigation bar, power profile and
general framework settings. Settings that need HALs this mainline bring-up
does not have yet (light sensor, doze, vendor color modes,
power HAL, telephony/IMS) are left out.

Audio: `audio/` is the dragonboard tinyalsa HAL (android-15.0.0_r32,
57fc686a) built as `audio.primary.curtana_ml`. It opens PCM 0 (speaker,
TAS2562), PCM 1 (headphones, WCD937x) or PCM 2 (microphones) and applies the
matching path from `audio/mixer_paths.xml`, whose controls come from the
miatoll-6.18 RAM-test script `miatoll/boot/audio-path`.

Power: `power/` is the AOSP example power HAL built as
`android.hardware.power-service.curtana_ml`; it passes the double tap to
wake mode to the FT8756 driver's `double_tap_enable` attribute.

Wi-Fi and Bluetooth: wpa_supplicant/wificond on nl80211 (ath10k WCN3990,
modem started by curtana-rmtfs -s, firmware served by curtana-tqftpserv) and
the AOSP Bluetooth HAL with the dragonboard set_bdaddr helper (address derived
from the serial number, not the factory one), the official sm6250 profile list
without SIM access and software A2DP. The modem services are RAM-test builds
from build_qcom_services_android.sh in android/lineage-tools.

Vibrator: `vibrator/` is an IVibrator V2 HAL on the first force-feedback input
device (the 6.18 aw8695-haptics driver). on/off play FF_CONSTANT with the
amplitude as level. perform() sends FF_PERIODIC/FF_CUSTOM with the Effect value
in custom_data[0], like the QTI vibrator HAL of the official build; the driver
plays the matching waveform of the AW8624 vendor library (`aw8624_haptic.bin`,
loaded by the kernel from its ramdisk). Effects: click, double click, tick, thud,
pop and heavy click, 30-40 ms as in the vendor configuration. The light,
medium and strong effect strengths use 25, 50 and 100 % of the waveform gain;
the Settings overlay offers the three touch intensity levels.

Camera (work in progress): the mainline CAMSS gives raw Bayer only, so the
camera HAL is libcamera's generic Android camera3 HAL with the simple pipeline
handler and the CPU software ISP, cross-built by `build_libcamera_android.sh`
in android/lineage-tools (patches in `libcamera-patches/`) and loaded by the
LineageOS AIDL camera provider. `camera/camera_hal.yaml` exposes main (0),
front (1), ultra-wide (2) and macro (3); the Aperture overlay enables the lens
selector. The back camera preview works; switching cameras, autofocus and the
front preview are not finished.
