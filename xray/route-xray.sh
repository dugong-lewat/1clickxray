#!/bin/bash

# Warna untuk output (sesuaikan dengan kebutuhan)
NC='\e[0m'       # No Color (mengatur ulang warna teks ke default)
DEFBOLD='\e[39;1m' # Default Bold
RB='\e[31;1m'    # Red Bold
GB='\e[32;1m'    # Green Bold
YB='\e[33;1m'    # Yellow Bold
BB='\e[34;1m'    # Blue Bold
MB='\e[35;1m'    # Magenta Bold
CB='\e[36;1m'    # Cyan Bold
WB='\e[37;1m'    # White Bold

CONFIG_FILE="/usr/local/etc/xray/config/06_routing.json"

# Fungsi untuk Verifikasi
verification_1st() {
    # Verifikasi perubahan
    if grep -q '"outboundTag": "warp"' $CONFIG_FILE; then
        echo -e "${GB}Perubahan berhasil dilakukan.${NC}"
    else
        echo -e "${RB}Perubahan gagal, silakan periksa file konfigurasi.${NC}"
    fi
}

# Fungsi untuk Verifikasi
verification_2nd() {
    # Verifikasi perubahan
    if grep -q '"outboundTag": "direct"' $CONFIG_FILE; then
        echo -e "${GB}Perubahan berhasil dilakukan.${NC}"
    else
        echo -e "${RB}Perubahan gagal, silakan periksa file konfigurasi.${NC}"
    fi
}

# Fungsi untuk merutekan seluruh lalu lintas via WARP
route_all_traffic() {
    # Menggunakan 'sed' untuk mengganti 'outboundTag' dari 'direct' menjadi 'warp'
    # sed -i '/"inboundTag": \[/,/"type": "field"/ s/"outboundTag": "direct"/"outboundTag": "warp"/' $CONFIG_FILE
    sed -i 's/"outboundTag": "direct"/"outboundTag": "warp"/g' $CONFIG_FILE
    verification_1st
    systemctl restart xray
}

# Fungsi untuk merutekan lalu lintas beberapa situs web via WARP
route_some_traffic() {
    # Menggunakan 'sed' untuk mengganti 'outboundTag' dari 'direct' menjadi 'warp' untuk domain tertentu
    sed -i '/"domain": \[/,/"type": "field"/ s/"outboundTag": "direct"/"outboundTag": "warp"/' $CONFIG_FILE
    verification_1st
    systemctl restart xray
}

# Fungsi untuk menonaktifkan rute WARP
disable_route() {
    # Menggunakan 'sed' untuk mengganti 'outboundTag' dari 'warp' menjadi 'direct'
    sed -i 's/"outboundTag": "warp"/"outboundTag": "direct"/g' $CONFIG_FILE
    systemctl restart xray
}

function_1st() {
  disable_route
  route_all_traffic
}
function_2nd() {
  disable_route
  route_some_traffic
}
function_3rd() {
  disable_route
  verification_2nd
}

# Fungsi untuk menampilkan menu
show_wg_menu() {
    clear
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "             ${WB}----- [ Route Xray Menu ] -----${NC}            "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e ""
    echo -e " ${MB}[1]${NC} ${YB}Route all traffic via WARP${NC}"
    echo -e " ${MB}[2]${NC} ${YB}Route some website traffic via WARP${NC}"
    echo -e " ${MB}[3]${NC} ${YB}Disable route WARP${NC}"
    echo -e ""
    echo -e " ${MB}[0]${NC} ${YB}Back To Menu${NC}"
    echo -e ""
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e ""
}

# Fungsi untuk menangani input menu
handle_wg_menu() {
    read -p " Select menu :  "  opt
    echo -e ""
    case $opt in
        1) function_1st ; sleep 2 ;;
        2) function_2nd ; sleep 2 ;;
        3) function_3rd ; sleep 2 ;;
        0) clear ; menu ;;
        *) echo -e "${YB}Invalid input${NC}" ; sleep 1 ; show_wg_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_wg_menu
    handle_wg_menu
done