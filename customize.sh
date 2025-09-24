#!/sbin/sh

MODPATH=/data/adb/modules_update/DianTk-Modz-Perf

# Set what you want to display when installing your module

ui_print " "
ui_print " Module info: "
ui_print " • Name            : DianTk Modz Perf+Morp:AutoChange-Render"
ui_print " • Codename        : Reboot"
ui_print " • Version         : XxX"
ui_print " • Status          : private release "
ui_print " • Owner           : DianTk "
ui_print " • Release Date    : Rilex"
ui_print " "
ui_print " Device info:"
ui_print " • Brand           : $(getprop ro.product.system.brand) "
ui_print " • Device          : $(getprop ro.product.system.model) "
ui_print " • Processor       : $(getprop ro.product.board) "
ui_print " • Android Version : $(getprop ro.system.build.version.release) "
ui_print " • SDK Version     : $(getprop ro.build.version.sdk) "
ui_print " • Architecture    : $(getprop ro.product.cpu.abi) "
ui_print " • Kernel Version  : $(uname -r) "
ui_print " "
ui_print " Thanks To:"
sleep 0.2
ui_print " • Allah swt"
sleep 0.2
ui_print " "
ui_print " • All my friends who contributed to the"
ui_print "   development of the project and many others"
ui_print " "

sleep 2
ui_print " "
ui_print " !!! WARNING !!!"
ui_print " "
ui_print " Dont Use or Apply Any:"
ui_print " • Render change tweaks/mod/optimization, and any Swap"
ui_print " "
ui_print " [ Only approved modifications from trusted developers"
ui_print " should be used to ensure continued normal functioning"
ui_print " and prevent potential issues. ]"
ui_print " "
ui_print " Preparing Settings..."

# Set permissions
ui_print " - Setting permissions"

sleep 2
ui_print " Apply Tweaks & Settings:"
ui_print " "
ui_print " Preparing Settings..."

