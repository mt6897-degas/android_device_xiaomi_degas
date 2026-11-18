# Out-of-tree patches (Evolution X 12.4 / Android 17 `cnb`)

These are changes `degas` needs in AOSP / Evolution X projects that a device
tree cannot express. Because `repo sync` drops local changes, re-apply them
after syncing.

## Phase 1 (`m vendorbootimage`) — Required before building `vendor_boot.img`

```sh
cd "$ANDROID_BUILD_TOP"
git -C hardware/mediatek apply "$ANDROID_BUILD_TOP"/device/xiaomi/degas/patches/hardware_mediatek/0001-drop-duplicate-mediatek-audio-service.patch
```

Without this patch, Soong aborts during analysis with `module "android.hardware.audio.service.mediatek" found in multiple namespaces (device/xiaomi/degas and hardware/mediatek)`, even for `vendorbootimage`.

## Already upstream in Evolution X `cnb` (dropped from `patches/`)

- `build/soong`: `com.xiaomi.*` is already present in `scripts/check_boot_jars/package_allowed_list.txt` on `Evolution-X/build_soong` (`cnb`).
- `vendor/lineage`: `release/aconfig/cp2a/com.android.systemui/flashlight_strength_flag_values.textproto` is already `ENABLED` on `Evolution-X/vendor_evolution` (`cnb`).

## Phase 2 (Full ROM `m evolution`) — Review / rebase on Android 17 (`cnb`)

Apply and verify each patch against Android 17 (`cnb`) sources before a full ROM build:

| Patch | Project | Android 17 (`cnb`) status |
| --- | --- | --- |
| `hardware_mediatek/0001-drop-duplicate-mediatek-audio-service.patch` | `hardware/mediatek` | **Required (Phase 1 & 2).** Matches `Evolution-X-Devices/hardware_mediatek` (`cnb`) cleanly. |
| `frameworks_native/0002-SurfaceFlinger-do-not-mode-set-a-powered-off-display.patch` | `frameworks/native` | **Recommended (Phase 2).** Prevents MTK composer 144 Hz screen-off vsync storm (~18% CPU drain). Check rebase on A17 `SurfaceFlinger.cpp`. |
| `frameworks_native/0001-Scheduler-do-not-resync-hw-vsync-on-a-powered-off-display.patch` | `frameworks/native` | Optional companion to `0002`. Check rebase on A17 `Scheduler.cpp`. |
| `frameworks_base/0002-BatteryStats-ignore-implausible-charge-time-from-health-HAL.patch` | `frameworks/base` | Cosmetic fix for MTK gauge `time_to_full_now` reporting multi-day charge ETA. Check rebase on A17 `BatteryStatsImpl.java`. |
| `frameworks_base/0003-udfps-hold-refresh-rate-while-overlay-shown.patch` | `frameworks/base` | Prevents full-screen LHBM flash during UDFPS touches by holding 120 Hz while overlay is shown. Check rebase on A17 `DisplayModeDirector.java` and `UdfpsController.java`. |
| `packages_apps_Launcher3/0001-Launcher3-do-not-blur-the-wallpaper-during-a-drag.patch` | `packages/apps/Launcher3` | Eliminates 45px drag-state wallpaper blur jank on Mali-G615. Check rebase on A17 Launcher3. |
| `frameworks_base/0001-SystemUI-register-non-ONE_SHOT-doze-sensors-via-listener.patch` | `frameworks/base` | **OBSOLETE** (kept for reference; replaced by `sensors.udfps.degas`). |

### Additional Phase 2 Android 17 MT6897 bring-up items (not in `patches/` yet)

Verified against `Evolution-X/packages_apps_Settings` (`cnb`) and sister MT6897 device `Evolution-X-Devices/device_xiaomi_duchamp` (`cnb`):

1. **`external/wpa_supplicant_8` (`lineage-24.0`):** Cherry-pick the 1-commit `CONFIG_DRIVER_NL80211_MTK` (`board_wlan_mtk_gen4m`) WPA3/SAE exemption from `degas-developers/android_external_wpa_supplicant_8`. `BoardConfig.mk` already sets `soong_config_set_bool,wpa_supplicant_8,board_wlan_mtk_gen4m,true`.
2. **`packages/apps/Settings` (`cnb`):** `Evolution-X/packages_apps_Settings` still lacks both MTK radio fixes:
   - `NetworkSelectSettings` / `isTdscdmaSupported`: pass `mSubId` via `getConfigForSubId(subId)` instead of `getConfig()`.
   - `EnabledNetworkModePreferenceController`: use GSM-inclusive network mode instead of `NETWORK_MODE_LTE_CDMA_EVDO_GSM_WCDMA` when saving user selection.
3. **Android 17 vendor blob `extract-files.py` & `proprietary-files.txt` updates (from MT6897 `duchamp` `cnb`):**
   - **Keymint V3 split:** `vendor/lib64/libkeymint_V3.so`, `lib_android_keymaster_keymint_utils_V3.so`, `libkeymint_remote_prov_support_V3.so`, `libkeymint_support_V3.so`, `libcppcose_rkp-V3.so`, `libbase-v34.so` for `android.hardware.security.keymint@3.0-service.mitee` and `odm/lib64/libmt_mitee.so`.
   - **Codec2 HIDL `-v34` split:** `libcodec2_hidl@1.0/1.1/1.2-v34.so`, `libcodec2_vndk-v34.so`, `libcodec2_hidl_plugin-v34.so`, `libcodec2_soft_common-v34.so`, `libsfplugin_ccodec_utils-v34.so`, `libformatter-v34.so`, `libstagefright_bufferqueue_helper-v36.so`, `libui-v34.so`.
   - **IMS audio shim:** `system_ext/lib64/libsink-mtk.so` -> `.add_needed('libaudioclient_shim.so')`.
   - **GNSS:** `vendor/bin/mnld` -> `.replace_needed('libmnl.so', 'libmnl-v34.so')`.
   - **Camera AWB crash fix:** check `vendor/lib64/mt6897/lib3a.awb.core.so` binary patch if `camerahalserver` crashes on zoom.
   - **Dolby Vision:** `DEGAS_DOLBY_VISION` starts `false` on `cnb` until Dolby Codec2 is audited against the Android 17 `-v34` libraries.
