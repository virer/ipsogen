#!/bin/bash
#################
# S.CAPS Jun2020
#################

cd /ipxe.git/src
rm -f bin/ipxe.iso bin-x86_64-efi/ipxe.efi

# The target name MUST be = to "bin/ipxe.iso"
# The embed extension must be ".ipxe"
make bin/ipxe.lkrn EMBED=scaps.ipxe

# The target name MUST be = to "bin-x86_64-efi/ipxe.efi"
# The embed extension must be ".ipxe"
make bin-x86_64-efi/ipxe.efi EMBED=scaps.ipxe

# Only 3 letters allowed with isolinux
cp bin/ipxe.lkrn ../img/boot/ipxe.krn
cp bin-x86_64-efi/ipxe.efi ../img/EFI/BOOT/ipxe_x64.efi

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

cd ../img

rm -f ../ipxe_uefi.iso

# boot.cat is generated on the fly
xorriso -as mkisofs \
    -r -V "SCAPS_IPSOGEN" \
    -o ../ipxe_uefi.iso \
    -J -J -joliet-long -cache-inodes \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -boot-load-size 4 -boot-info-table -no-emul-boot \
    -eltorito-alt-boot \
    -e --interval:appended_partition_2:all:: \
    -append_partition 2 0xef ../efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    .

cd ..

# EOF
