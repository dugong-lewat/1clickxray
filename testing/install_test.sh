#!/bin/bash

rm -rf install_test.sh
clear
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

secs_to_human() {
echo -e "${WB}Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds${NC}"
}
start=$(date +%s)

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

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang beberapa paket penting pada sistem Anda."

# Update package list
print_msg $YB "Memperbarui daftar paket..."
apt update -y
check_success
sleep 1

# Install paket pertama
print_msg $YB "Memasang socat, netfilter-persistent, dan bsdmainutils..."
apt install socat netfilter-persistent bsdmainutils -y
check_success
sleep 1

# Install paket kedua
print_msg $YB "Memasang vnstat, lsof, dan fail2ban..."
apt install vnstat lsof fail2ban -y
check_success
sleep 1

# Install paket ketiga
print_msg $YB "Memasang jq, curl, sudo, dan cron..."
apt install jq curl sudo cron -y
check_success
sleep 1

# Install paket keempat
print_msg $YB "Memasang build-essential dan dependensi lainnya..."
apt install build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev gcc clang llvm g++ valgrind make cmake debian-keyring debian-archive-keyring apt-transport-https systemd -y
apt install unzip systemd -y
check_success
sleep 1

# Pesan selesai
print_msg $GB "Semua paket telah berhasil dipasang!"
sleep 3
clear

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang Xray-core dan melakukan beberapa konfigurasi pada sistem Anda."

# Membuat direktori yang diperlukan
print_msg $YB "Membuat direktori yang diperlukan..."
sudo mkdir -p /user /tmp /usr/local/etc/xray /var/log/xray
check_success "Gagal membuat direktori."

# Menghapus file konfigurasi lama jika ada
print_msg $YB "Menghapus file konfigurasi lama..."
sudo rm -f /usr/local/etc/xray/city /usr/local/etc/xray/org /usr/local/etc/xray/timezone /usr/local/etc/xray/region
check_success "Gagal menghapus file konfigurasi lama."

# Fungsi untuk mendeteksi OS dan distribusi
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_msg $RB "Tidak dapat mendeteksi OS. Skrip ini hanya mendukung distribusi berbasis Debian dan Red Hat."
        exit 1
    fi
}

# Fungsi untuk memeriksa versi terbaru Xray-core
get_latest_xray_version() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r '.tag_name')
    if [ -z "$LATEST_VERSION" ]; then
        print_msg $RB "Tidak dapat menemukan versi terbaru Xray-core."
        exit 1
    fi
}

# Fungsi untuk memasang Xray-core
install_xray_core() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="64"
            ;;
        aarch64)
            ARCH="arm64-v8a"
            ;;
        *)
            print_msg $RB "Arsitektur $ARCH tidak didukung."
            exit 1
            ;;
    esac

    DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/$LATEST_VERSION/Xray-linux-$ARCH.zip"

    # Unduh dan ekstrak Xray-core
    print_msg $YB "Mengunduh dan memasang Xray-core..."
    curl -L -o xray.zip $DOWNLOAD_URL
    check_success "Gagal mengunduh Xray-core."

    sudo unzip -o xray.zip -d /usr/local/bin
    check_success "Gagal mengekstrak Xray-core."
    rm xray.zip

    sudo chmod +x /usr/local/bin/xray
    check_success "Gagal mengatur izin eksekusi untuk Xray-core."

    # Membuat layanan systemd
    print_msg $YB "Mengkonfigurasi layanan systemd untuk Xray-core..."
    sudo bash -c 'cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray/config/
RestartSec=3
Restart=always
LimitNOFILE=infinity
OOMScoreAdjust=100

[Install]
WantedBy=multi-user.target
EOF'
    check_success "Gagal mengkonfigurasi layanan systemd untuk Xray-core."

    sudo systemctl daemon-reload
    sudo systemctl enable xray
    sudo systemctl start xray
    check_success "Gagal memulai layanan Xray-core."
}

# Deteksi OS
print_msg $YB "Mendeteksi sistem operasi..."
detect_os

# Cek apakah OS didukung
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" || "$OS" == "Debian GNU/Linux" || "$OS" == "CentOS" || "$OS" == "Fedora" || "$OS" == "Red Hat Enterprise Linux" ]]; then
    print_msg $GB "Mendeteksi OS: $OS $VERSION"
else
    print_msg $RB "Distribusi $OS tidak didukung oleh skrip ini. Proses instalasi dibatalkan."
    exit 1
fi

