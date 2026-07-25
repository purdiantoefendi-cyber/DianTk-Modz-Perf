#!/system/bin/sh
# combined_service.sh - AI Perf Manager + Proteksi App + Extreme Fast Charging
# By Morpheus / DianTk Modz Edition (Single Loop - Global Timing)

# === Tunggu sampai booting selesai ===
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

sleep 1

# === Konfigurasi Utama ===
GLOBAL_DELAY=3 # Jeda waktu (dalam detik) untuk setiap putaran loop besar

# === Path dasar ===
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
INT=/storage/emulated/0
AGD=$INT/DianTk-Modz-Perf
LOG=$AGD/DianTk-log.log
MSC=$BASEDIR/script

# === File daftar app ===
LIST_FILE="$AGD/lock_applist.txt" 
APP_LIST="$AGD/applist_perf.txt"

# === Notif AI start ===
am start -a android.intent.action.MAIN -e toasttext "🤖 Ai is started..." -n bellavita.toast/.MainActivity
echo " 🤖 Ai is started at $(date "+%H:%M:%S")" >> $LOG

# === Lokasi skrip perf ===
PERF_SCRIPT="$MSC/perf.sh"
DEFAULT_SCRIPT="$MSC/default.sh"
SAVE_SCRIPT="$MSC/save.sh"

# === Variabel tracking state ===
LAST_STATE=""
CURRENT_APP=""
PROTECTED_PIDS=""

# === Variabel Extreme Fast Charging ===
CURRENT_MAX=9000000
VOLTAGE_MAX=12000000
TEMP_COOL=150
TEMP_HOT=900
TEMP_WARM=850

DEFAULT_CURRENT=2000000 # 2A
DEFAULT_VOLTAGE=5000000 # 5V

CP_PATHS="cp_enable cp_switcher_en cp_charging_enabled slave_chg_enable slave_enable"
MODULE_PATHS="/sys/module/qpnp_smb2/parameters /sys/module/qpnp_smb5/parameters /sys/module/smb1351_charger/parameters /sys/module/smb1355_charger/parameters /sys/module/smb_lib/parameters /sys/module/phy_msm_usb/parameters"
FEATURES="fast_charge boost_mode turbo_mode pd_allowed allow_hvdcp3 hvdcp_opti quick_charge_mode pump_express_enable fast_chg_type mtk_pulse_enable pd_active force_demo_mode toggle_stat aicl_done"
LIMITS="current_max constant_charge_current constant_charge_current_max input_current_limit input_current_max hw_current_max pd_current_max ctm_current_max sdp_current_max restricted_current main_current_max usb_current_max fc_current_limit fast_charge_current_limit vbus_current_max screen_on_current_limit"
VOLTAGES="input_voltage_limit input_voltage_max voltage_max voltage_max_design constant_charge_voltage_max vbus_voltage_max"
DISABLE_SAFETY="step_charging_enabled sw_jeita_enabled jeita_arise_throttled soft_jeita_btn_enabled aicl_enable input_suspend charge_disable safety_timer_enabled"

FAST_STATE="off"


# === Fungsi Utilities ===
lock_val() {
    if [ -e "$2" ]; then
        chmod 0666 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
        chmod 0444 "$2" >/dev/null 2>&1
    fi
}

run_script() {
    local new_state=$1
    if [ "$LAST_STATE" != "$new_state" ]; then
        echo "State changed from '$LAST_STATE' to '$new_state'"
        echo "State changed from '$LAST_STATE' to '$new_state' at $(date "+%H:%M:%S")" >> $LOG
        case "$new_state" in
            "perf")    sh $PERF_SCRIPT ;;
            "default") sh $DEFAULT_SCRIPT ;;
            "save")    sh $SAVE_SCRIPT ;;
        esac
        LAST_STATE=$new_state
    fi
}

is_protected() { echo "$PROTECTED_PIDS" | grep -qw "$1"; }
mark_protected() { PROTECTED_PIDS="$PROTECTED_PIDS $1"; }

