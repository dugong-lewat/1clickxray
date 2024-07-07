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

# Set your Cloudflare API credentials
API_EMAIL="1562apricot@awgarstone.com"
API_KEY="e9c80c4d538c819701ea0129a2fd75ea599ba"

# Set the DNS record details
TYPE_A="A"
TYPE_CNAME="CNAME"
IP_ADDRESS=$(curl -sS ipv4.icanhazip.com)

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

# Function to get Previous Zone ID and delete existing DNS records
get_previous_zone_id() {
  echo -e "${YB}Getting Previous Zone ID and Deleting Existing Records...${NC}"

  # Read previous A record and CNAME record
  PREVIOUS_A_RECORD=$(cat /usr/local/etc/xray/dns/a_record 2>/dev/null)
  PREVIOUS_CNAME_RECORD=$(cat /usr/local/etc/xray/dns/cname_record 2>/dev/null)

  if [ -n "$PREVIOUS_A_RECORD" ]; then
    PREVIOUS_DOMAIN="${PREVIOUS_A_RECORD#*.}"
  elif [ -n "$PREVIOUS_CNAME_RECORD" ]; then
    PREVIOUS_DOMAIN="${PREVIOUS_CNAME_RECORD#*.}"
  else
    echo -e "${GB}No previous records found.${NC}"
    return
  fi

  # Get Zone ID for the previous domain
  PREVIOUS_ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$PREVIOUS_DOMAIN" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$PREVIOUS_ZONE_ID" == "null" ]; then
    echo -e "${RB}Failed to get Zone ID for previous domain${NC}"
    return
  fi

  PREVIOUS_ZONE_ID_SENSORED="${GB}${PREVIOUS_ZONE_ID:0:3}*****${PREVIOUS_ZONE_ID: -3}"
  echo -e "${YB}Previous Zone ID: $PREVIOUS_ZONE_ID_SENSORED${NC}"

  # Delete previous A record
  if [ -n "$PREVIOUS_A_RECORD" ]; then
    delete_record "$PREVIOUS_A_RECORD" "$TYPE_A" "$PREVIOUS_ZONE_ID"
  fi

  # Delete previous CNAME record
  if [ -n "$PREVIOUS_CNAME_RECORD" ]; then
    delete_record "$PREVIOUS_CNAME_RECORD" "$TYPE_CNAME" "$PREVIOUS_ZONE_ID"
  fi
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
  local zone_id=${3:-$ZONE_ID}

  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$record_type&name=$record_name" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$RECORD_ID" != "null" ]; then
    echo -e "${YB}Deleting existing $record_type record: ${CB}$record_name${NC} ${YB}.....${NC}"
    response=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$RECORD_ID" \
      -H "X-Auth-Email: $API_EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      -H "Content-Type: application/json")
    handle_response "$response" "${YB}Deleting $record_type record:${NC} ${CB}$record_name${NC}"
  fi
}

# Function to add A record
create_A_record() {
  local record_name=$(cat /usr/local/etc/xray/dns/a_record 2>/dev/null)
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
  echo "$NAME_A" > /usr/local/etc/xray/dns/a_record
  echo "DNS=$NAME_A" > /var/lib/dnsvps.conf
  handle_response "$response" "${YB}Adding A record $GB$NAME_A$NC"
}

# Function to add CNAME record
create_CNAME_record() {
  local record_name=$(cat /usr/local/etc/xray/dns/cname_record 2>/dev/null)
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
  echo "$NAME_CNAME" > /usr/local/etc/xray/dns/cname_record
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
        print_msg $YB "1. Gunakan domain yang tersedia"
        print_msg $YB "2. Gunakan domain sendiri"

        # Meminta input dari pengguna untuk memilih opsi
        read -rp "Masukkan pilihan Anda: " choice

        # Memproses pilihan pengguna
        case $choice in
            1)
                while true; do
                    # clear
                    print_msg $YB "Pilih Domain anda:"
                    print_msg $YB "1. vless.sbs"
                    print_msg $YB "2. airi.buzz"
                    print_msg $YB "3. drm.icu"
                    read -rp "Masukkan pilihan Anda: " domain_choice
                    case $domain_choice in
                        1)
                            DOMAIN="vless.sbs"
                            break
                            ;;
                        2)
                            DOMAIN="airi.buzz"
                            break
                            ;;
                        3)
                            DOMAIN="drm.icu"
                            break
                            ;;
                        *)
                            print_error "Pilihan tidak valid!"
                            sleep 2
                            ;;
                    esac
                done
                NAME_A="$(openssl rand -hex 2).$DOMAIN"
                NAME_CNAME="*.$NAME_A"
                TARGET_CNAME="$NAME_A"
                get_previous_zone_id
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
