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
NAME_A="$(openssl rand -hex 2).$DOMAIN"
IP_ADDRESS=$(curl -sS ipv4.icanhazip.com)
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
            echo "$dns" > /usr/local/etc/xray/dns/domain
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

# Function to delete existing DNS record
delete_record() {
  local record_name=$1
  local record_type=$2

  echo -e "${YB}Checking for existing $record_type record: ${CB}$record_name${NC} ${YB}.....${NC}"
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$record_type&name=$record_name" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$RECORD_ID" != "null" ]; then
    echo -e "${YB}Deleting existing $record_type record: ${CB}$record_name${NC} ${YB}.....${NC}"
    response=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "X-Auth-Email: $API_EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      -H "Content-Type: application/json")
    handle_response "$response" "${YB}Deleting $record_type record:${NC} ${CB}$record_name${NC}"
  else
    echo -e "${GB}No existing $record_type record found for $record_name.${NC}"
  fi
}

# Function to add A record
create_A_record() {
  local record_name=$(cat /usr/local/etc/xray/a_record 2>/dev/null)
  if [ -n "$record_name" ]; then
    delete_record "$record_name" "$TYPE_A"
  fi

  echo -e "${YB}Adding A record $GB$NAME_A$NC $YB.....${NC}"
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
  echo "$NAME_A" > /usr/local/etc/xray/dns/domain
  echo "$NAME_A" > /usr/local/etc/xray/a_record
  echo "DNS=$NAME_A" > /var/lib/dnsvps.conf
  handle_response "$response" "${YB}Adding A record $GB$NAME_A$NC"
}

# Function to add CNAME record
create_CNAME_record() {
  local record_name=$(cat /usr/local/etc/xray/cname_record 2>/dev/null)
  if [ -n "$record_name" ]; then
    delete_record "$record_name" "$TYPE_CNAME"
  fi

  echo -e "${YB}Adding CNAME record for wildcard $GB$NAME_CNAME$NC $YB.....${NC}"
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
  echo "$NAME_CNAME" > /usr/local/etc/xray/cname_record
  handle_response "$response" "${YB}Adding CNAME record for wildcard $GB$NAME_CNAME$NC"
}

# Update Nginx configuration
update_nginx_config() {
    # Get new domain from file
    NEW_DOMAIN=$(cat /usr/local/etc/xray/dns/domain)
    # Update server_name in Nginx configuration
    sed -i "s/server_name .*;/server_name $NEW_DOMAIN;/g" /etc/nginx/nginx.conf

    # Check if Nginx configuration is valid after changes
    if nginx -t &> /dev/null; then
        # Reload Nginx configuration if valid
        systemctl reload nginx
        print_msg $GB "Nginx configuration reloaded successfully."
    else
        # If Nginx configuration is not valid, display error message
        print_msg $RB "Nginx configuration test failed. Please check your configuration."
    fi
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
                update_nginx_config
                break
                ;;
            2)
                # Menggunakan domain sendiri
                input_domain
                update_nginx_config
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
    sleep 2
}

# Menjalankan menu utama
setup_domain

input_menu() {
    # Isi dengan fungsi atau perintah untuk menampilkan menu Anda
    echo -e "${RB}Dont forget to renew certificate.${NC}"
    sleep 5
    echo -e "${YB}Returning to menu...${NC}"
    sleep 2
    clear
    menu
    # Contoh: panggil skrip menu atau perintah lain
    # ./menu.sh
}

# Panggil fungsi menu untuk kembali ke menu
input_menu
