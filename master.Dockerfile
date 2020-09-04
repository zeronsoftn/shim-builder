FROM <!DOCKER_IMAGE_ARCH>/ubuntu:20.04
MAINTAINER Joseph Lee <joseph@zeronsoftn.com>

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_ARCH=<!BUILD_ARCH>
ENV BUILD_GRUB_ARCH=<!BUILD_GRUB_ARCH>

COPY ["build/tmp/mirrors.txt", "/tmp/"]
RUN apt-get update -y && apt-get install -y ca-certificates openssl && \
    APT_REPO=$(cat /tmp/mirrors.txt | grep '<!MIRROR_FIND_STR>' | head -n 1) && \
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
    mkdir -p /work

CMD ["/opt/build.sh"]

