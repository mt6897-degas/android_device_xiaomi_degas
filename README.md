# Device tree for Xiaomi 14T (degas) — Evolution X 12.4 (Android 17)

Evolution X (`cnb`, Android 17 / `cp2a`) device tree for the Xiaomi 14T,
codename `degas` (MediaTek Dimensity 8300-Ultra, MT6897).

| Basic     | Spec sheet                                          |
| --------- | --------------------------------------------------- |
| SoC       | MediaTek Dimensity 8300-Ultra (MT6897)              |
| GPU       | Mali-G615 MC6                                       |
| Display   | 6.67" AMOLED, 1220x2712, 144 Hz                     |
| ROM       | Evolution X 12.4 (`cnb`, Android 17 / `cp2a`)       |
| Base FW   | HyperOS `OS3.0.4.0.WNEMIXM` (prebuilt GKI 6.1)      |

## Phase 1: `vendor_boot.img` bring-up (no vendor blobs required)

`BoardConfig.mk` and `device.mk` guard `vendor/xiaomi/degas` and
`vendor/xiaomi/degas-dolby` with `-include` / `inherit-product-if-exists` so
Phase 1 (`m vendorbootimage`) builds cleanly before proprietary blobs are
extracted.

What `vendor_boot.img` includes for `degas`:
- Boot header v4 (`BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864`, LZ4 ramdisk)
- DTB + first-stage vendor ramdisk modules (`vendor_ramdisk.modules.load`)
- Recovery ramdisk + touch modules (`vendor_ramdisk.modules.load.recovery`:
  `xiaomi_touch_common.ko`, `goodix_core_rothko.ko`, `focaltech_touch_rothko.ko`)
- Recovery touch fix (`init/init.recovery.mt6897.rc`:
  `write /sys/class/touch/touch_dev/enable_touch_raw 0`)
- Recovery HALs (`android.hardware.boot-service.mediatek_recovery`,
  `android.hardware.health-service.mediatek-recovery`, `create_pl_dev.recovery`,
  `fastbootd`, `update_engine_sideload`)

### Sync & build `vendor_boot.img`

Requires a Linux x86_64 host with **>= 250 GB free disk** (full `cnb` sync + build)
and >= 16 GB RAM (32 GB recommended):

```sh
mkdir -p evox-cnb && cd evox-cnb
repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs
mkdir -p .repo/local_manifests
cp /path/to/evox-a17-degas/manifests/evox-degas-cnb.xml .repo/local_manifests/
# Place this tree at device/xiaomi/degas (clone or copy)
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# Required Phase 1 patch (drops duplicate android.hardware.audio.service.mediatek)
git -C hardware/mediatek apply "$PWD/device/xiaomi/degas/patches/hardware_mediatek/0001-drop-duplicate-mediatek-audio-service.patch"

source build/envsetup.sh
lunch lineage_degas-cp2a-userdebug
m vendorbootimage
```

Output image: `out/target/product/degas/vendor_boot.img` (must be <= 64 MiB).

## Phase 2: Full Evolution X Android 17 ROM

See [`patches/README.md`](patches/README.md) for the Android 17 MT6897 blob
compatibility checklist (Keymint V3 split, Codec2 HIDL `-v34`, `libsink-mtk`
`libaudioclient_shim`, `mnld` `libmnl-v34`, `wpa_supplicant_8` gen4m WPA3/SAE,
and Settings radio patches).

Build flags in `lineage_degas.mk`:
- `EVO_BUILD_TYPE := Unofficial`
- `TARGET_PROVIDES_FACE_UNLOCK_HAL := true` (uses Xiaomi hardware Face HAL)
- `TARGET_USES_PICO_GAPPS := true` (override with `WITH_GMS=false` for Vanilla)
- `SURFACE_FLINGER_BOOST := true`
- `WITH_ADB_INSECURE` stays OFF.
- Partition allowlist stays strictly 14 Android partitions (NO `lk`, NO firmware).

```sh
source build/envsetup.sh
lunch lineage_degas-cp2a-userdebug
m evolution
```

## Credits

- Based on the [duchamp device tree](https://github.com/mt6897-devs/device_xiaomi_duchamp)
  and `Evolution-X-Devices/device_xiaomi_duchamp` (`cnb`), same MT6897 platform.
- Degas bring-up & Evolution X Android 17 adaptation by `@saiquer`.

## License

[Apache License, Version 2.0](LICENSE). See [NOTICE](NOTICE) for attribution
and stock-extracted configuration details.
