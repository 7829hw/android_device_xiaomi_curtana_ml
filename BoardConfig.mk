# Board configuration for curtana on mainline Linux, system on microSD.
# Based on device/linaro/dragonboard (sm8x50 SD-card boot), non-A/B.
DRAGONBOARD := device/linaro/dragonboard

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a76

TARGET_BOOTLOADER_BOARD_NAME := curtana_ml
TARGET_BOARD_PLATFORM := sm7125
TARGET_NO_BOOTLOADER := true
# The kernel is the separately built Linux 6.18 RAM-test kernel; boot.img is
# packaged by miatoll/boot tooling and sent with fastboot boot only.
TARGET_NO_KERNEL := true
TARGET_NO_RECOVERY := true

# Images
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_USERDATAIMAGE_PARTITION_SIZE := 8589934592
BOARD_F2FS_BLOCKSIZE := 4096
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_USES_METADATA_PARTITION := true

# Non-A/B: one slot, no update_engine slots on the SD card.
AB_OTA_UPDATER := false

# Super partition on the SD card
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
# The SD partition is los_super (see fstab.curtana_ml); the metadata must not
# name a "super" block device, which would resolve to the internal UFS.
BOARD_SUPER_PARTITION_METADATA_DEVICE := los_super
BOARD_SUPER_PARTITION_BLOCK_DEVICES := los_super
BOARD_LOS_SUPER_DEVICE_SIZE := 6442450944
BOARD_SUPER_PARTITION_SIZE := 6442450944
BOARD_SUPER_PARTITION_GROUPS := curtana_ml_dynamic_partitions
# Kept below half of super, as the partition size check requires.
BOARD_CURTANA_ML_DYNAMIC_PARTITIONS_SIZE := 3217031168
BOARD_CURTANA_ML_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor system_ext product

# Graphics: drm_hwcomposer + minigbm_msm + prebuilt Mesa freedreno.
include $(DRAGONBOARD)/shared/graphics/drm_hwcomposer/BoardConfig.mk
BOARD_SEPOLICY_DIRS += \
    device/xiaomi/curtana_ml/sepolicy \
    $(DRAGONBOARD)/shared/utils/sdcard-boot/sepolicy \
    $(DRAGONBOARD)/shared/graphics/minigbm_msm/sepolicy

DEVICE_MANIFEST_FILE := $(DRAGONBOARD)/manifest.xml
DEVICE_MATRIX_FILE := $(DRAGONBOARD)/compatibility_matrix.xml

BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Wi-Fi (ath10k, nl80211) and Bluetooth (hci_qca)
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HAVE_BLUETOOTH := true
