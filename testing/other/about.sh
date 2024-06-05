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
echo ""
echo ""
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
read -n 1 -s -r -p "Press any key to back on menu"
menu
