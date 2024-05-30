#!/bin/bash

rm -rf install.sh
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
print_msg $YB "Memasang curl, sudo, dan cron..."
apt install curl sudo cron -y
check_success
sleep 1

# Install paket keempat
print_msg $YB "Memasang build-essential dan dependensi lainnya..."
apt install build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev gcc clang llvm g++ valgrind make cmake debian-keyring debian-archive-keyring apt-transport-https systemd -y
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
sudo mkdir -p /user /tmp /usr/local/etc/xray
check_success "Gagal membuat direktori."

# Menghapus file konfigurasi lama jika ada
print_msg $YB "Menghapus file konfigurasi lama..."
sudo rm -f /usr/local/etc/xray/city /usr/local/etc/xray/org /usr/local/etc/xray/timezone /usr/local/etc/xray/region
check_success "Gagal menghapus file konfigurasi lama."

# Membuat file log Xray yang diperlukan
print_msg $YB "Membuat file log Xray yang diperlukan..."
sudo touch /var/log/xray/access.log
sudo touch /var/log/xray/error.log
check_success "Gagal membuat file log Xray yang diperlukan."

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
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
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
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

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
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" || "$OS" == "CentOS" || "$OS" == "Fedora" || "$OS" == "Red Hat Enterprise Linux" ]]; then
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

curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
# ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
timedatectl set-timezone Asia/Jakarta

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang dan mengkonfigurasi Nginx pada sistem Anda."

# Mendapatkan codename distribusi Ubuntu
print_msg $YB "Mendeteksi codename distribusi Ubuntu..."
code=$(grep DISTRIB_CODENAME /etc/lsb-release | cut -d '=' -f 2)
check_success "Gagal mendeteksi codename distribusi Ubuntu."

# Menambahkan repository Nginx
print_msg $YB "Menambahkan repository Nginx ke sources.list.d..."
cat > /etc/apt/sources.list.d/nginx.list << END
deb http://nginx.org/packages/ubuntu/ $code nginx
deb-src http://nginx.org/packages/ubuntu/ $code nginx
END
check_success "Gagal menambahkan repository Nginx."

# Mendownload kunci signing Nginx
print_msg $YB "Mendownload kunci signing Nginx..."
wget -q http://nginx.org/keys/nginx_signing.key
check_success "Gagal mendownload kunci signing Nginx."

# Menambahkan kunci signing Nginx ke apt
print_msg $YB "Menambahkan kunci signing Nginx ke apt..."
sudo apt-key add nginx_signing.key
check_success "Gagal menambahkan kunci signing Nginx ke apt."

# Membersihkan file kunci yang didownload
rm -rf nginx_signing.*
check_success "Gagal membersihkan file kunci yang didownload."

# Memperbarui daftar paket
print_msg $YB "Memperbarui daftar paket..."
apt update
check_success "Gagal memperbarui daftar paket."

# Menginstall Nginx
print_msg $YB "Menginstall Nginx..."
apt install nginx -y
check_success "Gagal menginstall Nginx."

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
touch /usr/local/etc/xray/domain

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
            echo -e "${YB}Nothing input for domain!${NC}"
        elif ! validate_domain "$dns"; then
            echo -e "${YB}Invalid domain format! Please input a valid domain.${NC}"
        else
            echo "$dns" > /usr/local/etc/xray/domain
            echo "DNS=$dns" > /var/lib/dnsvps.conf
            echo -e "${YB}Domain saved successfully!${NC}"
            break
        fi
    done
}

# Fungsi untuk menginstal acme.sh dan mendapatkan sertifikat
install_acme_sh() {
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh  --register-account  -m $(echo $RANDOM | md5sum | head -c 6; echo;)@gmail.com --server zerossl
    ~/.acme.sh/acme.sh --issue -d "$dns" --server zerossl --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --standalone --reloadcmd "systemctl reload nginx"
    chmod 745 /usr/local/etc/xray/private.key
    echo -e "${YB}Sertifikat SSL berhasil dipasang!${NC}"
}

# Panggil fungsi input_domain untuk memulai proses
input_domain

