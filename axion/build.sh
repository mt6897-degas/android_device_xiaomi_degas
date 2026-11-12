#!/usr/bin/env bash
# Build the full AxionOS ROM package (m bacon) for degas. Never flashes anything.
set -eo pipefail
BASE=$(realpath "${1:?usage: axion-rom.sh WORKSPACE [pico|core|gms|vanilla]}")
VARIANT=${2:-pico}
TOP="$BASE/axion-23.2"
JOBS=${JOBS:-32}
[[ $(uname -m) == x86_64 && "$JOBS" =~ ^[1-9][0-9]*$ ]] || exit 1
case "$VARIANT" in pico|core|gms|vanilla) ;; *) echo 'unknown variant' >&2; exit 1 ;; esac
cd "$TOP"
ulimit -n 65536

# Gate: the package must not carry firmware (lk, preloader and the rest).
V=vendor/xiaomi/degas
if grep -qE '^[^#]*(AB_OTA_PARTITIONS|add-radio-file)' $V/BoardConfigVendor.mk $V/Android.mk; then
    echo 'Firmware is back in the vendor makefiles; refusing to build.' >&2
    exit 1
fi

mkdir -p vendor/lineage-priv/keys
export CCACHE_DIR="$BASE/axion-ccache"
mkdir -p "$CCACHE_DIR"
unset OUT_DIR OUT_DIR_COMMON_BASE USE_LEFTOVERS
export GIT_TERMINAL_PROMPT=0
source build/envsetup.sh || { echo 'envsetup failed' >&2; exit 1; }
export USE_CCACHE=0 CCACHE_DISABLE=1
unset CCACHE_EXEC

# axion always returns success, so the product check below is the real gate.
if [[ $VARIANT == vanilla ]]; then axion degas userdebug || true; else axion degas userdebug "$VARIANT" || true; fi
[[ "${TARGET_PRODUCT:-}" == lineage_degas && "${TARGET_BUILD_VARIANT:-}" == userdebug ]] || {
    echo 'Product configuration failed' >&2
    exit 1
}
echo "variant=$VARIANT WITH_GMS=${WITH_GMS:-unset} TARGET_GAPPS_VARIANT=${TARGET_GAPPS_VARIANT:-unset}"
START=$(date +%s)
echo "Starting bacon at $(date -u --iso-8601=seconds) with $JOBS jobs"
# -k: keep going past failed modules so one run lists every failure. The exit
# status is still non-zero and no zip is produced if anything failed.
m -k -j"$JOBS" bacon || { echo 'bacon failed' >&2; exit 1; }
ZIP=$(ls -t out/target/product/degas/axion-*.zip 2>/dev/null | head -1)
[[ -s "$ZIP" && $(stat -c %Y "$ZIP") -ge $START ]] || { echo 'No fresh ROM zip' >&2; exit 1; }
echo 'Build finished. Not tested on a device.'
ls -lh "$ZIP"
sha256sum "$ZIP"
