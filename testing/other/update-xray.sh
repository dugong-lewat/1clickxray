#!/bin/bash

clear
# Warna teks
NC='\e[0m'       # No Color (mengatur ulang warna teks ke default)
DEFBOLD='\e[39;1m' # Default Bold
RB='\e[31;1m'    # Red Bold
GB='\e[32;1m'    # Green Bold
YB='\e[33;1m'    # Yellow Bold
BB='\e[34;1m'    # Blue Bold
MB='\e[35;1m'    # Magenta Bold
CB='\e[36;1m'    # Cyan Bold
WB='\e[37;1m'    # White Bold

# Fungsi untuk mencetak pesan dengan warna
print_msg() {
    COLOR=$1
    MSG=$2
    echo -e "${COLOR}${MSG}${NC}"
}

# Fungsi untuk mendeteksi OS Linux
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_msg $RB "Tidak dapat mendeteksi OS. Skrip ini hanya mendukung distribusi berbasis Debian dan Red Hat."
        exit 1
    fi
}

# Fungsi untuk memeriksa versi terbaru Xray-core
get_latest_xray_version() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r '.tag_name')
    if [ -z "$LATEST_VERSION" ]; then
        print_msg $RB "Tidak dapat menemukan versi terbaru Xray-core."
        exit 1
    fi
}

# Fungsi untuk memasang Xray-core
install_xray_core() {
    # Menampilkan pesan interaktif
    print_msg $YB "Persiapan instalasi Xray-core..."
    read -p "Tekan Enter untuk melanjutkan..."

    # Mendeteksi arsitektur
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="64"
            ;;
        aarch64)
            ARCH="arm64-v8a"
            ;;
        *)
            print_msg $RB "Arsitektur $ARCH tidak didukung."
            exit 1
            ;;
    esac

    # Mendownload dan menginstal Xray-core
    print_msg $YB "Mendownload dan menginstal Xray-core versi terbaru..."
    DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/$LATEST_VERSION/Xray-linux-$ARCH.zip"
    curl -sL -o xray.zip $DOWNLOAD_URL
    unzip -oq xray.zip -d /usr/local/bin
    rm -f xray.zip

    # Memberikan izin eksekusi
    chmod +x /usr/local/bin/xray

    # Menampilkan pesan penyelesaian
    print_msg $YB "Xray-core versi $GB$LATEST_VERSION$NC$YB berhasil diinstal."
}

# Memulai proses
print_msg $YB "Mendeteksi OS Linux yang digunakan..."
detect_os

# Menampilkan informasi OS
print_msg $YB "OS Linux yang digunakan: $GB$OS $VERSION"

# Memeriksa apakah OS didukung
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" || "$OS" == "CentOS" || "$OS" == "Fedora" || "$OS" == "Red Hat Enterprise Linux" ]]; then
    print_msg $YB "Memeriksa versi terbaru Xray-core..."
else
    print_msg $RB "Distribusi $OS tidak didukung oleh skrip ini. Proses instalasi dibatalkan."
    exit 1
fi

# Memeriksa versi terbaru Xray-core
get_latest_xray_version
print_msg $YB "Versi terbaru Xray-core: $GB$LATEST_VERSION"

# Memasang Xray-core
install_xray_core

# Meminta pengguna untuk menekan tombol apa pun sebelum kembali ke menu utama
read -n 1 -s -r -p "Tekan tombol apa pun untuk kembali ke menu utama..."
menu