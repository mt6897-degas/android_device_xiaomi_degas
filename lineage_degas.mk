#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/xiaomi/degas/device.mk)

# Inherit some common Evolution X / LineageOS stuff.
TARGET_DISABLE_EPPE := true
EVO_BUILD_TYPE := Unofficial
# degas ships Xiaomi's hardware Face Unlock HAL (libmiface + android.hardware.biometrics.face v3).
# Without this flag Evolution X installs its software FaceUnlock app and a duplicate permission XML.
TARGET_PROVIDES_FACE_UNLOCK_HAL := true
TARGET_USES_PICO_GAPPS := true
SURFACE_FLINGER_BOOST := true
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_BRAND := Xiaomi
PRODUCT_DEVICE := degas
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_MODEL := 2406APNFAG
PRODUCT_NAME := lineage_degas

PRODUCT_CHARACTERISTICS := nosdcard
PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="missi-user 16 BP2A.250605.031.A3 OS3.0.4.0.WNEMIXM release-keys" \
    BuildFingerprint=Xiaomi/degas_global/degas:16/BP2A.250605.031.A3/OS3.0.4.0.WNEMIXM:user/release-keys \
    DeviceProduct=degas_global
