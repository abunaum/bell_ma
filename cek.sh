#!/bin/bash

# --- KONFIGURASI ---
# Sesuaikan path ini dengan direktori Anda
APP_DIR="/home/ma/bell_ma"

# BARU: Tentukan lokasi folder MP3 Anda di sini
MP3_DIR="/home/ma/bell_ma"

# Path ke command
JQ_CMD="/usr/bin/jq"
MPG123_CMD="/usr/bin/play"

# Path ke file-file
JSON_FILE="$APP_DIR/jadwal.json"
LOG_FILE="$APP_DIR/jadwal.log"
# --- AKHIR KONFIGURASI ---

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 1. Dapatkan hari dan jam saat ini
CURRENT_DAY=$(date +%u)
CURRENT_TIME=$(date +%H:%M)

# 2. Cek apakah file JSON ada
if [ ! -f "$JSON_FILE" ]; then
    log "ERROR: File JSON tidak ditemukan di $JSON_FILE"
    exit 1
fi

# 3. Baca JSON dan filter untuk mendapatkan NAMA FILENYA
#    Variabelnya diubah menjadi FILENAME_TO_PLAY agar lebih jelas
FILENAME_TO_PLAY=$($JQ_CMD -r --arg day "$CURRENT_DAY" --arg time "$CURRENT_TIME" \
                       '.[] | select( (.hari_array | index($day | tonumber) != null) and .jam == $time) | .file_mp3' \
                       "$JSON_FILE")

# 4. Jika variabel FILENAME_TO_PLAY tidak kosong (ada jadwal)
if [ -n "$FILENAME_TO_PLAY" ]; then
    
    # BARU: Gabungkan path folder MP3 dengan nama filenya
    # Pastikan tidak ada spasi sebelum atau sesudah tanda =
    FULL_PATH_TO_PLAY="$MP3_DIR/$FILENAME_TO_PLAY"

    log "JADWAL DITEMUKAN: Memutar $FULL_PATH_TO_PLAY"
    
    # Cek apakah file MP3 ada di path LENGKAP
    if [ -f "$FULL_PATH_TO_PLAY" ]; then
        # Memutar MP3
        $MPG123_CMD "$FULL_PATH_TO_PLAY"
    else
        log "ERROR: File MP3 tidak ditemukan di $FULL_PATH_TO_PLAY"
    fi
fi
