#!/bin/bash

set -e

####
#### Do all the early installation stuff.
####


# Make sure we're not doing the stupid on spaceman...
if [ -b /dev/mapper/media_crypt ]; then
    echo "Wrong system!" >&2
    exit 100
fi

while true; do
    read -p "Go for stage1.sh on $(hostname)? (y/n): " response

    case $response in
        [Yy]*)
            break
            ;;
        [Nn]*)
            echo "Okay, not proceeding."
            exit 0
            ;;
        *)
            echo "Please answer with 'y' or 'n'."
            ;;
    esac
done



#############################
# 0. Configuration options. #
#############################
DISK=/dev/vda
CRYPT_PASSWORD=$(cat /tmp/gentoo/secrets/pw)
STATUS_LOG='/tmp/stage1'

echo "===============" >> "${STATUS_LOG}"
echo "Starting at $(date)" >> "${STATUS_LOG}"




###############
# 1. Disks... #
###############
wipefs -a "${DISK}"

parted    "${DISK}" mklabel gpt

parted    "${DISK}" mkpart  primary   fat32    1MiB    1GiB
parted    "${DISK}" set     1         boot     on
parted    "${DISK}" set     1         esp      on

parted    "${DISK}" mkpart  primary            1GiB  100%

echo "Partitioning complete" >> "${STATUS_LOG}"

# echo -n "${CRYPT_PASSWORD}" | cryptsetup luksFormat --label "crypt_root" "${DISK}2"
# echo -n "${CRYPT_PASSWORD}" | cryptsetup luksOpen "${DISK}2" "crypt_root"


mkfs.vfat -n boot "${DISK}1"
#mkfs.ext4 -L root /dev/mapper/crypt_root
mkfs.ext4 -L root "${DISK}2"

if [ -b /dev/vdb ]; then
    mkswap /dev/vdb
    swapon /dev/vdb
fi

mount --label root /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount --label boot /mnt/gentoo/boot/efi

# Need to incorporate these fs UUIDs generated above into fstab, crypttab, boot args, etc.

echo "Disk setup complete" >> "${STATUS_LOG}"
lsblk -o +label >> "${STATUS_LOG}"





###################################
# 2. Stage 3 download and extract #
###################################
cd /mnt/gentoo
tar xpf '/tmp/gentoo/binaries/stage3.tar.xz' --xattrs-include='*.*' --numeric-owner




###################
# 3. Config files #
###################
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
cat <<EOF > /mnt/gentoo/root/.emacs

    ;; Disable all ~ backups
    (setq make-backup-files nil)

EOF
echo -e '\nexport EDITOR=emacs\n' >> /mnt/gentoo/root/.bash_profile
echo -e 'escape ^\\\\n' >> /mnt/gentoo/root/.screenrc

rsync -a /tmp/gentoo/etc/ /mnt/gentoo/etc

echo "Stage 3 setup and configs copied" >> "${STATUS_LOG}"





##################
# 4. Bind mounts #
##################
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
mount --bind /tmp /mnt/gentoo/tmp

echo "Bind completed" >> "${STATUS_LOG}"
