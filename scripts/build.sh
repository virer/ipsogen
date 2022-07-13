#!/bin/bash
#################
# S.CAPS Jun2020
#################

UUID=$1

cp -r --preserve /ipxe.git/src /ipxe.git/${UUID}_build

cd /ipxe.git/${UUID}_build
rm -f bin/ipxe.lkrn bin-x86_64-efi/ipxe.efi

# The target name MUST be = to "bin/ipxe.lkrn"
# The embed extension must be ".ipxe"
make bin/ipxe.lkrn EMBED=${UUID}_scaps.ipxe

# The target name MUST be = to "bin-x86_64-efi/ipxe.efi"
# The embed extension must be ".ipxe"
make bin-x86_64-efi/ipxe.efi EMBED=${UUID}_scaps.ipxe

# Only 3 letters allowed with isolinux
cp -r ../img ../${UUID}_img
cp bin/ipxe.lkrn ../${UUID}_img/boot/ipxe.krn
cp bin-x86_64-efi/ipxe.efi ../${UUID}_img/EFI/BOOT/ipxe_x64.efi

####################################################################
# EFI : 
####################################################################

# Since the following script need root privilieges,
# we are using a prebuilded image for docker builds
# sudo /bin/sh mk_efi_img.sh
# Please let the script and the command to vbe able to rebuild that

####################################################################
# ISO :
####################################################################

cd ../${UUID}_img

rm -f ../${UUID}_ipxe_uefi.iso

# boot.cat is generated on the fly
xorriso -as mkisofs \
    -r -V "SCAPS_IPSOGEN" \
    -o ../${UUID}_ipxe_uefi.iso \
    -J -J -joliet-long -cache-inodes \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -boot-load-size 4 -boot-info-table -no-emul-boot \
    -eltorito-alt-boot \
    -e --interval:appended_partition_2:all:: \
    -append_partition 2 0xef ../efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    .

rm -rf ../${UUID}_img /ipxe.git/${UUID}_build &
cd ..

# EOF