# Panggil fungsi install_acme_sh untuk menginstal acme.sh dan mendapatkan sertifikat
install_acme_sh
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Nginx & Xray Conf${NC}"
uuid=$(cat /proc/sys/kernel/random/uuid)
pwtr=$(openssl rand -hex 4)
pwss=$(echo $RANDOM | md5sum | head -c 6; echo;)
userpsk=$(openssl rand -base64 32)
serverpsk=$(openssl rand -base64 32)
echo "$serverpsk" > /usr/local/etc/xray/serverpsk
cat > /usr/local/etc/xray/config.json << END
{
  "api": {
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ],
    "tag": "api"
  },
  "dns": {
    "queryStrategy": "UseIP",
    "servers": [
      {
        "address": "localhost",
        "domains": [
          "https://1.1.1.1/dns-query"
        ],
        "queryStrategy": "UseIP"
      }
    ],
    "tag": "dns_inbounds"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 62789,
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
          {"alpn": "h2", "dest": 4443, "xver": 2},
          {"dest": 8080, "xver": 2},
          // Websocket
          {"path": "/vless-ws", "dest": "@vless-ws", "xver": 2},
          {"path": "/vmess-ws", "dest": "@vmess-ws", "xver": 2},
          {"path": "/trojan-ws", "dest": "@trojan-ws", "xver": 2},
          {"path": "/ss-ws", "dest": 1000, "xver": 2},
          {"path": "/ss22-ws", "dest": 1100, "xver": 2},
          // HTTPupgrade
          {"path": "/vless-hup", "dest": "@vl-hup", "xver": 2},
          {"path": "/vmess-hup", "dest": "@vm-hup", "xver": 2},
          {"path": "/trojan-hup", "dest": "@tr-hup", "xver": 2},
          {"path": "/ss-hup", "dest": 3000, "xver": 2},
          {"path": "/ss22-hup", "dest": 3100, "xver": 2}
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
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
      }
    }
  ],
  "log": {
    "access": "/var/log/xray/access.log",
    "dnsLog": false,
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIP"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    },
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "sg.vless.sbs",
            "port": 443,
            "users": [
              {
                "encryption": "none",
                "id": "47f5ab29-37cb-4f1a-8638-765c59774836"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": true,
          "alpn": [],
          "fingerprint": "",
          "serverName": "sg.vless.sbs"
        },
        "wsSettings": {
          "headers": {
            "Host": "sg.vless.sbs"
          },
          "host": "sg.vless.sbs",
          "path": "/vless-ws"
        }
      },
      "tag": "sg.vless.sbs"
    }
  ],
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundDownlink": true,
      "statsInboundUplink": true,
      "statsOutboundDownlink": true,
      "statsOutboundUplink": true
    }
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked",
        "type": "field"
      },
      {
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ],
        "type": "field"
      },
      {
        "domain": [
          "geosite:google"
        ],
        "outboundTag": "sg.vless.sbs",
        "type": "field"
      }
    ]
  },
  "stats": {}
}
END
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
       server_name $dns;
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

systemctl restart nginx
systemctl restart xray
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Done${NC}"
sleep 1
clear
# Blokir lalu lintas torrent (BitTorrent)
sudo iptables -A INPUT -p udp --dport 6881:6889 -j DROP
sudo iptables -A INPUT -p tcp --dport 6881:6889 -j DROP
# Blokir lalu lintas torrent dengan modul string
sudo iptables -A INPUT -p tcp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
sudo iptables -A INPUT -p udp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
cd /usr/bin
GITHUB=raw.githubusercontent.com/dugong-lewat/1clickxray/main
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Main Menu${NC}"
wget -q -O menu "https://${GITHUB}/menu/menu.sh"
wget -q -O allxray "https://${GITHUB}/menu/allxray.sh"
wget -q -O del-xray "https://${GITHUB}/xray/del-xray.sh"
wget -q -O extend-xray "https://${GITHUB}/xray/extend-xray.sh"
wget -q -O create-xray "https://${GITHUB}/xray/create-xray.sh"
wget -q -O cek-xray "https://${GITHUB}/xray/cek-xray.sh"
sleep 0.5

echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Other Menu${NC}"
wget -q -O xp "https://${GITHUB}/other/xp.sh"
wget -q -O dns "https://${GITHUB}/other/dns.sh"
wget -q -O certxray "https://${GITHUB}/other/certxray.sh"
wget -q -O about "https://${GITHUB}/other/about.sh"
wget -q -O clear-log "https://${GITHUB}/other/clear-log.sh"
wget -q -O log-xray "https://${GITHUB}/other/log-xray.sh"
echo -e "${GB}[ INFO ]${NC} ${YB}Download All Menu Done${NC}"
sleep 2
chmod +x del-xray
chmod +x extend-xray
chmod +x create-xray
chmod +x cek-xray
chmod +x log-xray
chmod +x menu
chmod +x allxray
chmod +x xp
chmod +x dns
chmod +x certxray
chmod +x about
chmod +x clear-log
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
rm -f xray
secs_to_human "$(($(date +%s) - ${start}))"
echo -e "${YB}[ WARNING ] reboot now ? (Y/N)${NC} "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi
