---
title: "[Flutter] 위젯의 Size 결정 원칙"
description: Flutter 위젯의 크기와 위치를 결정하는 원칙인 'Constraints go down. Sizes go up. Parent
  sets position.'을 이해하고 주요 위젯의 크기 결정 방식을 분석합니다.
categories: Flutter
tags:
- Flutter Widget
date: 2024-08-04 12:02 +0900
---
## Flutter의 Constraints 및 Size 결정 원칙
Flutter에서 Widget의 크기와 위치는 다음 한 문장으로 정리할 수 있다.

**"Constraints go down. Sizes go up. Parent sets position."**

부모는 자식에게 Constraints를 주고, 자식은 자신의 Size를 결정해서 부모에게 알린다. 부모는 자식의 크기 정보들을 바탕으로 위치를 결정한다.

1. **Constraints의 전달**:
  - 부모 위젯은 자식 위젯에게 constraints를 전달한다. 이 constraints는 자식 위젯이 가질 수 있는 최소 및 최대 크기를 정의한다.

2. **자식 위젯의 크기 결정**:
  - 자식 위젯은 부모로부터 받은 constraints를 기반으로 자신의 크기를 결정한다.
  - 자식 위젯이 자신의 크기를 결정한 후, 부모 위젯에게 자신이 결정한 크기를 보고한다.

3. **부모 위젯의 크기 결정**:
  - 부모 위젯은 자식 위젯의 크기와 자신이 가진 constraints를 기반으로 자신의 크기를 결정한다.
  - 부모 위젯은 여러 자식 위젯이 있는 경우, 자식 위젯의 크기와 위치를 조정하여 전체 레이아웃을 구성한다.

## 주요 위젯의 크기 결정 방식

| 위젯 유형 | 자식에게 부과하는 제약 조건 | 자신의 사이즈 결정 방식 |
|-------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------|
| `Container` | 자신이 받은 constraints를 그대로 자식에게 전달. (width, height가 명시된 경우 해당 크기를 기준으로 constraints를 설정) | 자식의 크기와 자신의 constraints에 따라 크기 결정 |
| `Row` | 부모의 constraints 내에서 자식들에게 가능한 최대 가로 크기를 할당. 세로 크기는 부모의 constraints에 따름 | 자식들의 가로 합과 constraints에 따라 크기 결정 |
| `Column` | 부모의 constraints 내에서 자식들에게 가능한 최대 세로 크기를 할당. 가로 크기는 부모의 constraints에 따름 | 자식들의 세로 합과 constraints에 따라 크기 결정 |
| `Expanded` | 부모의 남은 공간을 최대한 활용하도록 자식에게 제약 조건을 부과 | 부모의 남은 공간을 차지하며 flex 비율에 따라 크기 결정 |
| `SizedBox` | 고정된 width와 height를 자식에게 전달 | 명시된 width와 height를 사용 |
| `Padding` | 자식의 constraints를 padding 값만큼 줄여서 전달 | 자식의 크기 + padding 값 |
| `Align` | 자식에게 자신의 constraints를 전달 | 자식의 크기나 constraints 중 작은 값 |
| `Center` | 자식에게 자신의 constraints를 전달 | 자식의 크기나 constraints 중 작은 값 |
| `FittedBox` | 자식에게 자신의 constraints를 전달, 자식의 크기를 constraints에 맞춤 | 부모의 constraints에 맞게 자식 크기 조정 |
| `AspectRatio` | 자식의 constraints를 AspectRatio에 맞게 조정 | 주어진 AspectRatio에 따라 크기 결정 |
| `Flexible` | 자식에게 주어진 비율만큼의 공간을 할당 | 자식의 크기나 남은 공간을 flex 비율에 따라 사용 |
| `Stack` | 자식에게 부모의 constraints를 전달 | 자식들이 겹치는 최대 크기에 따라 크기 결정 |
| `ListView` | 자식에게 무한대 높이/넓이 constraints 전달 | 부모 constraints 내에서 크기 결정. 자식들이 필요로 하는 크기만큼 스크롤 가능. |
| `GridView` | 자식에게 그리드 셀 크기에 따른 constraints를 전달 | 그리드의 총 크기에 따라 크기 결정 |
| `CustomScrollView`| 자식에게 무한대 높이/넓이 constraints 전달 | 부모 constraints 내에서 크기 결정. 자식들이 필요로 하는 크기만큼 스크롤 가능. |

## Flex 관련 추가 내용
### Flex 위젯의 기본 개념
Flutter의 Flex 위젯은 Row와 Column의 기본 클래스이며, 자식 위젯들이 남은 공간을 어떻게 나누어 가질지 결정하는 데 사용된다. Row는 가로 방향으로, Column은 세로 방향으로 자식들을 배치한다.

### Flex 위젯의 크기 결정 방식
- flex 속성:
  flex 속성은 자식 위젯이 남은 공간을 차지하는 비율을 결정한다. 예를 들어, flex: 2는 같은 부모 내에서 flex: 1인 자식보다 두 배의 공간을 차지한다.
- Expanded와 Flexible 위젯:
  Expanded: 남은 모든 공간을 차지하는 위젯. flex 비율을 사용하여 공간을 나눈다.
  Flexible: 남은 공간을 차지하되, 자식 위젯의 크기에 따라 유연하게 크기를 결정한다. 기본적으로 자식의 크기에 따라 공간을 나누지만, flex 비율을 사용할 수도 있다.

### Expanded 예시 코드
```dart
Row(
  children: <Widget>[
    Expanded(
      flex: 2,
      child: Container(color: Colors.red),
    ),
    Expanded(
      flex: 1,
      child: Container(color: Colors.green),
    ),
    Expanded(
      flex: 1,
      child: Container(color: Colors.blue),
    ),
  ],
);
```
![Expanded](/assets/img/flutter_size/expanded.png)

이 예시에서 빨간색 컨테이너는 전체 가로 공간의 절반을 차지하고, 녹색과 파란색 컨테이너는 각각 1/4씩 공간을 차지한다.

## Flexible한 위젯과 Fixed size 위젯이 섞여 있는 경우
Flexible한 위젯과 Fixed size 위젯이 함께 사용되는 경우, 부모 위젯은 먼저 Fixed size 위젯들의 크기를 계산하고, 남은 공간을 Flexible 위젯들에 할당한다.

### 예시 코드
```dart
Row(
  children: <Widget>[
    Container(
      width: 100,
      color: Colors.red,
    ),
    Expanded(
      flex: 1,
      child: Container(color: Colors.green),
    ),
    Container(
      width: 50,
      color: Colors.blue,
    ),
    Expanded(
      flex: 2,
      child: Container(color: Colors.yellow),
    ),
  ],
);
```
![Flexible with Fixed Size](/assets/img/flutter_size/flex_with_fixed.png)

이 예시에서, 빨간색 컨테이너는 고정된 100의 너비를 차지하고, 파란색 컨테이너는 고정된 50의 너비를 차지한다. 나머지 공간은 녹색과 노란색 컨테이너가 flex 비율에 따라 나눠 가진다. 녹색 컨테이너는 전체 남은 공간의 1/3을, 노란색 컨테이너는 2/3을 차지한다.

참고링크: [Flutter 공식 문서](https://docs.flutter.dev/ui/layout/constraints)