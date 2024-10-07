---
title: "[Flutter] integration_test로 다양한 디바이스에서 UI 테스트하기"
description: Flutter의 integration_test를 활용하여 다양한 디바이스에서 UI 테스트를 수행하는 방법을 소개합니다. 실제
  디바이스나 에뮬레이터에서 동시에 테스트를 실행하며, 주로 발생하는 문제 및 해결 팁을 제공합니다. UI 오류나 예외 상황을 사전에 확인하고 다양한
  해상도에서 앱의 동작을 검증하고자 하는 분을 위한 가이드입니다.
categories:
- Flutter
date: 2024-10-07 22:21 +0900
---
Flutter에는 End-to-End test를 위한 integration test가 존재한다. integration test를 이용하면 혹시 모를 UI error나 hang issue, uncaught exception 같은 버그들을 사전에 확인할 수 있다.  
또한 adb로 연결된 여러 디바이스(가상 디바이스 포함)에서 동시에 실행시킬 수 있기 때문에, 다양한 해상도의 디바이스에 대해 UI를 테스트할 때 특히 유용했다.

![Integration Test 실제 실행화면. 다양한 해상도의 디바이스에서 테스트 할 수 있다.](/assets/img/flutter_integration_test/flutter_integration_test_sample.gif)
<p class="image-caption">Integration Test 실제 실행화면. 다양한 해상도의 디바이스에서 테스트 할 수 있다.</p>

## integration_test 실행하기

### integration_test 의존성 추가하기
다음 명령어를 사용하여 의존성을 추가한다.
```bash
flutter pub add 'dev:integration_test:{"sdk":"flutter"}'
```

### integration_test 디렉토리 생성
프로젝트의 최상단에 `integration_test` 폴더를 생성한다.
```
lib/
  ...
integration_test/
  foo_test.dart
  bar_test.dart
```
**꼭 `integration_test` 폴더명을 지켜야 한다.** ~~이것땜에 테스트 안돌아간다고 뻘짓 함~~

### 테스트 코드 작성
`integration_test` 폴더 하위에 테스트하고자 하는 dart 파일을 만든다. (ex. integration_test/app_test.dart)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Counter increments test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Test code here
  });
}
```

### 테스트 실행
```bash
flutter test integration_test
```


## 테스트 코드 작성시 자주 사용할 명령어 예시들

| 명령어                                      | 설명                                                 | 비고                                             |
|------------------------------------------------|----------------------------------------------------------|----------------------------------------------------------|
| `tester.pumpAndSettle()`                        | 모든 위젯 프레임을 빌드하고 애니메이션이 완료될 때까지 대기하기 | timeout 설정 가능 |
| `tester.tap(find.byKey(Key('button_key')))`     | 지정된 Key를 가진 위젯을 찾고 탭하기                        | Key는 프로젝트 코드에 명시적으로 지정해주어야 함       |
| `tester.enterText(find.byType(TextField), 'Hello')` | 텍스트 필드를 찾아 텍스트를 입력하기                      | 여러 `TextField`가 있을 경우 `find.byType(TextField).at(0)` 처럼 특정 위젯을 식별해야 함 |
| `expect(find.text('Hello'), findsOneWidget)`    | 특정 텍스트를 가진 위젯이 화면에 한 개만 있는지 확인하기 |                                                          |
| `await tester.pump(Duration(seconds: 1))`       | 주어진 시간 동안 위젯 트리를 다시 빌드하기 (애니메이션 진행 시 사용) |                                                          |
| `tester.drag(find.byType(ListView), Offset(0, -300))` | 스크롤 가능한 위젯을 주어진 Offset 만큼 드래그하기  | 주어진 Offset 값에 따라 스크롤 방향이 달라짐        |
| `await tester.longPress(find.byType(Button))`   | 지정된 위젯을 길게 누르기                            |                                                          |
| `tester.ensureVisible(find.byType(TextField))`  | 특정 위젯이 보이도록 스크롤하기                        |   |
| `await tester.pumpWidget(MyApp())`              | 새로운 위젯 트리로 화면을 갱신하기                    | 앱의 초기 상태를 설정할 때 유용함                   |


## Tips
### enterText() 재사용 문제 해결
enterText()를 동일한 TextField에 두 번 이상 사용하면 값이 갱신되지 않는 문제가 발생했다.  
[Flutter 이슈](https://github.com/flutter/flutter/issues/134604)를 보면 많은 사람들이 공통적으로 겪는 이슈인듯 하다.  
이 경우, enterText()를 호출하기 전에 tester.testTextInput.register();를 추가하면 해결되더라.

```dart
final foundTextField = find.byType(TextField).at(0);
await tester.testTextInput.register();
await tester.enterText(foundTextField, 'first');
await tester.enterText(foundTextField, 'second'); // tester.testTextInput.register()를 추가해야 제대로 동작함
```

### back button 구현하기
physical back button을 누른걸 모사하고 싶었는데, 해당 기능을 완벽하게 지원하는 api가 없는 것 같았다.  
대신 다음과 같은 대안을 이용할 수 있었다.

- **UI내에 back button이 있는 경우**
```dart
final backButton = find.byTooltip("Back");
await tester.tap(backButton);
await tester.pumpAndSettle();
```

- **단순히 page를 벗어나고 싶은 경우**
```dart
final navigator = tester.state<NavigatorState>(find.byType(Navigator));
navigator.pop();
await tester.pumpAndSettle();
```

### Screenshot 찍기
```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  testWidgets('screenshot', (WidgetTester tester) async {
    // Build the app.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // Trigger a frame.
    await tester.pumpAndSettle();
    await binding.takeScreenshot('screenshot-1');
  });
}
```
위의 코드처럼 `binding.takeScreenshot()`을 이용해서 screenshot을 찍을 수 있다고 한다. 테스트 중 주기적으로 screenshot이 찍히도록 하여 UI가 올바르게 작동하는지 편하게 확인하는데 쓸 수 있을 것 같다. 하지만 나는 그냥 화면녹화로 해결했다.
참고 : [https://github.com/flutter/flutter/tree/main/packages/integration_test](https://github.com/flutter/flutter/tree/main/packages/integration_test)
