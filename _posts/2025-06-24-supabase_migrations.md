---
title: Supabase Migration 개념 & 사용법 정리
description: Supabase에서 마이그레이션을 관리하는 기본 개념과 폴더 구조, CLI 명령어 및 실제 워크플로우를 간단히 정리한 가이드입니다.
categories: Tips
mermaid: true
date: 2025-06-24 23:37 +0900
---
## 1. Migration 이란?

**Migration**(마이그레이션)은 데이터베이스 스키마(테이블, 인덱스, 뷰, 함수 등)의 변화를 **버전 관리**하기 위한 일련의 SQL 스크립트다. 코드가 git 이력을 따라가듯, 스키마 역시 **시간 순서**(timestamp)와 **의도**(description)가 남은 SQL 파일로 관리한다.

### 왜 필요한가?

* **협업** : 여러 개발자가 동시에 테이블 구조를 바꿔도 충돌 없이 머지 가능
* **배포 자동화** : CI/CD 파이프라인에서 동일한 스키마를 각 환경(dev/stage/prod)에 적용
* **롤백** : 잘못된 변경을 빠르게 이전 버전으로 되돌릴 수 있음

---

## 2. Supabase 의 Migration 구조

| 경로                          | 역할                        |
| --------------------------- | ------------------------- |
| `supabase/migrations/`      | 모든 migration SQL 이 모이는 폴더 |
| `yyyyMMddHHMMSS_<name>.sql` | 파일명 규칙. UTC 타임스탬프 + 설명    |
| `supabase/config.toml`      | DB 연결 정보·schema 포함 설정     |

```bash
my‑project/
└── supabase/
    ├── config.toml
    └── migrations/
        ├── 20250624140000_init.sql
        └── 20250624213030_add_profiles.sql
```

> 파일명에 공백 대신 밑줄(\_) 사용 → `db_diff` 가 자동 생성할 때 일관성을 유지한다.
{: .prompt-info}

---

## 3. 핵심 CLI 명령어

| 명령                                 | 용도 / 메모                                                 |
| ---------------------------------- | ------------------------------------------------------- |
| `supabase migration new <name>`    | **빈 migration 파일** 생성.<br>직접 SQL을 적거나 이후 `db diff` 로 채움 |
| `supabase db diff` | 현재 DB와 마지막 migration 비교 → **새 SQL 자동 생성**               |
| `supabase migration up`            | 로컬 DB에 **아직 적용되지 않은** migration 실행                      |
| `supabase migration list`          | 적용/미적용 목록 확인                                            |
| `supabase db push`                 | migrations 폴더의 모든 SQL을 대상 DB에 순서대로 실행(원격 배포 포함)         |
| `supabase db reset`                | 로컬 DB 드롭 → 모든 migration 재적용(초기화)                        |

---

## 4. Workflow

1. `supabase start` 로 스택 기동
2. psql / GUI 로 스키마 변경 ➜ `supabase db diff` 로 새 migration 생성
3. `supabase migration up` 으로 변경 확인
4. Git 커밋 & PR → CI 에서 `supabase db push` 로 스테이징/프로덕션 적용
