rm -rf xray
clear
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
secs_to_human() {
echo -e "${WB}Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds${NC}"
}
start=$(date +%s)
apt update -y
apt install socat netfilter-persistent bsdmainutils -y
apt install vnstat lsof fail2ban -y
apt install curl sudo cron -y
apt install build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev gcc clang llvm g++ valgrind make cmake debian-keyring debian-archive-keyring apt-transport-https systemd -y


mkdir /user >> /dev/null 2>&1
mkdir /tmp >> /dev/null 2>&1
rm /usr/local/etc/xray/city >> /dev/null 2>&1
rm /usr/local/etc/xray/org >> /dev/null 2>&1
rm /usr/local/etc/xray/timezone >> /dev/null 2>&1
rm /usr/local/etc/xray/region >> /dev/null 2>&1
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --beta
curl -s ipinfo.io/city >> /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /usr/local/etc/xray/org
curl -s ipinfo.io/timezone >> /usr/local/etc/xray/timezone
curl -s ipinfo.io/region >> /usr/local/etc/xray/region
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
clear


# ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
timedatectl set-timezone Asia/Jakarta


code=$(grep DISTRIB_CODENAME /etc/lsb-release | cut -d '=' -f 2)
cat > /etc/apt/sources.list.d/nginx.list << END
deb http://nginx.org/packages/ubuntu/ $code nginx
deb-src http://nginx.org/packages/ubuntu/ $code nginx
END
wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
rm -rf add nginx_signing.*
apt update
apt install nginx -y
rm -rf /etc/nginx/conf.d/default.conf >> /dev/null 2>&1
rm -rf /var/www/html/* >> /dev/null 2>&1
mkdir -p /var/www/html/xray >> /dev/null 2>&1
clear
systemctl restart nginx
systemctl stop nginx
systemctl stop xray


# Warna untuk output (sesuaikan dengan kebutuhan)
YB='\033[1;33m'  # Yellow Bold
NC='\033[0m'     # No Color
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
# wget -q -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/dugong-lewat/1clickxray/main/nginx.conf
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
