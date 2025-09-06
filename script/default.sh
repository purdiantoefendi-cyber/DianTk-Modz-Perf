#!/system/bin/sh
#By Morpheus

# Sync to data in the rare case a device crashes
sync

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
LOG=/storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

#autogapps
listgapps=$(pm list packages | cut -f 2 -d ":" | grep -e google -e vending)
pm enable $listgapps

change_default()
{
# Sett Renderer
default=(
"debug.hwui.renderer skiagl"
"debug.renderengine.backend skiagl"
"renderthread.vulkanthreaded"
"reduceopstasksplitting false"
"ro.hwui.hardware.vulkan false"
"ro.hwui.use_vulkan false"
"ro.ui.pipeline skiagl"
"ro.hwui.skia.show_vulkan_pipeline false"
"ro.hardware.cpu_use skiagl"
"debug.performance.tuning 0"
"persist.sys.power.default.powermode 0"
)
for default in "${default[@]}"; do
    setprop $default     
done
}

# Disable perf it when done
cmd power set-fixed-performance-mode-enabled false

settings put global low_power 0
#for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
#    echo "userspace" > "$cpu"
#done
for s in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $s/cpuinfo_max_freq; done
#autocpu
for j in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $j/scaling_governor; done
for l in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo userspace > $l/scaling_governor; done
for i in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo 1400000 > $i/scaling_setspeed; done

# Set balance
echo " •> ❄️ Default mode activated at $(date "+%H:%M:%S")" >> $LOG

#report
am start -a android.intent.action.MAIN -e toasttext "❄️ Default Mode..." -n bellavita.toast/.MainActivity

exit 0