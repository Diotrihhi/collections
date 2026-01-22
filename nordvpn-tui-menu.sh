#!/bin/bash
sudo systemctl start iptables

set_routing() {
{
echo 10;
echo "XXX";
echo "Aktiviere IP-Forwarding...";
echo "XXX"
sudo sysctl -w net.ipv4.ip_forward=1
#> /dev/null
sleep 1
echo 40;
echo "XXX";
echo "Lösche alte Regeln...";
echo "XXX"
sudo iptables -F
sudo iptables -t nat -F
sleep 1
echo 60;
echo "XXX";
echo "Setze NAT Masquerading...";
echo "XXX"
sudo iptables -t nat -A POSTROUTING -o nordlynx -j MASQUERADE
sleep 1
echo 80;
echo "XXX";
echo "Erlaube Forwarding...";
echo "XXX"
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

sudo iptables -A FORWARD -i end0 -o nordlynx -j ACCEPT
sleep 1
echo 100
} | whiptail --gauge "Konfiguriere Routing..." 6 50 0
}


CHOICE=$(whiptail --title "NordVPN Manager" --menu "Aktion wählen:" 18 70 6 \
"1" "NordVPN - Fastest Server" \
"2" "NordVPN - Germany" \
"3" "NordVPN - Kazakhstan (Unblock RUS)" \
"4" "NordVPN - Manuelle Wahl" \
"5" "VPN deaktivieren" \
"6" "Exit" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
        exit 0
fi

case $CHOICE in
1)
sudo nordvpn connect
set_routing
whiptail --msgbox "Verbunden mit Fastest Server!" 8 40
;;
2)
sudo nordvpn connect Germany
set_routing
whiptail --msgbox "Verbunden mit Germany!" 8 40
;;
3)
sudo nordvpn connect Kazakhstan
set_routing
whiptail --msgbox "Verbunden mit Kazakhstan!" 8 40
;;
4)
########################################################
whiptail --infobox "Lade Länderliste..." 8 40

# 1. Liste holen:
# 'tr' ersetzt Leerzeichen, Tabs und Kommas durch neue Zeilen.
# 'sort' sortiert alphabetisch.
# 'uniq' entfernt Doppelte (falls vorhanden).
# 'grep -v' entfernt leere Zeilen.
RAW_LIST=$(nordvpn countries | tr -s ' ,\t\r' '\n' | sort | uniq | grep -v "^$")

# 2. Array für Whiptail bauen
# Wir brauchen das Format: "Land" "Land" (als Key und Description)
OPTIONS=()
while read -r country; do
    OPTIONS+=("$country" "$country")
done <<< "$RAW_LIST"

# 3. Menü anzeigen
# "${OPTIONS[@]}" übergibt das gesamte Array als einzelne Argumente an whiptail
COUNTRY_INPUT=$(whiptail --title "Länderauswahl" --notags --menu "Wähle ein Land:" 22 70 12 \
"${OPTIONS[@]}" 3>&1 1>&2 2>&3)

# 4. Verbinden, wenn nicht abgebrochen wurde
if [ $? -eq 0 ] && [ ! -z "$COUNTRY_INPUT" ]; then
    sudo nordvpn connect "$COUNTRY_INPUT"
    set_routing
    whiptail --msgbox "Verbunden mit $COUNTRY_INPUT!" 8 40
fi
;;
###########################################
        #whiptail --infobox "Lade Länderliste..." 8 40
        #COUNTRIES=$(nordvpn countries)
        #whiptail --title "Verfügbare Länder" --scrolltext --msgbox "$COUNTRIES" 20 70
        #COUNTRY_INPUT=$(whiptail --inputbox "Bitte Land eingeben:" 8 60 3>&1 1>&2 2>&3)

        #if [ ! -z "$COUNTRY_INPUT" ]; then
        #       sudo nordvpn connect "$COUNTRY_INPUT"
        #       set_routing
        #whiptail --msgbox "Verbunden mit $COUNTRY_INPUT!" 8 40
        #fi
        #;;
5)
### Trennen und Firewall saeubern
{
echo 10;
echo "XXX";
echo "Trenne VPN...";
echo "XXX"
sudo nordvpn disconnect > /dev/null
sleep 1
echo 50;
echo "XXX";
echo "Lösche Firewall-Regeln...";
echo "XXX"
sudo iptables -F
sudo iptables -t nat -F
sleep 1
echo 100
} | whiptail --gauge "Deaktiviere VPN..." 6 50 0
whiptail --msgbox "VPN getrennt. Gateway ist inaktiv." 8 45
;;
6)
exit 0
;;

esac
