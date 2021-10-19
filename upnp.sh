#!/usr/bin/env bash
function wan_ip_connection() {
    local host=$1
         result=$( curl -s "http://$host/upnp/control?WANIPConnection" \
                 -H 'SOAPAction: "urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress"' \
                 --data-binary '<?xml version="1.0"?>'\
's:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'\
's:Body>'\
'u:GetExternalIPAddress xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1">'\
'/u:GetExternalIPAddress>'\
'/s:Body>'\
'/s:Envelope>'
         )

         REGEX='ExternalIPAddress>([0-9.]+)<'
         if [[ $result =~ $REGEX ]]
         then
                 echo "${BASH_REMATCH[@]:1}"
         fi
}

function initial_query() {
   echo -e 'M-SEARCH * HTTP/1.1\r\n'\
'HOST: 239.255.255.250:1900\r\n'\
'MAN: "ssdp:discover"\r\n'\
'MX: 3\r\n'\
'ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1\r\n'\
'\r\n'\
'' |
            socat STDIO UDP4-DATAGRAM:239.255.255.250:1900
}

function ip() {
        location=$( initial_query | grep LOCATION )
        location=${location%/*}
        location=${location##*/}
        ip=$( wan_ip_connection "$location" )
        echo $ip
}

function get_existing_ip() {
        # externip=121.221.66.178
        REGEX='^externip=([0-9.]+)'

        while read -r
        do
                if [[ $REPLY =~ $REGEX ]]
                then
                        current_ip="${BASH_REMATCH[@]:1}"
                        current_ip=${current_ip#*=}
                        echo "$current_ip"
                        return
                fi
        done < /etc/asterisk/sip_general_custom.conf
}

old_ip=$( get_existing_ip )
new_ip=$( ip )
if [[ $old_ip != $new_ip ]]
then
        echo "changing ip from $old_ip to $new_ip"
        perl -pi -e "s/externip=$old_ip/externip=$new_ip/" /etc/asterisk/sip_general_custom.conf
        service asterisk restart
else
        echo "ip hasn't changed $old_ip vs $new_ip"
fi