# Set permissions
ui_print " - Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/script 0 0 0755 0755
# # Installation script
chmod 0755 $MODPATH/*

# Setting permissions
set_perm_recursive $MODPATH 0 0 0755 0644


AUTOMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true


# Load utility functions
# SWAP FILE SIZE [2 - 999999]MB
SWAP_BIN_SIZE=4096
# SWAPPINESS [0 - 100]
SWAPPINESS=200
# SWAP PRIORITY [-999999 - 999999]
# 0 Will make it auto
SWAP_FILE_PRIOR=0


# Create Swapfile
ui_print "- Trying to stop Existing Swapfile"
ui_print "  (This can take a long time, do not panic if it looks stuck)"
swapoff /data/swap/swapfile
ui_print "- [OK]"
rm -rf /data/swap
mkdir /data/swap
ui_print "- Creating a swapfile of $SWAP_BIN_SIZE MB"
ui_print "  This can take a minute or two..."
cd /data/swap && dd if=/dev/zero of=swapfile bs=1048576 count=$SWAP_BIN_SIZE
ui_print "- [OK]"
ui_print "- Making Swapfile..."
cd /data/swap && mkswap swapfile
ui_print "- [OK]"

# Enable Swapfile settings
ui_print "- Setting Swappiness to $SWAPPINESS"
sysctl vm.swappiness=$SWAPPINESS
echo $SWAP_FILE_PRIOR > /data/swap/SWAP_FILE_PRIOR
echo $SWAPPINESS > /data/swap/SWAPPINESS
echo $SWAPPINESS > /proc/sys/vm/swappiness
ui_print "- [OK]"

# busybox
deploy(){
A=$(getprop ro.product.cpu.abi);
set_perm_recursive $MODPATH/system/xbin/ 0 0 0755 0777;
chmod -R 755 $MODPATH/system/xbin;
rm -f $MODPATH/isinstalled;

# Logika instalasi busybox berdasarkan arsitektur
# Jika arsitektur tidak ditemukan, proses ini akan dilewati dan skrip akan melanjutkan.
if [ "$A" = "$(echo "$A"|grep "arm64")" ]; then
    mv -f $MODPATH/system/xbin/busybox8 $MODPATH/system/xbin/busybox;
    rm -Rf $MODPATH/system/xbin/busybox7;
    rm -Rf $MODPATH/system/xbin/busybox64;
    rm -Rf $MODPATH/system/xbin/busybox86;
    ui_print "- 64 bit ARM arch detected. Installing busybox."
elif [ "$A" = "$(echo "$A"|grep "armeabi")" ]; then
    mv -f $MODPATH/system/xbin/busybox7 $MODPATH/system/xbin/busybox;
    rm -Rf $MODPATH/system/xbin/busybox8;
    rm -Rf $MODPATH/system/xbin/busybox64;
    rm -Rf $MODPATH/system/xbin/busybox86;
    ui_print "- 32bit ARM arch detected. Installing busybox."
elif [ "$A" = "$(echo "$A"|grep "x86_64")" ]; then
    mv -f $MODPATH/system/xbin/busybox64 $MODPATH/system/xbin/busybox;
    rm -Rf $MODPATH/system/xbin/busybox86;
    rm -Rf $MODPATH/system/xbin/busybox7;
    rm -Rf $MODPATH/system/xbin/busybox8;
    ui_print "- x86_64 arch detected. Installing busybox."
elif [ "$A" = "$(echo "$A"|grep "x86")" ]; then
    mv -f $MODPATH/system/xbin/busybox86 $MODPATH/system/xbin/busybox;
    rm -Rf $MODPATH/system/xbin/busybox64;
    rm -Rf $MODPATH/system/xbin/busybox7;
    rm -Rf $MODPATH/system/xbin/busybox8;
    ui_print "- x86_64 arch detected. Installing busybox."
else
    # Jika arsitektur tidak terdeteksi, cetak pesan peringatan dan hapus semua file busybox dari MODPATH.
    # Dengan begitu, instalasi busybox akan dilewati.
    ui_print "- WARNING: Can't detect arch of device! Skipping busybox installation."
    rm -Rf $MODPATH/system/xbin/busybox*;
fi;
};

# Hapus blok if/elif yang memeriksa konflik.
# Hanya lakukan penghapusan busybox lama secara paksa jika terdeteksi, lalu panggil fungsi deploy().
if [ -d /data/adb/modules/busybox-brutal ]; then
    ui_print "- Brutal busybox module already exists. Reinstalling."
    deploy;
else
    # Hapus busybox lama secara paksa jika ditemukan
    if [ -d /data/adb/modules/busybox-ndk ]; then
        ui_print "- Warning: busybox-ndk module detected. Attempting to reinstall over it."
        # Perlu dicatat: menghapus modul lama dari sini bisa berbahaya.
        # Pendekatan yang lebih aman adalah membiarkannya dan membiarkan Magisk menangani penimpaan.
    elif [ -e /system/xbin/busybox ]; then
        ui_print "- Warning: Busybox found in /system/xbin/. Overwriting."
        rm -f /system/xbin/busybox;
    elif [ -e /system/bin/busybox ]; then
        ui_print "- Warning: Busybox found in /system/bin/. Overwriting."
        rm -f /system/bin/busybox;
    elif [ -e /vendor/bin/busybox ]; then
        ui_print "- Warning: Busybox found in /vendor/bin/. Overwriting."
        rm -f /vendor/bin/busybox;
    fi;

    # Panggil fungsi deploy untuk memulai instalasi.
    deploy;
    
    # Blok instalasi ke /system/bin/
    if [ ! -e /system/xbin ]; then
        mkdir $MODPATH/system/bin;
        set_perm_recursive $MODPATH/system/bin/ 0 0 0755 0777;
        chmod -R 755 $MODPATH/system/bin;
        # Hanya pindahkan file jika busybox berhasil diinstal di langkah deploy()
        if [ -e $MODPATH/system/xbin/busybox ]; then
            mv -f $MODPATH/system/xbin/busybox $MODPATH/system/bin/busybox;
            rm -Rf $MODPATH/system/xbin;
            ui_print "- Installing to /system/bin/..";
        fi;
    fi;

    ui_print "- Brutal busybox by FeraVolt installed successfully."
    
# Install toast app
ui_print "• Menginstall Toast.apk..."

APK="$MODPATH/Toast.apk"
PKG="bellavita.toast"

if [ -f "$APK" ]; then
  if pm install -r "$APK" >/dev/null 2>&1; then
    ui_print "   [✓] Berhasil install $PKG"
    rm -f "$APK"
  else
    ui_print "   [✗] Gagal install $PKG"
    rm -f "$APK"
  fi
else
  ui_print "   [!] File $APK tidak ditemukan"
fi
    
# Check directory
if [ ! -e /storage/emulated/0/DianTk-Modz-Perf ]; then
  mkdir /sdcard/DianTk-Modz-Perf
fi

# Check applist file
if [ ! -e /sdcard/DianTk-Modz-Perf/applist_perf.txt ]; then
  cp -f /data/adb/modules_update/DianTk-Modz-Perf/script/applist_perf.txt /sdcard/DianTk-Modz-Perf/
fi

# Check dozer file
if [ ! -e /sdcard/DianTk-Modz-Perf/dozer_exept.txt ]; then
  cp -f /data/adb/modules_update/DianTk-Modz-Perf/script/dozer_exept.txt /sdcard/DianTk-Modz-Perf/
fi
echo
ui_print "/sdcard/DianTk-Modz-Perf/applist_perf.txt (gamelist/apps for mode performance)"
echo
ui_print "/sdcard/DianTk-Modz-Perf/dozer_exept.txt (always on / allow background apps)"
echo
    ui_print "- Please reboot right NOW."
fi;

                




