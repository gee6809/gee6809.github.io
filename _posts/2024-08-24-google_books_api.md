---
title: Google Books Open API 간단 가이드 (API Key 발급)
description: Google Books Open API 사용을 위한 간단한 가이드를 제공합니다. Google Cloud 홈에서 API Key를
  발급받는 방법을 포함합니다.
categories:
- Tips
date: 2024-08-24 13:11 +0900
---
## Google Cloud 프로젝트 만들기
**1. [Google Cloud 홈](https://console.cloud.google.com/)에 접속하여 프로젝트를 생성해줍니다.**
![Google Cloud 홈](/assets/img/google_books_api/google_cloud_home.png)

**2. 프로젝트 생성이 완료되면 검색창에 "book"을 검색하고 "Books API"를 선택합니다.**
![books API 검색창](/assets/img/google_books_api/search_books_api.png)

**3. Enable 버튼을 눌러줍니다.**
![Enable Button](/assets/img/google_books_api/enable.png)

**4. 좌측의 "Credentials"를 클릭하고, API key를 생성해줍니다.**
![Credential Page](/assets/img/google_books_api/Credential_page.png)

**5. 키 생성이 완료되면, 해당 key를 메모장에 따로 적어놓습니다.**
![API Key](/assets/img/google_books_api/api_key.png)


## 도서 검색하기
[Google Books APIs](https://developers.google.com/books/docs/v1/reference/volumes#resource)에 들어가면 API 사용법에 대한 가이드가 자세히 적혀있습니다.

여기서는 간단히 keyword로 도서 검색하는 방법을 안내합니다.

### keyword 도서 검색
`GET https://www.googleapis.com/books/v1/volumes?q="키워드"&key="발급받은 API KEY"` 를 통해서 검색할 수 있습니다.

예시로 달러구트를 검색했을때 결과는 다음과 같습니다.
```
{
  "kind": "books#volumes",
  "totalItems": 1399,
  "items": [
    {
      "kind": "books#volume",
      "id": "oa9izwEACAAJ",
      "etag": "lx5lwxHI874",
      "selfLink": "https://www.googleapis.com/books/v1/volumes/oa9izwEACAAJ",
      "volumeInfo": {
        "title": "달러구트 꿈 백화점 2(큰글자도서)(리더스원)",
        "authors": [
          "이미예"
        ],
        "publishedDate": "2022-09-16",
        "industryIdentifiers": [
          {
            "type": "ISBN_13",
            "identifier": "9791165345686"
          }
        ],
        "readingModes": {
          "text": false,
          "image": false
        },
        "pageCount": 0,
        "printType": "BOOK",
        "maturityRating": "NOT_MATURE",
        "allowAnonLogging": false,
        "contentVersion": "preview-1.0.0",
        "panelizationSummary": {
          "containsEpubBubbles": false,
          "containsImageBubbles": false
        },
        "language": "ko",
        "previewLink": "http://books.google.co.kr/books?id=oa9izwEACAAJ&dq=%EB%8B%AC%EB%9F%AC%EA%B5%AC%ED%8A%B8&hl=&cd=1&source=gbs_api",
        "infoLink": "http://books.google.co.kr/books?id=oa9izwEACAAJ&dq=%EB%8B%AC%EB%9F%AC%EA%B5%AC%ED%8A%B8&hl=&source=gbs_api",
        "canonicalVolumeLink": "https://books.google.com/books/about/%EB%8B%AC%EB%9F%AC%EA%B5%AC%ED%8A%B8_%EA%BF%88_%EB%B0%B1%ED%99%94%EC%A0%90_2_%ED%81%B0%EA%B8%80%EC%9E%90.html?hl=&id=oa9izwEACAAJ"
      },
      "saleInfo": {
        "country": "KR",
        "saleability": "NOT_FOR_SALE",
        "isEbook": false
      },
      "accessInfo": {
        "country": "KR",
        "viewability": "NO_PAGES",
        "embeddable": false,
        "publicDomain": false,
        "textToSpeechPermission": "ALLOWED",
        "epub": {
          "isAvailable": false
        },
        "pdf": {
          "isAvailable": false
        },
        "webReaderLink": "http://play.google.com/books/reader?id=oa9izwEACAAJ&hl=&source=gbs_api",
        "accessViewStatus": "NONE",
        "quoteSharingAllowed": false
      }
    },
    ...
  ]
}
```