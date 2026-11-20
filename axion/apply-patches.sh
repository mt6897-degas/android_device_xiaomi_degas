#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
DT="$ROOT/device/xiaomi/degas"

apply_one() {
    local repo="$1"
    local patch="$2"
    echo "Applying $(basename "$patch") -> $repo"
    if git -C "$ROOT/$repo" apply --reverse --check "$patch" 2>/dev/null; then
        echo "  (already applied, skipping)"
    else
        git -C "$ROOT/$repo" apply "$patch"
    fi
}

apply_one build/soong "$DT/patches/build_soong/0001-check_boot_jars-allow-com.xiaomi.patch"
apply_one frameworks/base "$DT/patches/frameworks_base/0001-SystemUI-register-non-ONE_SHOT-doze-sensors-via-listener.patch"
apply_one frameworks/base "$DT/patches/frameworks_base/0002-BatteryStats-ignore-implausible-charge-time-from-health-HAL.patch"
apply_one frameworks/base "$DT/axion/patches/frameworks_base-0003-udfps-hold-refresh-rate.patch"
apply_one frameworks/native "$DT/patches/frameworks_native/0001-Scheduler-do-not-resync-hw-vsync-on-a-powered-off-display.patch"
apply_one frameworks/native "$DT/patches/frameworks_native/0002-SurfaceFlinger-do-not-mode-set-a-powered-off-display.patch"
apply_one hardware/mediatek "$DT/patches/hardware_mediatek/0001-drop-duplicate-mediatek-audio-service.patch"
apply_one packages/apps/Launcher3 "$DT/patches/packages_apps_Launcher3/0001-Launcher3-do-not-blur-the-wallpaper-during-a-drag.patch"
apply_one vendor/lineage "$DT/patches/vendor_lineage/0001-Enable-the-SystemUI-flashlight-strength-slider.patch"
echo "All AxionOS 2.9 degas patches applied cleanly."
