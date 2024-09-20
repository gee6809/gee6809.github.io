---
title: Android 에뮬레이터에서 키보드 입력이 안될 때 해결방법
description: Android 에뮬레이터에서 물리 키보드 입력이 안될 때 해결방법에 대해 가이드 합니다.
categories:
- Android
date: 2024-09-20 19:49 +0900
---
Android 에뮬레이터를 사용하다보면, 스크린 키보드는 사용 가능하지만, 물리키보드는 사용 불가능한 경우가 있다.
이는 해당 에뮬레이터 머신의 설정에서 키보드 사용이 꺼져있기 때문이다.

`~/.android/avd/<emulator-device-name>.avd/config.ini` 파일에 `hw.keyboard=no`를 `hw.keyboard=yes`로 바꿔주면 간단히 해결된다.
