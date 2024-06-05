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

# Fungsi untuk memeriksa status layanan
check_service_status() {
    local service=$1
    local status=$(systemctl is-active "$service")
    if [[ $status == "active" ]]; then
        echo -e "${GB}[ ON ]${NC}"
    else
        echo -e "${RB}[ OFF ]${NC}"
    fi
}

# Memeriksa status layanan Xray dan Nginx
status_xray=$(check_service_status xray)
status_nginx=$(check_service_status nginx)

# Mengambil data bandwidth menggunakan vnstat
get_bandwidth_data() {
    local period=$1
    vnstat --json | jq -r ".interfaces[0].traffic.$period[] | .rx, .tx"
}

# Mendapatkan data bandwidth hari ini
today_data=($(get_bandwidth_data "day"))
dtoday=$(echo "${today_data[0]}" | awk '{printf "%.2f MiB", $1/1048576}')
utoday=$(echo "${today_data[1]}" | awk '{printf "%.2f MiB", $1/1048576}')
ttoday=$(echo "${today_data[0]} ${today_data[1]}" | awk '{printf "%.2f MiB", ($1 + $2)/1048576}')

# Mendapatkan data bandwidth bulanan
month=$(date +%Y-%m)
monthly_data=($(vnstat --json | jq -r ".interfaces[0].traffic.month[] | select(.date.year == $(date +%Y) and .date.month == $(date +%-m)) | .rx, .tx"))
dmon=$(echo "${monthly_data[0]}" | awk '{printf "%.2f MiB", $1/1048576}')
umon=$(echo "${monthly_data[1]}" | awk '{printf "%.2f MiB", $1/1048576}')
tmon=$(echo "${monthly_data[0]} ${monthly_data[1]}" | awk '{printf "%.2f MiB", ($1 + $2)/1048576}')

# Mengambil informasi konfigurasi dan sistem
domain=$(cat /usr/local/etc/xray/domain)
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
REG=$(cat /usr/local/etc/xray/region)
WKT=$(cat /usr/local/etc/xray/timezone)
DATE=$(date +"%a, %d %b %Y")
MYIP=$(curl -sS ipv4.icanhazip.com)
XRAY_VERSION=$(xray -version | head -n 1 | awk '{print "v"$2}')

# Fungsi untuk menampilkan menu
show_menu() {
    clear
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "               ${WB}----- [ Xray Script ] -----${NC}              "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e " ${YB}ISP${NC}          ${WB}: $ISP"
    echo -e " ${YB}Region${NC}       ${WB}: $REG${NC}"
    echo -e " ${YB}City${NC}         ${WB}: $CITY${NC}"
    echo -e " ${YB}Date${NC}         ${WB}: $DATE${NC}"
    echo -e " ${YB}Domain${NC}       ${WB}: $domain${NC}"
    echo -e " ${YB}Xray Version${NC} ${WB}: $XRAY_VERSION${NC}"
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "     ${WB}NGINX STATUS :${NC} $status_nginx    ${WB}XRAY STATUS :${NC} $status_xray   "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "          ${WB}----- [ Bandwidth Monitoring ] -----${NC}"
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "  ${GB}Today (${DATE})${NC}      ${GB}Monthly ($(date +%B/%Y))${NC}      "
    echo -e "  ${GB}↓↓ Down : $dtoday${NC}         ${GB}↓↓ Down : $dmon${NC}   "
    echo -e "  ${GB}↑↑ Up   : $utoday${NC}         ${GB}↑↑ Up   : $umon${NC}   "
    echo -e "  ${GB}≈ Total : $ttoday${NC}         ${GB}≈ Total : $tmon${NC}   "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "                   ${WB}----- [ Menu ] -----${NC}               "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e " ${MB}[1]${NC} ${YB}Xray Menu${NC}"
    echo -e " ${MB}[2]${NC} ${YB}Log Create Account${NC}"
    echo -e " ${MB}[3]${NC} ${YB}Update Xray-core${NC}"
    echo -e " ${MB}[4]${NC} ${YB}Speedtest${NC}"
    echo -e " ${MB}[5]${NC} ${YB}Change Domain${NC}"
    echo -e " ${MB}[6]${NC} ${YB}Cert Acme.sh${NC}"
    echo -e " ${MB}[7]${NC} ${YB}About Script${NC}"
    echo -e " ${MB}[8]${NC} ${YB}Exit${NC}"
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e ""
    # echo -e "${RB}Jika kalian mengubah domain maka Akun yang yang sudah dibuat akan hilang, Jadi tolong hati-hati.${NC}"
}

# Fungsi untuk menangani input menu
handle_menu() {
    read -p " Select Menu :  " opt
    echo -e ""
    case $opt in
        1) clear ; allxray ;;
        2) clear ; log-xray ;;
        3) clear ; update-xray ;;
        4) clear ; speedtest ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; show_menu ;;
        5) clear ; dns ;;
        6) clear ; certxray ;;
        7) clear ; about ;;
        8) exit ;;
        *) echo -e "${YB}Invalid input${NC}" ; sleep 1 ; show_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_menu
    handle_menu
done
