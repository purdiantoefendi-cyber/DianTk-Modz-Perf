#!/system/bin/sh

# Sync to data in the rare case a device crashes
sync

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
LOG=/storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

nohup sh "$BASEDIR/enable_thermal" &

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

#iosched
echo kyber > /sys/block/mmcblk0/queue/scheduler

# Disable perf it when done
cmd power set-fixed-performance-mode-enabled false

settings put global low_power 0

# perf-reset.sh - Reset Extreme Performance Mode

CPU_CTL="/dev/cpuctl/diantk_modz"
CPUSET="/dev/cpuset/diantk_modz"
STUNE="/dev/stune/diantk_modz"

# ============================================
# 1. CPU SHARES kembali default (1024 biasanya)
# ============================================
echo 1024 > $CPU_CTL/cpu.shares 2>/dev/null
echo 1024 > $STUNE/cpu.shares 2>/dev/null

# ============================================
# 2. CPU QUOTA default (100% quota)
#    100000 us = 100ms period, quota = 100000 us
# ============================================
echo 100000 > $CPU_CTL/cpu.cfs_quota_us 2>/dev/null
echo 100000 > $STUNE/cpu.cfs_quota_us 2>/dev/null

# ============================================
# 3. CPUSET default → semua core tetap diizinkan
#    tapi biasanya di OS, cpuset dibagi (top-app, bg, dsb)
#    jadi kalau perlu reset penuh, bisa dibiarkan kosong
# ============================================
if [ -f $CPUSET/cpus ]; then
    echo 0 > $CPUSET/cpus 2>/dev/null   # fallback: cuma core 0
fi

if [ -f $CPUSET/mems ]; then
    echo 0 > $CPUSET/mems 2>/dev/null   # fallback: cuma mem node 0
fi

# ============================================
# 4. MEMORY reset (jika tersedia)
# ============================================
if [ -f $CPUSET/memory.swappiness ]; then
    echo 60 > $CPUSET/memory.swappiness 2>/dev/null  # default Linux = 60
fi

if [ -f $CPUSET/memory.oom.group ]; then
    echo 0 > $CPUSET/memory.oom.group 2>/dev/null
fi

if [ -f $CPUSET/memory.max ]; then
    echo max > $CPUSET/memory.max 2>/dev/null
fi

# ============================================
# 5. LOG INFO
# ============================================
echo " •> Extreme Performance Mode reset → default"

# Set balance
echo " •> ❄️ Default mode activated at $(date "+%H:%M:%S")" >> $LOG

#report
am start -a android.intent.action.MAIN -e toasttext "❄️ Default Mode..." -n bellavita.toast/.MainActivity
