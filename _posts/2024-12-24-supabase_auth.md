---
title: "[Flutter] Supabase Social Login 지원하기 (Google & Apple - OAuth 방식)"
description: Supabase와 Flutter를 활용하여 Google과 Apple 소셜 로그인을 구현하는 방법에 대해 알아봅니다.
categories: Flutter
date: 2024-12-24 23:23 +0900
---

## Supabase Auth Providers 설정하기

Supabase 프로젝트에서 소셜 로그인 기능을 활성화하려면 Auth Providers 설정을 해야 합니다. 제가 작업하면서 진행했던 과정을 공유합니다:

### 1. **Supabase 프로젝트 열기**
  - [Supabase](https://supabase.com) 대시보드에 접속하여 프로젝트를 선택합니다.

### 2. **Auth 설정**
  - 프로젝트 대시보드에서 `Authentication > Providers` 메뉴로 이동합니다.

### 3. **Google & Apple 활성화**:
  - **Google**: Google Provider를 활성화합니다. Client ID와 Client Sceret은 [Google Cloud Console 설정](#google-cloud-console-설정하기)을 완료하면 생성됩니다.
  - **Apple**: Apple Provider를 활성화합니다. Client ID는 "com.example.app,com.example.app.service"로 설정합니다. Client Secret은 [Apple 설정](#apple-설정하기)을 완료하면 생성됩니다.

### 4. **Redirect URL 설정**
  - Deeplink URL을 Redirect URL로 허용해줘야 합니다. (Deeplink 설정은 [Deeplink 설정하기](#deeplink-설정하기) 참고)
  - "Authentication" -> "URL Configuration" 페이지로 들어갑니다.
  - Site URL & Redirect URL을 다음과 같이 설정합니다.
    - Site URL: com.example.app://home
    - Redirect URLs: com.example.app://*


![deep link](/assets/img/supabase_auth/deeplink.png)
---

## Google Cloud Console 설정하기

Google 로그인을 설정하려면 Google Cloud Console에서 클라이언트 ID와 클라이언트 시크릿을 생성해야 합니다:

1. **프로젝트 생성**: [Google Cloud Console](https://console.cloud.google.com)에 접속하여 새 프로젝트를 생성합니다.
2. **OAuth 2.0 클라이언트 ID 생성**:
   - `API 및 서비스 > 사용자 인증 정보` 메뉴로 이동합니다.
   - 사용자 인증 정보 생성 버튼을 클릭하고 `OAuth 클라이언트 ID`를 선택합니다.
   - 애플리케이션 유형을 `웹 애플리케이션`으로 설정합니다.
   - 승인된 리디렉션 URI에 `https://<YOUR_SUPABASE_PROJECT>.supabase.co/auth/v1/callback`을 추가합니다. (Supabase Providers 설정에 있습니다.)
3. **Supabase 클라이언트 ID & 시크릿 입력**: 생성된 클라이언트 ID와 클라이언트 시크릿을 복사하여 Supabase Auth Providers 설정에 입력합니다.

---

## Apple 설정하기

Apple 로그인은 많이 복잡합니다. 😂
[Youtube 영상](https://youtu.be/6I2JEky20ME?si=T3FoEyKTqQR0Vqj-)을 참고했습니다. 영상 안에서 차근차근 설명해주기 때문에, 이 글대로 따라하다가 막히는 부분이 있으면 참고해보세요

### 1. **Apple Developer 계정 로그인**
  - [Apple Developer](https://developer.apple.com/account/resources/identifiers/list) 페이지에 로그인합니다.

### 2. **App ID 생성**:
  - `Identifiers` 메뉴에서 새로운 App ID를 생성합니다.
  - Capabilities에서 "Sign in with Apple"을 활성화합니다.

### 3. **Service ID 생성**
  - OAuth를 이용하려면 Service ID도 생성해주어야 합니다.
  - Identifiers에서 "Service ID"를 추가합니다:
     - 예: `com.example.app.service` 형식으로 입력합니다.
     - 웹 도메인과 리디렉션 URL을 설정합니다:
       - 웹 도메인: Supabase 프로젝트 도메인 (예: https://<project-id>.supabase.co)
       - 리디렉션 URL: `https://<project-id>.supabase.co/auth/v1/callback`
     - ![Url](/assets/img/supabase_auth/url.png)

### 4. **Key 생성**
  - `Keys` 메뉴에서 새로운 Key를 생성합니다.
  - Key를 다운로드합니다. AuthKey_XXXXXXXXXX.p8 형식의 파일이 다운됩니다.

### 5. **Supabase용 Secret Key (JWT) 생성**
  - Supabase와 연동하기 위해 JWT key를 생성해야 합니다.
  - 다음 정보가 필요합니다:
     - **Team ID**: Apple Developer 계정의 고유 식별자.
     - **Key ID**: Apple Developer Console에서 생성한 Private Key의 ID.
     - **Service ID (Client ID)**: Apple 로그인을 위해 생성한 Service ID.
     - **Private Key**: 다운로드한 `AuthKey_XXXXXXXXXX.p8` 파일의 내용.
![How to find team id](/assets/img/supabase_auth/team_id.png)

### 6. **Ruby Script를 통한 JWT 생성**:
  - JWT를 생성하기 위해 Ruby 스크립트를 사용했습니다. 다른 방법도 있지만, 영상을 따라 Ruby로 작업했습니다.
  - `sudo gem install jwt` 명령어를 실행합니다.
  - 아래와 같이 `secret_gen.rb` 파일을 생성합니다:
  - `ruby secret_gen.rb` 명령어를 실행합니다.

```ruby
require "jwt"

key_file = "Path to the private key"
team_id = "Your Team ID"
client_id = "The Service ID of the service you created"
key_id = "The Key ID of the private key"
validity_period = 180 # In days. Max 180 (6 months) according to Apple docs.

private_key = OpenSSL::PKey::EC.new IO.read key_file

token = JWT.encode(
	{
		iss: team_id,
		iat: Time.now.to_i,
		exp: Time.now.to_i + 86400 * validity_period,
		aud: "https://appleid.apple.com",
		sub: client_id
	},
	private_key,
	"ES256",
	header_fields=
	{
		kid: key_id 
	}
)
puts token
```

### 7. **Supabase 클라이언트 ID & 시크릿 입력**
  - 생성된 클라이언트 ID와 클라이언트 시크릿을 복사하여 Supabase Auth Providers 설정에 입력합니다.
    - 클라이언트 ID: Apple 로그인을 위해 생성한 Service ID. (ex. com.example.app.service)
    - 클라이언트 시크릿: JWT key


>  Apple 소셜 로그인 설정에서 사용하는 **클라이언트 시크릿 (JWT)**는 유효 기간이 최대 6개월(180일)로 제한되어 있습니다. 6개월이 지나면 기존의 클라이언트 시크릿이 만료되므로 새로운 JWT를 생성해서 업데이트해야 합니다.
{: .prompt-danger }

---

## Flutter 구현 예시

### Deeplink 설정하기

1) `android/app/src/main/AndroidManifest.xml`에 `<intent-filter>`를 추가하여 딥링크를 설정합니다:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.example.app" android:host="home" />
</intent-filter>
```

2) iOS의 경우, `Runner/Info.plist` 파일에 URL Types를 추가합니다:

```xml
<dict>
  ...
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.example.app</string>
      </array>
    </dict>
  </array>
  ...
</dict>

```

3) `Runner/Info.plist` 파일에 `FlutterDeepLinkingEnabled`를 false로 해줍니다. (optional)

```xml
<dict>
  ...
  <key>FlutterDeepLinkingEnabled</key>
  <false/>
  ...
</dict>
```
> 밑의 [Flutter Code](#flutter-code)에서 저는 `SupabaseSocialAuth`를 사용했습니다. 해당 library는 내부적으로 app_links를 사용합니다. app_links는 `FlutterDeepLinkingEnabled`와 충돌하는 경우가 있기 때문에 false로 지정해주어야 합니다. 다른 library를 사용한다면 굳이 false로 지정하지 않아도 됩니다.
{:.prompt-info}

---

### Flutter Code
소셜 로그인 기능을 구현하기 위해 `supabase_auth_ui` 패키지를 사용했습니다. 이 패키지를 이용하면 UI 구성과 Social Login을 쉽게 구현할 수 있었습니다. 아래는 Google과 Apple 로그인을 처리하는 예제입니다:

url과 anonKey는 supabase 홈페이지 "Project Settings" -> "API" 페이지에서 확인할 수 있습니다.

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
          socialProviders: [
            OAuthProvider.apple,
            OAuthProvider.google,
          ],
          colored: true,
          redirectUrl: 'com.example.app://home',
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

### xcode capability 설정
ios native login을 사용하려면 xcode에서도 "Sign in with Apple"을 설정해줘야 합니다.

```bash
open ios/Runner.xcworkspace/
```
위 명령어로 xcode를 실행하여 "Sign in with Apple" capability를 추가해줍니다.
![xcode capability](/assets/img/supabase_auth/xcode_capability.png)