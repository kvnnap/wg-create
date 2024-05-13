#!/bin/bash

CIDR="10.0.0.0/29"
DEVICES=("kitchen" "living" "bedroom" "studio")
ALLOWED_IPS="IP_START\\/PREFIX_LENGTH"
SERVER_HOST=addr.duckdns.org
SERVER_PORT=51820
CLIENT_DNS=1.1.1.1

cidr_to_ip_range() {
    local cidr=$1
    IFS='/' read -r ip_address prefix_length <<< "$cidr"
    IFS='.' read -r ip1 ip2 ip3 ip4 <<< "$ip_address"
    netmask=$((0xFFFFFFFF << (32 - prefix_length)))
    IFS='.' read -r -a netmask_arr <<< "$(printf "%d.%d.%d.%d" "$((netmask >> 24 & 255))" "$((netmask >> 16 & 255))" "$((netmask >> 8 & 255))" "$((netmask & 255))")"
    ip_start=$(( (ip1 & netmask_arr[0]) << 24 | (ip2 & netmask_arr[1]) << 16 | (ip3 & netmask_arr[2]) << 8 | (ip4 & netmask_arr[3]) ))
    ip_end=$(( (ip1 | (255 - netmask_arr[0])) << 24 | (ip2 | (255 - netmask_arr[1])) << 16 | (ip3 | (255 - netmask_arr[2])) << 8 | (ip4 | (255 - netmask_arr[3])) ))
    declare -g result=("$ip_start" "$ip_end" "$prefix_length")
}

int_ip_to_string() {
    local ip=$1
    local octet1=$(( (ip >> 24) & 255 ))
    local octet2=$(( (ip >> 16) & 255 ))
    local octet3=$(( (ip >> 8) & 255 ))
    local octet4=$(( ip & 255 ))
    declare -g result="$octet1.$octet2.$octet3.$octet4"
}

create_pair() {
    local name=$1
    local gen_pre=$2
    local force_prv="false"
    local preshared=""

    local path="$BASE_DIR/$name/$name"
    local prev_umask=$(umask)
    
    umask $orig_umask
    mkdir -p "$BASE_DIR/$name"
    umask 077

    if [ ! -f "$path.private" ]; then
        wg genkey > $path.private
        force_prv="true"
    fi

    if [ "$force_prv" = "true" ] || [ ! -f "$path.public" ]; then
        umask $orig_umask
        cat $path.private | wg pubkey > $path.public
        umask 077
    fi

    if [ "$gen_pre" = "true" ] && [ ! -f "$path.server.preshared" ]; then
        wg genpsk > $path.server.preshared
    fi

    local private=$(cat $path.private | sed $ESCAPE)
    local public=$(cat $path.public | sed $ESCAPE)

    if [ "$gen_pre" = "true" ]; then
        preshared=$(cat $path.server.preshared | sed $ESCAPE)
    fi

    declare -g result=("$private" "$public" "$preshared")
}

# UMASK stuff
orig_umask=$(umask)
umask 077

ESCAPE='s/\//\\\//g'
BASE_DIR=keys

cidr_to_ip_range "$CIDR"
ip_start="${result[0]}"
ip_end="${result[1]}"
PREFIX_LENGTH="${result[2]}"


int_ip_to_string $ip_start
IP_START="$result"

int_ip_to_string $ip_end
IP_END="$result"

first_ip=$(($ip_start + 1))
int_ip_to_string $first_ip
SERVER_IP="$result"

# Gen server
create_pair "server" "false"
SERVER_PRIVATE_KEY="${result[0]}"
SERVER_PUBLIC_KEY="${result[1]}"
sed -e "s/SERVER_IP/$SERVER_IP/g" -e "s/SERVER_PORT/$SERVER_PORT/g" -e "s/PREFIX_LENGTH/$PREFIX_LENGTH/g" -e "s/SERVER_PRIVATE_KEY/$SERVER_PRIVATE_KEY/g" templates/server.template > $BASE_DIR/server/server.conf

# Gen clients
ip=$(($first_ip + 1))
for dev in "${DEVICES[@]}"; do
    if [ "$ip" -ge "$ip_end" ]; then
        echo "'$dev' cannot be created: ip range is too small"
        continue
    fi

    path="$BASE_DIR/$dev/$dev"
    create_pair "$dev" "true"
    CLIENT_PRIVATE_KEY="${result[0]}"
    CLIENT_PUBLIC_KEY="${result[1]}"
    PRESHARED_KEY="${result[2]}"

    int_ip_to_string $ip
    CLIENT_IP="$result"

    sed -e "s/CLIENT_NAME/$dev/g" -e "s/CLIENT_PUBLIC_KEY/$CLIENT_PUBLIC_KEY/g" -e "s/PRESHARED_KEY/$PRESHARED_KEY/g" -e "s/CLIENT_IP/$CLIENT_IP/g" templates/server-peer.template >> $BASE_DIR/server/server.conf
    
    sed -e "s/CLIENT_NAME/$dev/g" -e "s/ALLOWED_IPS/$ALLOWED_IPS/g" -e "s/IP_START/$IP_START/g" -e "s/CLIENT_IP/$CLIENT_IP/g" -e "s/PREFIX_LENGTH/$PREFIX_LENGTH/g" -e "s/CLIENT_PRIVATE_KEY/$CLIENT_PRIVATE_KEY/g" -e "s/CLIENT_DNS/$CLIENT_DNS/g" -e "s/SERVER_PUBLIC_KEY/$SERVER_PUBLIC_KEY/g" -e "s/PRESHARED_KEY/$PRESHARED_KEY/g" -e "s/SERVER_HOST/$SERVER_HOST/g" -e "s/SERVER_PORT/$SERVER_PORT/g" templates/peer.template > $path.conf
    qrencode -r $path.conf -o $path.png

    ((ip++))
done
