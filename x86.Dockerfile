FROM amd64/ubuntu:20.04
MAINTAINER Joseph Lee <joseph@zeronsoftn.com>

ENV DEBIAN_FRONTEND=noninteractive

COPY ["mirrors.txt", "/tmp/"]
RUN apt-get update -y && apt-get install -y ca-certificates openssl && \
    APT_REPO=$(cat /tmp/mirrors.txt | grep '/ubuntu/' | head -n 1) && \
    echo "APT_REPO: $APT_REPO" && \
    echo "\n\
deb $APT_REPO focal main restricted universe multiverse\n\
deb $APT_REPO focal-updates main restricted universe multiverse\n\
deb $APT_REPO focal-backports main restricted universe multiverse\n\
deb $APT_REPO focal-security main restricted universe multiverse\n\
" > /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get install -y bash tar xz-utils bzip2 gcc make git sed diffutils patch gnu-efi
RUN apt-get install -y libelf-dev

COPY ["opt/*", "vendor_cert.der", "/opt/"]
COPY ["build/shim.tar", "/opt/shim.tar"]
RUN chmod +x /opt/*.sh && \
    mkdir -p /work/build-x86_64 /work/build-ia32

WORKDIR /work

RUN tar xf /opt/shim.tar

# Build 64-bit
RUN make -C build-x86_64 ARCH=x86_64 VENDOR_CERT_FILE=/opt/vendor_cert.der EFI_PATH=/usr/lib \
    TOPDIR=.. -f ../Makefile -j4

# Build 32-bit
RUN make -C build-ia32 ARCH=ia32 VENDOR_CERT_FILE=/opt/vendor_cert.der EFI_PATH=/usr/lib32 \
    TOPDIR=.. -f ../Makefile -j4

