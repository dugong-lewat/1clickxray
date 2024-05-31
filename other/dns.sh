#!/bin/bash

NC='\e[0m'         # No Color (mengatur ulang warna teks ke default)
DEFBOLD='\e[39;1m' # Default Bold
RB='\e[31;1m'      # Red Bold
GB='\e[32;1m'      # Green Bold
YB='\e[33;1m'      # Yellow Bold
BB='\e[34;1m'      # Blue Bold
MB='\e[35;1m'      # Magenta Bold
CB='\e[36;1m'      # Cyan Bold
WB='\e[37;1m'      # White Bold
clear

# Fungsi untuk mencetak pesan dengan warna
print_msg() {
    COLOR=$1
    MSG=$2
    echo -e "${COLOR}${MSG}${NC}"
}

# Fungsi untuk memeriksa keberhasilan perintah
check_success() {
    if [ $? -eq 0 ]; then
        print_msg $GB "Berhasil"
    else
        print_msg $RB "Gagal: $1"
        exit 1
    fi
}

# Fungsi untuk menampilkan pesan kesalahan
print_error() {
    MSG=$1
    print_msg $RB "Error: ${MSG}"
}

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
        echo -e "${YB}Input Domain${NC}"
        echo " "
        read -rp "Input domain kamu: " -e dns

        if [ -z "$dns" ]; then
            echo -e "${RB}Nothing input for domain!${NC}"
        elif ! validate_domain "$dns"; then
            echo -e "${RB}Invalid domain format! Please input a valid domain.${NC}"
        else
            echo "$dns" > /usr/local/etc/xray/domain
            echo "DNS=$dns" > /var/lib/dnsvps.conf
            echo -e "Domain ${GB}${dns}${NC} saved successfully"
            echo -e "${YB}Don't forget to renew the certificate.${NC}"
            break
        fi
    done
}

# Fungsi untuk membuat subdomain acak di Cloudflare
create_random_subdomain() {
    DOMAIN=vless.sbs
    SUB_DOMAIN="xray-$(</dev/urandom tr -dc a-z0-9 | head -c4).$DOMAIN"
    CF_ID=1562apricot@awgarstone.com
    CF_KEY=e9c80c4d538c819701ea0129a2fd75ea599ba

    IP=$(wget -qO- ifconfig.me)
    echo -e "Updating DNS for ${GB}${SUB_DOMAIN}${NC}..."

    ZONE=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" | jq -r .result[0].id)

    RECORD=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${SUB_DOMAIN}" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" | jq -r .result[0].id)

    if [[ "${#RECORD}" -le 10 ]]; then
         RECORD=$(curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'${SUB_DOMAIN}'","content":"'${IP}'","ttl":0,"proxied":false}' | jq -r .result.id)
    fi

    RESULT=$(curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'${SUB_DOMAIN}'","content":"'${IP}'","ttl":0,"proxied":false}')

    echo "$SUB_DOMAIN" > /usr/local/etc/xray/domain
    echo "DNS=$SUB_DOMAIN" > /var/lib/dnsvps.conf
    echo -e "Domain ${GB}${SUB_DOMAIN}${NC} saved successfully"
    echo -e "${YB}Don't forget to renew the certificate.${NC}"
}

# Fungsi untuk menampilkan menu utama
setup_domain() {
    while true; do
        clear

        # Menampilkan judul
        print_msg $BB "————————————————————————————————————————————————————————"
        print_msg $YB "                      SETUP DOMAIN"
        print_msg $BB "————————————————————————————————————————————————————————"

        # Menampilkan pilihan untuk menggunakan domain acak atau domain sendiri
        print_msg $YB "Pilih Opsi:"
        print_msg $YB "1. Gunakan domain acak"
        print_msg $YB "2. Gunakan domain sendiri"

        # Meminta input dari pengguna untuk memilih opsi
        read -rp "Masukkan pilihan Anda: " choice

        # Memproses pilihan pengguna
        case $choice in
            1)
                # Menggunakan domain acak
                create_random_subdomain
                break
                ;;
            2)
                # Menggunakan domain sendiri
                input_domain
                break
                ;;
            *)
                # Opsi yang tidak valid
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done

    # Memberi waktu singkat sebelum membersihkan layar
    sleep 4
}

# Menjalankan menu utama
setup_domain

input_menu() {
    # Isi dengan fungsi atau perintah untuk menampilkan menu Anda
    echo -e "${YB}Returning to menu...${NC}"
    sleep 4
    clear
    menu
    # Contoh: panggil skrip menu atau perintah lain
    # ./menu.sh
}

# Panggil fungsi menu untuk kembali ke menu
input_menu