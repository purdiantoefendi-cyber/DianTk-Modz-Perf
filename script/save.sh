#!/system/bin/sh

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
LOG=/storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

nohup sh "$BASEDIR/powersave_thermal" &

# Sync to data in the rare case a device crashes
sync

# Disable perf it when done
cmd power set-fixed-performance-mode-enabled false

settings put global low_power 1
setprop debug.performance.tuning 0
setprop persist.sys.power.default.powermode 0

# powersave.sh - Super Hemat Daya Mode untuk diantk_modz

CPU_CTL="/dev/cpuctl/diantk_modz"
CPUSET="/dev/cpuset/diantk_modz"
STUNE="/dev/stune/diantk_modz"

# ============================================
# 1. CPU SHARES kecil → kasih prioritas rendah
# ============================================
echo 2 > $CPU_CTL/cpu.shares 2>/dev/null
echo 2 > $STUNE/cpu.shares 2>/dev/null

# ============================================
# 2. CPU QUOTA → batasi CPU usage (misal 20%)
# ============================================
# period = 100000 us, quota = 20000 us → max 20% CPU time
echo 20000 > $CPU_CTL/cpu.cfs_quota_us 2>/dev/null
echo 20000 > $STUNE/cpu.cfs_quota_us 2>/dev/null

# ============================================
# 3. CPUSET → pakai hanya core kecil (LITTLE cluster)
# ============================================
if [ -f /sys/devices/system/cpu/possible ]; then
    LITTLE_CORES="0-3"   # contoh LITTLE 4 core
    echo $LITTLE_CORES > $CPUSET/cpus 2>/dev/null
fi

if [ -f /sys/devices/system/node/online ]; then
    echo 0 > $CPUSET/mems 2>/dev/null   # pakai mem node 0 saja
fi

# ============================================
# 4. MEMORY → lebih agresif swap (hemat RAM)
# ============================================
if [ -f $CPUSET/memory.swappiness ]; then
    echo 100 > $CPUSET/memory.swappiness 2>/dev/null
fi

if [ -f $CPUSET/memory.oom.group ]; then
    echo 0 > $CPUSET/memory.oom.group 2>/dev/null
fi

# ============================================
# 5. LOG INFO
# ============================================
echo " •> Powersave Mode applied to diantk_modz"

# Report
am start -a android.intent.action.MAIN -e toasttext "💤 Powersaver Mode..." -n bellavita.toast/.MainActivity
echo " •> 💤 Powersaver Mode $(date +"%d-%m-%Y %r")" >> /storage/emulated/0/DianTk-Modz-Perf/DianTk-log.log

exit 0
