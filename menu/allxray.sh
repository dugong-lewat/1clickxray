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
show_allxray_menu() {
    clear
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e "             ${WB}----- [ All Xray Menu ] -----${NC}            "
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e ""
    echo -e " ${MB}[1]${NC} ${YB}Create Xray${NC}"
    echo -e " ${MB}[2]${NC} ${YB}Extend Xray${NC}"
    echo -e " ${MB}[3]${NC} ${YB}Delete Xray${NC}"
    echo -e " ${MB}[4]${NC} ${YB}User Login${NC}"
    echo -e ""
    echo -e " ${MB}[0]${NC} ${YB}Back To Menu${NC}"
    echo -e ""
    echo -e "${BB}————————————————————————————————————————————————————————${NC}"
    echo -e ""
}

# Fungsi untuk menangani input menu
handle_allxray_menu() {
    read -p " Select menu :  "  opt
    echo -e ""
    case $opt in
        1) clear ; create-xray ;;
        2) clear ; extend-xray ;;
        3) clear ; del-xray ;;
        4) clear ; cek-xray ;;
        0) clear ; menu ;;
        *) echo -e "${YB}Invalid input${NC}" ; sleep 1 ; show_allxray_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_allxray_menu
    handle_allxray_menu
done
