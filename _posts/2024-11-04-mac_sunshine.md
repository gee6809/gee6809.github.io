---
title: macOS Sequoia(15.0.1) Sunshine 설정하는 법
description: macOS에서 Sunshine과 Moonlight를 사용하여 Windows와 Mac 간에 빠르고 효율적인 원격 연결을 설정하는
  방법을 소개합니다. 기본 VNC보다 속도와 성능이 우수한 오픈소스 솔루션을 찾고 있다면 이 글을 참고하세요. Sunshine을 MacPorts로
  설치하고 필요한 권한을 설정하는 방법을 단계별로 정리했습니다.
categories: Tips
date: 2024-11-04 08:40 +0900
---
Windows 환경과 Mac 환경을 오가며 작업해야 하는 일이 많아졌다.

원격 연결을 사용하기로 결심했고, 최종 후보로 Sunshine을 선택했다.

오픈소스인 Sunshine과 Moonlight가 macOS를 지원하며, 낮은 레이턴시로 유명하다. 그리고 무료다!

[Sunshine 공식 가이드](https://github.com/LizardByte/Sunshine/blob/master/docs/getting_started.md)대로 진행하면 막히는 부분이 있었고, 여기에 그 해결법을 정리해 두려고 한다.

# Macport 설치하기
[MacPorts](https://www.macports.org/install.php)에 접속해 macOS Sequoia v15 pkg 파일을 다운로드한다. 

다운로드한 파일을 더블클릭해 설치하자.

# macport source update
```zsh
sudo nano /opt/local/etc/macports/sources.conf
```
위 명령어를 통해 마지막 줄에 다음 줄을 추가한다.
```
file:///Users/<username>/ports
```

# 코드 빌드 및 설치
```zsh
mkdir -p ~/ports/multimedia/sunshine
cd ~/ports/multimedia/sunshine
curl -OL https://github.com/LizardByte/Sunshine/releases/latest/download/Portfile
cd ~/ports
portindex
sudo port install sunshine
```
공식 가이드대로 위 명령어를 수행한다. 만약 문제없이 설치가 완료됐다면 `Terminal 화면제어 권한 설정`으로 넘어가자! 설치에 성공한 것이다.

나는 아래와 같은 오류가 발생했었다.

```zsh
/opt/local/var/macports/build/_Users_test_ports_multimedia_sunshine/Sunshine/work/Sunshine-0.23.1/src/upnp.cpp:334:23: error: no matching function for call to 'UPNP_GetValidIGD'
  334 |         auto status = UPNP_GetValidIGD(device.get(), &urls.el, &data, lan_addr.data(), lan_addr.size());
      |                       ^~~~~~~~~~~~~~~~
```

# Source Code 수정
[Github Issue](https://github.com/hrydgard/ppsspp/issues/19333)에서 확인한 바에 따르면 UPNP_GetValidIGD()의 파라미터가 5개에서 7개로 늘어나 문제가 발생한다고 한다.

`UPNP_GetValidIGD` 함수에 인자로 nullptr와 0을 추가하면 간단히 해결된다.

```
sudo port clean sunshine
sudo port install sunshine
```
실행 후, 소스코드 다운이 완료되고 빌드가 시작되기 전에 ctrl+c 를 통해 빌드를 취소하자.

다음 명령어로 문제 라인의 코드를 수정한다

```zsh
sudo vi /opt/local/var/macports/build/_Users_test_ports_multimedia_sunshine/Sunshine/work/Sunshine-0.23.1/src/upnp.cpp
```

이후 오류가 났던 line의 UPNP_GetValidIGD() 함수에 nulltpr, 0 을 인자로 추가해주자.

```c
// Example
PNP_GetValidIGD(devlist, urls, datas, lanaddr, sizeof(lanaddr));
                 vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
PNP_GetValidIGD(devlist, urls, datas, lanaddr, sizeof(lanaddr), nullptr, 0);

```

이후 다음 명령어를 차례로 실행한다.
```zsh
sudo port install sunshine
sudo port load sunshine
```

> port는 소스코드를 직접 clone해서 빌드하는 과정을 포함하고 있다. 따라서 소스코드를 수정한 후 `port clean`을 실행하면 수정한 소스코드가 삭제되고, 이후 install 과정에서 원본으로 복구되니 주의하자.
{: .prompt-tip }

# Terminal 화면제어 권한 설정
terminal에서 `$ sunshine` 명령어를 통해 sunshine을 실행하자.

이때 화면 제어 권한이 없다는 오류가 발생할 수 있다.

`시스템 설정 -> 개인정보 보호 및 보안 > 화면 및 시스템 오디오 녹음` 으로 들어가서 터미널 앱을 추가하자.

# 방화벽 해제
원격 제어를 위해 네트워크 접근이 필요하므로 방화벽이 켜져 있으면 외부 접근이 불가하다. 

`시스템 설정 -> 네트워크 -> 방화벽`에서 방화벽을 해제하거나 필요한 포트를 추가해 주자.

# Configure Sunshine
Sunshine을 실행하면 다음과 같은 로그가 출력된다.

```zsh
[2024:11:03:22:12:30]: Info: Configuration UI available at [https://localhost:47901]
```
위 주소로 접속하면 Sunshine 설정 페이지에 접근할 수 있다. 원하는 username과 password를 입력해 설정을 완료하자.

이후, `Configuration -> Network -> Protocol`로 이동해 Sunshine 접속에 사용할 포트를 확인해두자.

![Sunshine Configuration](/assets/img/mac_sunshine/sunshine_configuration.png)

# Connect Sunshine with Moonlight
원격으로 연결할 PC 또는 모바일 기기에 [Moonlight](https://moonlight-stream.org/)를 설치한다.

Moonlight에서 `수동으로 PC 추가 (ctrl + N)`을 선택하고, Sunshine이 실행 중인 PC의 IP 주소와 앞서 확인한 포트를 입력하자.

```
예시: 192.168.0.55:47900
```

마지막으로 Sunshine 설정 페이지에서 Pin을 선택해 페어링을 완료하면 연결이 완료된다.









