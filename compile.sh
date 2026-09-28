#!/bin/bash

# toolchain path
Toolchain=$(cd ../openwrt*/toolchain-mipsel*/bin; pwd)'/mipsel-openwrt-linux-'
Staging=${Toolchain%/toolchain-*}

echo "CROSS_COMPILE=${Toolchain}"
echo "STAGING_DIR=${Toolchain%/toolchain-*}"
cd $(dirname "$0")

make PYTHON=python2.7 CROSS_COMPILE=${Toolchain} STAGING_DIR=${Staging}
make savedefconfig
mkdir bin
mv defconfig bin/mt7621_defconfig
mv u-boot-mt7621.bin bin/
mv u-boot.img bin/
