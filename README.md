# Xiaomi 14T (degas)

Device configuration for Xiaomi 14T (`degas`, MT6897), maintained by [mt6897-degas](https://github.com/mt6897-degas).

| Hardware | Specification |
| --- | --- |
| SoC | MediaTek Dimensity 8300-Ultra |
| GPU | Mali-G615 MC6 |
| Display | 6.67-inch AMOLED, 1220 × 2712, up to 144 Hz |
| Battery | 5000 mAh |

## Branches

| Branch | ROM / Android | Stock firmware |
| --- | --- | --- |
| [`axion-2.9`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/axion-2.9) | AxionOS 2.9 / Android 16 | OS3.0.4.0.WNEMIXM |
| [`lineage-23.2`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/lineage-23.2) | LineageOS 23.2 / Android 16 | OS3.0.4.0.WNEMIXM |
| [`lineage-24.0`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/lineage-24.0) | LineageOS 24.0 / Android 17 | OS3.0.306.0.WNEEUXM (EEA) |
| [`pixelos-17`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/pixelos-17) | PixelOS 17 / Android 17 | OS3.0.306.0.WNEEUXM (EEA) |

Use the same branch for the device tree and [kernel prebuilts](https://github.com/mt6897-degas/android_device_xiaomi_degas-kernel). Keep the kernel, DTB, DTBO and modules together.

## Building

Use a Linux build host and sync the matching ROM sources following its build guide: [LineageOS](https://wiki.lineageos.org/devices/) or [PixelOS](https://blog.pixelos.net/docs/maintainers/guide/building-pixelos/). Run the commands below from the Android checkout root.

1. Clone the device and kernel trees; set `DEGAS_BRANCH` to the desired branch:

   ```sh
   DEGAS_BRANCH=pixelos-17
   git clone -b "$DEGAS_BRANCH" https://github.com/mt6897-degas/android_device_xiaomi_degas.git device/xiaomi/degas
   git clone -b "$DEGAS_BRANCH" https://github.com/mt6897-degas/android_device_xiaomi_degas-kernel.git device/xiaomi/degas-kernel
   ```

2. Sync dependencies. For Android 17 branches, copy `device/xiaomi/degas/degas.xml` to `.repo/local_manifests/` and run `repo sync`. For LineageOS 23.2, adjust `degas.xml` repository owners and remove the unpublished vendor project before syncing. For AxionOS, use `lineage.dependencies`. Avoid declaring paths already present in the ROM manifest.

3. Generate `vendor/xiaomi/degas` from an extracted dump of the stock firmware listed above:

   ```sh
   STOCK_DUMP=/absolute/path/to/stock/dump
   if [ -f device/xiaomi/degas/tools/extract-vendor.sh ]; then
       device/xiaomi/degas/tools/extract-vendor.sh "$STOCK_DUMP"
   else
       device/xiaomi/degas/extract-files.py "$STOCK_DUMP"
   fi
   ```

   Run `python3 device/xiaomi/degas/verify-hand-edits.py` when available. Do not use `--regenerate_makefiles`; it discards required edits.

4. Apply the required patches from [`patches/`](patches/). On Android 17 branches, run `python3 device/xiaomi/degas/tools/apply-patches.py --check`, then run it without `--check`.

5. Select the device and build:

   ```sh
   source build/envsetup.sh
   breakfast degas userdebug
   ```

   | ROM | Product | Build command |
   | --- | --- | --- |
   | AxionOS / LineageOS | `lineage_degas` | `m bacon` |
   | PixelOS | `custom_degas` | `m updatepackage pixelos` |

## Status

These are unofficial device trees. PixelOS 17 has been built and boot-tested with SELinux enforcing; hardware testing remains incomplete. LineageOS 24.0 has source checks only; a full build and device boot are unverified. Branch-specific fixes and verification notes are in [`patches/`](patches/).

## Credits and license

Original degas tree by [Mikhail Mlhcnn (Advnirr)](https://github.com/Advnirr) / [Degas Developers](https://github.com/degas-developers/android_device_xiaomi_degas), based on the [mt6897-devs duchamp tree](https://github.com/mt6897-devs/device_xiaomi_duchamp). Thanks to LineageOS, PixelOS, AxionOS and all contributors.

Copyright (C) 2025-2026 The LineageOS Project. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for licensing and attribution.
