# First compile EFI img
FROM debian:bullseye-slim as efi-builder

# Install all necessary packages for compiling the iPXE binary files
RUN apt-get update && apt-get install -y --fix-missing \
        gcc binutils genisoimage liblzma-dev mtools isolinux syslinux syslinux-common libssl-dev xorriso \
        grub2 grub-common dosfstools grub-efi-amd64-bin grub-efi-ia32-bin && rm -rf /var/lib/apt/lists/*

COPY EFI/ /EFI/
RUN chmod a+x /EFI/mk_efi_img.sh; /EFI/mk_efi_img.sh

# Compile iPXE first using Alpine
FROM python:3.10.5-alpine3.15
ENV PYTHONUNBUFFERED 1

# Install all necessary packages for compiling the iPXE binary files
RUN apk --no-cache add  \
        git \
        bash    \
        gcc \
        binutils    \
        make    \
        perl    \
        xz-dev  \
        mtools  \
        xorriso  \
        syslinux    \
        musl-dev    \
        coreutils   \
        openssl

# Define build argument for iPXE branch to clone/checkout
ARG IPXE_TAG="v1.21.1"

# Clone the iPXE repo
RUN git clone "git://git.ipxe.org/ipxe.git" /ipxe.git/ && cd /ipxe.git/ && git checkout "${IPXE_TAG}" -b ipsogen

# Enable Download via HTTPS, FTP, NFS
RUN sed -Ei "s/^#undef([ \t]*DOWNLOAD_PROTO_(HTTPS|FTP|NFS)[ \t]*)/#define\1/" /ipxe.git/src/config/general.h

# Enable SANBoot via iSCSI, AoE, Infiniband SCSI RDMA, Fibre Channel, HTTP SAN
# RUN sed -Ei "s/^\/\/#undef([ \t]*SANBOOT_PROTO_(ISCSI|AOE|IB_SRP|FCP|HTTP)[ \t]*)/#define\1/" /ipxe.git/src/config/general.h

# Enable additional iPXE commands: nslookup, ping, console, ipstat, profstat, ntp, cert
RUN sed -Ei "s/^\/\/(#define[ \t]*(NSLOOKUP|VLAN|REBOOT|POWEROFF|IMAGE_TRUST|PCI|PARAM|PING|CONSOLE|IPSTAT|NTP|CERT)_CMD)/\1/" /ipxe.git/src/config/general.h

WORKDIR /ipxe.git

# Prebuild (mandatory to avoid timeout when building ISO)
RUN make -j 4 -C src/ \
    && make -C src/ bin-x86_64-efi/ipxe.efi \
    && make -C src/ bin/ipxe.iso \
    && chown -R nobody: /ipxe.git
# chown mandatory to build ISO image file inside the container when running

# First stage build
COPY --from=efi-builder /EFI/efi.img /ipxe.git/efi.img

# Python app needs
COPY ./requirements.txt /
RUN python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r /requirements.txt

COPY . /

# Cleanup
RUN mv /EFI/img /ipxe.git/ && chown -R nobody: /ipxe.git/img && rm -rf /EFI /requirements.txt

USER nobody
WORKDIR /app

ENV GUNICORN_CMD_ARGS "--bind=0.0.0.0 --log-config /app/logger.ini"
ENTRYPOINT [ "gunicorn","ipsogen:app"]