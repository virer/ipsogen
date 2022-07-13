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
        cdrkit  \
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

COPY . /

WORKDIR /ipxe.git

RUN tar -xvzf /bundle/EFI.tgz 
# The following 2 lines as been commented to speed up process, now everything is bundled in the EFI.tgz
# Those are only there to be reproductible in case of
# USER root
# RUN rm -f /ipxe.git/efi.img && /scripts/mk_efi_img.sh

RUN chown -R nobody: /ipxe.git
USER nobody
RUN make -j 4 -C src/ \
    && make -C src/ bin-x86_64-efi/ipxe.efi \
    && make -C src/ bin/ipxe.iso



RUN python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r /requirements.txt

ENV GUNICORN_CMD_ARGS="--bind=0.0.0.0 --log-config /app/logger.ini"
ENTRYPOINT [ "gunicorn","ispogen:app"]