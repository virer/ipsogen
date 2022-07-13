#!/bin/sh
##################
# S.CAPS Aug2022 #
##################

BOOT_IMG_DATA=$(mktemp -d)
BOOT_IMG=efi.img

mkdir -p $(dirname $BOOT_IMG)

truncate -s 2M $BOOT_IMG
mkfs.vfat $BOOT_IMG
mkdir -p $BOOT_IMG_DATA/efi/boot

grub2-mkimage \
    -C xz \
    -O x86_64-efi \
    -p /boot/grub \
    -o $BOOT_IMG_DATA/efi/boot/bootx64.efi \
    boot linux search normal configfile \
    chain efifwsetup search_label search_fs_uuid search_fs_file \
    part_gpt btrfs fat iso9660 loopback \
    test keystatus gfxmenu regexp probe \
    efi_gop efi_uga all_video gfxterm font \
    echo read ls cat png jpeg halt reboot

mcopy -i $BOOT_IMG -s $BOOT_IMG_DATA/efi ::

# EOF
