#!/system/bin/sh 
# By Morpheus

sleep 1

# Path
BASEDIR=/data/adb/modules/DianTk-Modz-Perf
INT=/storage/emulated/0
AGD=$INT/DianTk-Modz-Perf
LOG=$AGD/DianTk-log.log
MSC=$BASEDIR/script

# Check directory
if [ ! -e $AGD ]; then
  mkdir $AGD
fi

# Get total size memory
memTotal=$(free -m | awk '/^Mem:/{print $2}')

echo " " > $LOG
echo " Module info: " >> $LOG
echo " • Name            : DianTk Modz " >> $LOG
echo " • Codename        : Reboot" >> $LOG  
echo " • Version         : XxX" >> $LOG
echo " • Status          : Private release " >> $LOG
echo " • Owner           : DianTk Modz " >> $LOG
echo " • Release Date    : Rilex " >> $LOG
echo " " >> $LOG

echo " Profile Mode:" >> $LOG

# Begin of AI
am start -a android.intent.action.MAIN -e toasttext "🤖 Ai is started..." -n bellavita.toast/.MainActivity
echo " 🤖 Ai is started" >> $LOG

# Start AI

# Lokasi skrip-skrip
PERF_SCRIPT="$MSC/perf.sh"
DEFAULT_SCRIPT="$MSC/default.sh"
SAVE_SCRIPT="$MSC/save.sh"
APP_LIST="$AGD/applist_perf.txt"

# Variabel untuk melacak status terakhir
LAST_STATE=""
CURRENT_APP=""

# Fungsi untuk menjalankan skrip jika status berubah
run_script() {
    local new_state=$1
    if [ "$LAST_STATE" != "$new_state" ]; then
        echo "State changed from '$LAST_STATE' to '$new_state'"
        case "$new_state" in
            "perf")
                sh $PERF_SCRIPT
                ;;
            "default")
                sh $DEFAULT_SCRIPT
                ;;
            "save")
                sh $SAVE_SCRIPT
                ;;
        esac
        LAST_STATE=$new_state
    fi
}

# Loop utama untuk memonitor
while true; do
    # Cek status layar
    SCREEN_ON=$(dumpsys power | grep "mWakefulness=" | cut -d'=' -f2)

    if [ "$SCREEN_ON" = "Awake" ]; then
        # Layar menyala, cek aplikasi yang sedang berjalan
        CURRENT_APP=$(dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | awk -F'/' '{print $1}' | awk '{print $NF}')

        if [ -n "$CURRENT_APP" ] && grep -q "^${CURRENT_APP}$" "$APP_LIST"; then
            # Aplikasi ada dalam daftar
            run_script "perf"
        else
            # Aplikasi tidak ada dalam daftar atau di home screen
            run_script "default"
        fi
    else
        # Layar mati
        run_script "save"
    fi

    # Tunggu beberapa saat sebelum memeriksa lagi untuk mengurangi penggunaan CPU
    sleep 2
done
