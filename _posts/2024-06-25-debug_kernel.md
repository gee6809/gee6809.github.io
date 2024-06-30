---
title: GDB로 리눅스 커널 디버깅 하기
description: 리눅스 커널에 gdb를 붙여서 디버깅을 할 수 있다. gdb를 이용하면 line-by-line 실행 및 stacktrace,
  변수값 출력등의 기능들을 사용할 수 있다.
author: jeuk
categories:
- Linux Kernel
tags:
- Linux Kernel
- QEMU
- gdb
date: 2024-06-25 14:11 +0900
---
Linux kernel의 가장 큰 장점은 opensource라는 것이다. 모든 코드들이 공개되어 있기 때문에 시스템 개발자로서는 최고의 교과서라고 할 수 있다. ~~하지만 교과서가 너무 거대하다..~~

QEMU를 이용하면 Linux kernel에 gdb를 붙여 그나마 코드 분석을 조금 용이하게 할 수 있다. 여기에는 QEMU와 gdb를 이용해서 linux kernel을 디버깅하는 방법에 대해 정리해놓는다.

## 환경
- x86_64 CPU
- Ubuntu 22.04
- Linux kernel source code v6.10 기준

## 준비물
QEMU에서는 linux kernel을 간단하게 올려볼 수 있도록 -kernel 옵션을 제공한다.
> When using these options, you can use a given Linux or Multiboot kernel without installing it in the disk image. It can be useful for easier testing of various kernels.
> ```
> -kernel bzImage
>   Use bzImage as kernel image. The kernel can be either a Linux kernel or in multiboot format.
> ```

해당 옵션을 사용하기 위해 우리가 준비해야하는 건 3가지다.
- bzImage
  : 빌드한 linux kernel 이미지
- initramfs
  : 초기 램 디스크 이미지로, 부팅 과정에서 필요한 초기 파일 시스템을 제공한다.
- busybox
  : 최소한의 유틸리티들을 제공하는 도구로, initramfs에 포함되어 초기 시스템 환경을 구축하는 데 사용된다.

## bzImage (Linux Kernel 빌드)
먼저, Linux kernel 소스를 clone한다.
```bash
git clone https://github.com/torvalds/linux.git
```

gdb를 연결하기 위해서는 디버그 빌드와 같은 커널 옵션들을 설정해줘야 한다.
```bash
cd linux
make defconfig
make menuconfig
```

다음 두 항목을 수정해준다.

1) debug build option을 켜줘야 한다. 
   : 이 항목을 활성화하면 gcc에서 `-g` 옵션이 추가되어 디버그 심볼이 포함되게 된다.
```
-> Kernel hacking                                                                                        
  -> Compile-time checks and compiler options                                                            
    -> Debug information (<choice> [=y])                                                                 
      -> Rely on the toolchain's implicit default DWARF version (DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT [=y])
```

2) KASLR 옵션을 꺼줘야 한다.
   : 해당 기능은 커널 바이너리가 랜덤한 오프셋 값만큼 밀린 채로 메모리에 올라가도록 한다. 이는 해커들로부터 커널 함수들의 주소를 숨기는 역할을 하기에 보안에 좋다. 하지만 우리에게는 gdb가 함수 주소를 매칭시키지 못하게 하는 방해꾼이다. 비활성화 시켜주도록 하자.
```
-> Processor type and features                                                
  -> Build a relocatable kernel (RELOCATABLE [=y])                            
    -> Randomize the address of the kernel image (KASLR) (RANDOMIZE_BASE [=n])
```

마지막으로 make명령어를 통해 커널을 빌드한다.
```bash
make -j$(nproc)
```
빌드가 정상적으로 완료되면 arch/x86/boot/bzImage 파일과 vmlinux 파일이 생성된다.

## busybox 빌드
리눅스 커널과 마찬가지로 소스를 clone한다.
```bash
git clone https://git.busybox.net/busybox
```

```bash
cd busybox
make defconfig
make menuconfig
```

static 빌드를 위해 menuconfig에서 해당 옵션을 y로 설정한다.
```
Settings  --->
 --- Build Options
 [y] Build static binary (no shared libs)
```

make 명령어를 통해 빌드한다.
```bash
make -j$(nproc)
```
빌드가 완료되면 busybox 파일이 생성된다.

## initramfs 준비
initramfs는 부팅 과정에서 필요한 초기 파일 시스템을 제공한다. 이를 준비하기 위해 initramfs 디렉터리를 만들고 필요한 파일들을 포함시킨다.

