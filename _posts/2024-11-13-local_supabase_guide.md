---
title: Ubuntu Local에서 Supabase 서버 실행하기 (with Edge Function)
description: Ubuntu 환경에서 Docker를 통해 Supabase를 설치하고 로컬 서버에서 실행하는 방법을 안내한다. 또한, 외부 API를
  이용해 데이터베이스에 캐시 기능을 추가하여 효율적인 데이터 조회를 구현한다.
categories:
- Tips
date: 2024-11-13 21:09 +0900
---
## 1. Docker 설치

Supabase를 로컬에서 실행하려면 Docker가 필요하다. Ubuntu에 Docker를 설치하는 방법은 다음과 같다.

### 1.1 패키지 업데이트 및 필수 패키지 설치
```bash
sudo apt-get update
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
```

### 1.2 Docker의 공식 GPG 키 추가
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### 1.3 Docker 저장소 설정
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 1.4 Docker 설치
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

### 1.5 Docker 서비스 시작 및 부팅 시 자동 시작 설정
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 1.6 현재 사용자에게 Docker 그룹 권한 부여
```bash
sudo usermod -aG docker $USER
```

이후, 변경 사항을 적용하려면 로그아웃 후 다시 로그인하거나 다음 명령어를 실행한다.

```bash
newgrp docker
```

## 2. Supabase CLI 설치

```bash
npm install supabase --save-dev
```

설치 후, `npx`를 통해 Supabase CLI를 실행할 수 있다

```bash
npx supabase --help
```

## 3. 프로젝트 초기화 및 로컬 서버 시작

프로젝트 디렉토리에서 다음 명령어를 실행하여 Supabase 프로젝트를 초기화한다

```bash
npx supabase init
```

그런 다음, 로컬 Supabase 스택을 시작한다:

```bash
npx supabase start
```

이 과정에서 Docker가 필요하므로, 앞서 설치한 Docker가 정상적으로 실행 중인지 확인해야 한다.

## 4. 데이터베이스 테이블 생성

`npx supabase start`가 정상적으로 실행되었다면, 다음과 같이 Studio URL을 확인할 수 있을것이다.
```bash
Studio URL: http://127.0.0.1:54323
```
브라우저를 통해 URL에 접속하자.

좌측 메뉴에서 SQL editor를 선택한다.

다음 SQL 명령을 실행해 items 테이블을 생성할 수 있다.

여기에는 영어사전 데이터를 저장하는 테이블을 예시로 사용한다.

```sql
CREATE TABLE items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phonetic text,
  audio_url text,
  part_of_speech text,
  definition text NOT NULL,
  example text
);
```

- name: 단어 이름
- phonetic: 발음 기호
- audio_url: 발음 오디오 URL
- part_of_speech: 품사
- definition: 정의
- example: 예제 문장


## 5. Edge Function 작성
"4. 데이터베이스 테이블 생성" 까지만 진행해도 기본적인 ADD, DELETE, QUERY api는 사용가능하다.

하지만 여기에 추가적으로 전처리등의 기능을 포함하고 싶다면 Edge Function을 이용해야 한다.

Edge Function은 Typescript언어를 사용해서 작성할 수 있다.

여기에는 예시로 다음과 같은 기능을 제공하는 Edge Function을 구현한다.
- GET http 요청을 통해 name parameter를 받는다.
- DB에 name이 일치하는 레코드가 있다면 해당 레코드를 json으로 변환하여 응답한다.
- DB에 name이 일치하는 레코드가 없다면 "api.dictionaryapi.dev" open api를 통해 정보를 query하고, 해당 레코드를 DB에 저장한다.

### 5.1 Edge Function 생성
```bash
npx supabase functions new fetch-item
```

### 5.2 fetch-item 함수 작성
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(supabaseUrl, supabaseKey);

serve(async (req) => {
  const url = new URL(req.url);
  const itemName = url.searchParams.get('name');

  if (!itemName) {
    return new Response(JSON.stringify({ error: 'Missing item name' }), { status: 400 });
  }

  // 데이터베이스에서 해당 아이템 조회 (maybeSingle 사용)
  const { data, error } = await supabase
    .from('items')
    .select('*')
    .eq('name', itemName)
    .maybeSingle();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  if (data) {
    // 데이터가 존재하는 경우
    return new Response(JSON.stringify(data), { status: 200 });
  } else {
    // 데이터가 없는 경우 외부 API 호출
    const externalResponse = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${itemName}`);
    if (!externalResponse.ok) {
      return new Response(JSON.stringify({ error: 'Failed to fetch from external API' }), { status: 500 });
    }
    const externalData = await externalResponse.json();

    // 외부 데이터 파싱
    const wordData = externalData[0];
    const phonetic = wordData.phonetic || '';
    const audio_url = wordData.phonetics[0]?.audio || '';
    const part_of_speech = wordData.meanings[0]?.partOfSpeech || '';
    const definition = wordData.meanings[0]?.definitions[0]?.definition || 'No definition available';
    const example = wordData.meanings[0]?.definitions[0]?.example || '';

    // 데이터베이스에 저장
    const { error: insertError } = await supabase
      .from('items')
      .insert([{
        name: itemName,
        phonetic,
        audio_url,
        part_of_speech,
        definition,
        example,
      }]);

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), { status: 500 });
    }

    // 클라이언트에 응답 반환
    return new Response(JSON.stringify({
      name: itemName,
      phonetic,
      audio_url,
      part_of_speech,
      definition,
      example,
    }), { status: 200 });
  }
});

```

## 6. Edge Function 로컬 실행

로컬에서 Edge Function을 실행한다
```bash
npx supabase functions serve fetch-item
```
이 명령어는 로컬에서 Edge Function을 실행하며, 기본적으로 `http://localhost:54321/functions/v1/fetch-item`에서 요청을 수신한다.

## 7. Edge Function 테스트

다음과 같이 `curl` 명령어를 사용하여 Edge Function을 테스트할 수 있다
```bash
curl 'http://localhost:54321/functions/v1/fetch-item?name=example'
```
이 요청은 `name` 파라미터에 "example" 값을 전달하며, Edge Function은 해당 이름의 아이템을 데이터베이스에서 조회하거나, 없을 경우 외부 API에서 데이터를 가져와 데이터베이스에 저장한 후 응답한다.

