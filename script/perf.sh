#!/system/bin/sh
#By Morpheus

# Sync to data in the rare case a device crashes
sync

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
INT="/storage/emulated/0"
AGD="$INT/DianTk-Modz-Perf"
LOG="$AGD/DianTk-log.log"

nohup sh "$BASEDIR/disable_thermal" &

#auto gapp
listgapps=$(pm list packages | cut -f 2 -d ":" | grep -e google -e vending)
pm disable $listgapps


change_vulkan()
{
# Sett Renderer
render=(
"ro.hwui.use_vulkan true"
"ro.hwui.hardware.vulkan true"
"ro.hwui.use_vulkan true"
"debug.vulkan.layers.enable 1"
"persist.sys.disable_skia_path_ops false"
"ro.config.hw_high_perf true"
"persist.sys.gpu.working_thread_priority 1"
"renderthread.skia.reduceopstasksplitting true"
"persist.sys.perf.topAppRenderThreadBoost.enable true"
"debug.skia.threaded_mode true"
"debug.hwui.fps_divisor 1"
"debug.hwui.render_thread true"
"debug.hwui.profile.maxframes 144"
"debug.hwui.render_dirty_regions false"
"debug.hwui.show_dirty_regions false"
"debug.hwui.webview_overlays_enabled true"
"debug.hwui.use_hint_manager false"
"debug.hwui.target_cpu_time_percent 1"
"debug.hwui.skia_tracing_enabled false"
"debug.hwui.skia_use_perfetto_track_events false"
"debug.hwui.capture_skp_enabled false"
"debug.hwui.trace_gpu_resources false"
"debug.hwui.show_layers_updates false"
"debug.hwui.skip_empty_damage true"
"debug.hwui.use_buffer_age false"
"debug.hwui.use_partial_updates false"
"debug.hwui.use_gpu_pixel_buffers false"
"debug.hwui.filter_test_overhead false"
"debug.hwui.overdraw true"
"debug.hwui.level 2"
"debug.hwui.clip_surfaceviews false"
"debug.hwui.nv_profiling false"
"debug.hwui.disable_draw_defer true"
"debug.hwui.disable_draw_reorder true"
"debug.hwui.8bit_hdr_headroom false"
"debug.hwui.app_memory_policy true"
"ro.hwui.disable_scissor_opt false"
"debug.hwui.disable_vsync false"
"debug.hwui.skp_filename false"
"ro.hwui.layer_cache_size 256.0f"
"ro.hwui.texture_cache_size 256.0f"
"ro.hwui.shape_cache_size 256.0f"
"ro.hwui.patch_cache_size 256.0f"
"ro.hwui.r_buffer_cache_size 64.0f"
"ro.hwui.path_cache_size 6.0f"
"ro.hwui.vertex_cache_size 1.6f"
"ro.hwui.drop_shadow_cache_size 4.0f"
"ro.hwui.texture_cache_flushrate 0.9f"
)
for render in "${render[@]}"; do
    setprop $render     
done
}
#iosched
echo performance > /sys/block/mmcblk0/queue/scheduler

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
        echo " - $APP tidak jalan"
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

# Set perf
echo " •> 🌡️ Peformance Mode activated at $(date "+%H:%M:%S")" >> $LOG

# Report
am start -a android.intent.action.MAIN -e toasttext "🌡️ Peformance Mode..." -n bellavita.toast/.MainActivity
