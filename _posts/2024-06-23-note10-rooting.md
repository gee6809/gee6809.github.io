---
layout: post
title: 갤럭시 노트10+ 루팅하기 (Android 12)
description: 갤럭시 노트10+를 포함한 삼성 안드로이드 12, 안드로이드 13 기기들의 루팅방법들에 대하여 설명합니다.
categories:
- Tips
date: 2024-06-23 20:33 +0900
---
> 루팅을 진행하게 되면 갤럭시 노트 워런티가 깨지게 됩니다. 추후 순정 펌웨어로 돌린다고 하더라도 삼성페이를 포함한 각종 은행 어플들을 사용할 수 없게 됩니다.
{: .prompt-danger }

안드로이드 버전 12 및 13에는 동일한 방법으로 루팅을 할 수 있습니다.
- 갤럭시 S20, S21, S22 시리즈
- 갤럭시 노트 10, 20 시리즈
- 갤럭시 탭 S6 lite, S7, S8 시리즈

## 모델 확인하기
정확한 모델명과 안드로이드 버전 확인이 필요합니다.
다음에서 확인할 수 있습니다.
- 설정 → 휴대전화 정보 (ex. SM-N976N)
- 설정 → 휴대전화 정보 → 소프트웨어 정보 (ex. Android 13)

## 파일 준비하기
필요한 파일들은 다음과 같습니다. 펌웨어 다운로드는 오래 걸리니 미리 준비하시기를 추천드립니다.

**Odin**
: [https://www.osamsung.com/kr/](https://www.osamsung.com/kr/)  
공식 웹사이트로부터 최신 버전을 다운 받아줍니다. 

**Samsung USB Driver**
: [https://developer.samsung.com/android-usb-driver](https://www.osamsung.com/kr/)  
공식 웹사이트로부터 최신 버전을 다운 받아줍니다. 

**Firmware**
: [https://samfrew.com/firmware/upload/Desc/0/10](https://www.osamsung.com/kr/)  
확인했던 모델명 (SM-N976N)과 OS 버전(13)을 선택합니다.  
핸드폰의 경우 통신사에 따라 Region을 선택해줍니다.

|Region| 통신사|
|---|---|
|KOO | 자급제|
|SKC | SKT |
|KTC | KT |
|LUC | LG |

**Magisk**
: [https://magiskmanager.com/](https://www.osamsung.com/kr/)  
공식 웹사이트로부터 최신 버전을 다운 받아줍니다. 

## Samsung USB Driver 설치하기
Samsung USB Driver의 압축을 풀고, exe파일을 통해 설치합니다.

## Magisk Patch File 준비하기
1) 펌웨어 파일의 압축을 해제합니다.

2) 휴대폰을 컴퓨터에 연결합니다.

3) 펌웨어 파일 중 AP로 시작하는 파일을 휴대폰으로 옮깁니다. (AP_XXX.tar.md5)

4) Magisk.apk 파일을 휴대폰으로 옮겨 설치합니다.

5) Magisk 앱 내에서 '설치'를 선택합니다.

6) '파일 선택'을 탭한 후 AP_XXX.tar.md5 파일을 찾아 선택합니다.

7) '패치' 버튼을 눌러 파일 패치를 시작합니다.

8) 패치가 완료된 파일을 컴퓨터로 복사합니다. (magisk_patched-XXX.tar)

![magisk](/assets/img/rooting/magisk_app.webp){: width="350" }


## Bootloader Unlock 하기
> 이 과정 중에 휴대폰의 모든 정보가 초기화 됩니다. 녹스 워런티는 깨지게 됩니다.
{: .prompt-danger }

1) **개발자 모드 활성화**
   - 설정 → 휴대전화 정보 → 소프트웨어 정보로 이동합니다.
   - '빌드번호'를 여러 번 탭합니다. 
   - 하단에 "개발자 모드가 활성화되었습니다"라는 메시지가 표시됩니다.

2) **개발자 옵션에서 OEM 잠금 해제 활성화**
   - 설정 → 개발자 옵션으로 이동합니다.
   - 'OEM 잠금 해제' 옵션을 찾아 활성화시킵니다.

