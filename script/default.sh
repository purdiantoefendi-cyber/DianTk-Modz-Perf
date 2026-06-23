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
"ro.hwui.render_ahead true"
"debug.hwui.render_thread true"
"debug.skia.threaded_mode true"
"debug.hwui.render_thread_count 1"
"debug.skia.num_render_threads 1"
"debug.skia.render_thread_priority true"
"persist.sys.gpu.working_thread_priority true"
"renderthread.skia.reduceopstasksplitting true"
"persist.sys.perf.topAppRenderThreadBoost.enable true"
"debug.hwui.profile.maxframes 144"
"debug.hwui.show_dirty_regions false"
"debug.hwui.fps_divisor 1"
"debug.hwui.webview_overlays_enabled true"
"debug.hwui.use_hint_manager false"
"debug.hwui.target_cpu_time_percent 0"
"debug.hwui.skia_tracing_enabled false"
"debug.hwui.skia_use_perfetto_track_events false"
"debug.hwui.capture_skp_enabled false"
"debug.hwui.trace_gpu_resources true"
"debug.hwui.show_layers_updates false"
"debug.hwui.skip_empty_damage true"
"debug.hwui.use_buffer_age false"
"debug.hwui.use_partial_updates false"
"debug.hwui.use_gpu_pixel_buffers true"
"debug.hwui.filter_test_overhead false"
"debug.hwui.overdraw true"
"debug.hwui.skp_filename false"
"debug.hwui.level 2"
"debug.hwui.clip_surfaceviews false"
"debug.hwui.nv_profiling false"
"debug.hwui.disable_draw_defer true"
"debug.hwui.disable_draw_reorder true"
"debug.hwui.8bit_hdr_headroom false"
"debug.hwui.app_memory_policy true"
"ro.hwui.disable_scissor_opt false"
"debug.hwui.disable_vsync false"
"ro.hwui.layer_cache_size 128.0f"
"ro.hwui.texture_cache_size 128.0f"
"ro.hwui.shape_cache_size 128.0f"
"ro.hwui.patch_cache_size 128.0f"
"ro.hwui.r_buffer_cache_size 64.0f"
"ro.hwui.path_cache_size 3.0f"
"ro.hwui.vertex_cache_size 1.2f"
"ro.hwui.drop_shadow_cache_size 3.0f"
"ro.hwui.texture_cache_flushrate 0.8f"
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
