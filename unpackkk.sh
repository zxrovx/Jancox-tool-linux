#!/bin/bash
# jancox-tool
# by whyu6070

# sudo permissions
sudo echo

# util_functions
. ./bin/linux/utility.sh

# Clear screen and display header
clear
echo "                          Jancox Tool by wahyu6070"
echo " "
echo "             Unpack"
echo " "

# Define directories and variables
localdir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
bin=./bin/linux
sdat2img=$bin/sdat2img.py
img=$bin/imgextractor.py
edit=./editor
tmp=./bin/tmp

# Use system's brotli if available, otherwise use the provided one
if command -v brotli &>/dev/null; then
    brotli_cmd=$(command -v brotli)
else
    brotli_cmd=$bin/brotli
fi

# Create necessary directories
[ -d ./editor ] && sudo rm -rf editor; mkdir editor;
[ -d ./bin/tmp ] && sudo rm -rf ./bin/tmp; mkdir bin/tmp;
[ ! -d $tmp ] && mkdir $tmp;

# Set permissions
chmod -R 777 $bin

# Determine input zip file
if [ -f ./input.zip ]; then
     input=./input.zip
elif [ -f ./rom.zip ]; then
     input=./rom.zip
else
    input="$(zenity --title "Pick your ROM" --file-selection 2>/dev/null)"
fi

# Get username if root
sleep 1s
if [ "$(whoami)" == root ]; then
    echo -n "Username Your PC : "
    read username
else
    username=$(whoami)
fi

# Extract input zip file
echo "- Using input from $input"
if [ -f "$input" ]; then
    echo "- Extracting input.zip ..."
    if command -v unzip &>/dev/null; then
        unzip -o "$input" -d $tmp >/dev/null
    else
        echo "unzip command not found"
        exit 1
    fi
else
    echo "- File zip not found"
    exit
fi

# Unpack .br files if they exist
if [ -f $tmp/system.new.dat.br ]; then
    echo "- Unpack system.new.dat.br..."
    $brotli_cmd -d $tmp/system.new.dat.br
    if [ $? -ne 0 ]; then
        echo "Error: Failed to unpack system.new.dat.br"
        exit 1
    fi
    sudo rm -rf $tmp/system.new.dat.br
fi

if [ -f $tmp/vendor.new.dat.br ]; then
    echo "- Unpack vendor.new.dat.br..."
    $brotli_cmd -d $tmp/vendor.new.dat.br
    if [ $? -ne 0 ]; then
        echo "Error: Failed to unpack vendor.new.dat.br"
        exit 1
    fi
    sudo rm -rf $tmp/vendor.new.dat.br
fi

# Unpack .dat files if they exist
if [ -f $tmp/system.new.dat ]; then
    echo "- Unpack system.new.dat..."
    python3 $sdat2img $tmp/system.transfer.list $tmp/system.new.dat $tmp/system.img > /dev/null
    sudo rm -rf $tmp/system.transfer.list $tmp/system.new.dat $tmp/system.patch.dat
fi

if [ -f $tmp/vendor.new.dat ]; then
    echo "- Unpack vendor.new.dat..."
    python3 $sdat2img $tmp/vendor.transfer.list $tmp/vendor.new.dat $tmp/vendor.img > /dev/null
    sudo rm -rf $tmp/vendor.transfer.list $tmp/vendor.new.dat $tmp/vendor.patch.dat
fi

# Unpack .img files if they exist
if [ -f $tmp/system.img ]; then
    echo "- Unpack system.img..."
    sudo python3 $img $tmp/system.img $edit/system > /dev/null
    sudo rm -rf $tmp/system.img
fi

if [ -f $tmp/vendor.img ]; then
    echo "- Unpack vendor.img..."
    sudo python3 $img $tmp/vendor.img $edit/vendor > /dev/null
    sudo rm -rf $tmp/vendor.img
fi

# Set permissions for extracted files
echo "- Set permissions by $username..."
sudo chown -R $username:$username $edit 2>/dev/null
sudo chown -R $username:$username $tmp 2>/dev/null
[ -f $tmp/system_file_contexts ] && mv -f $tmp/system_file_contexts $edit/
[ -f $tmp/vendor_file_contexts ] && mv -f $tmp/vendor_file_contexts $edit/
[ -f $tmp/system_fs_config ] && mv -f $tmp/system_fs_config $edit/
[ -f $tmp/vendor_fs_config ] && mv -f $tmp/vendor_fs_config $edit/

# Final confirmation and cleanup
sleep 2s
if [ -f $edit/system/build.prop ]; then
    sudo rm -rf $tmp >/dev/null 2>/dev/null
    echo "- Unpack done"
    echo " "
    if [ $(grep -q secure=0 $edit/vendor/default.prop) ]; then dmverity=true;
    elif [ $(grep forceencrypt $edit/vendor/etc/fstab.qcom) ]; then dmverity=true;
    elif [ $(grep forcefdeorfbe $edit/vendor/etc/fstab.qcom) ]; then dmverity=true;
    elif [ $(grep fileencryption $edit/vendor/etc/fstab.qcom) ]; then dmverity=true;
    elif [ $(grep .dmverity=true $edit/vendor/etc/fstab.qcom) ]; then dmverity=true;
    elif [ $(grep fileencryption $edit/vendor/etc/fstab.qcom) ]; then dmverity=true;
    else dmverity=false;
    fi
    . ./bin/linux/utility.sh rom-info
else
    echo "- Unpack done"
fi
sleep 1s

