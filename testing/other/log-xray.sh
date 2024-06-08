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

# Fungsi untuk menampilkan informasi dengan penundaan
info() {
    echo -e "${GB}[ INFO ]${NC} ${YB}$1${NC}"
    sleep 0.5
}

# Fungsi untuk menampilkan peringatan dengan penundaan
warning() {
    echo -e "${RB}[ WARNING ]${NC} ${YB}$1${NC}"
    sleep 0.5
}

# Fungsi untuk menampilkan menu jika tidak ada klien
no_clients_menu() {
    clear
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "                  ${WB}Log All Xray Account${NC}                 "
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "  ${YB}You have no existing clients!${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to back to menu"
    menu
}

clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    no_clients_menu
fi

clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                  ${WB}Log All Xray Account${NC}                 "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}User  Expired${NC}  "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
grep -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json" | cut -d ' ' -f 2-3 | column -t | sort | uniq
echo ""
echo -e "${YB}Tap enter to go back${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Input Username: " user
if [[ -z $user ]]; then
    menu
else
    clear
    log_file="/user/xray-$user.log"
    if [[ -f $log_file ]]; then
        echo -e "$(cat "$log_file")"
    else
        warning "Log file for user $user not found."
    fi
    echo ""
    read -n 1 -s -r -p "Press any key to back to menu"
    menu
fi