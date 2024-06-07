NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Start${NC} "
sleep 0.5
systemctl stop nginx
domain=$(cat /var/lib/dnsvps.conf | cut -d'=' -f2)
Cek=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
if [[ ! -z "$Cek" ]]; then
sleep 1
echo -e "${RB}[ WARNING ]${NC} ${YB}Detected port 80 used by $Cek${NC} "
systemctl stop $Cek
sleep 2
echo -e "${GB}[ INFO ]${NC} ${YB}Processing to stop $Cek${NC} "
sleep 1
fi
echo -e "${GB}[ INFO ]${NC} ${YB}Starting renew cert...${NC} "
sleep 2
bash .acme.sh/acme.sh --issue -d $domain --listen-v6 --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --standalone --force
chmod 745 /usr/local/etc/xray/private.key
echo -e "${GB}[ INFO ]${NC} ${YB}Renew cert done...${NC} "
sleep 2
echo -e "${GB}[ INFO ]${NC} ${YB}Starting service $Cek${NC} "
sleep 2
echo "$domain" > /usr/local/etc/xray/dns/domain
systemctl restart $Cek
systemctl restart nginx
echo -e "${GB}[ INFO ]${NC} ${YB}All finished...${NC} "
sleep 0.5
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
