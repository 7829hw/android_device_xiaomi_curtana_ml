# No RIL on the mainline kernel yet: build the Wi-Fi-only tablet flavour.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)
$(call inherit-product, device/xiaomi/curtana_ml/device.mk)

PRODUCT_NAME := lineage_curtana_ml
PRODUCT_DEVICE := curtana_ml
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Redmi Note 9S (mainline)
PRODUCT_MANUFACTURER := Xiaomi
