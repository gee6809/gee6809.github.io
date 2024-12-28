---
title: "[Flutter] Supabase Apple Login 지원하기 (Android & iOS)"
description: Supabase와 Flutter를 활용하여 Apple 소셜 로그인을 구현하는 방법에 대해 알아봅니다. Native login
  방식을 지원합니다.
categories: Flutter
date: 2024-12-28 17:12 +0900
---
지난 글 [Supabase Google Login 지원하기](/posts/supabase_auth_google/)에 이어서 이번에는 Apple 로그인을 지원하는 방법에 대해서 설명합니다.

안타깝게도 Apple은 Google보다도 더 복잡합니다...

[Youtube 영상](https://youtu.be/6I2JEky20ME?si=T3FoEyKTqQR0Vqj-)을 참고했습니다. 영상 안에서 차근차근 설명해주기 때문에, 따라하다가 막히는 부분이 있으면 참고해보세요.

## Apple 개발자 설정하기

### 1. **Apple Developer 계정 로그인**
- [Apple Developer Certificates](https://developer.apple.com/account/resources/identifiers/list) 페이지에 로그인합니다.

### 2. **App ID 생성**:
![New Identifiers](/assets/img/supabase_auth/new_identifiers.png)

- `Identifiers` 메뉴에서 (+) 아이콘을 클릭합니다.
- "**App ID**"를 선택하고 Continue 합니다.
- "App"을 선택하고 Continue 합니다.
- Bundle ID를 입력해줍니다. (com.example.test)
- Description은 임의로 입력합니다.
- "Capabilities"에서 "Sign in with Apple"을 활성화합니다. (edit은 할 필요 없습니다) 
- Register 버튼을 눌러 등록합니다.

### 3. **Service ID 생성**
- `Identifiers` 메뉴에서 (+) 아이콘을 클릭합니다.
- "**Service ID**"를 선택하고 Continue 합니다.
- Identifier를 입력합니다.
  - App ID의 Bundle ID와 중복이 되면 안됩니다.
  - 보통 `[Bundle ID].service` 형식으로 등록합니다. (com.example.test.service)
- 등록이 완료되면, 생성된 Identifier를 클릭해서 편집으로 들어갑니다.
- "Sign In with Apple"을 활성화하고 Configure를 선택합니다.
- 웹 도메인과 리디렉션 URL을 설정합니다:
  - 웹 도메인: Supabase 프로젝트 도메인 (예: https://<project-id>.supabase.co)
  - 리디렉션 URL: `https://<project-id>.supabase.co/auth/v1/callback`
  ![Url](/assets/img/supabase_auth/url.png)

### 4. **Key 생성**
  - `Keys` 메뉴에서 (+) 아이콘을 눌러 새로운 Key를 생성합니다.
  - Key Name을 임의로 입력해 줍니다.
  - "Sign in with Apple"을 활성화하고 Configure를 선택합니다.
  - App ID로 생성한 Identifier를 선택하고 Register될 때까지 continue를 선택합니다.
  - 등록이 완료되면 "Download"버튼을 통해 Key를 다운로드합니다. AuthKey_XXXXXXXXXX.p8 형식의 파일이 다운됩니다.

### 5. **Supabase용 Secret Key (JWT) 생성**
- Supabase와 연동하기 위해 JWT key를 생성해야 합니다.
- 다음 정보가 필요합니다:
   - **Team ID**: Apple Developer 계정의 고유 식별자.
   - **Key ID**: Apple Developer Console에서 생성한 Private Key의 ID.
   - **Service ID (Client ID)**: Apple 로그인을 위해 생성한 Service ID. (com.example.test.service)
   - **Key File**: 다운로드한 `AuthKey_XXXXXXXXXX.p8` 파일.
![How to find team id and key id](/assets/img/supabase_auth/team_id_and_key_id.png)
- JWT를 생성하기 위해 Ruby 스크립트를 사용했습니다.
- `sudo gem install jwt` 명령어를 실행합니다.
- 아래와 같이 `secret_gen.rb` 파일을 생성합니다:

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
- `ruby secret_gen.rb` 명령어를 실행합니다.
- 생성된 JWT Key를 메모장에 복사합니다.


## Supabase Auth Providers 설정하기

### 1. **Supabase 프로젝트 열기**
  - [Supabase](https://supabase.com) 대시보드에 접속하여 프로젝트를 선택합니다.

### 2. **Auth 설정**
  - 프로젝트 대시보드에서 `Authentication > Providers` 메뉴로 이동합니다.

### 3. **Apple 활성화**:
- Apple Provider를 활성화합니다. 
- Client ID는 "com.example.app.service,com.example.app"로 설정합니다. (테스트했을때, service가 포함된 ID가 앞에 와야 정상동작했었습니다. 이유는 모르겠습니다..)
- Secret Key는 메모장에 적어놨던 JWT KEY를 적어줍니다.

>  Apple 소셜 로그인 설정에서 사용하는 **JWT KEY**는 유효 기간이 최대 6개월(180일)로 제한되어 있습니다. 6개월이 지나면 만료되므로 새로운 JWT를 생성해서 업데이트해야 합니다.
{: .prompt-danger }



## Flutter 구현하기
드디어 모든 설정이 끝났습니다! 이제 Flutter에서 구현하는 일만 남았습니다.

### Deeplink 설정하기
먼저 flutter에서 deeplink를 지원하도록 설정해 주어야 합니다. Google에서 설정해주었던것과 동일합니다.

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

### xcode capability 설정하기
- ios native login을 사용하려면 xcode에서도 "Sign in with Apple"을 설정해줘야 합니다.
- `open ios/Runner.xcworkspace`를 통해 xcode를 실행합니다.
- Runner -> "Targets Runner" -> "Signing & Capabilities" -> "+ Capability" 선택합니다.
- "Sign in with Apple"을 추가합니다.
![xcode capability](/assets/img/supabase_auth/xcode_capability.png)

--- 

### Flutter Code
소셜 로그인 기능을 구현하기 위해 `supabase_auth_ui` 패키지를 사용했습니다. 이 패키지를 이용하면 UI 구성과 Social Login을 동시에 해결할 수 있습니다. 아래는 Apple 로그인을 처리하는 예제입니다:

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
          socialProviders: [
            OAuthProvider.apple,
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
