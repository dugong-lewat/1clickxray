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
    local field=$2
    vnstat | grep "$period" | awk "{print \$$field\" \"substr (\$$(($field+1)), 1, 3)}"
}

dtoday=$(get_bandwidth_data today 2)
utoday=$(get_bandwidth_data today 5)
ttoday=$(get_bandwidth_data today 8)

dmon=$(get_bandwidth_data "$(date +%G-%m)" 2)
umon=$(get_bandwidth_data "$(date +%G-%m)" 5)
tmon=$(get_bandwidth_data "$(date +%G-%m)" 8)

# Mengambil informasi konfigurasi dan sistem
domain=$(cat /usr/local/etc/xray/domain)
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
REG=$(cat /usr/local/etc/xray/region)
WKT=$(cat /usr/local/etc/xray/timezone)
DATE=$(date -R | cut -d " " -f -4)
MYIP=$(curl -sS ipv4.icanhazip.com)

# Fungsi untuk menampilkan menu
show_menu() {
    clear
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "               ${WB}----- [ Xray Script ] -----${NC}              "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e " ${YB}ISP${NC}    ${WB}: $ISP"
    echo -e " ${YB}Region${NC} ${WB}: $REG${NC}"
    echo -e " ${YB}City${NC}   ${WB}: $CITY${NC}"
    echo -e " ${YB}Date${NC}   ${WB}: $DATE${NC}"
    echo -e " ${YB}Domain${NC} ${WB}: $domain${NC}"
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "     ${WB}NGINX STATUS :${NC} $status_nginx    ${WB}XRAY STATUS :${NC} $status_xray   "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "          ${WB}----- [ Bandwidth Monitoring ] -----${NC}"
    echo -e ""
    echo -e "  ${GB}Today ($DATE)     Monthly ($(date +%B/%Y))${NC}      "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "    ${GB}↓↓ Down: $dtoday          ↓↓ Down: $dmon${NC}   "
    echo -e "    ${GB}↑↑ Up  : $utoday          ↑↑ Up  : $umon${NC}   "
    echo -e "    ${GB}≈ Total: $ttoday          ≈ Total: $tmon${NC}   "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "                   ${WB}----- [ Menu ] -----${NC}               "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e " ${MB}[1]${NC} ${YB}Xray Menu${NC}"
    echo -e " ${MB}[2]${NC} ${YB}Log Create Account${NC}"
    echo -e " ${MB}[3]${NC} ${YB}Speedtest${NC}"
    echo -e " ${MB}[4]${NC} ${YB}Change Domain${NC}"
    echo -e " ${MB}[5]${NC} ${YB}Cert Acme.sh${NC}"
    echo -e " ${MB}[6]${NC} ${YB}About Script${NC}"
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e ""
}

# Fungsi untuk menangani input menu
handle_menu() {
    read -p " Select Menu :  " opt
    echo -e ""
    case $opt in
        1) clear ; allxray ;;
        2) clear ; log-xray ;;
        3) clear ; speedtest ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; show_menu ;;
        4) clear ; dns ;;
        5) clear ; certxray ;;
        6) clear ; about ;;
        x) exit ;;
        *) echo -e "${YB}Invalid input${NC}" ; sleep 1 ; clear ; show_menu ; handle_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
show_menu
handle_menu