#!/system/bin/sh
# combined_service.sh - AI Perf Manager + Proteksi App + Fast Charging
# By Morpheus / DianTk Modz Edition

sleep 1

# === Path dasar ===
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
INT=/storage/emulated/0
AGD=$INT/DianTk-Modz-Perf
LOG=$AGD/DianTk-log.log
MSC=$BASEDIR/script

# === File daftar app ===
LIST_FILE="$AGD/dozer_exept.txt"
APP_LIST="$AGD/applist_perf.txt"

# === Notif AI start ===
am start -a android.intent.action.MAIN -e toasttext "🤖 Ai is started..." -n bellavita.toast/.MainActivity
echo " 🤖 Ai is started" >> $LOG

# === Lokasi skrip perf ===
PERF_SCRIPT="$MSC/perf.sh"
DEFAULT_SCRIPT="$MSC/default.sh"
SAVE_SCRIPT="$MSC/save.sh"

# === Variabel tracking state ===
LAST_STATE=""
CURRENT_APP=""

# === Tracking PID proteksi biar tidak spam log ===
PROTECTED_PIDS=""

# === Variabel Fast Charging ===
set_value() {
    if [[ -f "$2" ]]; then
        chmod 0666 "$2"
        echo "$1" > "$2"
        chmod 0444 "$2"
    fi
}
fast_charge() {
    paths=$(ls /sys/class/power_supply/*/$1 2>/dev/null)
    for path in $paths; do
        set_value $FC $path
    done
}

fast_charge_val=$(cat /sys/class/power_supply/battery/charge_full)
fast_charge=$(echo "$fast_charge_val/1000" | bc)
fast_charge1=$(expr $fast_charge + 1000)
FC=$(expr $fast_charge \* 1000)
FCC=$(expr $fast_charge1 \* 1000)
CF=$(expr 4000 \* 1000)
BMS=/sys/devices/platform/soc/c440000.qcom,spmi/spmi-0/spmi0-02/c440000.qcom,spmi:qcom,pm8150b@2:qpnp,fg/power_supply/bms

# Flag status fast charging terakhir
FAST_STATE="off"

# === Fungsi AI perf manager ===
run_script() {
    local new_state=$1
    if [ "$LAST_STATE" != "$new_state" ]; then
        echo "State changed from '$LAST_STATE' to '$new_state'"
        echo "State changed from '$LAST_STATE' to '$new_state'" >> $LOG
        case "$new_state" in
            "perf")    sh $PERF_SCRIPT ;;
            "default") sh $DEFAULT_SCRIPT ;;
            "save")    sh $SAVE_SCRIPT ;;
        esac
        LAST_STATE=$new_state
    fi
}

# === Fungsi cek apakah PID sudah pernah diproteksi ===
is_protected() {
    echo "$PROTECTED_PIDS" | grep -qw "$1"
}
mark_protected() {
    PROTECTED_PIDS="$PROTECTED_PIDS $1"
}

# === Loop utama gabungan ===
while true; do
    ##### Bagian 1: AI Perf Manager #####
    SCREEN_ON=$(dumpsys power | grep "mWakefulness=" | cut -d'=' -f2)

    if [ "$SCREEN_ON" = "Awake" ]; then
        CURRENT_APP=$(dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | \
                      awk -F'/' '{print $1}' | awk '{print $NF}')
        if [ -n "$CURRENT_APP" ] && grep -q "^${CURRENT_APP}$" "$APP_LIST"; then
            run_script "perf"
        else
            run_script "default"
        fi
    else
        run_script "save"
    fi

    ##### Bagian 2: Proteksi App dari dozer_exept.txt #####
    if [ -f "$LIST_FILE" ]; then
        while read -r APP; do
            [ -z "$APP" ] && continue
            PID=$(pidof "$APP")
            [ -z "$PID" ] && continue

            for P in $PID; do
                echo -1000 > /proc/$P/oom_score_adj 2>/dev/null
                [ -d /dev/stune/top-app ]  && echo $P > /dev/stune/top-app/tasks 2>/dev/null
                [ -d /dev/cpuctl/top-app ] && echo $P > /dev/cpuctl/top-app/tasks 2>/dev/null
                [ -d /dev/cpuset/top-app ] && echo $P > /dev/cpuset/top-app/tasks 2>/dev/null
                dumpsys deviceidle whitelist +$APP 2>/dev/null

                if ! is_protected "$P"; then
                    MSG=" •> Proteksi aktif di top-app untuk $APP (PID $P)"
                    echo "$MSG"
                    echo "$MSG" >> $LOG
                    mark_protected "$P"
                fi
            done
        done < "$LIST_FILE"
    fi

    ##### Bagian 3: Fast Charging #####
    STATUS=$(cat /sys/class/power_supply/battery/status)
    CAPACITY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
    VOLT_RAW=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
    VOLT=$(expr $VOLT_RAW / 1000000) # ubah µV ke V

    if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
        # Aktifkan fast charging
        set_value '1' /sys/kernel/fast_charge/force_fast_charge
        set_value '1' /sys/class/power_supply/battery/system_temp_level
        set_value '1' /sys/kernel/fast_charge/failsafe
        set_value '1' /sys/class/power_supply/battery/allow_hvdcp3
        set_value '1' /sys/class/power_supply/usb/pd_allowed
        set_value '1' /sys/class/power_supply/battery/subsystem/usb/pd_allowed
        set_value '0' /sys/class/power_supply/battery/input_current_limited
        set_value '1' /sys/class/power_supply/battery/input_current_settled
        set_value '0' /sys/class/qcom-battery/restricted_charging
        set_value '150' /sys/class/power_supply/bms/temp_cool
        set_value '480' /sys/class/power_supply/bms/temp_hot
        set_value '480' /sys/class/power_supply/bms/temp_warm
        set_value '0' /sys/class/qcom-battery/restrict_chg
        set_value $FCC /sys/class/qcom-battery/restricted_current
        set_value $FCC /sys/class/qcom-battery/restrict_cur

        fast_charge current_max
        fast_charge hw_current_max
        fast_charge pd_current_max
        fast_charge ctm_current_max
        fast_charge sdp_current_max
        fast_charge constant_charge_current_max

        if [ "$FAST_STATE" != "on" ]; then
            echo " •> Fast Charging ACTIVATED at $(date "+%H:%M:%S") | Battery: ${CAPACITY}% | ${VOLT}V" >> $LOG
            am start -a android.intent.action.MAIN -e toasttext "⚡ Fast Charging ACTIVATED (${CAPACITY}%, ${VOLT}V)" -n bellavita.toast/.MainActivity
            FAST_STATE="on"
        fi
    else
        # Nonaktifkan fast charging
        set_value '0' /sys/kernel/fast_charge/force_fast_charge
        set_value '0' /sys/kernel/fast_charge/failsafe
        set_value '0' /sys/class/power_supply/battery/allow_hvdcp3
        set_value '0' /sys/class/power_supply/usb/pd_allowed
        set_value '0' /sys/class/power_supply/battery/subsystem/usb/pd_allowed

        if [ "$FAST_STATE" != "off" ]; then
            echo " •> Fast Charging DEACTIVATED at $(date "+%H:%M:%S") | Battery: ${CAPACITY}% | ${VOLT}V" >> $LOG
            am start -a android.intent.action.MAIN -e toasttext "⚡ Fast Charging DEACTIVATED (${CAPACITY}%, ${VOLT}V)" -n bellavita.toast/.MainActivity
            FAST_STATE="off"
        fi
    fi

    # Delay loop
    sleep 2
done