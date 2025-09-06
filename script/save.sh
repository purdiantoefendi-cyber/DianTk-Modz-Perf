#!/system/bin/sh

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
LOG=/storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

# Sync to data in the rare case a device crashes
sync

# Screen is off, initiate Save Mode
# Governor
#for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
#    echo "powersave" > "$cpu"
#done

# Disable perf it when done
cmd power set-fixed-performance-mode-enabled false

settings put global low_power 1
setprop debug.performance.tuning 0
setprop persist.sys.power.default.powermode 0

#autocpu
for s in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $s/cpuinfo_max_freq; done
for j in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $j/scaling_governor; done
for l in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo userspace > $l/scaling_governor; done
for i in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo 0 > $i/scaling_setspeed; done

#for i in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo 500000 > $i/scaling_setspeed; done

# Report
am start -a android.intent.action.MAIN -e toasttext "💤 Powersaver Mode..." -n bellavita.toast/.MainActivity
echo " •> 💤 Powersaver Mode $(date +"%d-%m-%Y %r")" >> /storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

exit 0