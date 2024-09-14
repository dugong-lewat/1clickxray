#!/bin/bash

# Definisi Warna
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[36;1m'
WB='\e[37;1m'

# Fungsi untuk menghasilkan string acak
generate_random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$1" | head -n 1
}

# Fungsi untuk menghasilkan UUID
generate_uuid() {
    cat /proc/sys/kernel/random/uuid
}

# Fungsi untuk menambahkan konfigurasi ke file Xray
add_xray_config() {
    local section=$1
    local content=$2
    sed -i "/#$section\$/a\\#&@ $user $exp\n$content" /usr/local/etc/xray/config/04_inbounds.json
}

# Inisialisasi Variabel
user=$(generate_random_string 7)
domain=$(cat /usr/local/etc/xray/dns/domain)
cipher="aes-256-gcm"
cipher2="2022-blake3-aes-256-gcm"
uuid=$(generate_uuid)
pwtr=$(openssl rand -hex 4)
pwss=$(echo $RANDOM | md5sum | head -c 6)
userpsk=$(openssl rand -base64 32)
serverpsk=$(cat /usr/local/etc/xray/serverpsk)

echo -e "${BB}————————————————————————————————————————————————————————${NC}"

valid_input=false

while [ "$valid_input" = false ]; do
    read -p "Active Period / Masa Aktif (days): " masaaktif

    # Cek apakah input hanya berisi angka
    if [[ "$masaaktif" =~ ^[0-9]+$ ]]; then
        valid_input=true
    else
        echo -e "${RB}Input harus berupa angka. Silakan coba lagi.${NC}"
    fi
done

echo -e "${BB}————————————————————————————————————————————————————————${NC}"
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Menambahkan Konfigurasi ke File Xray
add_xray_config "xtls" "},{\"flow\": \"xtls-rprx-vision\",\"id\": \"$uuid\",\"email\": \"$user\""
add_xray_config "vless" "},{\"id\": \"$uuid\",\"email\": \"$user\""
add_xray_config "universal" "},{\"id\": \"$uuid\",\"email\": \"$user\""
add_xray_config "vmess" "},{\"id\": \"$uuid\",\"email\": \"$user\""
add_xray_config "trojan" "},{\"password\": \"$pwtr\",\"email\": \"$user\""
add_xray_config "ss" "},{\"password\": \"$pwss\",\"method\": \"$cipher\",\"email\": \"$user\""
add_xray_config "ss22" "},{\"password\": \"$userpsk\",\"email\": \"$user\""

ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
REG=$(cat /usr/local/etc/xray/region)

# Fungsi untuk membuat tautan Vmess
create_vmess_link() {
    local version="2"
    local ps=$1
    local port=$2
    local net=$3
    local path=$4
    local tls=$5
    cat <<EOF | base64 -w 0
{
"v": "$version",
"ps": "$ps",
"add": "$domain",
"port": "$port",
"id": "$uuid",
"aid": "0",
"net": "$net",
"path": "$path",
"type": "none",
"host": "$domain",
"tls": "$tls"
}
EOF
}

# Membuat Tautan Vmess
vmesslink1="vmess://$(create_vmess_link "vmess-ws-tls" "443" "ws" "/vmess-ws" "tls")"
vmesslink2="vmess://$(create_vmess_link "vmess-ws-ntls" "80" "ws" "/vmess-ws" "none")"
vmesslink3="vmess://$(create_vmess_link "vmess-hup-tls" "443" "httpupgrade" "/vmess-hup" "tls")"
vmesslink4="vmess://$(create_vmess_link "vmess-hup-ntls" "80" "httpupgrade" "/vmess-hup" "none")"
vmesslink5="vmess://$(create_vmess_link "vmess-grpc" "443" "grpc" "vmess-grpc" "tls")"

