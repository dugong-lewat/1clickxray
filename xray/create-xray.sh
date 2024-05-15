NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
user=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1`
domain=$(cat /usr/local/etc/xray/domain)
cipher="aes-256-gcm"
cipher2="2022-blake3-aes-256-gcm"
uuid=$(cat /proc/sys/kernel/random/uuid)
pwtr=$(openssl rand -hex 4)
pwss=$(echo $RANDOM | md5sum | head -c 6; echo;)
userpsk=$(openssl rand -base64 32)
serverpsk=$(cat /usr/local/etc/xray/serverpsk)
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
read -p "Active Period / Masa Aktif (days): " masaaktif
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#xtls$/a\#&@ '"$user $exp"'\
},{"flow": "'""xtls-rprx-vision""'","id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vless$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#universal$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vmess$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#trojan$/a\#&@ '"$user $exp"'\
},{"password": "'""$pwtr""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#ss$/a\#&@ '"$user $exp"'\
},{"password": "'""$pwss""'","method": "'""$cipher""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#ss22$/a\#&@ '"$user $exp"'\
},{"password": "'""$userpsk""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
REG=$(cat /usr/local/etc/xray/region)
vmlink1=`cat<<EOF
{
"v": "2",
"ps": "vmess-ws-tls",
"add": "${domain}",
"port": "443",
"id": "${uuid}",
"aid": "0",
"net": "ws",
"path": "/vmess-ws",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vmlink2=`cat<<EOF
{
"v": "2",
"ps": "vmess-ws-ntls",
"add": "${domain}",
"port": "80",
"id": "${uuid}",
"aid": "0",
"net": "ws",
"path": "/vmess-ws",
"type": "none",
"host": "$domain",
"tls": "none"
}
EOF`
vmlink3=`cat<<EOF
{
"v": "2",
"ps": "vmess-hup-tls",
"add": "${domain}",
"port": "443",
"id": "${uuid}",
"aid": "0",
"net": "httpupgrade",
"path": "/vmess-hup",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vmlink4=`cat<<EOF
{
"v": "2",
"ps": "vmess-hup-ntls",
"add": "${domain}",
"port": "80",
"id": "${uuid}",
"aid": "0",
"net": "httpupgrade",
"path": "/vmess-hup",
"type": "none",
"host": "$domain",
"tls": "none"
}
EOF`
vmlink5=`cat<<EOF
{
"v": "2",
"ps": "vmess-grpc",
"add": "${domain}",
"port": "443",
"id": "${uuid}",
"aid": "0",
"net": "grpc",
"path": "vmess-grpc",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vmesslink1="vmess://$(echo $vmlink1 | base64 -w 0)"
vmesslink2="vmess://$(echo $vmlink2 | base64 -w 0)"
vmesslink3="vmess://$(echo $vmlink3 | base64 -w 0)"
vmesslink4="vmess://$(echo $vmlink4 | base64 -w 0)"
vmesslink5="vmess://$(echo $vmlink5 | base64 -w 0)"

vlesslink1="vless://$uuid@$domain:443?path=/vless-ws&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#vless-ws-tls"
vlesslink2="vless://$uuid@$domain:80?path=/vless-ws&security=none&encryption=none&host=$domain&type=ws#vless-ws-ntls"
vlesslink3="vless://$uuid@$domain:443?path=/vless-hup&security=tls&encryption=none&host=$domain&type=httpupgrade&sni=$domain#vless-hup-tls"
vlesslink4="vless://$uuid@$domain:80?path=/vless-hup&security=none&encryption=none&host=$domain&type=httpupgrade#vless-hup-ntls"
vlesslink5="vless://$uuid@$domain:443?security=tls&encryption=none&headerType=gun&type=grpc&serviceName=vless-grpc&sni=$domain&flow=none#vless-grpc"
vlesslink6="vless://$uuid@$domain:443?security=tls&encryption=none&headerType=none&type=tcp&sni=$domain&flow=xtls-rprx-vision#vless-vision"

trojanlink1="trojan://$pwtr@$domain:443?path=/trojan-ws&security=tls&host=$domain&type=ws&sni=$domain#trojan-ws-tls"
trojanlink2="trojan://$pwtr@$domain:80?path=/trojan-ws&security=none&host=$domain&type=ws#trojan-ws-ntls"
trojanlink3="trojan://$pwtr@$domain:443?path=/trojan-hup&security=tls&host=$domain&type=httpupgrade&sni=$domain#trojan-hup-tls"
trojanlink4="trojan://$pwtr@$domain:80?path=/trojan-hup&security=tls&host=$domain&type=httpupgrade#trojan-hup-ntls"
trojanlink5="trojan://$pwtr@$domain:443?security=tls&type=grpc&mode=multi&serviceName=trojan-grpc&sni=$domain#trojan-grpc"
trojanlink6="trojan://$pwtr@$domain:443?security=tls&type=tcp&sni=$domain#trojan-tcp-tls"

echo -n "$cipher:$pwss" | base64 -w 0 > /tmp/log
ss_base64=$(cat /tmp/log)
sslink1="ss://${ss_base64}@$domain:443?path=/ss-ws&security=tls&host=${domain}&type=ws&sni=${domain}#ss-ws-tls"
sslink2="ss://${ss_base64}@$domain:80?path=/ss-ws&security=none&host=${domain}&type=ws#ss-ws-ntls"
sslink3="ss://${ss_base64}@$domain:443?path=/ss-hup&security=tls&host=${domain}&type=httpupgrade&sni=${domain}#ss-hup-tls"
sslink4="ss://${ss_base64}@$domain:80?path=/ss-hup&security=none&host=${domain}&type=httpupgrade#ss-hup-ntls"
sslink5="ss://${ss_base64}@$domain:443?security=tls&encryption=none&type=grpc&serviceName=ss-grpc&sni=$domain#ss-grpc"
rm -rf /tmp/log

echo -n "$cipher2:$serverpsk:$userpsk" | base64 -w 0 > /tmp/log
ss2022_base64=$(cat /tmp/log)
ss22link1="ss://${ss2022_base64}@$domain:443?path=/ss22-ws&security=tls&host=${domain}&type=ws&sni=${domain}#ss2022-ws-tls"
ss22link2="ss://${ss2022_base64}@$domain:80?path=/ss22-ws&security=none&host=${domain}&type=ws#ss2022-ws-ntls"
ss22link3="ss://${ss2022_base64}@$domain:443?path=/ss22-hup&security=tls&host=${domain}&type=httpupgrade&sni=${domain}#ss2022-hup-tls"
ss22link4="ss://${ss2022_base64}@$domain:80?path=/ss22-hup&security=none&host=${domain}&type=httpupgrade#ss2022-hup-ntls"
ss22link5="ss://${ss2022_base64}@$domain:443?security=tls&encryption=none&type=grpc&serviceName=ss22-grpc&sni=$domain#ss2022-grpc"
rm -rf /tmp/log

cat > /var/www/html/xray/xray-$user.log << END
========================================
        ----- [ All Xray ] -----
========================================
ISP            : $ISP
Region         : $REG
City           : $CITY
Port TLS/HTTPS : 443
Port HTTP      : 80
Transport      : XTLS-Vision, TCP TLS, HTTPupgrade, Websocket, gRPC
Expired On     : $exp

Note !!!
WS = Websocket
HUP = HTTPupgrade
========================================
       ----- [ Vmess Link ] -----
========================================
Link WS TLS      : $vmesslink1
========================================
Link WS nTLS     : $vmesslink2
========================================
Link HUP TLS     : $vmesslink3
========================================
Link HUP nTLS    : $vmesslink4
========================================
Link gRPC        : $vmesslink5
========================================


========================================
       ----- [ Vless Link ] -----
========================================
Link WS TLS      : $vlesslink1
========================================
Link WS nTLS     : $vlesslink2
========================================
Link HUP TLS     : $vlesslink3
========================================
Link HUP nTLS    : $vlesslink4
========================================
Link gRPC        : $vlesslink5
========================================
Link XTLS-Vision : $vlesslink6
========================================


========================================
       ----- [ Trojan Link ] -----
========================================
Link WS TLS      : $trojanlink1
========================================
Link WS nTLS     : $trojanlink2
========================================
Link HUP TLS     : $trojanlink3
========================================
Link HUP nTLS    : $trojanlink4
========================================
Link gRPC        : $trojanlink5
========================================
Link TCP TLS     : $trojanlink6
========================================


========================================
    ----- [ Shadowsocks Link ] -----
========================================
Link WS TLS      : $sslink1
========================================
Link WS nTLS     : $sslink2
========================================
Link HUP TLS     : $sslink3
========================================
Link HUP nTLS    : $sslink4
========================================
Link gRPC        : $sslink5
========================================


========================================
  ----- [ Shadowsocks 2022 Link ] -----
========================================
Link WS TLS      : $ss22link1
========================================
Link WS nTLS     : $ss22link2
========================================
Link HUP TLS     : $ss22link3
========================================
Link HUP nTLS    : $ss22link4
========================================
Link gRPC        : $ss22link5
========================================
END

systemctl restart xray
clear
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "              ----- [ All Xray ] -----              " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "ISP            : $ISP" | tee -a /user/xray-$user.log
echo -e "Region         : $REG" | tee -a /user/xray-$user.log
echo -e "City           : $CITY" | tee -a /user/xray-$user.log
echo -e "Port TLS/HTTPS : 443" | tee -a /user/xray-$user.log
echo -e "Port HTTP      : 80" | tee -a /user/xray-$user.log
echo -e "Transport      : XTLS-Vision, TCP TLS, Websocket, HTTPupgrade, gRPC" | tee -a /user/xray-$user.log
echo -e "Expired On     : $exp" | tee -a /user/xray-$user.log
echo -e "Link / Web     : https://$domain/xray/xray-$user.log" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "             ----- [ Vmess Link ] -----             " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS TLS    : $vmesslink1" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS   : $vmesslink2" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS   : $vmesslink3" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS  : $vmesslink4" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link gRPC      : $vmesslink5" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "             ----- [ Vless Link ] -----             " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $vlesslink1" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $vlesslink2" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $vlesslink3" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $vlesslink4" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $vlesslink5" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link XTLS-Vision : $vlesslink6" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "            ----- [ Trojan Link ] -----             " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $trojanlink1" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $trojanlink2" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $trojanlink3" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $trojanlink4" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $trojanlink5" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link TCP TLS     : $trojanlink6" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "          ----- [ Shadowsocks Link ] -----          " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $sslink1" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $sslink2" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $sslink3" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $sslink4" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $sslink5" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "       ----- [ Shadowsocks 2022 Link ] -----        " | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS TLS      : $ss22link1" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link WS nTLS     : $ss22link2" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP TLS     : $ss22link3" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link HUP nTLS    : $ss22link4" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e "Link gRPC        : $ss22link5" | tee -a /user/xray-$user.log
echo -e "————————————————————————————————————————————————————" | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
echo -e " " | tee -a /user/xray-$user.log
read -n 1 -s -r -p "Press any key to back on menu"
clear
allxray
