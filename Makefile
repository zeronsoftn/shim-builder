IMAGE_NAME_PREFIX=zeron-shim-builder2

PWD:=$(shell pwd)
UID:=$(shell id -u)
GID:=$(shell id -g)

CURRENT_DIR=${PWD}

SHIM_GIT_REPO=https://github.com/zeronsoftn/shim.git
SHIM_GIT_TAG=zeron/15+1552672080.a4a1fbe-1

BUILD_OUT_DIR=${CURRENT_DIR}/build/out

PHONY: build-x86 copy-x86 build-arm64 copy-arm64 review-request

build/prepare:
	rm -rf build
	mkdir -p ${BUILD_OUT_DIR}
	touch build/prepare

build/shim.tar: build/prepare
	rm -rf build/shim
	git clone -b "${SHIM_GIT_TAG}" "${SHIM_GIT_REPO}" build/shim
	rm -rf .build/shim/.git
	cd build/shim && tar -cf ${CURRENT_DIR}/build/shim.tar .

build/prepare-multiarch:
	sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	touch build/prepare-multiarch

build-x86: build/shim.tar
	sudo docker build -t ${IMAGE_NAME_PREFIX}-x86 -f x86.Dockerfile .

copy-x86: build-x86
	sudo rm -rf ${BUILD_OUT_DIR}/x86_64 ${BUILD_OUT_DIR}/ia32
	sudo docker run --rm -it -v ${BUILD_OUT_DIR}/x86_64:/work/out ${IMAGE_NAME_PREFIX}-x86 make -C build-x86_64 ARCH=x86_64 \
		DESTDIR=/work/out EFIDIR=ZeronsoftN TOPDIR=.. -f ../Makefile install
	sudo docker run --rm -it -v ${BUILD_OUT_DIR}/ia32:/work/out ${IMAGE_NAME_PREFIX}-x86 make -C build-ia32 ARCH=ia32 \
		DESTDIR=/work/out EFIDIR=ZeronsoftN TOPDIR=.. -f ../Makefile install
	sudo chown ${UID}:${GID} -R ${BUILD_OUT_DIR}/x86_64
	sudo chown ${UID}:${GID} -R ${BUILD_OUT_DIR}/ia32

build-arm64: build/shim.tar build/prepare-multiarch
	sed 's,<!DOCKER_IMAGE_ARCH>,arm64v8,g; s,<!BUILD_ARCH>,arm64,g; s,<!BUILD_GRUB_ARCH>,arm64,g; s,<!BUILD_SHIM_ARCH>,aarch64,g; s,<!MIRROR_FIND_STR>,/ubuntu-ports/,g' master.Dockerfile > Dockerfile.arm64
	sudo docker build -t ${IMAGE_NAME_PREFIX}-arm64 -f Dockerfile.arm64 .

copy-arm64: build-arm64
	sudo rm -rf ${BUILD_OUT_DIR}/arm64
	sudo docker run --rm -it -v ${BUILD_OUT_DIR}/arm64:/work/out ${IMAGE_NAME_PREFIX}-arm64 make -C build \
		DESTDIR=/work/out EFIDIR=ZeronsoftN TOPDIR=.. -f ../Makefile install
	sudo chown ${UID}:${GID} -R ${BUILD_OUT_DIR}/arm64

copy-for-review:
	mkdir -p review-request
	cp -f $(shell find ./build/out/ -type f -name "shim*.efi") ./review-request/
	find ./review-request/ -name "*.efi" | sort | xargs sha256sum

all: copy-x86 copy-arm64 copy-for-review