# Membuat Tautan Vless
vlesslink1="vless://$uuid@$domain:443?path=/vless-ws&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#vless-ws-tls"
vlesslink2="vless://$uuid@$domain:80?path=/vless-ws&security=none&encryption=none&host=$domain&type=ws#vless-ws-ntls"
vlesslink3="vless://$uuid@$domain:443?path=/vless-hup&security=tls&encryption=none&host=$domain&type=httpupgrade&sni=$domain#vless-hup-tls"
vlesslink4="vless://$uuid@$domain:80?path=/vless-hup&security=none&encryption=none&host=$domain&type=httpupgrade#vless-hup-ntls"
vlesslink5="vless://$uuid@$domain:443?security=tls&encryption=none&headerType=gun&type=grpc&serviceName=vless-grpc&sni=$domain#vless-grpc"
vlesslink6="vless://$uuid@$domain:443?security=tls&encryption=none&headerType=none&type=tcp&sni=$domain&flow=xtls-rprx-vision#vless-vision"

# Membuat Tautan Trojan
trojanlink1="trojan://$pwtr@$domain:443?path=/trojan-ws&security=tls&host=$domain&type=ws&sni=$domain#trojan-ws-tls"
trojanlink2="trojan://$pwtr@$domain:80?path=/trojan-ws&security=none&host=$domain&type=ws#trojan-ws-ntls"
trojanlink3="trojan://$pwtr@$domain:443?path=/trojan-hup&security=tls&host=$domain&type=httpupgrade&sni=$domain#trojan-hup-tls"
trojanlink4="trojan://$pwtr@$domain:80?path=/trojan-hup&security=none&host=$domain&type=httpupgrade#trojan-hup-ntls"
trojanlink5="trojan://$pwtr@$domain:443?security=tls&type=grpc&mode=multi&serviceName=trojan-grpc&sni=$domain#trojan-grpc"
trojanlink6="trojan://$pwtr@$domain:443?security=tls&type=tcp&sni=$domain#trojan-tcp-tls"

# Membuat Tautan Shadowsocks
encode_ss() {
    echo -n "$1:$2" | base64 -w 0
}

ss_base64=$(encode_ss "$cipher" "$pwss")
sslink1="ss://${ss_base64}@$domain:443?path=/ss-ws&security=tls&host=${domain}&type=ws&sni=${domain}#ss-ws-tls"
sslink2="ss://${ss_base64}@$domain:80?path=/ss-ws&security=none&host=${domain}&type=ws#ss-ws-ntls"
sslink3="ss://${ss_base64}@$domain:443?path=/ss-hup&security=tls&host=${domain}&type=httpupgrade&sni=${domain}#ss-hup-tls"
sslink4="ss://${ss_base64}@$domain:80?path=/ss-hup&security=none&host=${domain}&type=httpupgrade#ss-hup-ntls"
sslink5="ss://${ss_base64}@$domain:443?security=tls&encryption=none&type=grpc&serviceName=ss-grpc&sni=$domain#ss-grpc"

ss2022_base64=$(encode_ss "$cipher2" "$serverpsk:$userpsk")
ss22link1="ss://${ss2022_base64}@$domain:443?path=/ss22-ws&security=tls&host=${domain}&type=ws&sni=${domain}#ss2022-ws-tls"
ss22link2="ss://${ss2022_base64}@$domain:80?path=/ss22-ws&security=none&host=${domain}&type=ws#ss2022-ws-ntls"
ss22link3="ss://${ss2022_base64}@$domain:443?path=/ss22-hup&security=tls&host=${domain}&type=httpupgrade&sni=${domain}#ss2022-hup-tls"
ss22link4="ss://${ss2022_base64}@$domain:80?path=/ss22-hup&security=none&host=${domain}&type=httpupgrade#ss2022-hup-ntls"
ss22link5="ss://${ss2022_base64}@$domain:443?security=tls&encryption=none&type=grpc&serviceName=ss22-grpc&sni=$domain#ss2022-grpc"

