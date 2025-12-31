#!/system/bin/sh
# Path
MODDIR="$(cd "$(dirname "$0")" && pwd)"

INT="/storage/emulated/0"
AGD="$INT/DianTk-Modz-Perf"
LOG="$AGD/DianTk-log.log"

# Wait for boot completed
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 10; done

# Enable all tweak
su -lp 2000 -c "cmd notification post -S bigtext -t 'DianTk Modz Perf' tag '📢 Apply optimization please wait...'" >/dev/null 2>&1

# Check applist file
if [ ! -e "$AGD/applist_perf.txt" ]; then
  cp -f /data/adb/modules/DianTk-Modz-Perf/script/applist_perf.txt "$AGD/"
fi

# Check dozer file
if [ ! -e "$AGD/dozer_exept.txt" ]; then
  cp -f /data/adb/modules/DianTk-Modz-Perf/script/dozer_exept.txt "$AGD/"
fi

# Swap on
echo "-------------------" >> /data/swap/swapfile.log
now=$(date)
echo "$now" >> /data/swap/swapfile.log

if [ -e "/data/swap/INCOMPLETE" ]; then
    echo "$now : INCOMPLETE FILE still exists! Did it Fail to boot?" >> /data/swap/swapfile.log
else
    echo "INCOMPLETE" > /data/swap/INCOMPLETE
    SWAP_FILE_PRIOR=0
    SWAPPINESS=200
    if [ -f /data/swap/SWAP_FILE_PRIOR ]; then
        SWAP_FILE_PRIOR=$(cat /data/swap/SWAP_FILE_PRIOR)
    fi
    if [ -f /data/swap/SWAPPINESS ]; then
        SWAPPINESS=$(cat /data/swap/SWAPPINESS)
    fi

    # Set swappiness
    echo "$SWAPPINESS" > /proc/sys/vm/swappiness

    if [ "$SWAP_FILE_PRIOR" -eq 0 ]; then
        /system/bin/swapon /data/swap/swapfile >> /data/swap/swapfile.log 2>&1
    else
        /system/bin/swapon -p "$SWAP_FILE_PRIOR" /data/swap/swapfile >> /data/swap/swapfile.log 2>&1
    fi
fi

rm -f /data/swap/INCOMPLETE

# Set swappiness again to be sure
echo 200 > /proc/sys/vm/swappiness

# Device online functions
wait_until_login()
{
    # whether in lock screen, tested on Android 7.1 & 10.0
    # in case of other magisk module remounting /data as RW
    while [ "$(dumpsys window policy | grep mInputRestricted=true)" != "" ]; do
        sleep 2
    done
    # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
    while [ ! -d "/sdcard/Android" ]; do
        sleep 2
    done
}

# Device online
wait_until_login

# Check directory
if [ ! -e "$AGD" ]; then
  mkdir -p "$AGD"
fi

mkdir -p "$(dirname "$LOG")" 2>/dev/null; : > "$LOG"

# Get total size memory
memTotal=$(free -m | awk '/^Mem:/{print $2}')

echo " RAM : "$memTotal" " >> "$LOG"
echo " Module info: " >> "$LOG"
echo " • Name            : DianTk Modz " >> "$LOG"
echo " • Codename        : Reboot" >> "$LOG"  
echo " • Version         : XxX" >> "$LOG"
echo " • Status          : Private release " >> "$LOG"
echo " • Owner           : DianTk Modz " >> "$LOG"
echo " • Release Date    : Rilex " >> "$LOG"
echo " " >> "$LOG"

echo " Profile Mode:" >> "$LOG"

# make_cgroup.sh - Buat cgroup custom "diantk_modz" + assign apps dari list

APP_LIST="$AGD/applist_perf.txt"

# === 1. Buat cgroup di cpuctl, stune, cpuset ===
for BASE in /dev/cpuctl /dev/stune /dev/cpuset; do
    if [ -d "$BASE" ]; then
        mkdir -p "$BASE/diantk_modz"
        chmod 0777 "$BASE/diantk_modz"
        echo " •> Created $BASE/diantk_modz" >> "$LOG"
    fi
done

# Set parameter default (bisa diubah sesuai kebutuhan)
[ -d /dev/cpuctl/diantk_modz ] && echo 1024 > /dev/cpuctl/diantk_modz/cpu.shares 2>/dev/null
[ -d /dev/stune/diantk_modz ]  && echo 1024 > /dev/stune/diantk_modz/cpu.shares 2>/dev/null
[ -d /dev/cpuset/diantk_modz ] && echo 0-7  > /dev/cpuset/diantk_modz/cpus 2>/dev/null

# === 2. Masukkan app dari list ke cgroup ===
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

# angle
cmd settings put global angle_gl_driver_selection_values angle
cmd settings put global angle_gl_driver_all_angle 1

# animation off
settings put global transition_animation_scale 0
settings put global window_animation_scale 0
settings put global animator_duration_scale 0

# DeepSleep
dumpsys deviceidle force-idle

# entropy
echo 1024 > /proc/sys/kernel/random/read_wakeup_threshold
echo 1024 > /proc/sys/kernel/random/write_wakeup_threshold

# Stop some services
for svc in logd perfd tcpdump cnss_diag statsd traced idd-logreader idd-logreadermain vendor.perfservice miuibooster system_perf_init; do
    stop "$svc" 2>/dev/null
done

# Begin AI tweak
nohup sh "$MODDIR/script/DianTk-AI.sh" &

sleep 3

# dozer
nohup sh "$MODDIR/dozer" &

# cpuruntime breaker
nohup sh "$MODDIR/breaker" &

# disable syslimit
nohup sh "$MODDIR/syslimit" &

#fast charging
#nohup sh "$MODDIR/fast_charging" &

# Done
su -lp 2000 -c "cmd notification post -S bigtext -t 'DianTk Modz Perf' tag '🎉 All optimization is applied...'" >/dev/null 2>&1

# Jangan exit agar script tidak berhenti jika ada error
# exit 0