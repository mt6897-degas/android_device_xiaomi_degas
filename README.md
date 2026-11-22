# Xiaomi 14T (degas)

Device tree for Xiaomi 14T (`degas`, MediaTek Dimensity 8300-Ultra / MT6897) targeting AxionOS 2.9 (Android 16), maintained by [mt6897-degas](https://github.com/mt6897-degas).

| Hardware | Specification |
| --- | --- |
| SoC | MediaTek Dimensity 8300-Ultra (MT6897) |
| GPU | Mali-G615 MC6 |
| Display | 6.67-inch AMOLED, 1220 x 2712, 60/90/120/144 Hz |
| Battery | 5000 mAh, 67W fast charge |
| Stock base | OS3.0.4.0.WNEMIXM (Android 16) |

## Branches

| Branch | ROM / Android | Stock firmware |
| --- | --- | --- |
| [`axion-2.9`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/axion-2.9) | AxionOS 2.9 / Android 16 | OS3.0.4.0.WNEMIXM |
| [`lineage-23.2`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/lineage-23.2) | LineageOS 23.2 / Android 16 | OS3.0.4.0.WNEMIXM |
| [`lineage-24.0`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/lineage-24.0) | LineageOS 24.0 / Android 17 | OS3.0.306.0.WNEEUXM (EEA) |
| [`pixelos-17`](https://github.com/mt6897-degas/android_device_xiaomi_degas/tree/pixelos-17) | PixelOS 17 / Android 17 | OS3.0.306.0.WNEEUXM (EEA) |

Keep the device tree and [kernel prebuilts](https://github.com/mt6897-degas/android_device_xiaomi_degas-kernel) on matching branches so the kernel image, DTB, DTBO, and modules stay aligned.

## Building (AxionOS 2.9)

Run the commands below from the AxionOS 2.9 source checkout root:

1. Sync device, kernel, vendor, and hardware dependencies using the local manifest:

   ```sh
   mkdir -p .repo/local_manifests
   cp device/xiaomi/degas/axion/degas.xml .repo/local_manifests/degas.xml
   repo sync -c --no-clone-bundle --no-tags
   ```

   If extracting `vendor/xiaomi/degas` from a stock OS3.0.4.0.WNEMIXM dump instead:

   ```sh
   device/xiaomi/degas/extract-files.py /absolute/path/to/stock/dump
   ```

2. Apply the required tree patches:

   ```sh
   device/xiaomi/degas/axion/apply-patches.sh
   ```

3. Optionally run the offline configuration validator before building:

   ```sh
   python3 device/xiaomi/degas/tools/validate-tree.py --strict
   ```

4. Build:

   ```sh
   source build/envsetup.sh
   axion degas userdebug
   ax -b
   ```

## Included Device Features (`XiaomiParts`)

- Display: AOD brightness mode (Automatic via ambient light sensor, High 60 nit, Low 5 nit) and True Tone ambient color temperature adaptation.
- Thermal: Global `mi_thermald` profile selector (Default, Balanced, Gaming, Performance), Per-App Thermal Profiles, adaptive charging thermal switching, and a Quick Settings tile.
- Touch: High touch polling rate toggle + Quick Settings tile, and hardware Game Mode touch tuning sliders (response, sensitivity, edge rejection).
- Audio: 30-second built-in speaker dust/moisture cleaner with headset safety guard.

## Credits and license

Original `degas` tree by [Mikhail Mlhcnn (Advnirr)](https://github.com/Advnirr) / [Degas Developers](https://github.com/degas-developers/android_device_xiaomi_degas), based on the [mt6897-devs duchamp tree](https://github.com/mt6897-devs/device_xiaomi_duchamp). Thanks to LineageOS, AxionOS, PixelOS, and all contributors.

Copyright (C) 2025-2026 The LineageOS Project. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for licensing and attribution.
