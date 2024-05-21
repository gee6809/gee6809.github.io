---
title: QEMU Network 설정 방법 (가상머신끼리 통신하기)
categories:
- QEMU
tags:
- QEMU
- network
date: 2024-05-16 13:20 +0900
---
## User Networking (SLIRP)

```
                             +---------------------------+
                             |      Host Machine         |
                             |                           |
                             |   +-------------------+   |
                             |   |    user net       |   |
    Router ------------------|---|  (192.168.0.2)    |   |
 (192.168.0.1)               |   +-------------------+   |
                             |          |                |
                             |          |                |
                             +----------|----------------+
                                        |    
                                        |                   
                             +----------v----------+        
                             |    Virtual Machine  |        
                             |         VM          |        
                             |    (10.0.2.15)      |        
                             +---------------------+        
             
```

가장 쉬운 네트워크 구성 방법입니다. 가상머신의 네트워크를 분리하여 사설 네트워크망을 가지는 방식입니다. 호스트는 일종의 공유기 역할을 하게 됩니다.

가상머신은 호스트를 거쳐 외부 네트워크로 요청을 보낼 수 있습니다. 하지만, 일종의 사설 네트워크망이기 때문에 외부 네트워크에서 VM에 접근하기는 어렵습니다. 따라서 SSH, RDP 등의 기능을 사용하기 위해서는 포트 포워딩을 사용해야 합니다.

### QEMU Argument
```bash
-netdev user,id=usernet,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 -device e1000,netdev=usernet
```
QEMU에 위와 같은 argument를 추가하면 user network를 구성합니다. `hostfwd=tcp::2222-:22`는 호스트의 2222번 포트를 QEMU VM의 22번 포트로 포워딩한다는 것을 의미합니다. 위 그림에서 192.168.0.2:2222로 오는 요청은 10.0.2.15:22로 포워딩 됩니다.



## Bridge / Tap 네트워크 구성
```
                       +---------------------+ 
                       |   Host Machine      | 
                       |                     | 
                       |                     | 
                       |     +-----------+   | 
      LAN  --------------------- eth0    |   |       +-------------------+
 (192.168.0.1)         |     |   tap0 ---------------|        VM0        |
                       |     |   tap1 ------------+  |  (192.168.0.3)    |
                       |     +-----------+   |    |  +-------------------+
                       |         br0         |    |
                       |    (192.168.0.2)    |    |  +-------------------+
                       |                     |    +--|        VM1        |
                       +---------------------+       |  (192.168.0.4)    |
                                                     +-------------------+
```

Tap은 네트워크 데이터 흐름을 다른 방향으로 흘려주는 역할을 합니다. Bridge는 가상의 스위치처럼 동작하며 네트워크들을 하나로 묶어주는 역할을 합니다. Tap과 Bridge는 호스트 머신에서 만들어줘야 합니다.

### Bridge 추가하기
```bash
sudo nmcli c add type bridge ifname br0 con-name br0 #Bridge 생성하기
sudo nmcli c add type ethernet slave-type bridge con-name eth-br0 ifname eth0 master br0 #eth0를 bridge에 연결하기
sudo nmcli c up eth-br0 #bridge 연결 활성화하기
```
eth0는 자신의 네트워크 인터페이스 이름으로 바꿔주어야 합니다. `ifconfig` 명령어를 통해 쉽게 확인 가능합니다.
이 작업을 통해 eth0를 통해 연결되어 있던 네트워크가 해제되고, eth-br0를 통해 통신하도록 변경됩니다. 따라서 eth0의 연결이 잠시 끊길 수 있으므로, 원격으로 작업하시는 분들은 주의하시기 바랍니다.


### Tap 추가하기
```bash
sudo ip tuntap add dev tap0 mode tap user $(whoami)
sudo brctl addif br0 tap0
sudo ifconfig tap0 up
```
tap0를 생성하고 br0 브릿지에 추가합니다.

### QEMU Argument
```bash
-netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000,netdev=net0
```
tap0를 이용해서 QEMU VM을 구동합니다. tap0는 br0로 eth0와 묶여있기 때문에, 호스트와 같은 대역의 IP를 사용할 수 있습니다. LAN에 물려있는 공유기가 DHCP서버로써 가상머신들에도 ip를 할당해주게 됩니다.


