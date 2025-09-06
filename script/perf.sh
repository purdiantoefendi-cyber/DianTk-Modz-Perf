#!/system/bin/sh
#By Morpheus

# Sync to data in the rare case a device crashes
sync

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
LOG=/storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

#auto gapp
listgapps=$(pm list packages | cut -f 2 -d ":" | grep -e google -e vending)
pm disable $listgapps


change_vulkan()
{
# Sett Renderer
render=(
"debug.hwui.renderer skiavk"
"debug.renderengine.backend skiavk"
"renderthread.skiavkthreaded"
"reduceopstasksplitting true"
"ro.hwui.hardware.skiavk true"
"ro.hwui.use_skiavk true"
"ro.ui.pipeline skiavk"
"ro.hwui.skia.show_skiavk_pipeline true"
"ro.hardware.cpu_use skiavk"
"debug.performance.tuning 1"
"persist.sys.power.default.powermode 1"
)
for render in "${render[@]}"; do
    setprop $render     
done
}
# Enable Fixed Performance Mode
cmd power set-fixed-performance-mode-enabled true

settings put global low_power 0
#for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
#    echo "userspace" > "$cpu"
#done

#autocpu
#!/bin/sh
for s in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $s/cpuinfo_max_freq; done
for j in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $j/scaling_governor; done
for l in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo userspace > $l/scaling_governor; done
for i in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo $(cat $i/cpuinfo_max_freq) > $i/scaling_setspeed; done

# Set perf
echo " •> 🌡️ Peformance Mode activated at $(date "+%H:%M:%S")" >> $LOG

# Report
am start -a android.intent.action.MAIN -e toasttext "🌡️ Peformance Mode..." -n bellavita.toast/.MainActivity


exit 0