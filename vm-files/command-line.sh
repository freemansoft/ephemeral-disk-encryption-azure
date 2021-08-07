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
create_luks_partition() {
    parted $DISK_DEVICE mklabel gpt
    parted --align opt $DISK_DEVICE mkpart datadisk xfs 0% 100%
    #sudo parted $DISK_DEVICE print
    partprobe
}

encrypt_luks_partition() {
    # encrypt the volume - format as encrypted device
    echo $LUKS_KEY | cryptsetup --key-file - -v --type luks2 luksFormat $DISK_PARTITION
    # open the encrypted volume - $LUKS_PART_NAME will be name in /dev/mapper
    echo $LUKS_KEY | cryptsetup --key-file - -v luksOpen $DISK_PARTITION $LUKS_PART_NAME

    # set the encrypted partition label the same on all drives
    mkfs.xfs -L data $LUKS_DEVICE
    cryptsetup -v luksClose $LUKS_PART_NAME
}

# once per drive - variable driven to run across multiple drives
create_luks_automount() {
 
    cp $DIR/data.mount $MOUNT_DEF
    chown root:root $MOUNT_DEF
    sed -i "s:--LUKS_DEVICE--:$LUKS_DEVICE:g" "$MOUNT_DEF"
    sed -i "s:--LUKS_MOUNT_POINT--:$LUKS_MOUNT_POINT:g" "$MOUNT_DEF"
    sed -i "s:--SERVICE_DEF_NAME--:$SERVICE_DEF_NAME:g" "$MOUNT_DEF"

    cp $DIR/unlock-data.service $SERVICE_DEF
    chown root:root $SERVICE_DEF
    # use the UUID because - I really have no idea
    DRIVE_UUID="$(lsblk -o UUID $DISK_PARTITION --noheadings)"
    #echo $DRIVE_UUID
    sed -i "s:--DRIVE_UUID--:$DRIVE_UUID:g" "$SERVICE_DEF"
    sed -i "s:--LUKS_PART_NAME--:$LUKS_PART_NAME:g" "$SERVICE_DEF"

    # mount point ust match the unit name
    mkdir -p $LUKS_MOUNT_POINT
    systemctl daemon-reload
    systemctl enable --now $MOUNT_DEF
}

# once per drive
create_vars() {
    DISK_DEVICE="/dev/nvme$DISK_NUM""n1"
    DISK_PARTITION="$DISK_DEVICE""p1"

    # /dev/mapper name is magical part of cryptsetup
    LUKS_PART_NAME="data$DISK_NUM"
    LUKS_DEVICE="/dev/mapper/$LUKS_PART_NAME"
    LUKS_MOUNT_POINT="/$LUKS_PART_NAME"

    MOUNT_DEF_NAME="$LUKS_PART_NAME"".mount"
    MOUNT_DEF="/etc/systemd/system/$MOUNT_DEF_NAME"
    SERVICE_DEF_NAME="unlock-$LUKS_PART_NAME"".service"
    SERVICE_DEF="/etc/systemd/system/$SERVICE_DEF_NAME"
}

create_luks_etc_utils
LUKS_KEY="$(/etc/luks-key.sh)"
echo $LUKS_KEY
# loop until find no more NVMe drives
for DISK_NUM in {0..9}
do
    create_vars
    if [ -e "$DISK_DEVICE" ]
    then
        echo "creating partition $DISK_DEVICE"
        create_luks_partition
        echo "encrypting $DISK_PARTITION $LUKS_PART_NAME"
        encrypt_luks_partition
        echo "creating mounts $DISK_DEVICE $DISK_PARTITION"
        create_luks_automount
    else
        break
    fi
done
