#!/bin/bash

echo "--- Memulai Setup Penjadwal MP3 ---"

# --- 1. Update & Instalasi ---
echo "[1/5] Menjalankan apt update..."
sudo apt-get update

echo "[2/5] Menginstal package: sox, libsox-fmt-all, dan jq..."
# Opsi -y untuk otomatis menjawab 'yes'
sudo apt-get install -y sox libsox-fmt-all jq

# --- 2. Mencari Lokasi Perintah ---
echo "[3/5] Mencari lokasi 'play' dan 'jq'..."

PLAY_CMD=$(which play)
if [ -z "$PLAY_CMD" ]; then
    echo "ERROR: Perintah 'play' (dari sox) tidak ditemukan. Pastikan instalasi sox berhasil."
    exit 1
fi

JQ_CMD=$(which jq)
if [ -z "$JQ_CMD" ]; then
    echo "ERROR: Perintah 'jq' tidak ditemukan. Pastikan instalasi jq berhasil."
    exit 1
fi

echo "   > 'play' ditemukan di: $PLAY_CMD"
echo "   > 'jq' ditemukan di: $JQ_CMD"


# --- 3. Membuat cek_jadwal.sh ---
echo "[4/5] Membuat file 'cek_jadwal.sh'..."

# Mendeteksi path absolut dari direktori tempat setup.sh berada
# Ini akan menjadi lokasi untuk .sh, .json, dan .mp3
APP_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCRIPT_PATH="$APP_DIR/cek_jadwal.sh"

echo "   > Direktori aplikasi (JSON, MP3, Script) diatur ke: $APP_DIR"

# Menggunakan HEREDOC (cat << EOF) untuk menulis file cek_jadwal.sh
cat << EOF > "$SCRIPT_PATH"
#!/bin/bash

# --- KONFIGURASI ---
# Path ini diatur otomatis oleh setup.sh
APP_DIR="$APP_DIR"

# Lokasi MP3 diatur ke direktori yang sama dengan script (diatur oleh setup.sh)
MP3_DIR="$APP_DIR"

# Path command (diatur otomatis oleh setup.sh)
JQ_CMD="$JQ_CMD"
PLAY_CMD="$PLAY_CMD"

# Path ke file-file
JSON_FILE="\$APP_DIR/jadwal.json"
LOG_FILE="\$APP_DIR/jadwal.log"
# --- AKHIR KONFIGURASI ---

log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOG_FILE"
}

# 1. Dapatkan hari dan jam saat ini
CURRENT_DAY=\$(date +%u)
CURRENT_TIME=\$(date +%H:%M)

# 2. Cek apakah file JSON ada
if [ ! -f "\$JSON_FILE" ]; then
    log "ERROR: File JSON tidak ditemukan di \$JSON_FILE"
    exit 1
fi

# 3. Baca JSON dan filter untuk mendapatkan NAMA FILENYA
FILENAME_TO_PLAY=\$(\$JQ_CMD -r --arg day "\$CURRENT_DAY" --arg time "\$CURRENT_TIME" \
                       '.[] | select( (.hari_array | index(\$day | tonumber) != null) and .jam == \$time) | .file_mp3' \
                       "\$JSON_FILE")

# 4. Jika ada jadwal yang cocok
if [ -n "\$FILENAME_TO_PLAY" ]; then
    
    FULL_PATH_TO_PLAY="\$MP3_DIR/\$FILENAME_TO_PLAY"

    log "JADWAL DITEMUKAN: Memutar \$FULL_PATH_TO_PLAY"
    
    if [ -f "\$FULL_PATH_TO_PLAY" ]; then
        # Menggunakan 'play' dari 'sox'
        \$PLAY_CMD "\$FULL_PATH_TO_PLAY"
    else
        log "ERROR: File MP3 tidak ditemukan di \$FULL_PATH_TO_PLAY"
    fi
fi
EOF
# Akhir dari HEREDOC

# Memberi izin eksekusi ke cek_jadwal.sh
chmod +x "$SCRIPT_PATH"
echo "   > File 'cek_jadwal.sh' berhasil dibuat dan diberi izin eksekusi."


# --- 4. Mengedit Cron Job ---
echo "[5/5] Menambahkan tugas ke crontab..."

# Menyiapkan baris perintah cron
CRON_JOB="* * * * * export DISPLAY=:0; export XDG_RUNTIME_DIR=/run/user/\$(id -u); $SCRIPT_PATH"

# Cara aman menambahkan cron job (mencegah duplikat)
(crontab -l 2>/dev/null | grep -Fv "$SCRIPT_PATH"; echo "$CRON_JOB") | crontab -

echo "   > Cron job berhasil diatur untuk menjalankan $SCRIPT_PATH setiap menit."
echo ""
echo "--- SETUP SELESIAI ---"
echo "Semua path telah diatur secara otomatis."
echo "Pastikan file 'jadwal.json' dan SEMUA file .mp3 Anda berada di direktori yang sama:"
echo "$APP_DIR"