> 만약 위의 작업을 하고도 tap 네트워크가 활성화되지 않는다면, 다음과 같은 작업을 추가로 해줍니다.
> 1) /etc/sysctl.d/bridge-filter.conf에 다음 내용 추가
> ```
> net.bridge.bridge-nf-call-ip6tables=0
> net.bridge.bridge-nf-call-iptables=0
> net.bridge.bridge-nf-call-arptables=0
> ```
> 
> 2) /etc/udev/rules.d/99-bridge-filter.rules 에 다음 내용 추가
> ```
> ACTION=="add", SUBSYSTEM=="module", KERNEL=="br_netfilter", RUN+="/sbin/sysctl -p /etc/> sysctl.d/bridge-filter.conf"
> ```
> 3) 재부팅
{: .prompt-warning }

## 두개 이상의 VM이 사설망 공유하도록 만들기
```
                       +---------------------+ 
                       |   Host Machine      | 
                       |                     | 
                       |                     | 
                       |    +-------------+  | 
      LAN  -----------------|     eth0    |  | 
(192.168.0.1)          |    |(192.168.0.2)|  |
                       |    +-------------+  | 
                       |                     | 
                       |                     | 
                       |     +-----------+   |       +-------------------+
                       |     |   tap0    |-----------|        VM0        |
                       |     |   tap1    |--------+  |     (10.0.2.2)    |
                       |     +-----------+   |    |  +-------------------+
                       |         br0         |    |
                       |      (10.0.2.1)     |    |  +-------------------+
                       |                     |    +--|        VM1        |
                       +---------------------+       |     (10.0.2.3)    |
                                                     +-------------------+
```
여기서는 외부망과 연결되지 않은 채로, VM끼리의 통신망을 구축하는 방법을 소개합니다. 여기서도 기본적으로 bridge와 tap interface를 사용합니다.

먼저 host PC에서 다음과 같이 br0, tap0, tap1을 구성해줍니다.
```bash
sudo ip tuntap add dev tap0 mode tap
sudo ip tuntap add dev tap1 mode tap
sudo brctl addbr br0
sudo brctl addif br0 tap0
sudo brctl addif br0 tap1
sudo ifconfig tap0 up
sudo ifconfig tap1 up
```
DHCP서버 역할을 해주던 공유기가 없으므로 직접 ip를 설정해주어야 합니다. 다음과 같이 br0의 ip를 설정해 줍니다. 해당 ip 주소는 가상머신들의 게이트웨이 주소가 될 예정입니다.
```bash
sudo ifconfig br0 10.0.2.1 netmask 255.255.255.0 up
```
두 VM에 다음 argument를 이용해서 네트워크를 구성해줍니다. 이때 주의할 점은 두 머신의 MAC 주소를 겹치지 않도록 명시적으로 설정해주어야 한다는 점입니다.
```bash
#VM0
-netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000,netdev=net0,mac=52:54:00:12:34:56

#VM1
-netdev tap,id=net0,ifname=tap1,script=no,downscript=no -device e1000,netdev=net0,mac=52:54:00:12:34:57
```

두 가상머신을 켰다면, 마찬가지로 ip를 수동으로 설정해주어야 합니다. Windows 머신이라면 어댑터 설정 변경, Linux라면 다음 명령어를 이용합니다.
```bash
#VM0
sudo ifconfig eth0 10.0.2.2 netmask 255.255.255.0 up
sudo route add default gw 10.0.2.1

#VM1
sudo ifconfig eth0 10.0.2.3 netmask 255.255.255.0 up
sudo route add default gw 10.0.2.1
```

이제 호스트, 가상머신끼리 각각의 ip 주소를 통해 통신할 수 있습니다.
```bash
ping 10.0.2.1
ping 10.0.2.2
ping 10.0.2.3
```

> 만약 ping이 가지 않는다면 가상머신들의 방화벽을 꺼보시기 바랍니다.
{: .prompt-warning }
