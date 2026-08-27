# moeda (모으다)

> AI 자산관리 비서 — 개인 가계부 앱

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.1%2B-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6f42c1)
![SQLite](https://img.shields.io/badge/DB-SQLite-003B57?logo=sqlite&logoColor=white)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey)

**moeda**는 수입·지출 기록부터 예산 관리, 저축 목표, 자산/부채 현황, 카테고리별·기간별 통계까지 한눈에 관리할 수 있는 가계부 앱입니다.

## 스크린샷

> 실제 실행 화면

| 대시보드 | 통계 | 내역 |
| :---: | :---: | :---: |
| _(스크린샷 추가 예정)_ | _(스크린샷 추가 예정)_ | _(스크린샷 추가 예정)_ |

## 주요 기능

- **대시보드**: 총 순자산, 이번 달 수입/지출, 예산 잔액·진행률, 지출 속도 경고 배지를 한 화면에서 확인
- **내역 관리**: 수입/지출 추가·수정·삭제, 카테고리 연동
- **카테고리**: 수입/지출 항목 분류
- **예산**: 월별 예산 설정, 잔액·진행률·오늘의 권장 지출액 자동 계산
- **저축 목표**: 목표 금액 대비 진행률 관리, 추가·수정·삭제
- **자산/부채**: 보유 자산·부채 항목 관리, 총자산/총부채/순자산 요약
- **통계**: 카테고리별 지출 비중, 최근 6개월 수입/지출 추이 차트

## 기술 스택

- **Framework**: Flutter
- **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (`StateNotifier` 패턴)
- **Local Persistence**: [sqflite](https://pub.dev/packages/sqflite) (SQLite)

## 프로젝트 구조

기능(도메인) 단위로 폴더를 나누는 Feature-first 구조를 따릅니다.

```
lib/
├── core/
│   └── database/        # 데이터베이스
└── features/
    ├── ledger/           # 수입/지출 내역
    ├── category/         # 카테고리
    ├── budget/           # 월별 예산
    ├── goal/              # 저축 목표
    ├── asset/             # 자산/부채
    └── stats/             # 통계 화면
```

각 도메인은 다음 계층으로 구성됩니다.

- `models/` — 데이터 모델
- `services/` — SQLite 접근 (`AppDatabase.instance` 경유)
- `controllers/` — Riverpod `StateNotifier` 기반 상태·비즈니스 로직
- `views/` — `ConsumerWidget` 기반 UI

## 시작하기

### 요구 사항

- Flutter SDK (Dart >= 3.1.5)
- iOS 시뮬레이터 또는 Android 에뮬레이터/실기기
