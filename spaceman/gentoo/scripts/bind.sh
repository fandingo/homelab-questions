#!/bin/bash

set -e

# Convenience script to "resume" an install after a reboot.
# Does the annoying bind mounts that are tedious to type. 



#cat /tmp/gentoo/secrets/pw | cryptsetup luksOpen /dev/vda2 crypt_root
#mount /dev/mapper/crypt_root /mnt/gentoo

mount /dev/vda2 /mnt/gentoo
mount /dev/vda1 /mnt/gentoo/boot


if [ -b /dev/vdb ]; then
    mkswap /dev/vdb
    swapon /dev/vdb
fi


mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
mount --bind /tmp /mnt/gentoo/tmp
