#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
# Feravolt 2022
MODDIR=${0%/*}

if [ ! -e $MODDIR/isinstalled ]; then
 if [ ! -d $MODDIR/system/xbin ]; then
 chown 0:0 $MODDIR/system/bin/busybox;
 chmod 775 $MODDIR/system/bin/busybox;
 chcon u:object_r:system_file:s0 $MODDIR/system/bin/busybox;
 $MODDIR/system/bin/busybox --install -s $MODDIR/system/bin/;
 for sd in /system/bin/*; do
   rm -f $MODDIR/${sd};
 done;
else
 chown 0:0 $MODDIR/system/xbin/busybox;
 chmod 775 $MODDIR/system/xbin/busybox;
 chcon u:object_r:system_file:s0 $MODDIR/system/xbin/busybox;
 $MODDIR/system/xbin/busybox --install -s $MODDIR/system/xbin/;
 fi;
 rm -f $MODDIR/applets.png;
 touch $MODDIR/isinstalled;
fi;