# Menulis Log ke File
cat > /var/www/html/xray/xray-$user.html << END
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xray VPN</title>
    <link href="https://fonts.googleapis.com/css2?family=Google+Sans&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body {
            font-family: 'Google Sans', sans-serif;
            background-color: #f4f4f9;
            color: #333;
            margin: 0;
            padding: 20px;
        }
        header, footer {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            text-align: center;
        }
        h2 {
            color: #4CAF50;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
            margin-bottom: 20px;
            font-size: 24px;
        }
        pre {
            background-color: #272822;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-family: "Courier New", Courier, monospace;
            margin-bottom: 20px;
            border: 2px solid #4CAF50;
        }
        .section {
            margin-bottom: 40px;
        }
        hr {
            display: none;
            border: none;
            border-top: 2px solid #4CAF50;
            margin: 40px 0;
        }
        .link-section {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .link-box {
            flex: 1;
            min-width: 300px;
            max-width: 100%;
            padding: 15px;
            border: 2px solid #4CAF50;
            border-radius: 5px;
            background-color: #f9f9f9;
            margin-bottom: 20px;
            box-sizing: border-box;
        }
        button, .copy-button {
            display: inline-block;
            padding: 10px 15px;
            border: none;
            background-color: #4CAF50;
            color: white;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px 0;
        }
        .notification {
            display: none;
            position: fixed;
            top: 20px;
            right: 20px;
            background-color: #363ddf;
            color: white;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
            z-index: 1000;
        }
        footer {
            font-size: 14px;
        }
        .accordion-content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.5s ease-out;
        }
        .accordion-content.show {
            max-height: 1000px; /* Adjust based on content size or use a large value */
        }
        @media (prefers-color-scheme: dark) {
            body {
                background-color: #121212;
                color: #e0e0e0;
            }
            header, footer {
                background-color: #4CAF50;
                color: white;
            }
            .link-box {
                background-color: #333;
                border-color: #4CAF50;
            }
            pre {
                background-color: #1e1e1e;
                border-color: #4CAF50;
            }
            button, .copy-button {
                background-color: #4CAF50;
                color: white;
            }
        }
        @media (max-width: 768px) {
            h2 {
                font-size: 20px;
            }
            .link-box {
                min-width: 100%;
            }
        }
    </style>
</head>
<body>

    <header>
        <h1>Xray VPN</h1>
    </header>

    <div class="section">
        <h2><i class="fas fa-server"></i> Server Information</h2>
        <pre>ISP            : ${ISP}
