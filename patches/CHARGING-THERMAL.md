# Factory charging thermal profiles

The port previously selected thermal scenario 6 unconditionally after boot to
improve CPU performance. The pinned degas factory map resolves it to
`thermal-nolimits.conf`, which still limits charging.

At a rising **virtual board temperature** of 36.5 C, its battery target becomes
707. The factory daemon converts battery targets with `target / 100` while the
panel is on and `target % 100` while it is off. Both paths select thermal
level 7, which the factory PD table limits to 5000 mA of battery current.
That corresponds to roughly 20–22 W before phone load. This temperature is a
weighted board sensor, not the battery temperature reading.

`degas-charger-thermal.sh` now selects these existing factory profiles:

| Power/panel state | Scenario | Factory file |
|---|---:|---|
| Unplugged | 6 | thermal-nolimits.conf |
| Plugged, panel on | 0 | thermal-normal.conf |
| Plugged, panel off or AOD | 27 | thermal-charge.conf |
| Unknown input | 0 | thermal-normal.conf |

The selector reads USB online and kernel panel state every five seconds without
a wakelock or wakeup alarm. During its first twelve polls it reasserts the
profile so an early sysfs write cannot be mistaken for delivery to the thermal
daemon's inotify watch. Afterwards it only writes when the profile differs.
The extraction fix adds an init `onrestart` hook to restart the selector with
`mi_thermald`. The previous unconditional scenario-6 init write is removed.

At a rising virtual board temperature of 37 C, the decoded factory limits are:

| Scenario | Encoded target | Panel off: level/FCC | Panel on: level/FCC |
|---|---:|---:|---:|
| 6 | 707 | 7 / 5000 mA | 7 / 5000 mA |
| 0 | 800 | 0 / 12400 mA | 8 / 4400 mA |
| 27 | 1001 | 1 / 10000 mA | 10 / 2600 mA |

These are the allowances of one thermal vote. Actual current remains the
minimum of all votes and depends on temperature hysteresis, SOC, JEITA,
step charging, authentication and negotiated adapter capabilities. The stock
normal CPU policy applies while plugged with the panel on; the previous
battery-powered CPU profile is retained while unplugged.

The encrypted factory thermal files, thresholds, hysteresis, current/voltage
limits, kernel modules and authentication logic are unchanged. This fix does
not add APDOs to fixed-only adapters or bypass the MT6375 buck path's existing
3.15 A battery-current limit. It does not establish 67 W charging.

Run the public checkout tests from the Android workspace root:

```sh
python3 device/xiaomi/degas/tools/test_charging_thermal.py
python3 device/xiaomi/degas/tools/validate-tree.py
```

Optionally test the extraction hook against the actual stock init file:

```sh
python3 device/xiaomi/degas/tools/test_charging_thermal.py stock/dump/vendor/etc/init/hw/init.mi_thermald.rc
```

Tests replay thirteen plug/panel/restart/error transitions, the bounded startup
loop, failed writes and idempotent extraction. The default test uses a minimal
init fixture and needs no proprietary dump.

[Verification evidence](charging-thermal/VERIFICATION.json) records pinned
factory input hashes, four exact AES-CBC decrypt/re-encrypt roundtrips and
54 profile/temperature/panel cases. The equivalent local PixelOS policy was
compiled with neverallow checks; 23 effective policy decisions passed. Local
image metadata, all 35 OTA partitions, signatures, recovery decoding and AVB
were verified offline. A full build of this public checkout and phone
installation/power measurements have not been performed.

The separate transient PD-authentication retry experiment is not included.
