#!/bin/bash

# Warna dan gaya teks
NC='\e[0m'        # Tidak ada warna
DEFBOLD='\e[39;1m' # Warna teks default dengan gaya tebal
RB='\e[31;1m'      # Warna merah dengan gaya tebal
GB='\e[32;1m'      # Warna hijau dengan gaya tebal
YB='\e[33;1m'      # Warna kuning dengan gaya tebal
BB='\e[34;1m'      # Warna biru dengan gaya tebal
MB='\e[35;1m'      # Warna magenta dengan gaya tebal
CB='\e[36;1m'      # Warna cyan dengan gaya tebal
WB='\e[37;1m'      # Warna putih dengan gaya tebal

# Fungsi untuk menampilkan header
function display_header() {
    clear
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "             ${WB}All Xray User Login Account${NC}           "
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
}

# Fungsi untuk menampilkan menu
function display_menu() {
    echo -e "${YB}1. Refresh data akun${NC}"
    echo -e "${YB}2. Keluar${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
}

# Fungsi untuk menampilkan pengguna dan IP yang login
function display_users() {
    local config_file="/usr/local/etc/xray/config/04_inbounds.json"
    local log_file="/var/log/xray/access.log"

    if [[ ! -f "$config_file" ]]; then
        echo -e "${RB}File konfigurasi tidak ditemukan: $config_file${NC}"
        return
    fi

    if [[ ! -f "$log_file" ]]; then
        echo -e "${RB}File log tidak ditemukan: $log_file${NC}"
        return
    fi

    local data=($(grep '^#&@' "$config_file" | cut -d ' ' -f 2 | sort | uniq))
    if [ ${#data[@]} -eq 0 ]; then
        echo -e "${RB}Tidak ada akun pengguna ditemukan.${NC}"
        return
    fi

    for akun in "${data[@]}"; do
        [ -z "$akun" ] && akun="Tidak Ada"

        local data2=($(tail -n 500 "$log_file" | awk '{print $3}' | sed 's/tcp://g' | cut -d ":" -f 1 | sort | uniq))

        if [ ${#data2[@]} -eq 0 ]; then
            echo -e "${YB}Tidak ada alamat IP yang ditemukan untuk pengguna $YB$akun$NC.${NC}"
            continue
        fi

        echo -n > /tmp/ipxray
        echo -n > /tmp/other

        for ip in "${data2[@]}"; do
            local jum=$(grep -w "$akun" "$log_file" | tail -n 500 | awk '{print $3}' | sed 's/tcp://g' | cut -d ":" -f 1 | grep -w "$ip" | sort | uniq)
            if [[ "$jum" == "$ip" ]]; then
                echo "$jum" >> /tmp/ipxray
            else
                echo "$ip" >> /tmp/other
            fi
        done

        local jum=$(cat /tmp/ipxray)
        if [ -n "$jum" ]; then
            local jum2=$(nl < /tmp/ipxray)
            echo -e "${MB}User: ${WB}$akun${NC}"
            echo -e "${GB}$jum2${NC}"
            echo -e "${BB}————————————————————————————————————————————————————${NC}"
        fi

        rm -f /tmp/ipxray /tmp/other
    done
}

# Fungsi utama
function main() {
    while true; do
        display_header
        display_users
        display_menu
        read -p "Pilih opsi [1-2]: " choice

        case $choice in
            1) ;;
            2) echo -e "${YB}Keluar...${NC}"; sleep 2 ; clear ; menu ;;
            *) echo -e "${RB}Opsi tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# Menjalankan fungsi utama
main