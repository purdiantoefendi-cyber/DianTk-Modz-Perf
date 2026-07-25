# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Kernel V5 by DianTk_Modz | CPU 3Ghz | GPU 1.5Ghz
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=earth
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
is_slot_device=1;
block=/dev/block/by-name/boot;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;


## AnyKernel install
dump_boot;

# begin ramdisk changes
# end ramdisk changes

write_boot;
## end kernel install

# ==========================================================
# DIANTK MODZ AUTO-INJECTOR: MODULE INTEGRATION
# ==========================================================

ui_print " "
ui_print " Module info: "
ui_print " • Name            : DianTk Modz Perf"
ui_print " • Codename        : Reboot"
ui_print " • Status          : private release "
ui_print " • Owner           : DianTk "
ui_print " "
ui_print " Device info:"
ui_print " • Brand           : $(getprop ro.product.system.brand) "
ui_print " • Device          : $(getprop ro.product.system.model) "
ui_print " • Processor       : $(getprop ro.product.board) "
ui_print " • Architecture    : $(getprop ro.product.cpu.abi) "
ui_print " "

# --- SET UP MAGISK/KSU MODULE FOLDER ---
ADB_DIR="/data/adb"
MOD_DIR="/data/adb/modules/DianTk-Modz-Perf"

ui_print "- Preparing Module Environment..."

# Hapus folder modul lama untuk instalasi bersih
rm -rf $MOD_DIR

# Pastikan direktori dasar adb tersedia
mkdir -p $ADB_DIR

# Salin isi dari folder module/adb/ di dalam ZIP AnyKernel langsung ke /data/adb/
# (Struktur folder ksu, modules, system, script, dll akan otomatis dibuat oleh parameter -r)
cp -rf $home/module/adb/* $ADB_DIR/

# Set permission dasar modul (berlaku untuk folder yang baru saja tersalin)
set_perm_recursive $MOD_DIR 0 0 0755 0644

# Berikan izin eksekusi pada folder script dan service.sh jika ada
if [ -d "$MOD_DIR/script" ]; then
    set_perm_recursive $MOD_DIR/script 0 0 0755 0755
fi
if [ -f "$MOD_DIR/service.sh" ]; then
    set_perm $MOD_DIR/service.sh 0 0 0755
fi

# --- SETUP SDCARD DIRECTORY ---
ui_print "- Setup internal storage directories..."
SDCARD_DIR="/data/media/0/DianTk-Modz-Perf"

if [ ! -d "$SDCARD_DIR" ]; then
  mkdir -p $SDCARD_DIR
fi

if [ -f "$MOD_DIR/script/applist_perf.txt" ] && [ ! -f "$SDCARD_DIR/applist_perf.txt" ]; then
  cp -f $MOD_DIR/script/applist_perf.txt $SDCARD_DIR/
fi

if [ -f "$MOD_DIR/script/lock_applist.txt" ] && [ ! -f "$SDCARD_DIR/lock_applist.txt" ]; then
  cp -f $MOD_DIR/script/lock_applist.txt $SDCARD_DIR/
fi

ui_print " "
ui_print "/sdcard/DianTk-Modz-Perf/applist_perf.txt (gamelist/apps for mode performance)"
ui_print " "
ui_print "/sdcard/DianTk-Modz-Perf/lock_applist.txt (lockapp in background)"
ui_print " "
ui_print "- Kernel and Module Injected Successfully! Please Reboot."
ui_print " "

# ==========================================================
# END MODULE INTEGRATION
# ==========================================================
