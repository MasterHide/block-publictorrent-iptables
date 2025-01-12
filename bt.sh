#!/bin/bash
#
# 2025 Updated !!
# GitHub:   https://github.com/MasterHide/block-publictorrent-iptables
# Author:   MasterHide

echo -n "Blocking public trackers ... "
wget -q -O /etc/trackers https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/trackers
if [ $? -ne 0 ]; then
    echo "Failed to download trackers file."
    exit 1
fi

cat >/etc/cron.daily/denypublic<<'EOF'
IFS=$'\n'
IPTABLES_CMD=$(which iptables)
L=$(/usr/bin/sort /etc/trackers | /usr/bin/uniq)
for fn in $L; do
        $IPTABLES_CMD -D INPUT -d $fn -j DROP
        $IPTABLES_CMD -D FORWARD -d $fn -j DROP
        $IPTABLES_CMD -D OUTPUT -d $fn -j DROP
        $IPTABLES_CMD -A INPUT -d $fn -j DROP
        $IPTABLES_CMD -A FORWARD -d $fn -j DROP
        $IPTABLES_CMD -A OUTPUT -d $fn -j DROP
done
EOF
chmod +x /etc/cron.daily/denypublic

curl -s -LO https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/hostsTrackers
if [ $? -ne 0 ]; then
    echo "Failed to download hostsTrackers."
    exit 1
fi

cat hostsTrackers | sort -uf >> /etc/hosts
if [ $? -ne 0 ]; then
    echo "Failed to update /etc/hosts."
    exit 1
fi

echo "Blocking public trackers completed successfully."