# === Fungsi Enable/Disable Fast Charging ===
enable_extreme_fc() {
    for cp in $CP_PATHS; do find /sys/class/power_supply/ -name "$cp" 2>/dev/null | while read path; do lock_val "1" "$path"; done; done
    find /sys/class/power_supply/ -name "cp_current_limit" -o -name "cp_ilim" 2>/dev/null | while read path; do lock_val "$CURRENT_MAX" "$path"; done
    if [ -d "/sys/class/power_supply/dc_charger" ]; then
        lock_val "1" "/sys/class/power_supply/dc_charger/present"; lock_val "1" "/sys/class/power_supply/dc_charger/online"; lock_val "$CURRENT_MAX" "/sys/class/power_supply/dc_charger/current_max"
    fi
    TYPEC_PATH="/sys/class/typec/port0"
    if [ -d "$TYPEC_PATH" ]; then
        [ -f "$TYPEC_PATH/power_operation_mode" ] && chmod 0666 "$TYPEC_PATH/power_operation_mode"
        lock_val "sink" "$TYPEC_PATH/power_role"; lock_val "1" "$TYPEC_PATH/vbus_vsafe0v"
    fi
    for mod_path in $MODULE_PATHS; do
        lock_val "0" "$mod_path/aicl_enable"; lock_val "1" "$mod_path/hvdcp3_allowed"; lock_val "1" "$mod_path/step_charging_enable"; lock_val "0" "$mod_path/usb_in_suspend"; lock_val "1" "$mod_path/skip_usb_suspend_for_fake_battery"
    done
    [ -d "/proc/vooc_mp" ] && lock_val "1" "/proc/vooc_mp/allow_reading"
    if [ -d "/sys/class/power_supply/vooc" ]; then lock_val "1" "/sys/class/power_supply/vooc/fast_chg_ing"; lock_val "1" "/sys/class/power_supply/vooc/allow_reading"; fi
    for zone in /sys/class/thermal/thermal_zone*/mode; do lock_val "disabled" "$zone"; done
    find /sys/class/power_supply/ -name "skin_temp_mitigation" -o -name "connector_temp_mitigation" 2>/dev/null | while read path; do lock_val "0" "$path"; done
    find /sys/ -name "temp_cool" -o -name "temp_hot" -o -name "temp_warm" -o -name "temp_ambient" 2>/dev/null | while read path; do
        case "$path" in *"cool"*) lock_val "$TEMP_COOL" "$path" ;; *"hot"*) lock_val "$TEMP_HOT" "$path" ;; *"warm"*) lock_val "$TEMP_WARM" "$path" ;; *"ambient"*) lock_val "$TEMP_COOL" "$path" ;; esac
    done
    for feature in $FEATURES; do find /sys/class/power_supply/ -name "$feature" 2>/dev/null | while read path; do lock_val "1" "$path"; done; done
    for limit in $LIMITS; do find /sys/class/power_supply/ -name "$limit" 2>/dev/null | while read path; do lock_val "$CURRENT_MAX" "$path"; done; done
    find /sys/class/power_supply/ -name "$VOLTAGES" 2>/dev/null | while read path; do lock_val "$VOLTAGE_MAX" "$path"; done
    for safety in $DISABLE_SAFETY; do find /sys/class/power_supply/ -name "$safety" 2>/dev/null | while read path; do lock_val "0" "$path"; done; done
    if [ -d "/sys/devices/mtk-battery" ] || [ -d "/sys/bus/platform/drivers/mtk-battery" ]; then
        lock_val "$CURRENT_MAX" "/sys/devices/mtk-battery/restricted_current"; lock_val "$CURRENT_MAX" "/sys/devices/mtk-battery/fc_current_limit"; lock_val "1" "/sys/devices/mtk-battery/pump_express_enable"
    fi
    if [ -d "/sys/class/qcom-battery" ]; then
        lock_val "0" "/sys/class/qcom-battery/restricted_charging"; lock_val "0" "/sys/class/qcom-battery/restrict_chg"; lock_val "$CURRENT_MAX" "/sys/class/qcom-battery/restricted_current"; [ -f "/sys/class/qcom-battery/rerun_aicl" ] && echo "1" > "/sys/class/qcom-battery/rerun_aicl"
    fi
    if [ -d "/sys/class/power_supply/sec-charger" ]; then lock_val "$CURRENT_MAX" "/sys/class/power_supply/sec-charger/input_current_max"; lock_val "0" "/sys/class/power_supply/sec-charger/otg_enable"; fi
    find /sys/class/power_supply/usb/ -name "real_type" 2>/dev/null | while read path; do lock_val "DCP" "$path"; done
    find /sys/ -name "store_mode" -o -name "batt_slate_mode" 2>/dev/null | while read path; do lock_val "0" "$path"; done
    lock_val "0" "/sys/class/power_supply/battery/input_current_limited"; lock_val "1" "/sys/class/power_supply/battery/input_current_settled"; lock_val "100" "/sys/class/power_supply/battery/siop_level"; lock_val "0" "/sys/class/power_supply/battery/charge_control_limit_max"
}