Region         : ${REG}
City           : ${CITY}
Port TLS/HTTPS : 443
Port HTTP      : 80
Transport      : XTLS-Vision, TCP TLS, HTTPupgrade, Websocket, gRPC
Expired On     : ${exp}</pre>
    </div>

    <hr>

    <!-- Vmess Links -->
    <div class="section">
        <h2 onclick="toggleAccordion(this)"><i class="fas fa-link"></i> Vmess Links</h2>
        <div class="accordion-content">
            <div class="link-section">
                <div class="link-box">
                    <h3>Websocket TLS</h3>
                    <pre id="vmess-ws-tls">${vmesslink1}</pre>
                    <button onclick="copyToClipboard('vmess-ws-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>Websocket non TLS</h3>
                    <pre id="vmess-ws-ntls">${vmesslink2}</pre>
                    <button onclick="copyToClipboard('vmess-ws-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade TLS</h3>
                    <pre id="vmess-hup-tls">${vmesslink3}</pre>
                    <button onclick="copyToClipboard('vmess-hup-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade non TLS</h3>
                    <pre id="vmess-hup-ntls">${vmesslink4}</pre>
                    <button onclick="copyToClipboard('vmess-hup-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>gRPC</h3>
                    <pre id="vmess-grpc">${vmesslink5}</pre>
                    <button onclick="copyToClipboard('vmess-grpc')">Copy</button>
                </div>
            </div>
        </div>
    </div>

    <hr>

    <!-- Vless Links -->
    <div class="section">
        <h2 onclick="toggleAccordion(this)"><i class="fas fa-link"></i> Vless Links</h2>
        <div class="accordion-content">
            <div class="link-section">
                <div class="link-box">
                    <h3>Websocket TLS</h3>
                    <pre id="vless-ws-tls">${vlesslink1}</pre>
                    <button onclick="copyToClipboard('vless-ws-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>Websocket non TLS</h3>
                    <pre id="vless-ws-ntls">${vlesslink2}</pre>
                    <button onclick="copyToClipboard('vless-ws-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade TLS</h3>
                    <pre id="vless-hup-ntls">${vlesslink3}</pre>
                    <button onclick="copyToClipboard('vless-hup-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade non TLS</h3>
                    <pre id="vless-hup-ntls">${vlesslink4}</pre>
                    <button onclick="copyToClipboard('vless-hup-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>XTLS-RPRX-VISION</h3>
                    <pre id="vless-vision">${vlesslink5}</pre>
                    <button onclick="copyToClipboard('vless-vision')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>gRPC</h3>
                    <pre id="vless-grpc">${vlesslink6}</pre>
                    <button onclick="copyToClipboard('vless-grpc')">Copy</button>
                </div>
            </div>
        </div>
    </div>

    <hr>

    <!-- Trojan Links -->
    <div class="section">
        <h2 onclick="toggleAccordion(this)"><i class="fas fa-link"></i> Trojan Links</h2>
        <div class="accordion-content">
            <div class="link-section">
                <div class="link-box">
                    <h3>Websocket TLS</h3>
                    <pre id="trojan-ws-tls">${trojanlink1}</pre>
                    <button onclick="copyToClipboard('trojan-ws-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>Websocket non TLS</h3>
                    <pre id="trojan-ws-ntls">${trojanlink2}</pre>
                    <button onclick="copyToClipboard('trojan-ws-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade TLS</h3>
                    <pre id="trojan-hup-tls">${trojanlink3}</pre>
                    <button onclick="copyToClipboard('trojan-hup-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade non TLS</h3>
                    <pre id="trojan-hup-ntls">${trojanlink4}</pre>
                    <button onclick="copyToClipboard('trojan-hup-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>TCP TLS</h3>
                    <pre id="trojan-tcp">${trojanlink5}</pre>
                    <button onclick="copyToClipboard('trojan-tcp')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>gRPC</h3>
                    <pre id="trojan-grpc">${trojanlink6}</pre>
                    <button onclick="copyToClipboard('trojan-grpc')">Copy</button>
                </div>
            </div>
        </div>
    </div>

    <hr>

    <!-- Shadowsocks Links -->
    <div class="section">
        <h2 onclick="toggleAccordion(this)"><i class="fas fa-link"></i> Shadowsocks Links</h2>
        <div class="accordion-content">
            <div class="link-section">
                <div class="link-box">
                    <h3>Websocket TLS</h3>
                    <pre id="ss-ws-tls">${sslink1}</pre>
                    <button onclick="copyToClipboard('ss-ws-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>Websocket non TLS</h3>
                    <pre id="ss-ws-ntls">${sslink2}</pre>
                    <button onclick="copyToClipboard('ss-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade TLS</h3>
                    <pre id="ss-hup-tls">${sslink3}</pre>
                    <button onclick="copyToClipboard('ss-hup-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade non TLS</h3>
                    <pre id="ss-hup-ntls">${sslink4}</pre>
                    <button onclick="copyToClipboard('ss-hup-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>gRPC</h3>
                    <pre id="ss-grpc">${sslink5}</pre>
                    <button onclick="copyToClipboard('ss-grpc')">Copy</button>
                </div>
            </div>
        </div>
    </div>

    <hr>

    <!-- Shadowsocks 2022 Links -->
    <div class="section">
        <h2 onclick="toggleAccordion(this)"><i class="fas fa-link"></i> Shadowsocks 2022 Links</h2>
        <div class="accordion-content">
            <div class="link-section">
                <div class="link-box">
                    <h3>Websocket TLS</h3>
                    <pre id="ss2022-ws-tls">${ss22link1}</pre>
                    <button onclick="copyToClipboard('ss2022-ws-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>Websocket non TLS</h3>
                    <pre id="ss2022-ws-ntls">${ss22link2}</pre>
                    <button onclick="copyToClipboard('ss2022-ws-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade TLS</h3>
                    <pre id="ss2022-hup-tls">${ss22link3}</pre>
                    <button onclick="copyToClipboard('ss2022-hup-tls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>HTTPupgrade non TLS</h3>
                    <pre id="ss2022-hup-ntls">${ss22link4}</pre>
                    <button onclick="copyToClipboard('ss2022-hup-ntls')">Copy</button>
                </div>
                <div class="link-box">
                    <h3>gRPC</h3>
                    <pre id="ss2022-grpc">${ss22link5}</pre>
                    <button onclick="copyToClipboard('ss2022-grpc')">Copy</button>
                </div>
            </div>
        </div>
    </div>

    <div class="notification" id="notification">Copied to clipboard!</div>

    <footer>
        <p>Xray VPN Page &copy; 2024</p>
    </footer>

    <script>
        function copyToClipboard(elementId) {
            var codeElement = document.getElementById(elementId);
            var range = document.createRange();
            range.selectNodeContents(codeElement);
            var selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
            try {
                document.execCommand('copy');
                showNotification();
            } catch (err) {
                console.error('Failed to copy text: ', err);
            }
        }

        function showNotification() {
            var notification = document.getElementById('notification');
            notification.style.display = 'block';
            setTimeout(function() {
                notification.style.display = 'none';
            }, 2000);
        }

        function toggleAccordion(element) {
            var content = element.nextElementSibling;
            if (content.classList.contains('show')) {
                content.classList.remove('show');
                content.style.maxHeight = null; // Reset max-height
            } else {
                var allContents = document.querySelectorAll('.accordion-content');
                allContents.forEach(function(c) {
                    c.classList.remove('show');
                    c.style.maxHeight = null; // Reset max-height for all other contents
                });
                content.classList.add('show');
                content.style.maxHeight = content.scrollHeight + 'px'; // Set max-height to scrollHeight
            }
        }
    </script>
