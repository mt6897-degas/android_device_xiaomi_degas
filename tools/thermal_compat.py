# SPDX-License-Identifier: Apache-2.0
"""Restart the profile selector with the stock thermal daemon."""
from pathlib import Path


def patch_thermal_init_bytes(data: bytes) -> bytes:
    text = data.decode('utf-8')
    if 'service mi_thermald /system/vendor/bin/mi_thermald\n' not in text:
        raise ValueError('Unsupported mi_thermald init service')
    command = '    onrestart restart degas-charger-thermal\n'
    if command in text:
        if text.count(command) != 1:
            raise ValueError('Duplicate thermal profile restart hook')
        return data
    anchor = '    group system\n'
    if text.count(anchor) != 1:
        raise ValueError('Unsupported mi_thermald service group')
    return text.replace(anchor, anchor + command, 1).encode('utf-8')


def fix_thermal_init(ctx, file, file_path, *args, **kwargs):
    path = Path(file_path)
    original = path.read_bytes()
    patched = patch_thermal_init_bytes(original)
    if patched != original:
        path.write_bytes(patched)
