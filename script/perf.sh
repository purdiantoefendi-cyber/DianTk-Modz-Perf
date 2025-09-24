#!/system/bin/sh
#By Morpheus

# Sync to data in the rare case a device crashes
sync

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
INT="/storage/emulated/0"
AGD="$INT/DianTk-Modz-Perf"
LOG="$AGD/DianTk-log.log"

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

# perf.sh - Extreme Performance Mode

CPU_CTL="/dev/cpuctl/diantk_modz"
CPUSET="/dev/cpuset/diantk_modz"
STUNE="/dev/stune/diantk_modz"   # kalau tidak ada, baris stune akan otomatis gagal diam-diam

APP_LIST="$AGD/applist_perf.txt"

# === Masukkan app dari list ke cgroup ===
if [ ! -f "$APP_LIST" ]; then
    echo "File list app tidak ditemukan: $APP_LIST" >> "$LOG"
    # lanjutkan tanpa exit
fi

# Fallback pidof jika tidak ada
pidof() {
    pid=$(ps | grep "$1" | grep -v grep | awk '{print $2}')
    echo "$pid"
}

while IFS= read -r APP || [ -n "$APP" ]; do
    [ -z "$APP" ] && continue

    PID=$(pidof "$APP")
    if [ -z "$PID" ]; then
        echo " - $APP tidak jalan" >> "$LOG"
        continue
    fi

    for P in $PID; do
        [ -d /dev/cpuctl/diantk_modz ] && echo "$P" > /dev/cpuctl/diantk_modz/tasks 2>/dev/null
        [ -d /dev/stune/diantk_modz ]  && echo "$P" > /dev/stune/diantk_modz/tasks 2>/dev/null
        [ -d /dev/cpuset/diantk_modz ] && echo "$P" > /dev/cpuset/diantk_modz/tasks 2>/dev/null
        echo " •> $APP (PID $P) dimasukkan ke cgroup diantk_modz" >> "$LOG"
    done
done < "$APP_LIST"

# ============================================
# 1. CPU SHARES (prioritas CPU tinggi)
# ============================================
echo 999999 > $CPU_CTL/cpu.shares 2>/dev/null
echo 999999 > $STUNE/cpu.shares 2>/dev/null

# ============================================
# 2. CPU QUOTA (bebas pakai semua CPU time)
# ============================================
echo -1 > $CPU_CTL/cpu.cfs_quota_us 2>/dev/null
echo -1 > $STUNE/cpu.cfs_quota_us 2>/dev/null

# ============================================
# 3. CPUSET (akses ke semua core + semua mems)
# ============================================
# pakai semua core yang tersedia
if [ -f /sys/devices/system/cpu/online ]; then
    ALL_CPUS=$(cat /sys/devices/system/cpu/online)
    echo $ALL_CPUS > $CPUSET/cpus 2>/dev/null
fi

# pakai semua node memory
if [ -f /sys/devices/system/node/online ]; then
    ALL_MEMS=$(cat /sys/devices/system/node/online)
    echo $ALL_MEMS > $CPUSET/mems 2>/dev/null
fi

# ============================================
# 4. MEMORY (jika memory cgroup tersedia)
# ============================================
if [ -d $CPUSET ] && [ -f $CPUSET/memory.swappiness ]; then
    echo 0 > $CPUSET/memory.swappiness 2>/dev/null
fi

if [ -d $CPUSET ] && [ -f $CPUSET/memory.oom.group ]; then
    echo 1 > $CPUSET/memory.oom.group 2>/dev/null
fi

if [ -d $CPUSET ] && [ -f $CPUSET/memory.max ]; then
    echo max > $CPUSET/memory.max 2>/dev/null
fi

# ============================================
# 5. LOG INFO
# ============================================
echo " •> Extreme Performance Mode applied to diantk_modz"

# Pastikan semua core bisa diatur governor-nya
#for s in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $s/cpuinfo_max_freq; done
#for j in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do chmod 0777 $j/scaling_governor; done

# Aktifkan semua core (cpu0–cpu7)
for c in /sys/devices/system/cpu/cpu*/online; do
    echo 1 > $c
done

# Governor ke userspace dan pakai max freq
#for l in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo userspace > $l/scaling_governor; done
#for i in /sys/devices/system/cpu/{cpu1,cpu2,cpu3,cpu4,cpu5,cpu6,cpu7}/cpufreq/; do echo $(cat $i/cpuinfo_max_freq) > $i/scaling_setspeed; done

#New
for i in /sys/devices/system/cpu/cpu*/cpufreq/; do
    GOV="$i/scaling_governor"
    MIN="$i/scaling_min_freq"
    MAX="$i/scaling_max_freq"
    SET="$i/scaling_setspeed"

    chmod 0666 $GOV $MIN $MAX $SET

    echo userspace > $GOV

    FREQ=$(cat $i/cpuinfo_max_freq)

    echo $FREQ > $MIN
    echo $FREQ > $MAX
    echo $FREQ > $SET
done

# Set perf
echo " •> 🌡️ Peformance Mode activated at $(date "+%H:%M:%S")" >> $LOG

# Report
am start -a android.intent.action.MAIN -e toasttext "🌡️ Peformance Mode..." -n bellavita.toast/.MainActivity


exit 0