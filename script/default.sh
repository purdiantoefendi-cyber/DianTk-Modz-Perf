#!/system/bin/sh

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

# Aktifkan semua little core (cpu0–cpu3)
for c in /sys/devices/system/cpu/{cpu0,cpu1,cpu2,cpu3}/online; do
    echo 1 > $c
done

# Matikan sebagian big core (cpu4, cpu5)
for c in /sys/devices/system/cpu/{cpu4,cpu5}/online; do
    echo 0 > $c
done

# Aktifkan sebagian big core (cpu6, cpu7)
for c in /sys/devices/system/cpu/{cpu6,cpu7}/online; do
    echo 1 > $c
done

#New
# Target frekuensi (1.4 GHz)
TARGET=1450000

for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    GOV="$cpu/cpufreq/scaling_governor"
    MIN="$cpu/cpufreq/scaling_min_freq"
    MAX="$cpu/cpufreq/scaling_max_freq"
    SET="$cpu/cpufreq/scaling_setspeed"
    AVAIL="$cpu/cpufreq/scaling_available_frequencies"

    # Pastikan file tersedia
    [ -f "$AVAIL" ] || continue

    # Ambil daftar frekuensi CPU ini
    FREQS=$(cat $AVAIL)
    arr=($FREQS)

    # Cari frekuensi terdekat dengan target
    closest=${arr[0]}
    for f in "${arr[@]}"; do
        diff=$((f > TARGET ? f - TARGET : TARGET - f))
        best=$((closest > TARGET ? closest - TARGET : TARGET - closest))
        if [ $diff -lt $best ]; then
            closest=$f
        fi
    done

    FREQ=$closest
    echo "CPU$(basename $cpu) → lock ke $FREQ kHz (target $TARGET)"

    # Set permission (kalau perlu)
    chmod 0666 $GOV $MIN $MAX $SET

    # Set governor ke userspace
    echo userspace > $GOV

    # Lock min/max/setspeed
    echo $FREQ > $MIN
    echo $FREQ > $MAX
    echo $FREQ > $SET
done

# Set balance
echo " •> ❄️ Default mode activated at $(date "+%H:%M:%S")" >> $LOG

#report
am start -a android.intent.action.MAIN -e toasttext "❄️ Default Mode..." -n bellavita.toast/.MainActivity