# Memeriksa versi terbaru Xray-core
print_msg $YB "Memeriksa versi terbaru Xray-core..."
get_latest_xray_version
print_msg $GB "Versi terbaru Xray-core: $LATEST_VERSION"

# Memasang dependensi yang diperlukan
print_msg $YB "Memasang dependensi yang diperlukan..."
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" ]]; then
    sudo apt update
    sudo apt install -y curl unzip
elif [[ "$OS" == "CentOS" || "$OS" == "Fedora" || "$OS" == "Red Hat Enterprise Linux" ]]; then
    sudo yum install -y curl unzip
fi
check_success "Gagal memasang dependensi yang diperlukan."

# Memasang Xray-core
install_xray_core

print_msg $GB "Pemasangan Xray-core versi $LATEST_VERSION selesai."

# Mengumpulkan informasi dari ipinfo.io
print_msg $YB "Mengumpulkan informasi lokasi dari ipinfo.io..."
curl -s ipinfo.io/city | sudo tee /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 | sudo tee /usr/local/etc/xray/org
curl -s ipinfo.io/timezone | sudo tee /usr/local/etc/xray/timezone
curl -s ipinfo.io/region | sudo tee /usr/local/etc/xray/region
check_success "Gagal mengumpulkan informasi lokasi."

print_msg $GB "Semua tugas selesai. Xray-core telah dipasang dan dikonfigurasi dengan informasi lokasi."
sleep 3
clear

# Menampilkan pesan interaktif
print_msg $YB "Selamat datang! Skrip ini akan menginstal Speedtest CLI dan mengatur zona waktu Anda."
sleep 3

# Mengunduh dan menginstal Speedtest CLI
print_msg $YB "Mengunduh dan menginstal Speedtest CLI..."
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash &>/dev/null
sudo apt-get install -y speedtest &>/dev/null
print_msg $YB "Speedtest CLI berhasil diinstal."

# Mengatur zona waktu ke Asia/Jakarta
print_msg $YB "Mengatur zona waktu ke Asia/Jakarta..."
sudo timedatectl set-timezone Asia/Jakarta &>/dev/null
print_msg $YB "Zona waktu berhasil diatur."

# Memberikan pesan penyelesaian
print_msg $YB "Instalasi selesai."
sleep 3
clear

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang dan mengkonfigurasi Nginx pada sistem Anda."

# Mendapatkan informasi distribusi dan codename
print_msg $YB "Mendeteksi distribusi dan codename Linux..."
if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    os=$DISTRIB_ID
    codename=$DISTRIB_CODENAME
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    os=$ID
    codename=$VERSION_CODENAME
else
    print_msg $RB "Gagal mendeteksi distribusi Linux."
    exit 1
fi
check_success "Gagal mendeteksi distribusi Linux."

# Menentukan URL repository berdasarkan distribusi dan codename
case "$os" in
    ubuntu)
        repo_url="http://nginx.org/packages/ubuntu/"
        ;;
    debian)
        repo_url="http://nginx.org/packages/debian/"
        ;;
    Ubuntu)
        repo_url="http://nginx.org/packages/ubuntu/"
        ;;
    Debian)
        repo_url="http://nginx.org/packages/debian/"
        ;;
    *)
        print_msg $RB "Distribusi Linux tidak didukung."
        exit 1
        ;;
esac

# Menambahkan repository Nginx
print_msg $YB "Menambahkan repository Nginx ke sources.list.d..."
cat > /etc/apt/sources.list.d/nginx.list << END
deb $repo_url $codename nginx
deb-src $repo_url $codename nginx
END
check_success "Gagal menambahkan repository Nginx."

# Mendownload kunci signing Nginx
print_msg $YB "Mendownload kunci signing Nginx..."
wget -q http://nginx.org/keys/nginx_signing.key
check_success "Gagal mendownload kunci signing Nginx."

# Menambahkan kunci signing Nginx ke apt
print_msg $YB "Menambahkan kunci signing Nginx ke apt..."
apt-key add nginx_signing.key
check_success "Gagal menambahkan kunci signing Nginx ke apt."

# Membersihkan file kunci yang didownload
rm -rf nginx_signing.*
check_success "Gagal membersihkan file kunci yang didownload."

# Memperbarui daftar paket
print_msg $YB "Memperbarui daftar paket..."
apt update
check_success "Gagal memperbarui daftar paket."

# Menginstal Nginx versi terbaru
print_msg $YB "Menginstal Nginx versi terbaru..."
apt install -y nginx
check_success "Gagal menginstal Nginx."