```bash
mkdir initramfs
cd initramfs
mkdir -p {bin,sbin,dev,etc,home,mnt,proc,sys,usr,tmp}
mkdir -p usr/{bin,sbin}
mkdir -p proc/sys/kernel
cd dev
sudo mknod sda b 8 0
sudo mknod console c 5 1
cd ..
```

다음으로 빌드한 busybox 바이너리를 포함시켜 주어야 한다.
```bash
cp ../busybox/busybox ./bin/
```

qemu 부팅 후 실행될 init script를 만들어준다.
```bash
nano init
```
```bash
#!/bin/busybox sh

# Make symlinks
/bin/busybox --install -s

# Mount system
mount -t devtmpfs devtmpfs /dev
mount -t proc     proc     /proc
mount -t sysfs    sysfs    /sys
mount -t tmpfs    tmpfs    /tmp

# Busybox TTY fix
setsid cttyhack sh
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s

sh
```
```bash
chmod +x init
```

결과적으로 initramfs 디렉토리가 다음과 같이 구성되어야 한다.
```
.
├── bin
│   └── busybox
├── dev
│   ├── console
│   └── sda
├── etc
├── home
├── init
├── mnt
├── proc
│   └── sys
│       └── kernel
├── sbin
├── sys
├── tmp
└── usr
    ├── bin
    └── sbin

```

마지막으로 압축을 통해 initramfs파일을 만들어준다.
```bash
find . -print0 | cpio --null -ov --format=newc | gzip -9 > initramfs.cpio.gz
```

성공적으로 마쳤다면 initramfs.cpio.gz 파일이 생성된 것을 확인할 수 있다.

## QEMU를 이용한 Linux Kernel 실행
QEMU를 사용하여 bzImage와 initramfs를 로드한다.

```bash
qemu-system-x86_64 \
  -nographic \
  -enable-kvm \
  -cpu host \
  -m 1G \
  -gdb tcp::1234 \
  -append "console=ttyS0 nokaslr" \
  -kernel {/path/to/linux/arch/x86_64/boot/bzImage} \
  -initrd {/path/to/initramfs.cpio.gz}
```

실행하면 부팅과정에서 kernel의 message들이 출력된 후 shell script가 실행된 모습을 볼 수 있다.

## gdb를 이용한 디버깅
QEMU의 `-gdb tcp::1234` 옵션은 gdb server를 1234 포트로 실행하라는 뜻이다. 따라서 localhost:1234에 접속하여 gdb를 attach 시킬 수 있다.

```bash
gdb -ex "target remote localhost:1234" /path/to/linux/vmlinux
```

이제 gdb를 통해 Linux kernel의 소스 코드를 따라가며 디버깅할 수 있다.

> QEMU를 강제로 종료하고 싶다면 ctrl+a => x를 누르면 된다. 정상적으로 종료시키고 싶다면 busybox shell에서 `poweroff -f` 명령어를 입력한다.
{: .prompt-tip }

## arm64 디버깅
만약 x86이 아니라 arm이나 risc-v에 대해 디버깅을 해보고 싶다면, 리눅스 커널과 busybox를 빌드할때 ARCH와 CROSS_COMPILE옵션을 주면 된다.

```bash
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
qemu-system-aarch64 ...
```

> kernel config를 직접 편집해도 된다. 다음 옵션들이 들어있는지 확인하자
> ```
> CONFIG_DEBUG_INFO=y
> CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y
> CONFIG_EXPERT=y
> # CONFIG_DEBUG_INFO_REDUCED is not set
> # CONFIG_RELOCATABLE is not set
> # CONFIG_RANDOMIZE_BASE is not set
> ```
{: .prompt-tip }

busybox를 initramfs/bin에 cp해서 initramfs.cpio.gz를 만들어준다.
qemu command는 다음과 같이 수정해주자.
```bash
qemu-system-aarch64 \
  -nographic \
  -cpu cortex-a57 \
  -machine virt \
  -nodefaults \
  -m 1G \
  -gdb tcp::1234 \
  -append "console=ttyAMA0 nokaslr" \
  -serial mon:stdio \
  -kernel kernel/arch/arm64/boot/Image \
  -initrd initramfs.cpio.gz
```

gdb는 gdb-multiarch를 사용해주어야 한다.
```bash
gdb-multiarch -ex "target remote localhost:1234" /path/to/linux/vmlinux
```
