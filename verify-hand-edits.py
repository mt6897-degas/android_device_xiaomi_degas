#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Guards the one blob in vendor/xiaomi/degas that carries a hand edit which
# extract-files.py cannot reproduce.
#
# Everything else survives a re-extract on its own: blob_fixups live in
# extract-files.py, and FIX_SONAME / DISABLE_CHECKELF / PRESIGNED live in
# proprietary-files.txt, all of which are checked in. Audited 2026-07-26 by
# hashing all 2987 shipped blobs against the stock dump - 53 differed, 42 are
# blob_fixup output, 5 are FIX_SONAME, 1 (the displayconfig XML) differs only in
# comments, and 1 is the file below.
#
# Run it after every `./extract-files.py`, before building.

import hashlib
import sys
import zipfile
from os import path

VENDOR = path.join(
    path.dirname(path.abspath(__file__)),
    '..', '..', '..', 'vendor', 'xiaomi', 'degas', 'proprietary',
)

# ImsService.apk carries a smali edit that exports receivers Android 14+
# refuses to register unexported. Without it com.mediatek.ims crash-loops and
# takes the boot-time notification shade with it. A re-extract silently
# restores the stock dex.
IMS_SERVICE = 'system_ext/priv-app/ImsService/ImsService.apk'
# Verified hashes from OS3.0.306.0.WNEEUXM (patched via blob-patches/ImsService).
IMS_PATCHED_DEX_SHA1 = '0b3400a9408f60fd1b30b4dcc3a2be05117be5fb'
IMS_PATCHED_DEX_SHA256 = '95a155d78c023a1ad09633fcd4bc520a910adef8640de0682eb60e630dead0d0'
IMS_STOCK_DEX_SHA1 = '46b15a0842b66bf4b584095a58d13ad217152559'


def classify_ims_dex(dex: bytes) -> str:
    sha1 = hashlib.sha1(dex).hexdigest()
    if (sha1 == IMS_PATCHED_DEX_SHA1
            and hashlib.sha256(dex).hexdigest() == IMS_PATCHED_DEX_SHA256):
        return 'patched'
    if sha1 == IMS_STOCK_DEX_SHA1:
        return 'stock'
    return 'unknown'


def main() -> int:
    apk = path.join(VENDOR, IMS_SERVICE)

    if not path.isfile(apk):
        print(f'FAIL: {IMS_SERVICE} is missing')
        return 1

    try:
        with zipfile.ZipFile(apk) as z:
            if z.namelist().count('classes.dex') != 1:
                print(f'FAIL: {IMS_SERVICE} needs exactly one classes.dex')
                return 1
            dex = z.read('classes.dex')
    except (OSError, KeyError, zipfile.BadZipFile) as error:
        print(f'FAIL: cannot read {IMS_SERVICE}: {type(error).__name__}')
        return 1

    got = hashlib.sha1(dex).hexdigest()
    state = classify_ims_dex(dex)
    if state == 'patched':
        print(f'OK: {IMS_SERVICE} still carries the verified r4 receiver-export patch')
        return 0

    if state == 'stock':
        print(
            f'FAIL: {IMS_SERVICE} was reverted to the stock dex by a '
            're-extract.\n'
            '      Re-apply the receiver-export smali patch, or the device '
            'will boot with\n'
            '      com.mediatek.ims in a crash loop.'
        )
        return 1

    print(
        f'FAIL: {IMS_SERVICE} classes.dex is neither the stock nor the '
        f'patched one\n'
        f'      (sha1 {got}). Someone changed it - update this script if that '
        'was deliberate.'
    )
    return 1


if __name__ == '__main__':
    sys.exit(main())