3) **다운로드 모드로 진입**
   - 휴대전화를 종료합니다.
   - 전원이 꺼진 상태에서 볼륨업과 볼륨다운 버튼을 동시에 누릅니다.
   - 버튼을 누른채로 휴대폰을 USB 케이블로 컴퓨터에 연결합니다.

4) **Bootloader Unlock**
   - 볼륨상 키를 길게 누릅니다 (약 7초)
   - 'Unlock Bootloader?' 메시지가 나타나면, 볼륨 상키를 눌러 잠금 해제를 선택합니다.
   - 휴대폰이 자동으로 재부팅되며, 과정 중 여러 경고 문구가 나타날 수 있습니다.

5) **Unlock 확인**
   - 재부팅이 완료되면 다시 개발자 모드를 활성화합니다.
   - 개발자 옵션에서 'OEM 잠금 해제'가 음영 처리되어 있는지 확인합니다.

![oem](/assets/img/rooting/oem.webp){: width="350" }

> 만약 OEM 잠금 해제 항목이 아예 보이지 않는 경우, 다음과 같이 수행합니다.
> - '설정' → '개발자 옵션' → '시스템 자동 업데이트'를 해제합니다.
> - '설정' → '일반' → '날짜 및 시간' → '날짜 및 시간 자동 설정'을 해제합니다.
> - 날짜를 한 달 전으로 설정 후, 장치를 재부팅합니다.
{: .prompt-tip }

## Firmware 설치하기
1) **휴대폰 준비하기**
   - 휴대폰 전원을 종료하고, 연결된 케이블을 분리합니다.

2) **다운로드 모드 진입**
   - 볼륨업 및 볼륨다운 키를 동시에 누른 채로 휴대폰에 케이블을 연결합니다.
   - 경고 문구가 나타나면, 볼륨업 키를 짧게 눌러 다운로드 모드에 진입합니다.

3) **Odin 설정**
   - 컴퓨터에서 Odin 프로그램을 실행합니다.
   - 각 항목에 맞는 파일을 선택합니다.
     - "BL"에는 BL_XXX.tar.md5 파일을,
     - "AP"에는 magisk_patched-XXX.tar 파일을,
     - "CP"에는 CP_XXX.tar.md5 파일을,
     - "CSC"에는 HOME_CSC_XXX.tar.md5 파일을 로드합니다.
     - "USERDATA"는 비워둡니다.
   - "Options"에서 "Auto Reboot" 옵션의 체크를 해제합니다.

![odin](/assets/img/rooting/odin.webp)


1) **Firmware 설치**
   - Odin에서 "Start" 버튼을 클릭하여 펌웨어 설치를 시작합니다.
   - 설치가 끝나면, '볼륨다운 + 빅스비 버튼'을 길게 누릅니다.
   - 화면이 꺼지면 '볼륨업 + 빅스비 버튼'을 길게 눌러 리커버리 모드로 진입합니다. (휴대폰 케이블이 연결되어 있어야 합니다.)
   - "Wipe data/factory reset"과 "Wipe cache partition"을 선택하여 데이터를 초기화합니다.
   - "Reboot System now"를 선택하여 재부팅합니다.

2) **Magisk 재설치**
   - 부팅이 완료되면, Magisk를 다시 설치합니다.
   - Magisk 앱을 실행 후 재부팅이 필요하다는 알림이 뜨면 확인을 눌러 재부팅합니다.
   - 재부팅 후, 루팅이 성공적으로 완료되었는지 확인합니다.

![rooted_magisk](/assets/img/rooting/rooted_magisk.webp){: width="350" }

> Magisk를 이용한 루팅은 **리커버리 모드**에서만 작동합니다. 일반 부팅은 루팅이 되지 않은 상태로 부팅됩니다. 
> 리커버리 모드로 부팅하기 위해서는, **휴대폰을 컴퓨터에 연결**한 채로 볼륨상키와 전원버튼을 꾹 누르고 있어야 합니다. (이후 Reboot System now를 통해 리커버리 모드로 부팅)
> 만약 리커버리 모드 부팅이 안될 시에는, adb 툴을 이용해 `adb reboot recovery` 명령어를 사용하시면 됩니다.
