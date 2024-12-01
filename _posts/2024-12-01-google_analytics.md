---
title: "[Flutter] Google Analytics 연동하기"
description: Flutter 프로젝트에 Google Analytics를 연동하는 방법에 대한 가이드
categories: Flutter
date: 2024-12-01 18:18 +0900
---
## Firebase 프로젝트 생성

Firebase Console(https://console.firebase.google.com/)에 접속하여 새 프로젝트를 생성합니다.
1. 프로젝트 추가 버튼을 클릭합니다.

2. 프로젝트 이름을 입력한 후 Firebase 사용 약관에 동의합니다.

3. Google Analytics 사용 여부를 선택한 후 프로젝트를 생성합니다.

## Google Analytics 설정

1. Firebase Console에서 프로젝트를 생성한 후, **Google Analytics**를 활성화합니다.
   - **Firebase > 애널리틱스 > Google 애널리틱스 사용 설정**을 클릭합니다.

2. Firebase Console의 좌측 상단 메뉴에서 **프로젝트 개요** 오른쪽의 설정 아이콘(톱니바퀴)을 클릭합니다.
![firebase_setting_icon](/assets/img/google_analytics/firebase_setting_icon.png)

   - **프로젝트 설정**을 선택합니다.


3. iOS와 Android 각각의 설정을 완료합니다.
![fire_base_ios_android_icon](/assets/img/google_analytics/fire_base_ios_android_icon.png)

   - 각 플랫폼에 맞는 Google Analytics 구성 파일을 다운로드합니다.

   **Android**:

   - `google-services.json` 파일을 다운로드하여 Flutter 프로젝트의 다음 경로에 추가합니다:
     ```
     YOUR_FLUTTER_PROJECT/android/app/google-services.json
     ```

   **iOS**:

   - `GoogleService-Info.plist` 파일을 다운로드하여 Flutter 프로젝트의 다음 경로에 추가합니다:
     ```
     YOUR_FLUTTER_PROJECT/ios/Runner/GoogleService-Info.plist
     ```
   - Xcode에서 프로젝트를 열고, 왼쪽 프로젝트 탐색기에서 Runner 폴더를 우클릭한 후, 'Add Files to "Runner"'를 선택합니다.
   - GoogleService-Info.plist 파일을 선택하여 추가합니다.<br/>
![xcode_googleservice_info_json](/assets/img/google_analytics/xcode_googleservice_info_json.png)

## Firebase CLI 설치 및 로그인
1. Node.js 및 npm 설치:
  Firebase CLI는 Node.js가 필요하므로 터미널에서 다음 명령어를 실행하여 Node.js와 npm을 설치합니다:
  ```bash
  sudo apt update
  sudo apt install -y nodejs npm
  ```

2. Firebase CLI 설치:
  Firebase CLI를 npm으로 설치합니다:
  ```bash
  sudo npm install -g firebase-tools
  ```

3. Firebase CLI 로그인:
  Firebase 계정에 로그인합니다:
  ```bash
  firebase login
  ```
  이 명령어를 실행하면 브라우저가 열리고 Firebase 계정에 로그인할 수 있습니다.

4. Firebase에서 프로젝트 설정 페이지에 접속합니다. <br/>
![firebase_setting_icon](/assets/img/google_analytics/firebase_setting_icon.png)

5. Flutter를 선택합니다. <br/>
![ga_set_flutter](/assets/img/google_analytics/ga_set_flutter.png)

6. FlutterFire CLI 설치:
  Firebase의 가이드에 따라 다음 명령어를 실행합니다:
  ```bash
  cd YOUR_FLUTTER_PROJECT
  dart pub global activate flutterfire_cli
  export PATH=$PATH:$HOME/.pub-cache/bin
  flutterfire configure --project=YOUR_PROJECT_ID
  ```
  이 명령어를 실행하면 firebase_options.dart 파일이 생성됩니다. 이 파일은 Firebase.initializeApp()에 사용됩니다.


## Flutter에 코드 추가
main.dart 파일에 Firebase와 Google Analytics 초기화 코드를 추가합니다:

![google analytics flutter code](/assets/img/google_analytics/flutter_ga_code.png)

Flutter 프로젝트를 실행하여 Google Analytics가 올바르게 동작하는지 확인합니다.


## Firebase에서 확인하기
1. Firebase Console에 접속합니다.
https://console.firebase.google.com/
2. 좌측 메뉴에서 애널리틱스 > DebugView로 이동합니다.
3. 터미널에서 다음 명령어를 실행합니다.
  ```bash
  adb shell setprop debug.firebase.analytics.app PACKAGE_ID # ex) adb shell setprop debug.firebase.analytics.app com.company.example
  ```
4. 앱에서 트리거된 이벤트가 표시되는지 확인합니다. <br/>
![firebase_debugview](/assets/img/google_analytics/firebase_debugview.png)