#!/system/bin/sh
# combined_service.sh - AI Perf Manager + Fast Charging (Android 16 Supported)
# DianTk Modz Edition

sleep 1

# === Path dasar ===
BASEDIR=/data/adb/modules#!/system/bin/sh
# combined_service.sh - AI Perf Manager + Fast Charging (Android 16 Supported - Fixed Screen Det)
# By Morpheus / DianTk Modz Edition

sleep 1

# === Path dasar ===
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
INT=/storage/emulated/0
AGD=$INT/DianTk-Modz-Perf
LOG=$AGD/DianTk-log.log
MSC=$BASEDIR/script

# === File daftar app ===
APP_LIST="$AGD/applist_perf.txt"

# === Fungsi Toast / Notifikasi (Support Android 14/15/16) ===
send_toast() {
    local MSG="$1"
    local CURR_USER=$(am get-current-user 2>/dev/null || echo 0)
    am start --user "$CURR_USER" -a android.intent.action.MAIN -e toasttext "$MSG" -n bellavita.toast/.MainActivity >/dev/null 2>&1
}

# === Notif AI start ===
send_toast "🤖 Ai is started..."
echo " 🤖 Ai is started at $(date "+%Y-%m-%d %H:%M:%S")" >> $LOG

# === Lokasi skrip perf ===
PERF_SCRIPT="$MSC/perf.sh"
DEFAULT_SCRIPT="$MSC/default.sh"
SAVE_SCRIPT="$MSC/save.sh"

# === Variabel tracking state ===
LAST_STATE=""
CURRENT_APP=""

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

# Penggunaan Native Shell Math (Support Android 16 tanpa butuh binary 'bc'/'expr')
fast_charge_val=$(cat /sys/class/power_supply/battery/charge_full 2>/dev/null || echo 0)
fast_charge=$((fast_charge_val / 1000))
fast_charge1=$((fast_charge + 1000))
FC=$((fast_charge * 1000))
FCC=$((fast_charge1 * 1000))
CF=$((4000 * 1000))
BMS=/sys/devices/platform/soc/c440000.qcom,spmi/spmi-0/spmi0-02/c440000.qcom,spmi:qcom,pm8150b@2:qpnp,fg/power_supply/bms

# Flag status fast charging terakhir
FAST_STATE="off"

# === Fungsi AI perf manager ===
run_script() {
    local new_state=$1
    if [ "$LAST_STATE" != "$new_state" ]; then
        echo "State changed from '$LAST_STATE' to '$new_state'"
        echo "[$(date "+%H:%M:%S")] State changed to '$new_state'" >> $LOG
        case "$new_state" in
            "perf")    sh $PERF_SCRIPT ;;
            "default") sh $DEFAULT_SCRIPT ;;
            "save")    sh $SAVE_SCRIPT ;;
        esac
        LAST_STATE=$new_state
    fi
}

# === Loop utama gabungan ===
while true; do
    ##### Bagian 1: AI Perf Manager #####
    
    # [PERBAIKAN] Deteksi Layar Universal yang kebal terhadap perubahan format Android
    if dumpsys power | grep -q -E "mWakefulness=Awake|mInteractive=true"; then
        # --- BLOK KETIKA LAYAR MENYALA ---
        
        # Deteksi aplikasi foreground jauh lebih akurat untuk Android 14+
        CURRENT_APP=$(dumpsys activity activities | grep -E "mResumedActivity" | head -n 1 | awk '{print $4}' | cut -d'/' -f1)
        
        # Fallback jika metode pertama kosong (untuk kompatibilitas device lain)
        if [ -z "$CURRENT_APP" ]; then
            CURRENT_APP=$(dumpsys window | grep -E 'mCurrentFocus' | awk -F'/' '{print $1}' | awk '{print $NF}')
        fi

        # Cek apakah aplikasi yang sedang dibuka ada di dalam list perf
        if [ -n "$CURRENT_APP" ] && grep -q "^${CURRENT_APP}$" "$APP_LIST"; then
            run_script "perf"
        else
            run_script "default"
        fi
    else
        # --- BLOK KETIKA LAYAR MATI / TERKUNCI ---
        run_script "save"
    fi

    ##### Bagian 2: Fast Charging #####
    STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
    CAPACITY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
    VOLT_RAW=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null || echo 0)
    
    # Konversi microVolt ke Volt
    VOLT=$((VOLT_RAW / 1000000)) 

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
            send_toast "⚡ Fast Charging ACTIVATED (${CAPACITY}%, ${VOLT}V)"
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
            send_toast "⚡ Fast Charging DEACTIVATED (${CAPACITY}%, ${VOLT}V)"
            FAST_STATE="off"
        fi
    fi

    # Delay loop untuk efisiensi CPU
    sleep 2
