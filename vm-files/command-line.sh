#!/bin/bash
# must run as root/sudo
# installs our luks scripts, encrypts the drive and configures the automount
set -e

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "script requires root priv to insall in /etc"
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
# luks-key.sh requires jq
if ! command -v jq &> /dev/null
then
    sudo snap install jq
fi

create_luks_etc_utils(){
    cp $DIR/luks-key.sh /etc
    cp $DIR/luks-env.sh /etc

    chown root:root /etc/luks-key.sh
    chmod 0500 /etc/luks-key.sh
    chown root:root /etc/luks-env.sh
    chmod 0500 /etc/luks-env.sh
}

create_luks_partitions() {
    parted $DISK_DEVICE mklabel gpt
    parted -a opt $DISK_DEVICE mkpart datadisk xfs 0% 100%

    /etc/luks-key.sh | cryptsetup -d - -v --type luks2 luksFormat $DISK_PARTITION
    /etc/luks-key.sh | cryptsetup -d - -v luksOpen $DISK_PARTITION $LUKS_PART_NAME

    mkfs.xfs -L data1 $LUKS_DEVICE
    cryptsetup -v luksClose $LUKS_PART_NAME
}

create_luks_automounts() {
    # in unlock-data1.service - replace DRIVE_UUID with $UUID
    DRIVE_UUID="$(lsblk -o UUID $DISK_PARTITION --noheadings)"
    #echo $DRIVE_UUID

    cp $DIR/data.mount $MOUNT_DEF
    chown root:root $MOUNT_DEF
    sed -i "s:--LUKS_DEVICE--:$LUKS_DEVICE:g" "$MOUNT_DEF"
    sed -i "s:--LUKS_PART_NAME--:$LUKS_PART_NAME:g" "$MOUNT_DEF"
    sed -i "s:--SERVICE_DEF_NAME--:$SERVICE_DEF_NAME:g" "$MOUNT_DEF"

    cp $DIR/unlock-data.service $SERVICE_DEF
    chown root:root $SERVICE_DEF
    sed -i "s:--DRIVE_UUID--:$DRIVE_UUID:g" "$SERVICE_DEF"
    sed -i "s:--LUKS_PART_NAME--:$LUKS_PART_NAME:g" "$SERVICE_DEF"

    systemctl daemon-reload
    mkdir -p /$LUKS_PART_NAME
    systemctl enable --now $MOUNT_DEF
}

# this should loop across all found nvme drives
DISK_NUM=0
DISK_DEVICE="/dev/nvme$DISK_NUM""n1"
DISK_PARTITION="/dev/nvme$DISK_NUM""n1p1"
LUKS_PART_NAME="data$DISK_NUM"
LUKS_DEVICE="/dev/mapper/data$DISK_NUM"
MOUNT_DEF="/etc/systemd/system/data$DISK_NUM.mount"
SERVICE_DEF="/etc/systemd/system/unlock-data$DISK_NUM.service"
SERVICE_DEF_NAME="unlock-data$DISK_NUM.service"

create_luks_etc_utils
create_luks_partitions
create_luks_automounts
