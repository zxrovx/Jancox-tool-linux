#!/bin/bash
#jancox tool
#by wahyu6070

#util functions
. ./bin/linux/utility.sh

#
localdir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
out=./output
tmp=./bin/tmp
bin=./bin/linux
prop=./bin/jancox.prop
tunix=$(date -u +%s)
clear
if [ ! -d $edit/system ]; then echo "  Please Unpack !"; sleep 3s; exit;fi;
echo "                        Jancox Tool by wahyu6070"
echo "       Repack "
echo " "
$bin/utility.sh rom-info
echo " "
[ ! -d $tmp ] && mkdir $tmp
if [ -d $edit/system ]; then
echo "- Repack system"
$bin/make_ext4fs -J -T $tunix -S $edit/system_file_contexts -C $edit/system_fs_config -l 5114429440 -a /system $tmp/system.img $edit/system/ > /dev/null
fi

if [ -d $edit/vendor ]; then
echo "- Repack vendor"
$bin/make_ext4fs -J -T $tunix -S $edit/vendor_file_contexts -C $edit/vendor_fs_config -l 1452277760 -a /vendor $tmp/vendor.img $edit/vendor/ > /dev/null
fi;

if [ -d $edit/boot ] && [ -f $edit/boot.img ]; then
		echo "- Repack boot"
		[ -f editor/boot/kernel ] && cp -f $edit/boot/kernel ./
		[ -f editor/boot/kernel_dtb ] && cp -f $edit/boot/kernel_dtb ./
		[ -f editor/boot/ramdisk.cpio ] && cp -f $edit/boot/ramdisk.cpio ./
		[ -f editor/boot/second ] && cp -f $edit/boot/second ./
		$bin/magiskboot repack $edit/boot.img >/dev/null 2>/dev/null
		sleep 1s
		[ -f new-boot.img ] && mv -f ./new-boot.img $tmp/boot.img
		rm -rf kernel kernel_dtb ramdisk.cpio second >/dev/null 2>/dev/null
fi

[ -d $edit/META-INF ] && cp -a $edit/META-INF $tmp/
[ -d $edit/install ] && cp -a $edit/install $tmp/
[ -d $edit/system2 ] && cp -a $edit/system2 $tmp/system
[ -d $edit/firmware-update ] && cp -a $edit/firmware-update $tmp/
[ -f $edit/compatibility.zip ] && cp -f $edit/compatibility.zip $tmp/
[ -f $edit/compatibility_no_nfc.zip ] && cp -f $edit/compatibility_no_nfc.zip $tmp/

datefile=$(date +"%Y-%m-%d")
datetime=$(date +"%H:%M:%S")
touch -cd $datefile $datetime $tmp/*
touch -cd $datefile $datetime $tmp/install/bin/*
touch -cd $datefile $datetime $tmp/firmware-update/*
touch -cd $datefile $datetime $tmp/META-INF/com/android/*
touch -cd $datefile $datetime $tmp/META-INF/com/google/android/*


if [ -d $tmp/META-INF ]; then
	echo "- Zipping"
	[ -f ./new_rom.zip ] && rm -rf ./new_rom.zip
	$bin/7za a -tzip new_rom.zip $tmp/*  >/dev/null 2>/dev/null
fi


if [ -f ./new_rom.zip ]; then
      [ -d $tmp ] && rm -rf $tmp
      echo "- Repack done"
else
      echo "- Repack error"
fi
