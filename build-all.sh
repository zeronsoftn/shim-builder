#!/bin/bash

set -e

CURRENT_DIR=$PWD

SHIM_GIT_REPO=https://github.com/zeronsoftn/shim.git
SHIM_GIT_TAG=zeron/15+1552672080.a4a1fbe-1

BUILD_TMP_DIR=$CURRENT_DIR/build/tmp
BUILD_OUT_DIR=$CURRENT_DIR/build/out
BUILD_LOG_DIR=$CURRENT_DIR/build/log

REVIEW_REQUEST_OUTPUT_DIR=$CURRENT_DIR/review-request

rm -rf ./build
rm -rf $BUILD_OUT_DIR
mkdir -p $BUILD_TMP_DIR $BUILD_OUT_DIR $BUILD_LOG_DIR $REVIEW_REQUEST_OUTPUT_DIR
curl -o ./build/tmp/mirrors.txt http://mirrors.ubuntu.com/mirrors.txt

rm -rf ./build/shim
git clone -b "$SHIM_GIT_TAG" "$SHIM_GIT_REPO" ./build/shim

cd ./build/shim
rm -rf .git
tar -cf $CURRENT_DIR/build/shim.tar .

cd $CURRENT_DIR

sed 's,<!DOCKER_IMAGE_ARCH>,amd64,g; s,<!BUILD_ARCH>,x86_64,g; s,<!BUILD_GRUB_ARCH>,x86_64,g; s,<!MIRROR_FIND_STR>,/ubuntu/,g' master.Dockerfile > Dockerfile.x86_64
sed 's,<!DOCKER_IMAGE_ARCH>,i386,g; s,<!BUILD_ARCH>,i386,g; s,<!BUILD_GRUB_ARCH>,i386,g; s,<!MIRROR_FIND_STR>,/ubuntu/,g' master.Dockerfile > Dockerfile.i386
sed 's,<!DOCKER_IMAGE_ARCH>,arm64v8,g; s,<!BUILD_ARCH>,arm64,g; s,<!BUILD_GRUB_ARCH>,arm64,g; s,<!MIRROR_FIND_STR>,/ubuntu-ports/,g' master.Dockerfile > Dockerfile.arm64

IMAGE_NAME_PREFIX=zeron-shim-builder

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

ARCH_LIST="x86_64 i386 arm64"

for build_arch in $ARCH_LIST; do
	docker build --tag=${IMAGE_NAME_PREFIX}_$build_arch -f Dockerfile.$build_arch .
done

for build_arch in $ARCH_LIST; do
	cur_out_dir=$BUILD_OUT_DIR/$build_arch
	cur_log_file=$BUILD_LOG_DIR/$build_arch.log
	mkdir -p $cur_out_dir $REVIEW_REQUEST_OUTPUT_DIR/$build_arch
        docker run --rm -it -v $cur_out_dir:/work/out ${IMAGE_NAME_PREFIX}_$build_arch > $cur_log_file
	cp -rf $cur_out_dir/boot/efi/EFI/* $REVIEW_REQUEST_OUTPUT_DIR/$build_arch
	cp $cur_log_file $REVIEW_REQUEST_OUTPUT_DIR/buildlog-$build_arch.txt
done


