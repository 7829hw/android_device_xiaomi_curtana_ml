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

# Graphics: drm_hwcomposer + minigbm_msm + Mesa freedreno for the Adreno 618
# (EGL/GLES and Turnip Vulkan). AOSP external/mesa3d does not build freedreno
# with Soong, so Mesa is cross-built with the NDK by build_mesa_android.sh in
# android/lineage-tools and unpacked to vendor/xiaomi/curtana_ml-mesa; it is
# not kept in Git. The dragonboard graphics makefiles are not inherited because
# they set ro.sf.lcd_density=160 and persist.demo.rotationlock=1 for a
# landscape monitor.
$(call inherit-product, $(DRAGONBOARD)/shared/graphics/drm_hwcomposer/device.mk)
$(call inherit-product, $(DRAGONBOARD)/shared/graphics/minigbm_msm/device.mk)

CURTANA_ML_MESA := vendor/xiaomi/curtana_ml-mesa
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(CURTANA_ML_MESA)/lib64,$(TARGET_COPY_OUT_VENDOR)/lib64)

PRODUCT_VENDOR_PROPERTIES += \
    ro.sf.lcd_density=440 \
    ro.hardware.egl=mesa \
    ro.hardware.vulkan=freedreno \
    ro.opengles.version=196610 \
    debug.hwui.renderer=skiagl \
    vendor.minigbm.debug=nocompression

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2022-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

TARGET_USES_VULKAN := true

# Camera: the mainline CAMSS gives RDI raw Bayer only (no Qualcomm ISP driver),
# so libcamera's simple pipeline handler with its software ISP produces the
# frames. libcamera and its camera3 HAL (hw/camera.curtana_ml.so) are
# cross-built with the NDK by build_libcamera_android.sh in
# android/lineage-tools and unpacked to vendor/xiaomi/curtana_ml-libcamera; it
# is not kept in Git. The LineageOS AIDL provider loads the HAL module.
CURTANA_ML_LIBCAMERA := vendor/xiaomi/curtana_ml-libcamera
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(CURTANA_ML_LIBCAMERA)/lib64,$(TARGET_COPY_OUT_VENDOR)/lib64) \
    $(call find-copy-subdir-files,*,$(CURTANA_ML_LIBCAMERA)/bin,$(TARGET_COPY_OUT_VENDOR)/bin) \
    $(call find-copy-subdir-files,*,$(CURTANA_ML_LIBCAMERA)/share,$(TARGET_COPY_OUT_VENDOR)/share) \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    $(LOCAL_PATH)/camera/camera_hal.yaml:$(TARGET_COPY_OUT_VENDOR)/etc/libcamera/camera_hal.yaml

PRODUCT_PACKAGES += \
    android.hardware.camera.provider-service.lineage

# Resource overlays, selected from the official LineageOS sm6250-common tree.
PRODUCT_PACKAGES += \
    CurtanaMLAperture \
    CurtanaMLFrameworks \
    CurtanaMLSettings \
    CurtanaMLSystemUI

# Storage and init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/fstab.curtana_ml:$(TARGET_COPY_OUT_RAMDISK)/first_stage_ramdisk/fstab.curtana_ml \
    $(LOCAL_PATH)/fstab.curtana_ml:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.curtana_ml \
    $(DRAGONBOARD)/init.common.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.rc \
    $(LOCAL_PATH)/init.curtana_ml.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.usb.rc \
    $(LOCAL_PATH)/init.curtana_ml.remoteproc.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.remoteproc.rc \
    $(LOCAL_PATH)/init.curtana_ml.modem.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.curtana_ml.modem.rc \
    $(LOCAL_PATH)/curtana-efs-readonly.sh:$(TARGET_COPY_OUT_VENDOR)/bin/curtana-efs-readonly.sh \
    $(LOCAL_PATH)/curtana-adsp-start.sh:$(TARGET_COPY_OUT_VENDOR)/bin/curtana-adsp-start.sh \
    $(LOCAL_PATH)/ueventd.curtana_ml.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc \
    frameworks/base/data/keyboards/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/curtana_ml.kl

# Firmware loaded by the 6.18 kernel (firmware_class.path=/vendor/firmware/).
# The files are copied from the pinned RAM-test payloads by
# miatoll/android/prepare_vendor_firmware.py; they are not kept in Git.
CURTANA_ML_FIRMWARE := vendor/xiaomi/curtana_ml-firmware
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(CURTANA_ML_FIRMWARE)/firmware,$(TARGET_COPY_OUT_VENDOR)/firmware)

