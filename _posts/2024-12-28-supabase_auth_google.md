---
title: "[Flutter] Supabase Google Login 지원하기 (Android & iOS)"
description: Supabase와 Flutter를 활용하여 Google 소셜 로그인을 구현하는 방법에 대해 알아봅니다. Native login
  방식을 지원합니다.
categories: Flutter
date: 2024-12-28 00:39 +0900
---
Supabase를 이용해 flutter에서 Social Login을 구현해 보았습니다. 생각보다 엄청 복잡합니다... 😭

중간에 하나라도 빠뜨리면 api 거절을 당하기 때문에, 상세하게 정리하려 노력했습니다.

Google Login과 Apple Login 두 편으로 나누어서 작성했습니다.

Supabase 프로젝트를 이미 생성했다고 가정하고 시작하겠습니다. 만약 아직 생성하지 않으셨다면, [Supabase Dashboard](https://supabase.com/dashboard/projects)에서 프로젝트 하나를 생성해 주시면 됩니다.

---
## Google Cloud Console 설정하기

### 1. **프로젝트 생성**
[Google Cloud Console](https://console.cloud.google.com)에 접속하여 새 프로젝트를 생성합니다.


### 2. **OAuth 2.0 클라이언트 ID 생성**

> Supabase를 통한 social login을 하려면 무조건 `web application` type을 등록해주어야 합니다. 그 후 추가적으로 Native login을 지원하기 위해 `Android` & `iOS` type을 등록해 주시면 됩니다.
{:.prompt-info}

#### **Application Type - Web Application**

- `API 및 서비스 > Credentials` 메뉴로 이동합니다.
![oauth_client](/assets/img/supabase_auth/oauth_client.png)
- 사용자 인증 정보 생성 버튼을 클릭하고 `OAuth 클라이언트 ID`를 선택합니다.
  - 만약 `CONFIGURE CONSENT SCREEN`이 뜬다면 `External`을 선택해 줍니다. (Internal은 조직원으로 등록된 사람만 이용가능합니다. 회사 내부 도구 제작용인듯 합니다.)
  - `OAuth consent screen` 탭에서는 `App name`, `User support email`, `Developer contact information` 등 필수항목을 입력합니다.
  - `Scopes` 탭에서는 `ADD OR REMOVE SCOPES`에서 `../auth/userinfo.email`과 `../auth/userinfo.profile`을 선택합니다.
    ![scopes](/assets/img/supabase_auth/scope.png)
  - `Test users`에서는 oauth를 통해 로그인할 계정을 입력해줍니다. (꼭 필요한 건 아닌 것 같습니다.)
- Application type을 `Web Application`으로 설정합니다. 
- Authorized redirect URIs 항목에 `https://<YOUR_SUPABASE_PROJECT>.supabase.co/auth/v1/callback`을 추가합니다. (SUPABASE_PROJECT는 Supabase 홈페이지 `Project Settings -> API -> Project URL`에서 확인할 수 있습니다.)
![project url](/assets/img/supabase_auth/project_url.png)

- 생성된 Client ID와 Client Secret을 메모장에 복사해 둡니다.

#### **Application Type - Android**
- `API 및 서비스 > Credentials` 메뉴로 이동합니다.
- 사용자 인증 정보 생성 버튼을 클릭하고 `OAuth 클라이언트 ID`를 선택합니다.
- Application type을 `Android`으로 설정합니다. 
- Package name을 `[Bundle ID]`로 입력합니다. (com.example.test)
- SHA-1을 입력합니다. 다음 방법으로 확인할 수 있습니다.
  - 빌드머신에서 `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore` 을 실행합니다.
  - 비밀번호로 `android`를 입력합니다.
  - 출력된 SHA-1 값을 입력합니다.
- 생성된 Client ID을 메모장에 복사해 둡니다.

> SHA-1 값은 OAuth과정에서 App을 증명하기 위한 key값으로 사용됩니다. `~/.android/debug.keystore`은 Debug 빌드할 때 사용되는 앱서명키입니다. 따라서 production 할 때는 play console에서 발급받는 keystore로 바꿔주어야 합니다. 또한 `~/.android/debug.keystore` key값은 빌드머신마다 다르니, 앱을 빌드할 머신의 keystore를 사용했는지 꼭 확인합시다.
{:.prompt-danger}

#### Application Type - iOS
- `API 및 서비스 > Credentials` 메뉴로 이동합니다.
- 사용자 인증 정보 생성 버튼을 클릭하고 `OAuth 클라이언트 ID`를 선택합니다.
- Application type을 `iOS`으로 설정합니다. 
- Bundle ID를 `[Bundle ID]`로 설정합니다. (com.example.test)
- Team ID를 입력합니다. 다음 방법으로 확인할 수 있습니다.
  - [Apple 개발자 사이트](https://developer.apple.com/account/resources/identifiers/list)에 접속합니다.
  - 페이지 우측상단에서 TEAM ID를 확인합니다.
    ![apple team id](/assets/img/supabase_auth/team_id.png)
- 생성된 Client ID을 메모장에 복사해 둡니다.

---

## Supabase Auth Providers 설정하기

### 1. **Supabase 프로젝트 열기**
- [Supabase](https://supabase.com) 대시보드에 접속하여 프로젝트를 선택합니다.

### 2. **Auth 설정**
- 프로젝트 대시보드에서 `Authentication > Providers` 메뉴로 이동합니다.

### 3. **Google 활성화**:
- Google Provider를 활성화합니다. 
- Client ID와 Client Sceret에 **Web Application** 으로 생성한 Client ID와 Client Secret을 입력합니다.
- `Skip nonce checks`를 활성화합니다. iOS 로그인을 지원하기 위해서 필요합니다.
![Skip nonce check](/assets/img/supabase_auth/skip_nonce.png)
  
### 4. **Redirect URL 설정**
- Deeplink URL을 Redirect URL로 허용해줘야 합니다.
- 프로젝트 대시보드에서 `Authentication > URL Configuration` 메뉴로 이동합니다
- Site URL & Redirect URL을 다음과 같이 설정합니다.
  - Site URL: [YOUR_SCHEME]://[YOUR_SCHEME] (com.example.test://home)
  - Redirect URLs: [YOUR_SCHEME]://* (com.example.test://*)

> Redirect URL로 Deeplink를 설정해주어야 인증이 완료된 후에 앱으로 돌아가게 됩니다. [Deeplink 설정하기](#deeplink-설정하기)를 참고해서, flutter가 deeplink를 실행할 수 있도록 꼭 설정해 줍시다.
{:.prompt-info}

---

## Flutter 구현하기
드디어 모든 설정이 끝났습니다! 이제 Flutter에서 구현하는 일만 남았습니다.

### Deeplink 설정하기
먼저 flutter에서 deeplink를 지원하도록 설정해 주어야 합니다.

- `android/app/src/main/AndroidManifest.xml` 파일에 `<intent-filter>`를 추가하여 딥링크를 설정합니다:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Accepts URIs that begin with YOUR_SCHEME://YOUR_HOST -->
    <data android:scheme="com.example.test" android:host="home" /> 
</intent-filter>
```

- `Runner/Info.plist` 파일에 URL Types를 추가합니다:

```xml
<!-- ... other tags -->
<plist>
<dict>
  <!-- ... other tags -->
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.example.app</string>
        <string>com.googleusercontent.apps.[ios type client id]</string>
        <!-- example -->
        <!-- <string>com.googleusercontent.apps.861823949799-vc35cprkp249096uujjn0vvnmcvjppkn</string> -->
      </array>
    </dict>
  </array>
  <!-- ... other tags -->
</dict>
</plist>
```

- `ios/Runner/Info.plist` 파일에 `FlutterDeepLinkingEnabled`를 false로 해줍니다. (optional)
  - [Flutter 예시코드](#flutter-code)에서 저는 `SupabaseSocialAuth`를 사용했습니다. 해당 library는 내부적으로 app_links를 사용합니다. app_links는 `FlutterDeepLinkingEnabled`와 충돌하는 경우가 있기 때문에 false로 지정해주어야 합니다. 다른 library를 사용한다면 굳이 false로 지정하지 않아도 됩니다.

```xml
<dict>
  ...
  <key>FlutterDeepLinkingEnabled</key>
  <false/>
  ...
</dict>
```

---

### Flutter Code
소셜 로그인 기능을 구현하기 위해 `supabase_auth_ui` 패키지를 사용했습니다. 이 패키지를 이용하면 UI 구성과 Social Login을 동시에 해결할 수 있습니다. 아래는 Google 로그인을 처리하는 예제입니다:

예시 코드내 `url`과 `anonKey`는 supabase 홈페이지 `Project Settings -> API` 페이지에서 확인할 수 있습니다.
![url and anon key](/assets/img/supabase_auth/url_anon_key.png)

```bash
flutter pub add supabase_auth_ui
```

```dart
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    // **TODO**
    url: 'https://<your-supabase-url>.supabase.co',
    anonKey: '<your-anon-key>',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Social Login',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SupaSocialsAuth(
          // **TODO: Native Login을 지원하기 위해서 필요합니다**
          nativeGoogleAuthConfig: NativeGoogleAuthConfig(
            iosClientId: '[ios type으로 생성한 Client ID]',
            webClientId: '[web application type으로 생성한 Client ID]'
          ),
          socialProviders: [
            OAuthProvider.google,
          ],
          colored: true,
          onSuccess: (Session response) {
            Navigator.pushReplacementNamed(context, '/home');
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('로그인 실패: $error')),
            );
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome Home!')),
    );
  }
}
```

다음편에서는 Flutter + Supabase조합으로 Apple Login을 구현하는 방법에 대해서 작성하도록 하겠습니다!

참고로 Apple Login은 Google Login보다도 복잡합니다. 😭