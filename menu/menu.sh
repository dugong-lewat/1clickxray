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

# Fungsi untuk menampilkan menu
show_menu() {
    clear
    python /usr/bin/system_info.py
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "               ${WB}----- [ Xray Script ] -----${NC}              "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "                   ${WB}----- [ Menu ] -----${NC}               "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e " ${MB}[1]${NC} ${YB}Xray Menu${NC}"
    echo -e " ${MB}[2]${NC} ${YB}Xray Route${NC}"
    echo -e " ${MB}[3]${NC} ${YB}Xray Statistics${NC}"
    echo -e " ${MB}[4]${NC} ${YB}Log Create Account${NC}"
    echo -e " ${MB}[5]${NC} ${YB}Update Xray-core${NC}"
    echo -e " ${MB}[6]${NC} ${YB}Speedtest${NC}"
    echo -e " ${MB}[7]${NC} ${YB}Change Domain${NC}"
    echo -e " ${MB}[8]${NC} ${YB}Cert Acme.sh${NC}"
    echo -e " ${MB}[9]${NC} ${YB}About Script${NC}"
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
        2) clear ; route-xray ;;
        3) clear ; python /usr/bin/traffic.py ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; show_menu ;;
        4) clear ; log-xray ;;
        5) clear ; update-xray ;;
        6) clear ; speedtest ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; show_menu ;;
        7) clear ; dns ;;
        8) clear ; certxray ;;
        9) clear ; about ;;
        *) echo -e "${YB}Invalid input${NC}" ; sleep 1 ; show_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_menu
    handle_menu
done
