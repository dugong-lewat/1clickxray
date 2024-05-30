#!/bin/bash

NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
clear

# Fungsi untuk memvalidasi domain
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Fungsi untuk meminta input domain
input_domain() {
    while true; do
        clear
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        read -rp "Domain/Host: " -e host

        if [ -z "$host" ]; then
            echo -e "${YB}No input provided! Please enter a valid domain.${NC}"
            echo -e "${BB}————————————————————————————————————————————————————${NC}"
            read -n 1 -s -r -p "Press any key to try again"
        elif ! validate_domain "$host"; then
            echo -e "${YB}Invalid domain format! Please input a valid domain.${NC}"
            echo -e "${BB}————————————————————————————————————————————————————${NC}"
            read -n 1 -s -r -p "Press any key to try again"
        else
            echo "DNS=$host" > /var/lib/dnsvps.conf
            echo -e "${BB}————————————————————————————————————————————————————${NC}"
            echo -e "${YB}Domain saved successfully! Don't forget to renew the certificate.${NC}"
            echo ""
            read -n 1 -s -r -p "Press any key to return to the menu"
            break
        fi
    done
}

# Panggil fungsi input_domain untuk memulai proses
input_domain

# Fungsi untuk menampilkan menu (sesuaikan dengan fungsi menu Anda)
input_menu() {
    # Isi dengan fungsi atau perintah untuk menampilkan menu Anda
    clear
    echo -e "${YB}Returning to menu...${NC}"
    sleep 1.5
    menu
    # Contoh: panggil skrip menu atau perintah lain
    # ./menu.sh
}

# Panggil fungsi menu untuk kembali ke menu
input_menu