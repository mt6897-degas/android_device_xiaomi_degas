# Device tree for Xiaomi 14T (degas) — Evolution X 12.4 (Android 17)

Evolution X (`cnb`, Android 17 / `cp2a`) device tree for the Xiaomi 14T,
codename `degas` (MediaTek Dimensity 8300-Ultra, MT6897).

| Basic     | Spec sheet                                          |
| --------- | --------------------------------------------------- |
| SoC       | MediaTek Dimensity 8300-Ultra (MT6897)              |
| GPU       | Mali-G615 MC6                                       |
| Display   | 6.67" AMOLED, 1220x2712, 144 Hz                     |
| ROM       | Evolution X 12.4 (`cnb`, Android 17 / `cp2a`)       |
| Base FW   | HyperOS `OS3.0.306.0.WNEEUXM` (EEA, GKI 6.1.157, SPL 2026-08-01) |

## Phase 1: `vendor_boot.img` bring-up (no vendor blobs required)

`BoardConfig.mk` and `device.mk` guard `vendor/xiaomi/degas` and
`vendor/xiaomi/degas-dolby` with `-include` / `inherit-product-if-exists` so
Phase 1 (`m vendorbootimage`) builds cleanly before proprietary blobs are
extracted.

```sh
mkdir -p evox-cnb && cd evox-cnb
repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs
mkdir -p .repo/local_manifests
cp /path/to/evox-a17-degas/manifests/evox-degas-cnb.xml .repo/local_manifests/
# Place this tree at device/xiaomi/degas (clone or copy)
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# Refresh device/xiaomi/degas-kernel with 3.0.306 GKI 6.1.157 kernel, DTB, and .ko modules
# and unpack OS3.0.306.0.WNEEUXM partitions into ~/dump-306/root
bash /path/to/evox-a17-degas/scripts/prepare-306-base.sh "$PWD" ~/dump-306 --download

bash /path/to/evox-a17-degas/scripts/build-vendor-boot.sh "$PWD"
```

Output image: `out/target/product/degas/vendor_boot.img` (verified `VNDRBOOT`
header v4, <= 64 MiB, touch fix `enable_touch_raw 0` + recovery touch modules).

## Phase 2: Full Evolution X 12.4 (Android 17) ROM

`extract-files.py` and `proprietary-files.txt` are pre-ported to Android 17
(`cnb`) MT6897 requirements (all top-level vendor `.so` and `init/*.rc` paths
verified against stock `OS3.0.306.0.WNEEUXM`, `pq_aidl` bumped to v7):
- **Keymint V3 split:** `libkeymint_V3.so`, `libkeymint_remote_prov_support_V3.so`,
  `libcppcose_rkp-V3.so` + AOSP `lib_android_keymaster_keymint_utils_V3` /
  `libkeymint_support_V3` + compat `libbase-v34.so`.
- **Codec2 HIDL `-v34` split:** `libcodec2_hidl@1.0/1.1/1.2-v34.so`,
  `libcodec2_vndk-v34.so`, `libcodec2_hidl_plugin-v34.so`,
  `libcodec2_soft_common-v34.so`, `libsfplugin_ccodec_utils-v34.so`,
  `libformatter-v34.so`, `libstagefright_bufferqueue_helper-v36.so`, `libui-v34.so`.
- **Audio & SoundTrigger:** `android.hardware.audio@7.1-util-v34.so`,
  `libaudio_aidl_conversion_common_ndk-v34.so`.
- **IMS & GNSS & TEE:** `libsink-mtk.so` -> `libaudioclient_shim.so`,
  `mnld` -> `libmnl-v34.so`, `tee-supplicant.rc` `/dev/ufs-bsg0` ownership fix.

Steps on build server:
1. Extract blobs from the unpacked `OS3.0.306.0.WNEEUXM` dump created by `prepare-306-base.sh`:
   ```sh
   cd device/xiaomi/degas
   ./extract-files.py ~/dump-306/root
   ./fix-generated-bp.py
   ```
2. Strip firmware lines (`AB_OTA_PARTITIONS` / `add-radio-file`) from
   `vendor/xiaomi/degas/BoardConfigVendor.mk` and `vendor/xiaomi/degas/Android.mk`
   so the ROM strictly touches only the 14 Android partitions (NO `lk`).
3. Ensure `vendor/xiaomi/degas/proprietary/system_ext/priv-app/ImsService/ImsService.apk`
   carries the receiver-export smali patch (`./verify-hand-edits.py` must print `OK`).
4. Build:
   ```sh
   bash /path/to/evox-a17-degas/scripts/build-rom.sh "$ANDROID_BUILD_TOP"
   ```

Build flags in `lineage_degas.mk`:
- `EVO_BUILD_TYPE := Unofficial`
- `TARGET_PROVIDES_FACE_UNLOCK_HAL := true` (uses Xiaomi hardware Face HAL)
- `TARGET_USES_PICO_GAPPS := true` (override with `WITH_GMS=false` for Vanilla)
- `SURFACE_FLINGER_BOOST := true`
- `WITH_ADB_INSECURE` stays OFF.
- `DEGAS_DOLBY_VISION := false` initially until A17 Dolby Codec2 `-v34` ABI is audited.

## Credits

- Based on `mt6897-devs/device_xiaomi_duchamp` and
  `Evolution-X-Devices/device_xiaomi_duchamp` (`cnb`), same MT6897 platform.
- Degas bring-up & Evolution X Android 17 adaptation by `@saiquer`.

## License

[Apache License, Version 2.0](LICENSE). See [NOTICE](NOTICE) for attribution
and stock-extracted configuration details.