</body>
</html>
END

# Restart Xray Service
systemctl restart xray

# Clear Screen
clear

# Menampilkan Informasi ke Pengguna
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "              ----- [ All Xray ] -----              " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "ISP            : $ISP" | tee -a /user/xray-$user.log
echo -e "Region         : $REG" | tee -a /user/xray-$user.log
echo -e "City           : $CITY" | tee -a /user/xray-$user.log
echo -e "Port TLS/HTTPS : 443" | tee -a /user/xray-$user.log
echo -e "Port HTTP      : 80" | tee -a /user/xray-$user.log
echo -e "Transport      : XTLS-Vision, TCP TLS, Websocket, HTTPupgrade, gRPC" | tee -a /user/xray-$user.log
echo -e "Expired On     : $exp" | tee -a /user/xray-$user.log
echo -e "Link / Web     : https://$domain/xray/xray-$user.html" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "             ----- [ Vmess Link ] -----             " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS TLS    : $vmesslink1" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS   : $vmesslink2" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS   : $vmesslink3" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS  : $vmesslink4" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link gRPC      : $vmesslink5" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "             ----- [ Vless Link ] -----             " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $vlesslink1" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $vlesslink2" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $vlesslink3" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $vlesslink4" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $vlesslink5" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link XTLS-Vision : $vlesslink6" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "            ----- [ Trojan Link ] -----             " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $trojanlink1" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $trojanlink2" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $trojanlink3" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $trojanlink4" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $trojanlink5" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link TCP TLS     : $trojanlink6" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "          ----- [ Shadowsocks Link ] -----          " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $sslink1" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $sslink2" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $sslink3" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $sslink4" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $sslink5" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "       ----- [ Shadowsocks 2022 Link ] -----        " | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $ss22link1" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $ss22link2" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $ss22link3" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $ss22link4" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $ss22link5" | tee -a /user/xray-$user.log
echo -e "${BB}————————————————————————————————————————————————————${NC}" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log

read -n 1 -s -r -p "Press any key to go back to menu"
clear
allxray
