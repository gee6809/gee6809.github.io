---
title: "Langchain 기반 챗봇 만들기 #1 - OpenAI API Key 발급"
description: OpenAI API를 사용하기 위해 계정 생성부터 API Key 발급, 모델 등록, 테스트 코드 실행까지의 과정을 단계별로
  정리했습니다. 다음 장에서는 Langchain을 활용해 기억하는 챗봇을 만들어봅니다.
categories:
- Flutter
- Programming
date: 2025-06-07 13:32 +0900
---
# OpenAI API Key 발급 기록
> 다음에는 더 빠르게 하기 위해 정리한다.  
> ~~Limits 오류 때문에 오늘도 삽질하고 남긴다.~~

## 1. OpenAI 계정 준비
1. [OpenAI API Platform](https://platform.openai.com/)에 접속한다.  
2. Sign Up 또는 Log In 버튼을 눌러 계정에 로그인한다.  
3. 이메일 인증이 안됐으면 즉시 인증 메일을 확인‧완료한다.  
4. **결제 수단**을 아직 등록하지 않았다면 `Billing → Payment methods`에서 카드 정보를 추가한다.  
![캡션: OpenAI 플랫폼 대시보드 첫 화면](/assets/img/chatbot_1_api_key/billing.png)


## 2. API Key 생성
1. 왼쪽 메뉴에서 **API keys**를 클릭한다.  
2. 우측 상단 **+ Create new secret key** 버튼을 누른다.  
3. 원하는 키 이름(예: `dev-laptop-20250607`)을 입력하고 **Create secret key**를 누른다.  
4. 생성 직후 팝업에 나타나는 **sk-*** 형태의 키를 **반드시 복사**한다. (다시는 못 본다.)  
![캡션: 새 Key 생성 팝업에서 sk-로 시작하는 키를 복사하는 화면](/assets/img/chatbot_1_api_key/key.png)


## 3. 사용할 모델 설정
1. 왼쪽 메뉴에서 **Limits**를 클릭한다.
2. Edit 버튼을 눌러 사용할 모델 목록을 등록한다.
   * 예: `gpt-4.1-nano`, `gpt-4o`, `gpt-4`, `dall-e-3` 등
   * **주의**: 등록하지 않은 모델은 API 호출 시 오류가 발생한다.
![캡션: 모델 선택 화면 – gpt-4o, gpt-3.5-turbo 등 다양한 모델 확인](/assets/img/chatbot_1_api_key/model_limit.png)


## 4. Python 테스트 코드
Python에서 `openai` 패키지를 사용해 간단히 키 테스트를 해본다.

### 설치
```bash
pip install openai
```

### 코드
```python
import os
from openai import OpenAI

# API 키 설정
client = OpenAI(api_key="발급받은 OPENAI_API_KEY")

# 간단한 챗 테스트
response = client.chat.completions.create(
    model="gpt-4.1-nano",
    messages=[
        {"role": "user", "content": "Hello, who are you?"}
    ]
)

print(response.choices[0].message.content)
```

### 결과예시
```
Hello! I'm ChatGPT, an AI language model developed by OpenAI. I'm here to help answer your questions, have conversations, and assist with a variety of topics. How can I assist you today?
```

## 이제 준비 완료!
이제 OpenAI API를 사용할 수 있는 모든 준비가 끝났다.  
다음 장에서는 Langchain을 이용해 **대화 기록을 기억하는 간단한 챗봇**을 만들어본다.