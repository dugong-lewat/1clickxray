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
mkdir /user >> /dev/null 2>&1
mkdir /tmp >> /dev/null 2>&1
rm /usr/local/etc/xray/city >> /dev/null 2>&1
rm /usr/local/etc/xray/org >> /dev/null 2>&1
rm /usr/local/etc/xray/timezone >> /dev/null 2>&1
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --beta
curl -s ipinfo.io/city >> /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /usr/local/etc/xray/org
curl -s ipinfo.io/timezone >> /usr/local/etc/xray/timezone
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
clear
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
apt install nginx -y
rm -rf /var/www/html/* >> /dev/null 2>&1
rm /etc/nginx/sites-enabled/default >> /dev/null 2>&1
rm /etc/nginx/sites-available/default >> /dev/null 2>&1
mkdir -p /var/www/html/xray >> /dev/null 2>&1
systemctl restart nginx
clear
touch /usr/local/etc/xray/domain
echo -e "${YB}Input Domain${NC} "
echo " "
read -rp "Input domain kamu : " -e dns
if [ -z $dns ]; then
echo -e "Nothing input for domain!"
else
echo "$dns" > /usr/local/etc/xray/domain
echo "DNS=$dns" > /var/lib/dnsvps.conf
fi
clear
systemctl stop nginx
systemctl stop xray
domain=$(cat /usr/local/etc/xray/domain)
curl https://get.acme.sh | sh
source ~/.bashrc
bash .acme.sh/acme.sh  --register-account  -m $(echo $RANDOM | md5sum | head -c 6; echo;)@gmail.com --server zerossl
bash .acme.sh/acme.sh --issue -d $domain --server zerossl --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --standalone --force --dnssleep
chmod 745 /usr/local/etc/xray/private.key
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Nginx & Xray Conf${NC}"
uuid=$(cat /proc/sys/kernel/random/uuid)
pwtr=$(openssl rand -hex 4)
pwss=$(echo $RANDOM | md5sum | head -c 6; echo;)
userpsk=$(openssl rand -base64 16)
serverpsk=$(openssl rand -base64 16)
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
# VLESS HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": 1000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email": "httpupgrade",
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
        "httpupgradeSettings": {
          "path": "/vless-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      }
    },
# VMESS HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": 1100,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "httpupgrade",
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
        "httpupgradeSettings": {
          "path": "/vmess-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      }
    },
# TROJAN HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": 1200,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "email": "httpupgrade",
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
        "httpupgradeSettings": {
          "path": "/trojan-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      }
    },
# Shadowsocks HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": "1300",
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-128-gcm",
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
        "httpupgradeSettings": {
          "path": "/ss-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      }
    },
# Shadowsocks 2022 HTTPupgrade
    {
      "listen": "127.0.0.1",
      "port": "1400",
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
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
        "httpupgradeSettings": {
          "path": "/ss22-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      }
    },
# VLESS Websocket
    {
      "listen": "127.0.0.1",
      "port": 2000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email": "websocket",
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
        "wsSettings": {
          "path": "/vless-ws"
        },
        "network": "ws",
        "security": "none"
      }
    },
# VMESS Websocket
    {
      "listen": "127.0.0.1",
      "port": 2100,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "websocket",
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
        "wsSettings": {
          "path": "/vmess-ws"
        },
        "network": "ws",
        "security": "none"
      }
    },
# TROJAN Websocket
    {
      "listen": "127.0.0.1",
      "port": 2200,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "email": "websocket",
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
        "wsSettings": {
          "path": "/trojan-ws"
        },
        "network": "ws",
        "security": "none"
      }
    },
# Shadowsocks Websocket
    {
      "listen": "127.0.0.1",
      "port": "2300",
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-128-gcm",
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
          "path": "/ss-ws"
        },
        "network": "ws",
        "security": "none"
      }
    },
# Shadowsocks 2022 Websocket
    {
      "listen": "127.0.0.1",
      "port": "2400",
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
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
          "path": "/ss22-ws"
        },
        "network": "ws",
        "security": "none"
      }
    },
# VLESS gRPC
    {
      "listen": "127.0.0.1",
      "port": 3000,
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
          "serviceName": "vless-grpc"
        },
        "network": "grpc",
        "security": "none"
      }
    },
# VMESS gRPC
    {
      "listen": "127.0.0.1",
      "port": 3100,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "websocket",
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
          "serviceName": "vmess-grpc"
        },
        "network": "grpc",
        "security": "none"
      }
    },
# TROJAN gRPC
    {
      "listen": "127.0.0.1",
      "port": 3200,
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
          "serviceName": "trojan-grpc"
        },
        "network": "grpc",
        "security": "none"
      }
    },
# Shadowsocks gRPC
    {
      "listen": "127.0.0.1",
      "port": "3300",
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
            {
              "method": "aes-128-gcm",
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
          "serviceName": "ss-grpc"
        },
        "network": "grpc",
        "security": "none"
      }
    },
# Shadowsocks 2022 gRPC
    {
      "listen": "127.0.0.1",
      "port": "3400",
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
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
          "serviceName": "ss22-grpc"
        },
        "network": "grpc",
        "security": "none"
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
          "allowInsecure": false,
          "alpn": [],
          "fingerprint": "",
          "serverName": "sg.vless.sbs"
        },
        "wsSettings": {
          "headers": {
            "Host": "sg.vless.sbs"
          },
          "host": "sg.vless.sbs",
          "path": "/vless"
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
wget -q -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/dugong-lewat/1clickxray/main/nginx.conf
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
echo -e "  ${YB}- Vmess WS TLS${NC}         : ${YB}443${NC}"
echo -e "  ${YB}- Vmess WS nTLS${NC}        : ${YB}80${NC}"
echo -e "  ${YB}- Vmess HTTPupgrade${NC}    : ${YB}443${NC}"
echo -e "  ${YB}- Vless XTLS Vision${NC}    : ${YB}443${NC}"
echo -e "  ${YB}- Vless WS TLS${NC}         : ${YB}443${NC}"
echo -e "  ${YB}- Vless WS nTLS${NC}        : ${YB}80${NC}"
echo -e "  ${YB}- Vless HTTPupgrade${NC}    : ${YB}443${NC}"
echo -e "  ${YB}- Trojan TCP TLS${NC}       : ${YB}443${NC}"
echo -e "  ${YB}- Trojan WS TLS${NC}        : ${YB}443${NC}"
echo -e "  ${YB}- Trojan WS nTLS${NC}       : ${YB}80${NC}"
echo -e "  ${YB}- Trojan HTTPupgrade${NC}   : ${YB}443${NC}"
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
