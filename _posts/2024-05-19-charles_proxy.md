---
layout: post
title: Charles Proxy로 안드로이드 앱 HTTPS 패킷 분석하기
author: jeuk
categories:
- Tips
tags:
- android
date: 2024-05-19 18:21 +0900
---
Charles Proxy를 이용하면, 안드로이드 어플들이 보내는 패킷들을 분석할 수 있습니다.

## Charles Proxy 설치 및 환경설정
- [https://www.charlesproxy.com/](https://www.charlesproxy.com/) 에서 각 OS에 맞는 버전을 다운받습니다. 
- Proxy -> Proxy settings 에서 http proxy port를 확인해줍니다.
![alt text](/assets/img/charles_proxy/proxy_port.png)

## Android Proxy 설정
- Android 디바이스에서 WIFI 설정으로 들어갑니다.
- Proxy 설정으로 진입합니다.
- Charles Proxy를 실행하는 PC의 ip와, 이전에 확인했던 port값을 입력합니다.
![alt text](/assets/img/charles_proxy/wifi_settings.png)
- Android device에서 chrome을 실행하고 아무 페이지에 진입합니다.
- Charles Proxy에 연결을 허용하겠냐는 팝업이 뜨면 "Allow"를 클릭합니다.
![alt text](/assets/img/charles_proxy/allow.png)

## Packet 녹화
- Charles Proxy에서 "Start Recording" 버튼을 누르면 기록을 시작합니다.
![alt text](/assets/img/charles_proxy/recording.png)