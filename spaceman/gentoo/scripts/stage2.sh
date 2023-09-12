#!/bin/bash

####
#### Do the later emerge stuff.
#### Separate from stage1.sh to avoid starting from scratch every time.
####


#############################
# 0. Configuration options. #
#############################
PROFILE='default/linux/amd64/17.1/no-multilib/systemd/merged-usr'
DISK=/dev/vda

STATUS_LOG='/tmp/stage2'


##############
# 1. Secrets #
##############

_F='/mnt/gentoo/etc/dropbear/keys/'
mkdir -p -m 700 "${_F}"
setfacl -b "${_F}"
rsync -a /tmp/gentoo/secrets/ "${_F}"
unset _F

echo "Secrets setup" >> "${STATUS_LOG}"




############################
# 2. Initial Package setup #
############################

chroot /mnt/gentoo /bin/bash <<EOF
       clear
       echo "Going in boss..." >> "${STATUS_LOG}"
       ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
       source /etc/profile
       locale-gen
       eselect locale set en_US.utf8
       emerge-webrsync
       eselect profile set "${PROFILE}"
       echo "Updating @world..." >> "${STATUS_LOG}"
       emerge --update --deep --newuse @world
       echo "@World update complete" >> "${STATUS_LOG}"
       
       echo "Installing pkgs..." >> "${STATUS_LOG}"


# For src install
#       emerge sys-kernel/gentoo-sources sys-kernel/linux-firmware sys-firmware/intel-microcode sys-boot/efibootmgr sys-kernel/dracut sys-kernel/dracut-crypt-ssh net-misc/dropbear sys-apps/busybox sys-apps/systemd    app-text/tree app-misc/screen app-editors/emacs app-portage/eix app-text/tree app-portage/gentoolkit

# for dist install
       emerge sys-kernel/linux-firmware sys-firmware/intel-microcode sys-boot/efibootmgr sys-kernel/dracut sys-apps/systemd    app-text/tree app-misc/screen app-editors/emacs app-portage/eix app-text/tree app-portage/gentoolkit
       echo "Emerge complete" >> "${STATUS_LOG}"
       env-update
EOF

##########
# 3. ESP #
##########

chroot /mnt/gentoo /bin/bash <<EOF
       bootctl --esp-path=/boot/efi install
       echo "ESP Installed" >> "${STATUS_LOG}"
EOF

# This needs to be done separately for the dist install?
# I think `bootctl install` needs to be done first.
chroot /mnt/gentoo /bin/bash <<EOF
       echo "Install kernel" >> "${STATUS_LOG}"
       emerge sys-kernel/gentoo-kernel-bin sys-kernel/installkernel-systemd-boot
EOF


###################
# 4. Build Kernel #
###################

# Commented out because I'm doing a dist kernel now while troubleshooting...
# chroot /mnt/gentoo /bin/bash <<EOF
#        # cp /tmp/gentoo/kconfig /usr/src/linux/.config
#        cd /usr/src/linux
#        make allyesconfig
#        echo "Building kernel & modules" >> "${STATUS_LOG}"
#        make -j4 && make -j4 modules_install
#        echo "Kernel compile completed" >> "${STATUS_LOG}"
# EOF

#############
# 5. Dracut #
#############

# Dracut gets run by the dist kernel install.
# chroot /mnt/gentoo /bin/bash <<EOF
#        rm -f /etc/fstab /etc/crypttab /etc/dracut.conf
#        #CRYPT_UUID=$(lsblk -nd -o UUID "${DISK}2")
#        #ROOT_UUID=$(lsblk -nd -o UUID "/dev/mapper/crypt_root")
#        ROOT_UUID=$(lsblk -nd -o UUID "${DISK}2")
#        #echo "luks-\${CRYPT_UUID} UUID=\${CRYPT_UUID} none " >> /etc/crypttab
#        echo "UUID=\${ROOT_UUID} / ext4 defaults,x-systemd.device-timeout=0 1 1" >> /etc/fstab
#        #cat /tmp/gentoo/etc/dracut.conf | sed "s/<<ROOTUUID>>/\${ROOT_UUID}/g ; s/<<LUKSUUID>>/\${CRYPT_UUID}/g" >> /etc/dracut.conf
#        cat /tmp/gentoo/etc/dracut.conf | sed "s/<<ROOTUUID>>/\${ROOT_UUID}/g" >> /etc/dracut.conf
#        KVER=$(basename \$(realpath /usr/src/linux) | sed 's/^[^0-9]*\(.*\)/\1/')
#        dracut -fv --kver="\${KVER}"
# EOF



echo "Finished at $(date)" >> "${STATUS_LOG}"
