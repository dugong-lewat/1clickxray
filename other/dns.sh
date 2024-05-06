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
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Domain/Host: " -e host
if [ -z $host ]; then
echo -e "${YB}????${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
dns
else
echo "DNS=$host" > /var/lib/dnsvps.conf
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "${YB}Dont Forget To Renew Cert${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
fi
