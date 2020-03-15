#! /bin/bash -xe

source .env || true

if [[ -z ${SSID} ]]; then
    echo "Environment variable SSID not set"
    exit 1
fi

if [[ -z ${PSK} ]]; then
    echo "Environment variable PSK not set"
    exit 1
fi

echo "Setting up SSH"
echo -n "" > /Volumes/boot/ssh

echo "Setting up WPA supplicant"
cat <<EOT > /Volumes/boot/wpa_supplicant.conf
country=IT
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
network={
    ssid="$SSID"
    psk="$PSK"
    key_mgmt=WPA-PSK
}

EOT
