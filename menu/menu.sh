NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
xray_service=$(systemctl status xray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
nginx_service=$(systemctl status nginx | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ $xray_service == "running" ]]; then
status_xray="${GB}[ ON ]${NC}"
else
status_xray="${RB}[ OFF ]${NC}"
fi
if [[ $nginx_service == "running" ]]; then
status_nginx="${GB}[ ON ]${NC}"
else
status_nginx="${RB}[ OFF ]${NC}"
fi
dtoday="$(vnstat | grep today | awk '{print $2" "substr ($3, 1, 3)}')"
utoday="$(vnstat | grep today | awk '{print $5" "substr ($6, 1, 3)}')"
ttoday="$(vnstat | grep today | awk '{print $8" "substr ($9, 1, 3)}')"
dmon="$(vnstat -m | grep `date +%G-%m` | awk '{print $2" "substr ($3, 1 ,3)}')"
umon="$(vnstat -m | grep `date +%G-%m` | awk '{print $5" "substr ($6, 1 ,3)}')"
tmon="$(vnstat -m | grep `date +%G-%m` | awk '{print $8" "substr ($9, 1 ,3)}')"
domain=$(cat /usr/local/etc/xray/domain)
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
REG=$(cat /usr/local/etc/xray/region)
WKT=$(cat /usr/local/etc/xray/timezone)
DATE=$(date -R | cut -d " " -f -4)
MYIP=$(curl -sS ipv4.icanhazip.com)
clear
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "               ${WB}----- [ Xray Script ] -----${NC}              "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e " ${YB}ISP${NC}    ${WB}: $ISP"
echo -e " ${YB}Region${NC} ${WB}: $REG${NC}"
echo -e " ${YB}City${NC}   ${WB}: $CITY${NC}"
echo -e " ${YB}Date${NC}   ${WB}: $DATE${NC}"
echo -e " ${YB}Domain${NC} ${WB}: $domain${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "     ${WB}NGINX STATUS :${NC} $status_nginx    ${WB}XRAY STATUS :${NC} $status_xray   "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
# echo -e "          ${WB}----- [ Bandwidth Monitoring ] -----${NC}"
# echo -e ""
# echo -e "  ${GB}Today ($DATE)     Monthly ($(date +%B/%Y))${NC}      "
# echo -e "${BB}————————————————————————————————————————————————————————${NC}"
# echo -e "    ${GB}↓↓ Down: $dtoday          ↓↓ Down: $dmon${NC}   "
# echo -e "    ${GB}↑↑ Up  : $utoday          ↑↑ Up  : $umon${NC}   "
# echo -e "    ${GB}≈ Total: $ttoday          ≈ Total: $tmon${NC}   "
# echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "                   ${WB}----- [ Menu ] -----${NC}               "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e " ${MB}[1]${NC} ${YB}Xray Menu${NC}"
echo -e " ${MB}[2]${NC} ${YB}Log Create Account${NC}"
echo -e " ${MB}[3]${NC} ${YB}Speedtest${NC}"
echo -e " ${MB}[4]${NC} ${YB}Change Domain${NC}"
echo -e " ${MB}[5]${NC} ${YB}Cert Acme.sh${NC}"
echo -e " ${MB}[6]${NC} ${YB}About Script${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e ""
read -p " Select Menu :  "  opt
echo -e ""
case $opt in
1) clear ; allxray ;;
2) clear ; log-xray ;;
3) clear ; speedtest ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; menu ;;
4) clear ; dns ;;
5) clear ; certxray ;;
6) clear ; about ;;
x) exit ;;
*) echo -e "${YB}salah input${NC}" ; sleep 1 ; menu ;;
esac
