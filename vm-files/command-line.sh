#!/bin/bash
# must run as root/sudo
# installs our luks scripts, encrypts the drive and configures the automount
set -e

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "script requires root priv to insall in /etc"
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
# lunks-key.sh requires jq
if ! command -v jq &> /dev/null
then
    sudo snap install jq
fi

cp $DIR/luks-key.sh /etc
cp $DIR/luks-env.sh /etc

chown root:root /etc/luks-key.sh
chmod 0500 /etc/luks-key.sh
chown root:root /etc/luks-env.sh
chmod 0500 /etc/luks-env.sh

# hard coded to the first NVMe drive
parted /dev/nvme0n1 mklabel gpt
parted -a opt /dev/nvme0n1 mkpart datadisk xfs 0% 100%

/etc/luks-key.sh | cryptsetup -d - -v --type luks2 luksFormat /dev/nvme0n1p1
/etc/luks-key.sh | cryptsetup -d - -v luksOpen /dev/nvme0n1p1 data1

mkfs.xfs -L data1 /dev/mapper/data1

cryptsetup -v luksClose data1

# in unlock-data1.service - replace DRIVE_UUID with $UUID
UUID="$(lsblk -o UUID /dev/nvme0n1p1 --noheadings)"
#echo $UUID

# the rest of this script isn't correct until we replace the UUID with the one we looked up
#exit 0

cp $DIR/data1.mount /etc/systemd/system
chown root:root /etc/systemd/system/data1.mount

cp $DIR/unlock-data1.service /etc/systemd/system
chown root:root /etc/systemd/system/unlock-data1.service
sed -i 's/DRIVE_UUID/$UUID/' /etc/systemd/system/unlock-data1.service

systemctl daemon-reload
mkdir /data1
systemctl enable --now data1.mount