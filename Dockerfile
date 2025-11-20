FROM ruby:3.2-slim

# 빌드/네이티브 gem 설치용 도구들
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/jekyll

# bundler가 컨테이너 안에 공용 경로를 쓰도록 (나중에 volume으로 캐시)
ENV BUNDLE_PATH=/usr/local/bundle

# 실제 소스는 volume으로 마운트할 거라 여기선 아무것도 복사 안 함

