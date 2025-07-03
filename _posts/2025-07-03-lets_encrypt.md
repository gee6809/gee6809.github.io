---
title: "Let's Encrypt로 SSL 인증서 발급받기 - Mac Mini로 홈서버 구축하기 #3"
description: Let's Encrypt를 사용하여 무료 SSL 인증서를 발급받고 자동 갱신 설정하는 방법
date: 2025-07-03 20:00 +0900
categories:
- Tips
---

> 미리 알아야할 것:
> - [Duck DNS로 DDNS 설정하기 - Mac Mini로 홈서버 구축하기 #1](/posts/duck_dns/)
> - [nginx 서버 열기 - Mac Mini로 홈서버 구축하기 #2](/posts/nginx/)


이전 글에 이어서 Let's Encrypt를 사용하여 무료 SSL 인증서를 발급받는 방법을 알아보겠습니다.

이 과정을 완료하면 HTTPS 보안 프로토콜을 사용하여 홈 서버에 안전하게 접근할 수 있게 됩니다.

## 프로젝트 디렉터리 구조

```
nginx/
├── conf/
│   ├── nginx.conf
│   └── sites-enabled/
│       └── default.conf
├── html/
│   └── index.html
├── logs/
│   └── nginx/
│       ├── access.log
│       └── error.log
├── certbot/                # ← 새로 추가
│   ├── www/                # /.well-known/acme-challenge 파일 저장
│   └── letsencrypt/        # /etc/letsencrypt 실제 인증서
└── docker-compose.yml
```

- **certbot/www**: 웹루트 플러그인용 챌린지 파일을 저장하는 디렉터리
- **certbot/letsencrypt**: live/, archive/, renewal/ 하위 디렉터리를 포함한 Certbot 기본 구조를 보관하는 디렉터리

이렇게 독립된 폴더를 구성하면 컨테이너를 교체해도 인증서와 챌린지 파일이 보존됩니다.

## 수정된 docker-compose.yml

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: my-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./conf/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf/sites-enabled:/etc/nginx/conf.d:ro
      - ./logs/nginx:/var/log/nginx
      - ./certbot/www:/var/www/certbot            # 웹루트 공유
      - ./certbot/letsencrypt:/etc/letsencrypt    # 인증서 공유
    restart: unless-stopped

  certbot:
    image: certbot/certbot:latest
    container_name: certbot
    depends_on:
      - nginx
    volumes:
      - ./certbot/www:/var/www/certbot
      - ./certbot/letsencrypt:/etc/letsencrypt
    restart: "no"
```

Nginx 설정에서 `/var/www/certbot`을 루트로 지정한 `location /.well-known/acme-challenge/` 블록을 반드시 포함해야 합니다.

Certbot 서비스는 상시 실행할 필요가 없으므로 `restart: "no"`로 설정하고, 인증서 발급 및 갱신 시에만 `docker compose run`으로 호출합니다.

## 최초 인증서 발급 절차

### 1단계: nginx 설정 파일 수정

`conf/sites-enabled/default.conf` 파일에 다음 내용을 추가해야 합니다:

```nginx
server {
    listen       80;                   # 수신 포트 (HTTP 기본 80)
    server_name  your-domain.duckdns.org;
    root         /usr/share/nginx/html;
    index        index.html index.htm; # 기본 문서

    # ACME 챌린지용 경로
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # 기본 정적 파일 서빙
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 2단계: 인증서 발급

```bash
# HTTP 모드로 Nginx만 우선 기동
docker compose up -d nginx

# 인증서 최초 발급 (웹루트 방식)
# ⚠️ docker-compose.yml의 certbot command를 제거하고 아래 명령어를 사용하세요
docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d your-domain.duckdns.org \
  --email your-email@example.com --agree-tos --no-eff-email
```

발급이 완료되면 `certbot/letsencrypt/live/your-domain.duckdns.org/{fullchain.pem,privkey.pem}` 파일이 생성됩니다.

## HTTPS 설정 추가

인증서 발급이 완료되면 nginx 설정을 HTTPS로 업데이트해야 합니다:

```nginx
server {
    listen 80;
    server_name your-domain.duckdns.org;
    
    # ACME 챌린지용 경로
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # HTTP를 HTTPS로 리다이렉트
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name your-domain.duckdns.org;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.duckdns.org/privkey.pem;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

설정 변경 후 nginx를 재시작합니다:

```bash
docker compose restart nginx
```

## crontab으로 자동 갱신

### 크론 항목 예시 (macOS 또는 Linux 호스트)

```bash
# 매일 03:00에 갱신 시도
# ⚠️ /path/to/nginx를 실제 nginx 프로젝트 경로로 변경하세요
00 3 * * * cd /path/to/nginx && \
  docker compose run --rm certbot renew --webroot -w /var/www/certbot --quiet && \
  docker compose exec nginx nginx -s reload
```

Let's Encrypt 커뮤니티와 Certbot 문서에서는 하루 1~2회 호출을 권장합니다. `renew` 명령은 30일 이하로 만료되는 인증서만 실제로 갱신하므로 서버 부담이 적습니다.


## 주의사항

1. **도메인 이름 변경**: 위 예시의 `your-domain.duckdns.org`를 실제 사용하는 도메인으로 변경하세요.
2. **이메일 주소 변경**: `your-email@example.com`을 실제 이메일 주소로 변경하세요.
3. **경로 확인**: crontab의 `/path/to/nginx`를 실제 nginx 프로젝트 경로로 변경하세요.
4. **포트 확인**: 방화벽에서 80번과 443번 포트가 열려있는지 확인하세요.