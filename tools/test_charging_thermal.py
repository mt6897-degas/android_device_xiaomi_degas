#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Replay plug/screen/restart/error cases through the real shell selector."""
import os
import sys
from pathlib import Path
import shlex
import subprocess
import tempfile
from thermal_compat import patch_thermal_init_bytes

DEVICE = Path(__file__).resolve().parents[1]
ROOT = DEVICE.parents[2]
SCRIPT = DEVICE / 'init/degas-charger-thermal.sh'


def main():
    subprocess.run(['sh', '-n', str(SCRIPT)], check=True)
    with tempfile.TemporaryDirectory(prefix='degas-thermal-') as d:
        work = Path(d)
        thermal = work / 'thermal'
        thermal.mkdir()
        usb = work / 'online'
        state = thermal / 'screen_state'
        config = thermal / 'sconfig'
        # Real connection, screen, AOD, unplug and bad-read transitions.
        snapshots = [
            ('0', '1', 0, '6', True),
            ('0', '1', 0, '6', False),
            ('1', '1', 0, '0', True),
            ('1', '0', 0, '27', True),
            ('1', '0', 0, '27', False),
            ('1', '0', 1, '27', True),  # Reassert after daemon restart.
            ('1', '1', 0, '0', True),
            ('0', '0', 0, '6', True),
            (None, '0', 0, '0', True),
            ('1', None, 0, '0', False),
            ('invalid', '0', 0, '0', False),
            ('1', 'invalid', 0, '0', False),
            ('1', '0', 0, '27', True),
        ]
        config.write_text('-1\n')
        for online, screen, force, expected, written in snapshots:
            for p, value in [(usb, online), (state, screen)]:
                if value is None:
                    p.unlink(missing_ok=True)
                else:
                    p.write_text(value+'\n')
            command = (
                '. '+shlex.quote(str(SCRIPT))+'\n'
                'USB_ONLINE='+shlex.quote(str(usb))+'\n'
                'THERMAL_MESSAGE='+shlex.quote(str(thermal))+'\n'
                f'apply_thermal_scenario {force}\n'
            )
            result = subprocess.run(['sh', '-c', command], text=True, capture_output=True,
                                    env={**os.environ, 'DEGAS_CHARGER_THERMAL_LIBRARY':'1'})
            assert result.returncode == 0, result.stderr
            assert config.read_text().strip() == expected
            assert ('scenario=' in result.stdout) == written, (online,screen,result.stdout)
        # Run the actual daemon loop with a fake clock. Startup reassertion ends
        # after twelve polls, so normal operation only writes on state changes.
        loop = command.rsplit('apply_thermal_scenario', 1)[0] + '''
polls=0
sleep() {
    [ "$1" = 5 ] || exit 2
    polls=$((polls + 1))
    [ "$polls" -le 13 ] || exit 0
}
run_thermal_policy
'''
        result = subprocess.run(['sh', '-c', loop], text=True, capture_output=True,
                                env={**os.environ, 'DEGAS_CHARGER_THERMAL_LIBRARY':'1'})
        assert result.returncode == 0, result.stderr
        assert result.stdout.count('scenario=27') == 12
        # A failed node write is reported and can be retried, never a false success.
        config.unlink()
        config.mkdir()
        result = subprocess.run(['sh','-c',command], text=True,capture_output=True,
                                env={**os.environ,'DEGAS_CHARGER_THERMAL_LIBRARY':'1'})
        assert result.returncode == 1 and 'cannot write' in result.stderr
    # Keep the public checkout testable without proprietary extraction inputs.
    original = Path(sys.argv[1]).read_bytes() if len(sys.argv) > 1 else b'''on boot
    start mi_thermald

service mi_thermald /system/vendor/bin/mi_thermald
    class main
    user root
    group system
    seclabel u:r:mi_thermald:s0
'''
    fixed = patch_thermal_init_bytes(original)
    assert patch_thermal_init_bytes(fixed) == fixed
    assert fixed.count(b'onrestart restart degas-charger-thermal') == 1
    assert b'seclabel u:r:mi_thermald:s0' in fixed  # The existing extraction step owns removal.
    try:
        patch_thermal_init_bytes(b'service wrong /bin/wrong\n')
    except ValueError:
        pass
    else:
        raise AssertionError('Unknown init service accepted')
    print('PASS: 13 transitions, bounded startup loop, write failure and init hook idempotency')


if __name__ == '__main__':
    main()