disable_extreme_fc() {
    for cp in $CP_PATHS; do find /sys/class/power_supply/ -name "$cp" 2>/dev/null | while read path; do lock_val "0" "$path"; done; done
    for safety in $DISABLE_SAFETY; do find /sys/class/power_supply/ -name "$safety" 2>/dev/null | while read path; do lock_val "1" "$path"; done; done
    for feature in $FEATURES; do find /sys/class/power_supply/ -name "$feature" 2>/dev/null | while read path; do lock_val "0" "$path"; done; done
    for zone in /sys/class/thermal/thermal_zone*/mode; do lock_val "enabled" "$zone"; done
    find /sys/class/power_supply/ -name "skin_temp_mitigation" -o -name "connector_temp_mitigation" 2>/dev/null | while read path; do lock_val "1" "$path"; done
    for limit in $LIMITS; do find /sys/class/power_supply/ -name "$limit" 2>/dev/null | while read path; do lock_val "$DEFAULT_CURRENT" "$path"; done; done
    find /sys/class/power_supply/ -name "$VOLTAGES" 2>/dev/null | while read path; do lock_val "$DEFAULT_VOLTAGE" "$path"; done
    for mod_path in $MODULE_PATHS; do lock_val "1" "$mod_path/aicl_enable"; lock_val "0" "$mod_path/skip_usb_suspend_for_fake_battery"; done
    if [ -d "/sys/class/qcom-battery" ]; then lock_val "1" "/sys/class/qcom-battery/restricted_charging"; lock_val "1" "/sys/class/qcom-battery/restrict_chg"; lock_val "$DEFAULT_CURRENT" "/sys/class/qcom-battery/restricted_current"; fi
    [ -d "/proc/vooc_mp" ] && lock_val "0" "/proc/vooc_mp/allow_reading"
}

# =====================================================================
# Inisialisasi: Masukkan app ke Whitelist Doze Mode (Eksekusi 1x saja)
# =====================================================================
if [ -f "$LIST_FILE" ]; then
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        [[ "$pkg" == \#* ]] && continue
        pkg=$(echo "$pkg" | tr -d '\r')
        dumpsys deviceidle whitelist +$pkg 2>/dev/null
    done < "$LIST_FILE"
fi

# =====================================================================
# LOOP UTAMA TUNGGAL (Global Timing)
# =====================================================================
while true; do

    ##### 1. AI Perf Manager #####
    if dumpsys power | grep -iq "mWakefulness=Awake"; then
        CURRENT_APP=$(dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | \
                      awk -F'/' '{print $1}' | awk '{print $NF}' | tr -d '\r' | tr -d ' ')
        
        if [ -n "$CURRENT_APP" ] && grep -q "^${CURRENT_APP}$" "$APP_LIST"; then
            run_script "perf"
        else
            run_script "default"
        fi
    else
        run_script "save"
    fi

    ##### 2. Fast Charging Tracking #####
    STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
    CAPACITY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
    VOLT_RAW=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
    
    if [ -n "$VOLT_RAW" ]; then
        VOLT=$(expr $VOLT_RAW / 1000000)
    else
        VOLT="N/A"
    fi

    if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
        enable_extreme_fc
        if [ "$FAST_STATE" != "on" ]; then
            echo " •> Extreme Fast Charging ACTIVATED at $(date "+%H:%M:%S") | Battery: ${CAPACITY}% | ${VOLT}V" >> $LOG
            am start -a android.intent.action.MAIN -e toasttext "⚡ Fast Charging ACTIVATED (${CAPACITY}%, ${VOLT}V)" -n bellavita.toast/.MainActivity
            FAST_STATE="on"
        fi
    else
        disable_extreme_fc
        if [ "$FAST_STATE" != "off" ]; then
            echo " •> Extreme Fast Charging DEACTIVATED at $(date "+%H:%M:%S") | Battery: ${CAPACITY}% | ${VOLT}V" >> $LOG
            am start -a android.intent.action.MAIN -e toasttext "⚡ Fast Charging DEACTIVATED (${CAPACITY}%, ${VOLT}V)" -n bellavita.toast/.MainActivity
            FAST_STATE="off"
        fi
    fi

    ##### 3. Proteksi App (Anti-Kill & CPU Priority) #####
    if [ -f "$LIST_FILE" ]; then
        while IFS= read -r pkg; do
            [ -z "$pkg" ] && continue
            [[ "$pkg" == \#* ]] && continue
            pkg=$(echo "$pkg" | tr -d '\r')

            for P in $(pidof "$pkg"); do
                echo -1000 > /proc/$P/oom_score_adj 2>/dev/null
                [ -d /dev/stune/top-app ]  && echo $P > /dev/stune/top-app/tasks 2>/dev/null
                [ -d /dev/cpuctl/top-app ] && echo $P > /dev/cpuctl/top-app/tasks 2>/dev/null
                [ -d /dev/cpuset/top-app ] && echo $P > /dev/cpuset/top-app/tasks 2>/dev/null

                if ! is_protected "$P"; then
                    MSG=" •> Proteksi aktif di top-app untuk $pkg (PID $P)"
                    echo "$MSG"
                    echo "$MSG" >> $LOG
                    mark_protected "$P"
                fi
            done
        done < "$LIST_FILE"
    fi

    # === Global Timing Delay ===
    sleep $GLOBAL_DELAY

done
