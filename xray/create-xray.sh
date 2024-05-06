user=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1`
domain=$(cat /usr/local/etc/xray/domain)
uuid=$(cat /proc/sys/kernel/random/uuid)
pwtr=$(openssl rand -hex 4)
read -p "Expired (days): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#vless$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vmess$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#trojan$/a\#&@ '"$user $exp"'\
},{"password": "'""$pwtr""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
vmlink1=`cat<<EOF
{
"v": "2",
"ps": "${user}",
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
"ps": "${user}",
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
"ps": "${user}",
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
"ps": "${user}",
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
vmesslink1="vmess://$(echo $vmlink1 | base64 -w 0)"
vmesslink2="vmess://$(echo $vmlink2 | base64 -w 0)"
vmesslink3="vmess://$(echo $vmlink3 | base64 -w 0)"
vmesslink4="vmess://$(echo $vmlink4 | base64 -w 0)"

vlesslink1="vless://$uuid@$domain:443?path=/vless-ws&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user"
vlesslink2="vless://$uuid@$domain:80?path=/vless-ws&security=none&encryption=none&host=$domain&type=ws#$user"
vlesslink3="vless://$uuid@$domain:443?path=/vless-hup&security=tls&encryption=none&host=$domain&type=httpupgrade&sni=$domain#$user"
vlesslink4="vless://$uuid@$domain:80?path=/vless-hup&security=none&encryption=none&host=$domain&type=httpupgrade#$user"

trojanlink1="trojan://$pwtr@$domain:443?path=/trojan-ws&security=tls&host=$domain&type=ws&sni=$domain#$user"
trojanlink2="trojan://$pwtr@$domain:80?path=/trojan-ws&security=none&host=$domain&type=ws#$user"
trojanlink3="trojan://$pwtr@$domain:443?path=/trojan-hup&security=tls&host=$domain&type=httpupgrade&sni=$domain#$user"
trojanlink4="trojan://$pwtr@$domain:80?path=/trojan-hup&security=tls&host=$domain&type=httpupgrade#$user"
systemctl restart xray

clear
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "              ----- [ All Xray ] -----              " | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Domain            : $domain" | tee -a /user/log-xray-$user.txt
echo -e "ISP               : $ISP" | tee -a /user/log-xray-$user.txt
echo -e "City              : $CITY" | tee -a /user/log-xray-$user.txt
echo -e "Port Websocket    : 443, 80" | tee -a /user/log-xray-$user.txt
echo -e "Port HTTPupgrade  : 443, 80" | tee -a /user/log-xray-$user.txt
echo -e "Network           : Websocket, HTTPupgrade" | tee -a /user/log-xray-$user.txt
echo -e "Alpn              : h2, http/1.1" | tee -a /user/log-xray-$user.txt
echo -e "Expired On        : $exp" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "             ----- [ Vmess Link ] -----             " | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link WS TLS    : $vmesslink1" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link WS nTLS   : $vmesslink2" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link HUP TLS   : $vmesslink3" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link HUP nTLS  : $vmesslink4" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e " " | tee -a /user/log-xray-$user.txt
echo -e " " | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "             ----- [ Vless Link ] -----             " | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link WS TLS    : $vlesslink1" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link WS nTLS   : $vlesslink2" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link HUP TLS   : $vlesslink3" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link HUP nTLS  : $vlesslink4" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e " " | tee -a /user/log-xray-$user.txt
echo -e " " | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "            ----- [ Trojan Link ] -----             " | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link WS TLS    : $trojanlink1" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link WS nTLS   : $trojanlink2" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link HUP TLS   : $trojanlink3" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e "Link HUP nTLS  : $trojanlink4" | tee -a /user/log-xray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-xray-$user.txt
echo -e " " | tee -a /user/log-xray-$user.txt
echo -e " " | tee -a /user/log-xray-$user.txt
read -n 1 -s -r -p "Press any key to back on menu"
clear
allxray
