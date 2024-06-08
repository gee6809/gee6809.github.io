---
layout: post
title: Charles Proxy로 안드로이드 HTTP 패킷 분석하기
description: Charles Proxy를 이용하여 안드로이드 어플들이 보내는 패킷을 후킹하는 방법에 대하여 안내합니다.
author: jeuk
categories:
- Tips
tags:
- android
date: 2024-05-19 18:21 +0900
---
Charles Proxy를 이용하면, 안드로이드에서 보내는 패킷들을 분석할 수 있습니다.

## Charles Proxy 설치 및 환경설정
- [https://www.charlesproxy.com/](https://www.charlesproxy.com/) 에서 각 OS에 맞는 버전을 다운받습니다. ubuntu에서는 다음 명령어로 쉽게 설치할 수 있습니다.
```bash
wget -qO- https://www.charlesproxy.com/packages/apt/charles-repo.asc | sudo tee /etc/apt/keyrings/charles-repo.asc
sudo sh -c 'echo deb [signed-by=/etc/apt/keyrings/charles-repo.asc] https://www.charlesproxy.com/packages/apt/ charles-proxy main > /etc/apt/sources.list.d/charles.list'
sudo apt-get update && sudo apt-get install charles-proxy
charles
```
- Proxy -> Proxy settings 에서 http proxy port를 확인해줍니다.
![alt text](/assets/img/charles_proxy/proxy_port.png)

## Android Proxy 설정
- Android 디바이스에서 WIFI 설정으로 들어갑니다.
- 연결되어 있는 WIFI의 Proxy 설정으로 진입합니다.

![alt text](/assets/img/charles_proxy/each_wifi.png){: width="400"}

![alt text](/assets/img/charles_proxy/proxy_tab.png){: width="400"}

- Charles Proxy를 실행하는 PC의 ip와, 이전에 확인했던 port값을 입력합니다.

![alt text](/assets/img/charles_proxy/wifi_settings.png)

- Android device에서 chrome을 실행하고 아무 페이지에 진입합니다.
- Charles Proxy에서 연결을 허용하겠냐는 팝업이 뜨면 "Allow"를 클릭합니다.
![alt text](/assets/img/charles_proxy/allow.png)

## Packet 녹화
- Charles Proxy에서 "Start Recording" 버튼을 누르면 기록을 시작합니다.
![alt text](/assets/img/charles_proxy/recording.png)

- 핸드폰으로 웹사이트에 접근하면 charles proxy에서 패킷을 기록합니다.

## SSL 인증서 설치 (https)
위 작업만으로도 `http://` 웹사이트들의 패킷은 전부 살펴볼 수 있습니다. 하지만 `https://` 웹사이트들은 SSL 암호화를 이용하기 때문에 패킷들이 깨져보이게 됩니다. 
이를 해결하기 위해 charles proxy에서 SSL 인증서를 받아서 설치해주어야 합니다. 또한 안드로이드의 SSL Pinning을 우회하기 위해서 사용자 인증서를 시스템 인증서로 등록해주는 작업이 필요합니다. 이때 루트 권한이 필요합니다.
> 안드로이드에서 암호화 패킷을 확인하기 위해서는 루팅된 디바이스가 필요합니다.
{: .prompt-warning }

### SSL 프록시 활성화:
- Charles Proxy를 실행합니다.
- Proxy 메뉴로 이동한 다음 SSL Proxying Settings를 선택합니다.
- SSL Proxying을 활성화하고 Add 버튼을 클릭하여 HTTPS 트래픽을 모니터링할 도메인을 추가합니다. (*를 입력하여 모든 도메인의 HTTPS 트래픽을 모니터링할 수 있습니다.)

### 컴퓨터에 SSL 인증서 설치
- Help > SSL Proxying > Install Charles Root Certificate를 선택합니다.
- 설치 후 인증서를 신뢰하는지 묻는 팝업이 뜨면 신뢰를 선택합니다.

> ubuntu에서 설치가 잘 안될 시에, 수동으로 설치할 수 있습니다.
> - Help > SSL Proxying > Save Charles Root Certificate를 선택합니다.
> - Binary certificate (.cer)을 선택하고 확인을 누릅니다.
> - 다음 명령어를 통해 시스템 인증서 저장소를 업데이트합니다
```bash
sudo openssl x509 -inform DER -in ~/charles-ssl-proxying-certificate.cer -out /usr/local/share/ca-certificates/charles-ssl-proxying-certificate.crt
cd /usr/local/share/ca-certificates
sudo update-ca-certificates
```
{: .prompt-info }


### 안드로이드 장치에 인증서 설치
- 모바일 디바이스에서 http://chls.pro/ssl에 접속합니다. (charles proxy에 연결되어 있어야 합니다.)
- Charles 인증서를 다운로드합니다.
- HTTPS 트래픽을 후킹하기 위해 Android에서 신뢰할 수 있는 시스템 CA 인증서로 보이도록 해줘야 합니다. 다음 명령어를 수행합니다.
> Android 인증서 저장소:
> - 시스템 저장소: /system/etc/security/cacerts/
> - 사용자 저장소: /data/misc/user/0/cacerts-added/
{: .prompt-info }

```bash
# 안드로이드 기기에 다운로드 했던 charles 인증서 파일을 데스크탑으로 옮겨서 작업합니다.
openssl x509 -inform PEM -subject_hash_old -in your_certificate.pem.crt | head -1 # 해쉬값이 나옵니다 (ex. abcdef12)
mv your_certificate.pem.crt your_hash.0 # ex. mv charle-proxy-ssl-proxying-certificate.pem.crt abcdef12.0
adb push your_hash.0 /data/local/tmp/

adb shell
su
mkdir -p -m 700 /data/local/tmp/htk-ca-copy
cp /system/etc/security/cacerts/* /data/local/tmp/htk-ca-copy/
mount -t tmpfs tmpfs /system/etc/security/cacerts
mv /data/local/tmp/htk-ca-copy/* /system/etc/security/cacerts/
mv /data/local/tmp/your_hash.0 /system/etc/security/cacerts/
chown root:root /system/etc/security/cacerts/*
chmod 644 /system/etc/security/cacerts/*
chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*

rm -r /data/local/tmp/htk-ca-copy
```
> 참고사이트: https://httptoolkit.com/blog/intercepting-android-https/
{: .prompt-info}

- 몇번의 재부팅을 해줍니다.  
- Android 기기 설정 > 생체 인식 및 보안 > 기타 보안 설정 > 인증서 확인에서 "XK72 Ltd"가 보이면 성공입니다.

![alt text](/assets/img/charles_proxy/https_success.png)
