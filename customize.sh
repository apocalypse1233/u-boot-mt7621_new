#!/bin/bash

# toolchain path
Toolchain=$(cd ../openwrt*/toolchain-mipsel*/bin; pwd)'/mipsel-openwrt-linux-'
Staging=${Toolchain%/toolchain-*}

echo "CROSS_COMPILE=${Toolchain}"
echo "STAGING_DIR=${Toolchain%/toolchain-*}"
cd $(dirname "$0")

# arguments:
# $1	string: u-boot partition size (in k)
# $2	string: u-boot-env partition size (in k)
# $3	string: factory partition size (in k)
# $4	string: kernel offset
# $5	number: cpu frequency
# $6	number: ram frequency
# $7	string: ddr param
# $8	string: baud rate

# simple check if partition table is valid
#if [ -z $( echo -n "$1" | grep '),-(firmware)') ]; then
	#echo "Invalid mtd partition table!"
	#exit 1
#fi

if [ -z $( echo -n "$1" | grep 'k') ]; then
	echo "Invalid u-boot partition size (example: 192k)"
	exit 1
fi

if [ -z $( echo -n "$2" | grep 'k') ]; then
	echo "Invalid u-boot-env partition size (example: 64k)"
	exit 1
fi

if [ -z $( echo -n "$3" | grep 'k') ]; then
	echo "Invalid factory partition size (example: 64k)"
	exit 1
fi

partition_table="${1}(u-boot),${2}(u-boot-env),${3}(factory),-(firmware)"

DEFCONFIG="configs/mt7621_build_defconfig"
cp configs/mt7621_nor_template_defconfig ${DEFCONFIG}

echo "set partition table: $partition_table"
echo -e "CONFIG_MTDPARTS_DEFAULT=\"mtdparts=raspi:$partition_table\"" >> ${DEFCONFIG}

echo "set kernel offset: $4"
echo "CONFIG_DEFAULT_NOR_KERNEL_OFFSET=$4" >> ${DEFCONFIG}

if [ "$5" -ge 400 -a "$5" -le 1200 ]; then
	echo "set CPU frequency: $5 MHz"
	echo "CONFIG_MT7621_CPU_FREQ_LEGACY=$5" >> ${DEFCONFIG}
else
	echo "Invalid CPU Frequency!"
	exit 1
fi

echo "set DRAM frequency: $6 MT/s"
echo "CONFIG_MT7621_DRAM_FREQ_$6_LEGACY=y" >> ${DEFCONFIG}

echo "Parse DDR init parameters: $7"
case "$7" in
DDR2-64MiB)
	echo "CONFIG_MT7621_DRAM_DDR2_512M_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR2-128MiB)
	echo "CONFIG_MT7621_DRAM_DDR2_1024M_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR2-W9751G6KB-64MiB-1066MHz)
	echo "CONFIG_MT7621_DRAM_DDR2_512M_W9751G6KB_A02_1066MHZ_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR2-W971GG6KB25-128MiB-800MHz)
	echo "CONFIG_MT7621_DRAM_DDR2_1024M_W971GG6KB25_800MHZ_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR2-W971GG6KB18-128MiB-1066MHz)
	echo "CONFIG_MT7621_DRAM_DDR2_1024M_W971GG6KB18_1066MHZ_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR3-128MiB)
	echo "CONFIG_MT7621_DRAM_DDR3_1024M_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR3-256MiB)
	echo "CONFIG_MT7621_DRAM_DDR3_2048M_LEGACY=y" >> ${DEFCONFIG}
	;;
DDR3-512MiB)
	echo "CONFIG_MT7621_DRAM_DDR3_4096M_LEGACY=y" >> ${DEFCONFIG}
	if [ -n $(cat ${DEFCONFIG} | grep MT7621_DRAM_FREQ_1200_LEGACY) ]; then
		echo "The max DRAM speed for 512 MiB RAM is 1066 MT/s"
		sed -i 's/MT7621_DRAM_FREQ_1200_LEGACY/MT7621_DRAM_FREQ_1066_LEGACY/' ${DEFCONFIG}
	fi
	;;
DDR3-128MiB-KGD)
	echo "CONFIG_MT7621_DRAM_DDR3_1024M_KGD_LEGACY=y" >> ${DEFCONFIG}
	;;
esac

echo "Set baud rate: $8"
if [ "$8" = '57600' ]; then
	echo "CONFIG_BAUDRATE=57600" >> ${DEFCONFIG}
else
	echo "CONFIG_BAUDRATE=115200" >> ${DEFCONFIG}
fi

make mt7621_build_defconfig