# Qualcomm file services for the modem, cross-built from the pinned RAM-test
# sources by build_qcom_services_android.sh (android/lineage-tools); not in Git.
# They get their own names: the dragonboard tree also defines rmtfs,
# tqftpserv and qrtr modules (upstream rmtfs writes to the EFS).
CURTANA_ML_QCOM := vendor/xiaomi/curtana_ml-qcom
PRODUCT_COPY_FILES += \
    $(CURTANA_ML_QCOM)/bin/rmtfs:$(TARGET_COPY_OUT_VENDOR)/bin/curtana-rmtfs \
    $(CURTANA_ML_QCOM)/bin/tqftpserv:$(TARGET_COPY_OUT_VENDOR)/bin/curtana-tqftpserv \
    $(CURTANA_ML_QCOM)/bin/qrtr-lookup:$(TARGET_COPY_OUT_VENDOR)/bin/curtana-qrtr-lookup

# Wi-Fi: WCN3990 through ath10k (nl80211), as on dragonboard
PRODUCT_PACKAGES += \
    hostapd \
    libwpa_client \
    wpa_supplicant \
    wificond
PRODUCT_VENDOR_PROPERTIES += \
    wifi.interface=wlan0 \
    wifi.supplicant_scan_interval=15
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant_template.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf

# Bluetooth: WCN3991 through the kernel hci_qca driver and the AOSP HAL.
# The controller has no BD address and registers unconfigured, so the HAL
# never sees it; set_bdaddr.sh (dragonboard) derives a stable address from
# androidboot.serialno and sets it with MGMT, as db845c does. It is not the
# factory address.
PRODUCT_PACKAGES += \
    android.hardware.bluetooth-service.default \
    bdaddr
PRODUCT_COPY_FILES += \
    $(DRAGONBOARD)/shared/utils/bdaddr/set_bdaddr.sh:$(TARGET_COPY_OUT_VENDOR)/bin/set_bdaddr.sh

# Bluetooth profiles, from the official LineageOS sm6250-common vendor.prop
# (45b3b7da) without SIM access (no RIL) and without the Qualcomm A2DP
# offload, which needs the vendor audio stack: A2DP is encoded in software
# through the AOSP Bluetooth audio HAL.
PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.profile.a2dp.source.enabled=true \
    bluetooth.profile.asha.central.enabled=true \
    bluetooth.profile.avrcp.target.enabled=true \
    bluetooth.profile.bas.client.enabled=true \
    bluetooth.profile.gatt.enabled=true \
    bluetooth.profile.hfp.ag.enabled=true \
    bluetooth.profile.hid.device.enabled=true \
    bluetooth.profile.hid.host.enabled=true \
    bluetooth.profile.map.server.enabled=true \
    bluetooth.profile.opp.enabled=true \
    bluetooth.profile.pan.nap.enabled=true \
    bluetooth.profile.pan.panu.enabled=true \
    bluetooth.profile.pbap.server.enabled=true \
    persist.bluetooth.a2dp_offload.disabled=true
PRODUCT_PACKAGES += \
    android.hardware.bluetooth.audio-impl \
    audio.bluetooth.default
PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

# HALs and services (software implementations from AOSP)
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service \
    android.hardware.gatekeeper@1.0-service.software \
    com.google.cf.health \
    com.android.hardware.thermal \
    android.hardware.power-service.curtana_ml \
    android.hardware.light-service.lineage \
    android.hardware.vibrator-service.curtana_ml \
    android.hardware.audio.service \
    android.hardware.audio@7.0-impl \
    android.hardware.audio.effect@7.0-impl \
    android.hardware.soundtrigger@2.3-impl \
    audio.primary.curtana_ml \
    audio.r_submix.default \
    audio.usb.default \
    suspend_blocker \
    tinyplay tinycap tinymix tinypcminfo

USE_XML_AUDIO_POLICY_CONF := 1
PRODUCT_COPY_FILES += \
    $(DRAGONBOARD)/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
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
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

PRODUCT_SOONG_NAMESPACES += $(DRAGONBOARD)

# Bring-up: make adb available without a device-side prompt on userdebug.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.usb.config=adb
PRODUCT_PRODUCT_PROPERTIES += \
    persist.adb.nonblocking_ffs=0 \
    ro.adb.nonblocking_ffs=0
