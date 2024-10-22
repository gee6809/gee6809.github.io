---
title: "[Flutter] 비동기 함수에서 파라미터 사용 시 주의할 점"
description: 비동기 함수에서 값 타입과 참조 타입을 전달할 때 생길 수 있는 문제를 예시 코드와 함께 설명한다.
categories:
- Flutter
date: 2024-10-22 23:13 +0900
---
`FutureBuilder`를 이용해 HTTP 요청이 완료되면 `Text` 위젯을 리턴해주는 함수를 만들었는데, HTTP 요청이 정상적으로 완료되었음에도 불구하고 값이 제대로 바뀌지 않는 상황을 겪었다.

이 문제는 비동기 함수에서의 **값 타입**과 **참조 타입**의 차이에서 발생한 것이었다.

비동기 함수는 코드의 실행 순서가 예기치 않게 뒤섞일 수 있기 때문에, 값 타입과 참조 타입의 동작 방식 차이가 큰 영향을 미친다.

이를 더 잘 이해하기 위해, 다음 예시 코드를 살펴보자.

## 예시 코드
```dart
class Wrapper {
  String str;

  Wrapper(this.str);
}

Future<void> foo(String plainStr, Wrapper wrappedStr) async {
  print('1) plainStr: $plainStr');
  print('1) wrappedStr: ${wrappedStr.str}');

  await Future.delayed(Duration(seconds: 1));

  print('2) plainStr: $plainStr');
  print('2) wrappedStr: ${wrappedStr.str}');
}

void main() {
  String plainStr = 'First';
  Wrapper wrappedStr = Wrapper('First');
  foo(plainStr, wrappedStr);
  plainStr = 'Second';
  wrappedStr.str = 'Second';
  print('main exit');
}

```
위 코드의 실행결과는 다음과 같다.
```
1) plainStr: First
2) wrappedStr: First
main exit
1) plainStr: First
2) wrappedStr: Second
```

## 왜 이런 결과가 나오는가?
plainStr는 String 타입으로, Dart에서는 기본형 데이터는 **값(value)**으로 전달된다. 함수에 전달된 시점 이후로는 함수 내부의 plainStr과 원래의 plainStr이 서로 독립된 변수가 된다. 그래서 plainStr의 값이 "First"로 계속 유지된 것이다.

반면, wrappedStr는 클래스 인스턴스이기 때문에 **참조(reference)**로 전달된다. 함수가 await로 대기하는 동안 wrappedStr.str의 값이 "Second"로 바뀌면서, 함수 내부에서도 그 변경이 반영되었다. 이렇게 참조로 전달된 객체는 외부에서 수정되면, 함수 내부에서도 그 변화가 그대로 반영된다.

## 요약
- 기본형 데이터는 값 복사로 전달되기 때문에, 함수 내부에서의 값 변경에 영향을 주지 않는다.
- 객체는 참조로 전달되므로, 외부에서 해당 객체를 수정하면 함수 내부에도 그 변화가 반영된다.
