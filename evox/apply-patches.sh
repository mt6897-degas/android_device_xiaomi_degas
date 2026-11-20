#!/usr/bin/env bash
# Apply verified Evolution X 12.4 (Android 17 cnb) out-of-tree patches for degas.
# Safe to re-run (skips patches that are already applied).
set -euo pipefail

MODE="${1:-}"
TOP="${2:-$PWD}"

usage() {
    echo "Usage: $0 [--phase1|--phase2|--status] [/path/to/evox-cnb-root]" >&2
    echo "  --phase1  Apply only patches required for m vendorbootimage (hardware/mediatek)" >&2
    echo "  --phase2  Apply all 8 Evolution X cnb patches for full ROM builds" >&2
    echo "  --status  Check which patches are applied without modifying anything" >&2
    exit 1
}

case "$MODE" in
    --phase1|--phase2|--status) ;;
    *) usage ;;
esac

TOP="$(realpath "$TOP")"
PATCH_ROOT="$TOP/device/xiaomi/degas/patches"

if [[ ! -d "$PATCH_ROOT" ]]; then
    echo "ERROR: Missing $PATCH_ROOT" >&2
    exit 1
fi

apply_one() {
    local repo="$1"
    local rel_patch="$2"
    local repo_dir="$TOP/$repo"
    local patch_file="$PATCH_ROOT/$rel_patch"

    if [[ ! -d "$repo_dir/.git" && ! -f "$repo_dir/.git" ]]; then
        echo "ERROR: Missing git repository: $repo_dir" >&2
        return 1
    fi
    if [[ ! -f "$patch_file" ]]; then
        echo "ERROR: Missing patch file: $patch_file" >&2
        return 1
    fi

    if git -C "$repo_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
        echo "[APPLIED] $repo <- $rel_patch"
        return 0
    fi

    if [[ "$MODE" == "--status" ]]; then
        if git -C "$repo_dir" apply --check "$patch_file" 2>/dev/null; then
            echo "[PENDING] $repo <- $rel_patch (applies cleanly)"
        else
            echo "[CONFLICT] $repo <- $rel_patch (needs manual rebase)"
            return 1
        fi
        return 0
    fi

    git -C "$repo_dir" apply --check "$patch_file"
    git -C "$repo_dir" apply "$patch_file"
    echo "[OK]      $repo <- $rel_patch"
}

# Phase 1 (required even for m vendorbootimage)
apply_one "hardware/mediatek" \
    "hardware_mediatek/0001-drop-duplicate-mediatek-audio-service.patch"

apply_one "device/mediatek/sepolicy_vndr" \
    "device_mediatek_sepolicy_vndr/0001-drop-duplicate-typec-genfscon-for-A17.patch"

if [[ "$MODE" == "--phase1" ]]; then
    exit 0
fi

# Phase 2 (full ROM Evolution X Android 17 cnb)
apply_one "external/wpa_supplicant_8" \
    "external_wpa_supplicant_8/0001-nl80211-do-not-advertise-WPA_VERSION_3-for-SAE-on-MTK-gen4m.patch"

apply_one "packages/apps/Settings" \
    "packages_apps_Settings/0001-settings-subscription-network-selection.patch"

apply_one "frameworks/native" \
    "frameworks_native/0001-Scheduler-do-not-resync-hw-vsync-on-a-powered-off-display.patch"

apply_one "frameworks/native" \
    "frameworks_native/0002-SurfaceFlinger-do-not-mode-set-a-powered-off-display.patch"

apply_one "frameworks/base" \
    "frameworks_base/0002-BatteryStats-ignore-implausible-charge-time-from-health-HAL.patch"

apply_one "frameworks/base" \
    "frameworks_base/0003-udfps-hold-refresh-rate-while-overlay-shown.patch"

apply_one "packages/apps/Launcher3" \
    "packages_apps_Launcher3/0001-Launcher3-do-not-blur-the-wallpaper-during-a-drag.patch"