done
DianTk-Modz-Perf
INT=/storage/emulated/0
AGD=$INT/DianTk-Modz-Perf
LOG=$AGD/DianTk-log.log
MSC=$BASEDIR/script

# === File daftar app ===
APP_LIST="$AGD/applist_perf.txt"

# === Fungsi Toast / Notifikasi (Support Android 14/15/16) ===
send_toast() {
    local MSG="$1"
    # Dapatkan ID user yang sedang aktif agar am start tidak diblokir system di Android terbaru
    local CURR_USER=$(am get-current-user 2>/dev/null || echo 0)
    am start --user "$CURR_USER" -a android.intent.action.MAIN -e toasttext "$MSG" -n bellavita.toast/.MainActivity >/dev/null 2>&1
}

# === Notif AI start ===
send_toast "🤖 Ai is started..."
echo " 🤖 Ai is started at $(date "+%Y-%m-%d %H:%M:%S")" >> $LOG

# === Lokasi skrip perf ===
PERF_SCRIPT="$MSC/perf.sh"
DEFAULT_SCRIPT="$MSC/default.sh"
SAVE_SCRIPT="$MSC/save.sh"

# === Variabel tracking state ===
LAST_STATE=""
CURRENT_APP=""

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

# Penggunaan Native Shell Math (Support Android 16 tanpa butuh binary 'bc'/'expr')
fast_charge_val=$(cat /sys/class/power_supply/battery/charge_full 2>/dev/null || echo 0)
fast_charge=$((fast_charge_val / 1000))
fast_charge1=$((fast_charge + 1000))
FC=$((fast_charge * 1000))
FCC=$((fast_charge1 * 1000))
CF=$((4000 * 1000))
BMS=/sys/devices/platform/soc/c440000.qcom,spmi/spmi-0/spmi0-02/c440000.qcom,spmi:qcom,pm8150b@2:qpnp,fg/power_supply/bms

# Flag status fast charging terakhir
FAST_STATE="off"

# === Fungsi AI perf manager ===
run_script() {
    local new_state=$1
    if [ "$LAST_STATE" != "$new_state" ]; then
        echo "State changed from '$LAST_STATE' to '$new_state'"
        echo "[$(date "+%H:%M:%S")] State changed to '$new_state'" >> $LOG
        case "$new_state" in
            "perf")    sh $PERF_SCRIPT ;;
            "default") sh $DEFAULT_SCRIPT ;;
            "save")    sh $SAVE_SCRIPT ;;
        esac
        LAST_STATE=$new_state
    fi
}

# === Loop utama gabungan ===
while true; do
    ##### Bagian 1: AI Perf Manager #####
    # Deteksi layar dengan mInteractive untuk akurasi tertinggi di Android modern
    IS_INTERACTIVE=$(dumpsys power | grep "mInteractive=" | cut -d'=' -f2 | tr -d '\r')

    if [ "$IS_INTERACTIVE" = "true" ]; then
        # Deteksi aplikasi foreground jauh lebih akurat untuk Android 14+
        CURRENT_APP=$(dumpsys activity activities | grep -E "mResumedActivity" | head -n 1 | awk '{print $4}' | cut -d'/' -f1)
        
        # Fallback jika metode pertama kosong (untuk kompatibilitas device lain)
        if [ -z "$CURRENT_APP" ]; then
            CURRENT_APP=$(dumpsys window | grep -E 'mCurrentFocus' | awk -F'/' '{print $1}' | awk '{print $NF}')
        fi

        # Cek apakah aplikasi yang sedang dibuka ada di dalam list perf
        if [ -n "$CURRENT_APP" ] && grep -q "^${CURRENT_APP}$" "$APP_LIST"; then
            run_script "perf"
        else
            run_script "default"
        fi
    else
        # Jika layar mati atau terkunci (termasuk mode Doze/AOD)
        run_script "save"
    fi

    ##### Bagian 2: Fast Charging #####
    STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
    CAPACITY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
    VOLT_RAW=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null || echo 0)
    
    # Konversi microVolt ke Volt
    VOLT=$((VOLT_RAW / 1000000)) 

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
            send_toast "⚡ Fast Charging ACTIVATED (${CAPACITY}%, ${VOLT}V)"
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
            send_toast "⚡ Fast Charging DEACTIVATED (${CAPACITY}%, ${VOLT}V)"
            FAST_STATE="off"
        fi
    fi

    # Delay loop untuk efisiensi CPU
    sleep 2
done
