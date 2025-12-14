---
title: MobaXterm에서 한글 조합 중 Backspace 누르면 멈추는 현상 해결 (Windows 11)
description: Windows 11에서 Microsoft IME 호환성 설정으로 MobaXterm 한글 조합 중 Backspace 프리징을 해결한 방법.
categories:
- Tips
date: 2025-12-14 15:07 +0900
---
## 증상

Windows 11에서 MobaXterm 터미널에 한글 입력 중, 자음만 입력된 **조합 상태(Preedit)** 에서 `Backspace`를 누르면

- 터미널에는 아직 글자가 입력되지 않았는데
- 창 **좌측 상단에 조합 중인 글자(예: ㄱ)** 가 작게 뜬 상태에서
- `Backspace` 입력 시 **MobaXterm이 응답 없음(프리징)** 상태로 빠지는 문제가 발생했다.

## 원인(추정)

한글 입력은 IME(Input Method Editor)가 **조합 문자열(Preedit/Composition)** 을 관리한다.  
이 조합 상태에서 들어오는 `Backspace` 키 이벤트를 MobaXterm이 IME와 정상적으로 주고받지 못하면서, 조합 갱신이 꼬이거나 메시지 처리에서 멈춤이 발생한 것으로 보인다.

## 해결 방법 (Windows 11)

Windows 11의 **Microsoft IME 호환성 설정**을 변경하니 문제 없이 해결됐다.

1. **설정** → **시간 및 언어** → **언어 및 지역**
2. **한국어** 오른쪽 `…` → **언어 옵션**
3. **키보드**에서 **Microsoft 입력기** 오른쪽 `...`→ **키보드 옵션**
4. **호환성** 항목에서  
   **"이전 버전의 Microsoft IME 사용"**을 **켬 상태로 변경**
5. MobaXterm 완전히 종료 후 재실행
