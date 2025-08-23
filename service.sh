#!/system/bin/sh

# Swap
# Waiting for boot completed
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 3; done

# Path
MODDIR="$(cd "$(dirname "$0")" && pwd)"

# Check directory
if [ ! -e /storage/emulated/0/DianTk-Modz-Perf ]; then
  mkdir /sdcard/DianTk-Modz-Perf
fi

# Check applist file
if [ ! -e /sdcard/DianTk-Modz-Perf/applist_perf.txt ]; then
  cp -f /data/adb/modules/DianTk-Modz-Perf/script/applist_perf.txt /sdcard/DianTk-Modz-Perf/
fi

# Check dozer file
if [ ! -e /sdcard/DianTk-Modz-Perf/dozer_exept.txt ]; then
  cp -f /data/adb/modules/DianTk-Modz-Perf/script/dozer_exept.txt /sdcard/DianTk-Modz-Perf/
fi

#swap on
echo "-------------------" >> /data/swap/swapfile.log
now=$(date)
echo "$now" >> /data/swap/swapfile.log

# START BOOT SAFETY
# We create a file before swap on and delete it after successful start
# If the file exists on service boot, that means there has been an issue from the 
# Module. Ask the user to share the /data/swap/swapfile.log file with devs

if [ -e "/data/swap/INCOMPLETE" ]; then
    echo "$now : INCOMPLETE FILE still exists! Did it Fail to boot?" >> /data/swap/swapfile.log
else
    echo "INCOMPLETE" >> /data/swap/INCOMPLETE
    SWAP_FILE_PRIOR="$(cat /data/swap/SWAP_FILE_PRIOR)"
    SWAPPINESS="$(cat /data/swap/SWAPPINESS)"
    sysctl vm.swappiness=200
    if [[ "$SWAP_FILE_PRIOR" -eq 0 ]]; then
        /system/bin/swapon /data/swap/swapfile >> /data/swap/swapfile.log
    else
        /system/bin/swapon -p $SWAP_FILE_PRIOR /data/swap/swapfile >> /data/swap/swapfile.log
    fi
fi
# Service BOOT OK!
rm /data/swap/INCOMPLETE

#swappiness
echo 200 > /proc/sys/vm/swappiness
sysctl vm.swappiness=200

# Enable all tweak
su -lp 2000 -c "cmd notification post -S bigtext -t 'DianTk Modz Perf' tag '📢 Apply optimization please wait...'" >/dev/null 2>&1

# Begine AI
sleep 3
# Exec Morpheus Function Tweak
nohup sh $MODDIR/script/DianTk-AI.sh &

#angle
cmd settings put global angle_gl_driver_selection_values angle
cmd settings put global angle_gl_driver_all_angle 1

#animation off
settings put global transition_animation_scale 0
settings put global window_animation_scale 0
settings put global animator_duration_scale 0

#DeepSleep
dumpsys deviceidle force-idle

#disable thermal replace
nohup sh $MODDIR/Atlantis &
nohup sh $MODDIR/@Z907L &
nohup sh $MODDIR/local &

#dozer
nohup sh $MODDIR/dozer &

#cpuruntime breaker
nohup sh $MODDIR/breaker &

#disable syslimit
nohup sh $MODDIR/syslimit &

echo " •> DianTk Syslimit Disabler + CPU Runtime Breaker Has Been Patched at $(date +"%d-%m-%Y %r")" >> /storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

# Done
su -lp 2000 -c "cmd notification post -S bigtext -t 'DianTk Modz Perf' tag '🎉 All optimization is applied...'" >/dev/null 2>&1

exit 0
