---
title: "[Flutter] DraggableScrollableSheet로 ModalBottomSheet을 전체화면으로 드래그 가능하도록 만들기"
description: Flutter에서 DraggableScrollableSheet를 사용하여 ModalBottomSheet를 전체 화면으로 드래그할
  수 있도록 구현하는 방법을 소개합니다.
categories: Flutter
tags:
- Flutter Widget
mermaid: true
date: 2024-08-04 19:40 +0900
---
지도에서 자주 보이는 하단의 BottomSheet를 Flutter에서 구현하는 방법을 알아본다.
![map_bottom_sheet](/assets/img/showModalBottomSheet/map_bottom_sheet.png)

## ShowModalBottomSheet
`ShowModalBottomSheet()`은 화면 하단에 UI가 나타나도록 해준다.

```dart
showModalBottomSheet(
  context: context,
  builder: (BuildContext context) {
    return Container(
      height: 200,
      color: Colors.white,
      child: Center(
        child: Text('This is a modal bottom sheet'),
      ),
    );
  },
);
```

![basic_modal_sheet](/assets/img/showModalBottomSheet/basic_modal_sheet.png){:style="border:1px solid #eaeaea; border-radius: 7px; padding: 0px;" }

## 드래그 가능한 ModalBottomSheet
`ShowModalBottomSheet()`의 parameter 중에 `enableDrag`와 `isScrollControlled`옵션이 있다. 

### enableDrag
이 옵션을 활성화하면 BottomSheet를 위아래로 드래그할 수 있게 되며, 아래로 드래그했을 때 BottomSheet가 사라지게 된다.

### isScrollControlled
이 옵션이 `false`로 되어 있으면, height contraints를 강제하게 된다. (contraints 개념은 [[Flutter] 위젯의 Size 결정 원칙](/posts/flutter_size/) 참고). height contraints 기본값은 화면 height의 9/16으로 설정되어 있으며 `scrollControlDisabledMaxHeightRatio` parameter를 통해 변경가능하다.
반대로 `isScrollControlled`가 `true`로 되면, height contraints 제한이 없어지게 된다.

따라서, `isScrollControlled == true`는 `isScrollControlled == false && scrollControlDisabledMaxHeightRatio == 1.0` 과 같은 기능이라고 볼 수 있다.

### 주의할 점
위의 두 parameter 모두 child에 직접적으로 `Draggable`과 `Scrollable` 위젯을 부여하지 않는다는 점이다. 단지 제약조건을 풀어줄 뿐이다.

따라서, `Draggable`과 `Scrollable` 위젯 기능을 부여하기 위해서는 child를 `DraggableScrollableSheet`로 감싸야한다.

## DraggableScrollableSheet와 함께 사용하기
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  enableDrag: true,
  showDragHandle: true,
  builder: (BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 1.0,
      initialChildSize: 0.4,
      minChildSize: 0.4,
      expand: false,
      snap: true,
      snapSizes: [0.4, 1.0],
      builder: (context, scrollController) => SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column( children: List<Text>.generate(100, (index) => Text("hello..?"))),
        ),
      )
    );
  },
);
```
![Scrollable_modal_bottom_sheet.gif](/assets/img/showModalBottomSheet/Scrollable_modal_bottom_sheet.gif){:style="border:1px solid #eaeaea; border-radius: 7px; padding: 0px;" }

### expand parameter
`DraggableScrollableSheet`에서 `expand` parameter에 주의해야 한다. 앞서 말했듯, `showModalBottomSheet()`의 `isScrollControlled`는 max height에 대한 "contraints"만 풀어준다. ModalBottomSheet의 size는 여전히 child의 size에 의해 정해진다는 것이다.
따라서, `expand` parameter를 true로 하게 되면, `DraggableScrollableSheet`의 height이 화면 전체가 되어 버리면서 BottomSheet가 화면을 전부 가리게 된다.

### snap parameter
`snap` parameter를 주면, 드래그가 끝났을 때 지정한 snap위치로 `DraggableScrollableSheet`위젯이 돌아가게 된다. 그렇지 않으면 `DraggableScrollableSheet`가 user가 드래그하는 어느 위치에든 멈춰 있을 수 있게 된다.
