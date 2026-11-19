# Out-of-tree patches — Evolution X 12.4 (Android 17 `cnb`)

All **8 patches** in this directory have been rebased and verified (`git apply --check`)
against live Evolution X `cnb` (`android-17.0.0_r1` / `lineage-24.0`) repositories.
Because `repo sync` drops local modifications, re-apply them after syncing using
`scripts/apply-patches.sh`:

```sh
# Phase 1 (vendor_boot.img only)
bash /path/to/evox-a17-degas/scripts/apply-patches.sh --phase1 "$ANDROID_BUILD_TOP"

# Phase 2 (full ROM)
bash /path/to/evox-a17-degas/scripts/apply-patches.sh --phase2 "$ANDROID_BUILD_TOP"

# Check status at any time
bash /path/to/evox-a17-degas/scripts/apply-patches.sh --status "$ANDROID_BUILD_TOP"
```

## Already upstream in Evolution X `cnb` (dropped)

- `build/soong`: `com.xiaomi.*` is already in `scripts/check_boot_jars/package_allowed_list.txt`.
- `vendor/lineage`: `release/aconfig/cp2a/com.android.systemui/flashlight_strength_flag_values.textproto` is already `ENABLED`.
- `frameworks/base/0001-*`: obsolete since `sensors.udfps.degas` provides the ONE_SHOT UDFPS wake sensor directly.

## Active Evolution X `cnb` patches (8 total)

| Patch | Target repo | Phase | Why |
| --- | --- | --- | --- |
| `hardware_mediatek/0001-drop-duplicate-mediatek-audio-service.patch` | `hardware/mediatek` | **1 & 2 (Required)** | Drops duplicate `android.hardware.audio.service.mediatek` from upstream so Soong builds `degas`'s `audio/` service (boot-crash fix + soundtrigger3 V3). |
| `external_wpa_supplicant_8/0001-nl80211-do-not-advertise-WPA_VERSION_3-for-SAE-on-MTK-gen4m.patch` | `external/wpa_supplicant_8` | **2 (Required for WPA3)** | Rebased onto Android 17 `wpa_ver_supported()`. Prevents MTK `gen4m` driver from rejecting WPA3/WPA3-transition APs with status 16; activated by `board_wlan_mtk_gen4m` in `BoardConfig.mk`. |
| `packages_apps_Settings/0001-settings-subscription-network-selection.patch` | `packages/apps/Settings` | **2 (Required for 5G/dual-SIM)** | Uses `getConfigForSubId(subId)` in `isTdscdmaSupported()` and selects GSM-inclusive `NETWORK_MODE_LTE_GSM_WCDMA` instead of CDMA global mode so `mtkfusionrild` accepts user network mode writes. |
| `frameworks_native/0002-SurfaceFlinger-do-not-mode-set-a-powered-off-display.patch` | `frameworks/native` | **2 (Strongly recommended)** | Rebased onto Android 17 bundled multi-display modeset loop. Drops mode sets when `!display->isPoweredOn()` to prevent MTK composer's 144 Hz screen-off vsync storm (~18% CPU drain). |
| `frameworks_native/0001-Scheduler-do-not-resync-hw-vsync-on-a-powered-off-display.patch` | `frameworks/native` | **2 (Recommended)** | Companion to `0002`: avoids re-enabling HW vsync while the panel is powered off. |
| `frameworks_base/0003-udfps-hold-refresh-rate-while-overlay-shown.patch` | `frameworks/base` | **2 (Strongly recommended)** | Rebased onto Evolution X `cnb`. Adds `config_udfpsRefreshRate` (set to `120` in `DegasFrameworksOverlay`) and holds it for the full UDFPS overlay lifetime so local HBM never full-screen flashes on touch. |
| `frameworks_base/0002-BatteryStats-ignore-implausible-charge-time-from-health-HAL.patch` | `frameworks/base` | **2 (Cosmetic)** | Caps implausible MTK gauge `time_to_full_now` (e.g. "36 days") at 12 h so BatteryStats falls back to its real step tracker. |
| `packages_apps_Launcher3/0001-Launcher3-do-not-blur-the-wallpaper-during-a-drag.patch` | `packages/apps/Launcher3` | **2 (Recommended)** | Rebased onto Android 17 `ActivityContext`. Zeroes drag-state wallpaper blur depth (`SPRING_LOADED`) to eliminate Mali-G615 144 Hz drag jank while keeping all-apps/overview blur. |

## Optional camera zoom check (Android 17)

If `camerahalserver` crashes during camera zoom on Android 17, check `vendor/lib64/mt6897/lib3a.awb.core.so` against `Evolution-X-Devices/device_xiaomi_duchamp` commit `1110be6` (not pre-applied blindly because `degas` uses `OS3.0.306.0.WNEEUXM` while `duchamp` targets `OS3.0.10.0.WNLMIXM`).
