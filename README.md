# device/xiaomi/curtana_ml

LineageOS 22.2 device tree for the Xiaomi Redmi Note 9S (curtana) running the
mainline Linux 6.18 kernel from `miatoll-6.18` (branch `miatoll/6.18-lineage1`).

- Android runs entirely from the SM32G microSD (`soc@0/8804000.mmc`):
  `androidboot.boot_devices` points at the SD controller and the lineage1 kernel
  DT disables the internal UFS, the modem, IPA and Wi-Fi. No internal partition
  is mounted or written; the kernel is sent with `fastboot boot` only.
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
