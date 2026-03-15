---
title: 삼성 파워봇 리모컨 만들기 (리모컨 없어서 SmartThings 못하는 사람)
description: 삼성 파워봇 VR20R7260WD를 리모컨 없이 SmartThings에 연결하기 위해 라즈베리파이 IR 송신기를 사용한 방법을
  정리한 글입니다.
categories:
- Tips
tags:
- Samsung
- PowerBot
- SmartThings
- Raspberry Pi
date: 2026-03-15 11:34 +0900
---
집에 있던 **삼성 파워봇 로봇청소기 (VR20R7260WD)**를 SmartThings에 연결하려고 했다.

근데 시작부터 문제가 있었다.

**리모컨이 없다.**

이게 왜 문제냐면 SmartThings 연결 과정에서 **리모컨 버튼 입력이 필요하다.**
본체만 가지고는 특정 모드로 진입할 수 없다.

솔직히 말하면 이건 좀 이해가 안 된다.
청소기는 멀쩡히 돌아가는데 앱 연결 하나 하려면 리모컨이 필요하다니.

왜 그렇게 설계했냐 삼성.

어쨌든 리모컨이 없으니 방법은 하나였다.

**리모컨 신호를 직접 쏘자.**

## 라즈베리파이로 IR 송신기 만들기

그래서 라즈베리파이에 IR LED를 연결해서 **IR 송신기**를 만들었다.

회로 구성은 여기서 자세히 다루지 않는다.
라즈베리파이 IR 송신 회로는 인터넷에 이미 자료가 많다.

라즈베리파이로 IR 신호를 송신할 수 있는 상태만 만들면 된다.

![raspberry pi ir circuit](/assets/img/samsung_powerbot_remote/raspberrypi_circuit.jpg)

## SmartThings 연결에 필요한 버튼

파워봇을 SmartThings에 등록하려면 리모컨에서 다음 버튼이 필요하다.

- **Clock**
- **Recharge**

연결 과정은 대략 이런 흐름이다.

1. `Clock` 버튼으로 특정 모드 진입
2. `Recharge` 버튼을 **길게 눌러 비프음 확인**
3. 이후 SmartThings 등록 진행

여기서 중요한 포인트는 **Recharge 버튼을 길게 누르는 동작**이다.

IR 리모컨에서 "길게 누름"은 보통

- 긴 신호 한 번

이 아니라

- **같은 신호를 일정 간격으로 반복 송신**

으로 구현된다.

그래서 라즈베리파이에서도 **신호를 여러 번 반복 송신**해야 한다.

## 파워봇 리모컨 신호

신호를 찾는 과정도 꽤 번거로웠다.
결국 GPT의 힘을 조금 빌려서 중국 사이트들에 올라온 삼성 로봇청소기 계열 IR 신호들을 뒤졌고,
그중에서 파워봇에서 실제로 먹히는 신호를 추려냈다.

아래 두 신호가 제일 중요하다.
SmartThings 연결용으로 결국 **`clock.ir`와 `recharge.ir`를 쏴야 한다.**

### `clock.ir`

```text
carrier 38000
pulse 4523
space 4497
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 43993
```

### `recharge.ir`

```text
carrier 38000
pulse 4523
space 4497
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 579
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 1709
pulse 552
space 43993
```

## 라즈베리파이에서 신호 송신

라즈베리파이에서 IR 송신이 가능하다면 이런 식으로 테스트할 수 있다.

```
ir-ctl -d /dev/lirc1 --send=recharge.ir
```

정상적으로 구현했다면 파워봇에서 응답 소리가 날 것이다.

Smartthings에 연결할때는 다음과 같이 사용하면 길게 누르고 있는 효과를 낼 수 있다.

```bash
for i in {1..50}; do
  ir-ctl -d /dev/lirc1 --send=recharge.ir
  sleep 0.11
done
```

