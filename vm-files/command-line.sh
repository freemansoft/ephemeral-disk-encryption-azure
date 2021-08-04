vi /etc/luks-key.sh #put script from below here
chown root:root /etc/luks-key.sh
chmod 0500 /etc/luks-key.sh

parted /dev/nvme0n1 mklabel gpt
parted -a opt /dev/nvme0n1 mkpart datadisk xfs 0% 100%

/etc/luks-key.sh | cryptsetup -d - -v --type luks2 luksFormat /dev/nvme0n1p1
/etc/luks-key.sh |cryptsetup -d - -v luksOpen /dev/nvme0n1p1 data1

mkfs.xfs -L data1 /dev/mapper/data1

cryptsetup -v luksClose data1

vi /etc/systemd/system/unlock-data1.service # systemd unit to unlock, will be below
vi /etc/systemd/system/data1.mount. # system unit to mount, also below

systemctl daemon-reload

mkdir /data1

systemctl enable --now ddata1.mount