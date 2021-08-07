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

# once per VM
create_luks_etc_utils(){
    cp $DIR/luks-key.sh /etc
    cp $DIR/luks-env.sh /etc

    chown root:root /etc/luks-key.sh
    chmod 0500 /etc/luks-key.sh
    chown root:root /etc/luks-env.sh
    chmod 0500 /etc/luks-env.sh
}

# once per drive
create_luks_partitions() {
    parted $DISK_DEVICE mklabel gpt
    parted -a opt $DISK_DEVICE mkpart datadisk xfs 0% 100%

    /etc/luks-key.sh | cryptsetup -d - -v --type luks2 luksFormat $DISK_PARTITION
    /etc/luks-key.sh | cryptsetup -d - -v luksOpen $DISK_PARTITION $LUKS_PART_NAME

    mkfs.xfs -L $LUKS_PART_NAME $LUKS_DEVICE
    cryptsetup -v luksClose $LUKS_PART_NAME
}

# once per drive - variable driven to run across multiple drives
create_luks_automounts() {
 
    cp $DIR/data.mount $MOUNT_DEF
    chown root:root $MOUNT_DEF
    sed -i "s:--LUKS_DEVICE--:$LUKS_DEVICE:g" "$MOUNT_DEF"
    sed -i "s:--LUKS_PART_NAME--:$LUKS_PART_NAME:g" "$MOUNT_DEF"
    sed -i "s:--SERVICE_DEF_NAME--:$SERVICE_DEF_NAME:g" "$MOUNT_DEF"

    cp $DIR/unlock-data.service $SERVICE_DEF
    chown root:root $SERVICE_DEF
    # in unlock-data<n>.service - replace DRIVE_UUID with $DRIVE_UUID
    DRIVE_UUID="$(lsblk -o UUID $DISK_PARTITION --noheadings)"
    #echo $DRIVE_UUID
    sed -i "s:--DRIVE_UUID--:$DRIVE_UUID:g" "$SERVICE_DEF"
    sed -i "s:--LUKS_PART_NAME--:$LUKS_PART_NAME:g" "$SERVICE_DEF"

    systemctl daemon-reload
    mkdir -p /$LUKS_PART_NAME
    systemctl enable --now $MOUNT_DEF
}

# once per drive
create_vars() {
    DISK_DEVICE="/dev/nvme""$DISK_NUM""n1"
    DISK_PARTITION="/dev/nvme""$DISK_NUM""n1p1"
    LUKS_PART_NAME="data""$DISK_NUM"
    LUKS_DEVICE="/dev/mapper/data""$DISK_NUM"
    MOUNT_DEF="/etc/systemd/system/data""$DISK_NUM"".mount"
    SERVICE_DEF="/etc/systemd/system/unlock-data""$DISK_NUM"".service"
    SERVICE_DEF_NAME="unlock-data""$DISK_NUM"".service"
}

create_luks_etc_utils
# should loop until find no more NVMe drives
for DISK_NUM in {0..9}
do
    create_vars
    if [ -e "$DISK_DEVICE" ]
    then
        echo "creating devices $DISK_DEVICE $DISK_PARTITION"
        create_luks_partitions
        echo "creating mounts $DISK_DEVICE $DISK_PARTITION"
        create_luks_automounts
    else
        exit 0
    fi
done
