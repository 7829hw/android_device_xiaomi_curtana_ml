# Xiaomi curtana (Redmi Note 9S) on the mainline Linux 6.18 kernel, booted
# from the SM32G microSD card. See miatoll/LINEAGE-SD.ko.md.
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_curtana_ml.mk

COMMON_LUNCH_CHOICES := \
    lineage_curtana_ml-bp1a-userdebug
