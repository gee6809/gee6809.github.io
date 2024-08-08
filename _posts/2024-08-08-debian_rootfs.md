---
title: Debian 기반 rootfs 제작하기
description: QEMU를 활용하여 Debian 기반의 root 파일 시스템(rootfs)을 생성하고 부팅하는 방법을 단계별로 설명합니다.
categories:
- QEMU
date: 2024-08-08 11:03 +0900
---
## 필요한 도구 설치
```bash
sudo apt update
sudo apt install qemu qemu-system-x86 debootstrap
```

## debian기반 rootfs 이미지 생성

**1) QEMU 디스크 이미지 생성**

```bash
qemu-img create -f qcow2 debian-rootfs.img 10G
```

**2) 디스크 이미지 포맷 및 마운트**

```bash
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 debian-rootfs.img

# 연결된 디스크를 포맷합니다.
sudo mkfs.ext4 /dev/nbd0

# 파일 시스템을 마운트합니다.
sudo mount /dev/nbd0 /mnt
```

**3) debootstrap 실행**

```bash
sudo debootstrap --arch=amd64 bullseye /mnt http://deb.debian.org/debian
```

**4) 초기 설정 (network 설정 포함)**

```bash
sudo chroot /mnt
passwd # root에 대한 password를 설정해 줍니다.

# -----------------------------------
#eth0 는 ip link 통해 내 network에 맞게 수정해주어야 합니다.
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOT
# -----------------------------------
cat <<EOT > /etc/fstab
/dev/sda / ext4 errors=remount-ro 0 1
EOT
# -----------------------------------

exit
sudo umount /mnt
sudo qemu-nbd --disconnect /dev/nbd0
```

## QEMU 부팅
```bash
sudo qemu-system-x86_64 \
    -kernel /path/to/linux/arch/x86/boot/bzImage \
    -append "root=/dev/sda console=ttyS0" \
    -hda /path/to/debian-rootfs.img \
    -m 1024 \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
    -device e1000,netdev=usernet \
    -nographic
```
"root / 설정한 비밀번호" 로그인하면 됩니다.

## 만약 인터넷이 안될 시
1. QEMU 환경 내에서 `ip link`를 통해 네트워크 인터페이스(eth0, enp0s3, ...)를 확인합니다.
```bash
nano /etc/network/interfaces
```
네트워크 인터페이스가 올바르게 되어 있는지 확인합니다.

2. 수정 후 네트워크를 재실행합니다.
```bash
/etc/init.d/networking restart
```

3. 네트워크 연결 상태를 확인합니다.
```bash
ping -c 4 google.com
```

## user 추가하기
처음 실행했을 때는 root user밖에 없습니다. ssh-server 등을 사용하기 위해서는 새로운 user를 추가해 줄 필요가 있습니다.
```bash
adduser newuser
usermod -aG sudo newuser

apt install sudo
```