# Menghapus konfigurasi default Nginx dan konten default web
print_msg $YB "Menghapus konfigurasi default Nginx dan konten default web..."
rm -rf /etc/nginx/conf.d/default.conf >> /dev/null 2>&1
rm -rf /var/www/html/* >> /dev/null 2>&1
check_success "Gagal menghapus konfigurasi default Nginx dan konten default web."

# Membuat direktori untuk Xray
print_msg $YB "Membuat direktori untuk Xray di /var/www/html..."
mkdir -p /var/www/html/xray >> /dev/null 2>&1
check_success "Gagal membuat direktori untuk Xray."

# Pesan selesai
print_msg $GB "Pemasangan dan konfigurasi Nginx telah selesai."
sleep 3
clear
systemctl restart nginx
systemctl stop nginx
systemctl stop xray
mkdir -p /usr/local/etc/xray/config >> /dev/null 2>&1
mkdir -p /usr/local/etc/xray/dns >> /dev/null 2>&1
touch /usr/local/etc/xray/dns/domain

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
    sleep 2
}

# Menjalankan menu utama
setup_domain

# Fungsi untuk menginstal acme.sh dan mendapatkan sertifikat
install_acme_sh() {
    domain=$(cat /usr/local/etc/xray/dns/domain)
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh  --register-account  -m $(echo $RANDOM | md5sum | head -c 6; echo;)@gmail.com --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d "$domain" --listen-v6 --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --standalone --reloadcmd "systemctl reload nginx"
    chmod 745 /usr/local/etc/xray/private.key
    echo -e "${YB}Sertifikat SSL berhasil dipasang!${NC}"
}

# Panggil fungsi install_acme_sh untuk menginstal acme.sh dan mendapatkan sertifikat
install_acme_sh
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Nginx & Xray Config${NC}"
# Menghasilkan UUID
uuid=$(cat /proc/sys/kernel/random/uuid)

# Menghasilkan password random
pwtr=$(openssl rand -hex 4)
pwss=$(echo $RANDOM | md5sum | head -c 6; echo;)

# Menghasilkan PSK (Pre-Shared Key) untuk pengguna dan server
userpsk=$(openssl rand -base64 32)
serverpsk=$(openssl rand -base64 32)
echo "$serverpsk" > /usr/local/etc/xray/serverpsk

# Konfigurasi Xray-core
print_msg $YB "Mengonfigurasi Xray-core..."
XRAY_CONFIG=raw.githubusercontent.com/dugong-lewat/1clickxray/main/testing/config
wget -q -O /usr/local/etc/xray/config/00_log.json "https://${XRAY_CONFIG}/00_log.json"
wget -q -O /usr/local/etc/xray/config/01_api.json "https://${XRAY_CONFIG}/01_api.json"
wget -q -O /usr/local/etc/xray/config/02_dns.json "https://${XRAY_CONFIG}/02_dns.json"
wget -q -O /usr/local/etc/xray/config/03_policy.json "https://${XRAY_CONFIG}/03_policy.json"
cat > /usr/local/etc/xray/config/04_inbounds.json << END
{
    "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
# XTLS
    {
      "listen": "::",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "flow": "xtls-rprx-vision",
            "id": "$uuid"
#xtls
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": 4443,
            "xver": 2
          },
          {
            "dest": 8080,
            "xver": 2
          },
          // Websocket
          {
            "path": "/vless-ws",
            "dest": "@vless-ws",
            "xver": 2
          },
          {
            "path": "/vmess-ws",
            "dest": "@vmess-ws",
            "xver": 2
          },
          {
            "path": "/trojan-ws",
            "dest": "@trojan-ws",
            "xver": 2
          },
          {
            "path": "/ss-ws",
            "dest": 1000,
            "xver": 2
          },
          {
            "path": "/ss22-ws",
            "dest": 1100,
            "xver": 2
          },
          // HTTPupgrade
          {
            "path": "/vless-hup",
            "dest": "@vl-hup",
            "xver": 2
          },
          {
            "path": "/vmess-hup",
            "dest": "@vm-hup",
            "xver": 2
          },
          {
            "path": "/trojan-hup",
            "dest": "@tr-hup",
            "xver": 2
          },
          {
            "path": "/ss-hup",
            "dest": "3000",
            "xver": 2
          },
          {
            "path": "/ss22-hup",
            "dest": "3100",
            "xver": 2
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "tlsSettings": {
          "certificates": [
            {
              "ocspStapling": 3600,
              "certificateFile": "/usr/local/etc/xray/fullchain.cer",
              "keyFile": "/usr/local/etc/xray/private.key"
            }
          ],
          "minVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "tcp",
        "security": "tls"
      },
      "tag": "in-01"
    },
# TROJAN TCP TLS
    {
      "listen": "127.0.0.1",
      "port": 4443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ],
        "fallbacks": [
          {
            "dest": "8443",
            "xver": 2
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "tcpSettings": {
          "acceptProxyProtocol": true
        },
        "network": "tcp",
        "security": "none"
      },
      "tag": "in-02"
    },
# VLESS WS
    {
      "listen": "@vless-ws",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-03"
    },
# VMESS WS
    {
      "listen": "@vmess-ws",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "general@vmess-ws", 
            "id": "$uuid"
#vmess
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-04"
    },
# TROJAN WS
    {
      "listen": "@trojan-ws",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-05"
    },
# SS WS
    {
      "listen": "127.0.0.1",
      "port": 1000,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-256-gcm",
              "password": "$pwss"
#ss
            }
          ],
        "network": "tcp,udp"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-06"
    },
# SS2022 WS
    {
      "listen": "127.0.0.1",
      "port": 1100,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-256-gcm",
        "password": "$(cat /usr/local/etc/xray/serverpsk)",
        "clients": [
          {
            "password": "$userpsk"
#ss22
          }
        ],
        "network": "tcp,udp"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss22-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-07"
    },
# VLESS HTTPupgrade
    {
      "listen": "@vl-hup",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-08"
    },
# VMESS HTTPupgrade
    {
      "listen": "@vm-hup",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vmess
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-09"
    },
# TROJAN HTTPupgrade
    {
      "listen": "@tr-hup",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-10"
    },
# SS HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": "3000",
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-256-gcm",
              "password": "$pwss"
#ss
            }
          ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-11"
    },
# SS2022 HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": "3100",
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-256-gcm",
        "password": "$(cat /usr/local/etc/xray/serverpsk)",
        "clients": [
          {
            "password": "$userpsk"
#ss22
          }
        ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss22-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-12"
    },
# VLESS gRPC
    {
      "listen": "127.0.0.1",
      "port": 5000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email": "grpc",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "vless-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-13"
    },
# VMESS gRPC
    {
      "listen": "127.0.0.1",
      "port": 5100,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "grpc",
            "id": "$uuid"
#vmess
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "vmess-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-14"
    },
# TROJAN gRPC
    {
      "listen": "127.0.0.1",
      "port": 5200,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "email": "grpc",
            "password": "$pwtr"
#trojan
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "trojan-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-15"
    },
# SS gRPC
    {
      "listen": "127.0.0.1",
      "port": 5300,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-256-gcm",
              "password": "$pwss"
#ss
            }
          ],
        "network": "tcp,udp"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "ss-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-16"
    },
# SS2022 gRPC
    {
      "listen": "127.0.0.1",
      "port": 5400,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-256-gcm",
        "password": "$(cat /usr/local/etc/xray/serverpsk)",
        "clients": [
          {
            "password": "$userpsk"
#ss22
          }
        ],
        "network": "tcp,udp"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "ss22-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-17"
    },
    {
      "port": 80,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid"
#universal
          }
        ],
        "fallbacks": [
          {
            "dest": 8080,
            "xver": 2
          },
          // Websocket
          {
            "path": "/vless-ws",
            "dest": "@vless-ws",
            "xver": 2
          },
          {
            "path": "/vmess-ws",
            "dest": "@vmess-ws",
            "xver": 2
          },
          {
            "path": "/trojan-ws",
            "dest": "@trojan",
            "xver": 2
          },
          {
            "dest": 2000,
            "xver": 2
          },
          {
            "dest": 2100,
            "xver": 2
          },
          // HTTPupgrade
          {
            "path": "/vless-hup",
            "dest": "@vl-hup",
            "xver": 2
          },
          {
            "path": "/vmess-hup",
            "dest": "@vm-hup",
            "xver": 2
          },
          {
            "path": "/trojan-hup",
            "dest": "@trojan-hup",
            "xver": 2
          },
          {
            "path": "/ss-hup",
            "dest": "4000",
            "xver": 2
          },
          {
            "path": "/ss22-hup",
            "dest": "4100",
            "xver": 2
          }
        ],
        "decryption": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-18"
    },
# TROJAN WS
    {
      "listen": "@trojan",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-19"
    },
# SS WS
    {
      "listen": "127.0.0.1",
      "port": 2000,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-256-gcm",
              "password": "$pwss"
#ss
            }
          ],
        "network": "tcp,udp"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-20"
    },
# SS2022 WS
    {
      "listen": "127.0.0.1",
      "port": 2100,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-256-gcm",
        "password": "$(cat /usr/local/etc/xray/serverpsk)",
        "clients": [
          {
            "password": "$userpsk"
#ss22
          }
        ],
        "network": "tcp,udp"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss22-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-21"
    },
# TROJAN HTTPupgrade
    {
      "listen": "@trojan-hup",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-22"
    },
# SS HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": 4000,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-256-gcm",
              "password": "$pwss"
#ss
            }
          ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-23"
    },
# SS2022 HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": "4100",
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-256-gcm",
        "password": "$(cat /usr/local/etc/xray/serverpsk)",
        "clients": [
          {
            "password": "$userpsk"
#ss22
          }
        ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/ss22-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-24"
    }
  ]
}
END
wget -q -O /usr/local/etc/xray/config/05_outbonds.json "https://${XRAY_CONFIG}/05_outbonds.json"
wget -q -O /usr/local/etc/xray/config/06_routing.json "https://${XRAY_CONFIG}/06_routing.json"
wget -q -O /usr/local/etc/xray/config/07_stats.json "https://${XRAY_CONFIG}/07_stats.json"
sleep 1.5

# Membuat file log Xray yang diperlukan
print_msg $YB "Membuat file log Xray yang diperlukan..."
sudo touch /var/log/xray/access.log /var/log/xray/error.log
sudo chown nobody:nogroup /var/log/xray/access.log /var/log/xray/error.log
sudo chmod 644 /var/log/xray/access.log /var/log/xray/error.log
check_success "Gagal membuat file log Xray yang diperlukan."
sleep 1.5

# Konfigurasi Nginx
print_msg $YB "Mengonfigurasi Nginx..."
cat > /etc/nginx/nginx.conf << END
# Generated by nginxconfig.io
user www-data;
pid /run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
   multi_accept on;
   worker_connections 65535;
}

http {
   charset utf-8;
   sendfile on;
   tcp_nopush on;
   tcp_nodelay on;
   server_tokens off;
   types_hash_max_size 2048;
   server_names_hash_bucket_size 128;
   server_names_hash_max_size 512;
   client_max_body_size 16M;

   # logging
   access_log /var/log/nginx/access.log;
   error_log /var/log/nginx/error.log warn;

   # Compression
   gzip on;
   gzip_comp_level 5;
   gzip_min_length 256;
   gzip_proxied any;
   gzip_types application/javascript application/json application/xml text/css text/plain text/xml application/xml+rss application/grpc+proto;

   include /etc/nginx/conf.d/*.conf;
   include /etc/nginx/sites-enabled/*;

   upstream vless_grpc {
       server 127.0.0.1:5000;
   }
   upstream vmess_grpc {
       server 127.0.0.1:5100;
   }
   upstream trojan_grpc {
       server 127.0.0.1:5200;
   }
   upstream ss_grpc {
       server 127.0.0.1:5300;
   }
   upstream ss22_grpc {
       server 127.0.0.1:5400;
   }
   server {
       listen 8443 http2 proxy_protocol;
       set_real_ip_from 127.0.0.1;
       real_ip_header proxy_protocol;
       root /var/www/html;
       index index.html index.htm;
   }
   server {
       listen 8080 proxy_protocol default_server;
       listen 8443 http2 proxy_protocol default_server;
       set_real_ip_from 127.0.0.1;
       real_ip_header proxy_protocol;
       server_name $domain;
       root /var/www/html;

       location /vless-grpc {
          grpc_pass grpc://vless_grpc;
       }
       location /vmess-grpc {
          grpc_pass grpc://vmess_grpc;
       }
       location /trojan-grpc {
          grpc_pass grpc://trojan_grpc;
       }
       location /ss-grpc {
          grpc_pass grpc://ss_grpc;
       }
       location /ss22-grpc {
          grpc_pass grpc://ss22_grpc;
       }
   }
}
END
wget -q -O /var/www/html/index.html https://raw.githubusercontent.com/dugong-lewat/1clickxray/main/index.html
# Jika sampai di sini tidak ada error, maka konfigurasi berhasil
print_msg $GB "Konfigurasi Xray-core dan Nginx berhasil."
sleep 3

systemctl restart nginx
systemctl restart xray
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Done${NC}"
sleep 3
clear
# Blokir lalu lintas torrent (BitTorrent)
sudo iptables -A INPUT -p udp --dport 6881:6889 -j DROP
sudo iptables -A INPUT -p tcp --dport 6881:6889 -j DROP
# Blokir lalu lintas torrent dengan modul string
sudo iptables -A INPUT -p tcp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
sudo iptables -A INPUT -p udp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
cd /usr/bin
GITHUB=raw.githubusercontent.com/dugong-lewat/1clickxray/main/testing
echo -e "${GB}[ INFO ]${NC} ${YB}Mengunduh menu utama...${NC}"
wget -q -O menu "https://${GITHUB}/menu/menu.sh"
wget -q -O allxray "https://${GITHUB}/menu/allxray.sh"
wget -q -O del-xray "https://${GITHUB}/xray/del-xray.sh"
wget -q -O extend-xray "https://${GITHUB}/xray/extend-xray.sh"
wget -q -O create-xray "https://${GITHUB}/xray/create-xray.sh"
wget -q -O cek-xray "https://${GITHUB}/xray/cek-xray.sh"
sleep 0.5

echo -e "${GB}[ INFO ]${NC} ${YB}Mengunduh menu lainnya...${NC}"
wget -q -O xp "https://${GITHUB}/other/xp.sh"
wget -q -O dns "https://${GITHUB}/other/dns.sh"
wget -q -O certxray "https://${GITHUB}/other/certxray.sh"
wget -q -O about "https://${GITHUB}/other/about.sh"
wget -q -O clear-log "https://${GITHUB}/other/clear-log.sh"
wget -q -O log-xray "https://${GITHUB}/other/log-xray.sh"
wget -q -O update-xray "https://${GITHUB}/other/update-xray.sh"

echo -e "${GB}[ INFO ]${NC} ${YB}Memberikan izin eksekusi pada skrip...${NC}"
chmod +x del-xray extend-xray create-xray cek-xray log-xray menu allxray xp dns certxray about clear-log update-xray
echo -e "${GB}[ INFO ]${NC} ${YB}Persiapan Selesai.${NC}"
sleep 3
cd
echo "0 0 * * * root xp" >> /etc/crontab
echo "*/3 * * * * root clear-log" >> /etc/crontab
systemctl restart cron
clear
echo ""
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "                  ${WB}XRAY SCRIPT BY DUGONG${NC}"
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "                 ${WB}»»» Protocol Service «««${NC}  "
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "${YB}Vmess Websocket${NC}     : ${YB}443 & 80${NC}"
echo -e "${YB}Vmess HTTPupgrade${NC}   : ${YB}443 & 80${NC}"
echo -e "${YB}Vmess gRPC${NC}          : ${YB}443${NC}"
echo ""
echo -e "${YB}Vless XTLS-Vision${NC}   : ${YB}443${NC}"
echo -e "${YB}Vless Websocket${NC}     : ${YB}443 & 80${NC}"
echo -e "${YB}Vless HTTPupgrade${NC}   : ${YB}443 & 80${NC}"
echo -e "${YB}Vless gRPC${NC}          : ${YB}443${NC}"
echo ""
echo -e "${YB}Trojan TCP TLS${NC}      : ${YB}443${NC}"
echo -e "${YB}Trojan Websocket${NC}    : ${YB}443 & 80${NC}"
echo -e "${YB}Trojan HTTPupgrade${NC}  : ${YB}443 & 80${NC}"
echo -e "${YB}Trojan gRPC${NC}         : ${YB}443${NC}"
echo ""
echo -e "${YB}SS Websocket${NC}        : ${YB}443 & 80${NC}"
echo -e "${YB}SS HTTPupgrade${NC}      : ${YB}443 & 80${NC}"
echo -e "${YB}SS gRPC${NC}             : ${YB}443${NC}"
echo ""
echo -e "${YB}SS 2022 Websocket${NC}   : ${YB}443 & 80${NC}"
echo -e "${YB}SS 2022 HTTPupgrade${NC} : ${YB}443 & 80${NC}"
echo -e "${YB}SS 2022 gRPC${NC}        : ${YB}443${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo ""
rm -f install_test.sh
secs_to_human "$(($(date +%s) - ${start}))"
echo -e "${YB}[ WARNING ] reboot now ? (Y/N)${NC} "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi