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

# Set your Cloudflare API credentials and zone ID
API_EMAIL="1562apricot@awgarstone.com"
API_KEY="e9c80c4d538c819701ea0129a2fd75ea599ba"

# Set the DNS record details
DOMAIN="vless.sbs"
TYPE_A="A"
TYPE_CNAME="CNAME"
NAME_A="xray-$(</dev/urandom tr -dc a-z0-9 | head -c4).$DOMAIN"
IP_ADDRESS=$(wget -qO- ifconfig.me)
NAME_CNAME="*.$NAME_A"
TARGET_CNAME="$NAME_A"
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

# Function to get Zone ID
get_zone_id() {
  echo -e "${YB}Getting Zone ID...${NC}"
  ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$ZONE_ID" == "null" ]; then
    echo -e "${RB}Failed to get Zone ID${NC}"
    exit 1
  fi

  # Sensoing Zone ID (Only showing first and last 3 characters)
  ZONE_ID_SENSORED="${GB}${ZONE_ID:0:3}*****${ZONE_ID: -3}"

  echo -e "${YB}Zone ID: $ZONE_ID_SENSORED${NC}"
}

# Function to handle API response
handle_response() {
  local response=$1
  local action=$2

  success=$(echo $response | jq -r '.success')
  if [ "$success" == "true" ]; then
    echo -e "$action ${YB}was successful.${NC}"
  else
    echo -e "$action ${RB}failed.${NC}"
    errors=$(echo $response | jq -r '.errors[] | .message')
    echo -e "${RB}Errors: $errors${NC}"
  fi
}

# Function to add A record
create_A_record() {
  echo -e "${YB}Adding domain $GB$NAME_A$NC $YB.....${NC}"
  response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    --data '{
      "type": "'$TYPE_A'",
      "name": "'$NAME_A'",
      "content": "'$IP_ADDRESS'",
      "ttl": 0,
      "proxied": false
    }')
  handle_response "$response" "${YB}Adding domain $GB$NAME_A$NC"
}

# Function to add CNAME record
create_CNAME_record() {
  echo -e "${YB}Adding wildcard domain $GB$NAME_CNAME$NC $YB.....${NC}"
  response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    --data '{
      "type": "'$TYPE_CNAME'",
      "name": "'$NAME_CNAME'",
      "content": "'$TARGET_CNAME'",
      "ttl": 0,
      "proxied": false
    }')
  handle_response "$response" "${YB}Adding wildcard domain $GB$NAME_CNAME$NC"
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
                get_zone_id
                create_A_record
                create_CNAME_record
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
    echo -e "${YB}Dont forget to renew certificate.${NC}"
    sleep 2
    echo -e "${YB}Returning to menu...${NC}"
    sleep 4
    clear
    menu
    # Contoh: panggil skrip menu atau perintah lain
    # ./menu.sh
}

# Panggil fungsi menu untuk kembali ke menu
input_menu