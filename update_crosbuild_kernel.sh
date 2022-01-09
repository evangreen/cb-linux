#!/bin/bash

source utils/functions.sh
source utils/extract.sh

# Some notes if you're building your own kernel in the Chrome OS chroot:
# My own commandline looks something like this (I'm building for dedede):
# USE="fbconsole pcserial vtconsole" emerge-dedede chromeos-kernel-5_4
# You'll want to change a few configs from the default Chrome OS by
# adding them to the bottom of
# chromeos/config/x86_64/chromeos-intel-pineview.flavour.config,
# and then running ./chromeos/scripts/kernelconfig olddefconfig:
# CONFIG_DM_MULTIPATH=y
# CONFIG_EFIVAR_FS=y
# CONFIG_FB_VESA=y
# CONFIG_LSM="lockdown,yama,loadpin,safesetid,integrity,selinux,smack,tomoyo,apparmor,bpf"
# CONFIG_SQUASHFS_XZ=y
#
# I'm saving my set of changes in this repository at kernel/changes-5.4.patch.
# Feel free to discard the config changes and regenerate based on above
# if there are conflicts.

[[ -n "$1" ]] && { export BOARD=$1; }

if [ -z "$BOARD" ]; then
    printerr "Expected a BOARD."
    exit 1
fi

WD=~/linux-build
mkdir -p "$WD"
scriptdir="$(dirname "$0")"

linuz="/build/$BOARD/boot/vmlinuz"
if ! [ -r "$linuz" ]; then
    printerr "Error: $linuz" does not exist.
    exit 1
fi

cp "$linuz" "$WD/bzImage"

if [ -r ~/"trunk/src/build/images/$BOARD/latest/config.txt" ]; then
    cp ~/"trunk/src/build/images/$BOARD/latest/config.txt" "$WD/kernel.flags"

else
    # Copy kernel.flags from repo.
    cp "$scriptdir/kernel/kernel.flags" "$WD/kernel.flags"
fi

if ! [ -d "/build/$BOARD/lib/modules" ]; then
    printerr "Error: /build/$BOARD/lib/modules does not exist."
    exit 1
fi

printf "Zipping up modules..."
tar cfJ "$WD/modules.tar.xz" -C "/build/$BOARD/" lib/modules lib/firmware
echo "Done"


exec bash -x "$scriptdir/updatekernel.sh"
