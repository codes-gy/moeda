# moeda (모으다)

> 로컬 우선(local-first) 개인 가계부 앱 — 수입·지출, 예산, 저축 목표, 자산/부채를 기기 안에서 관리

[![CI](https://github.com/codes-gy/moeda/actions/workflows/ci.yml/badge.svg)](https://github.com/codes-gy/moeda/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6f42c1)
![SQLite](https://img.shields.io/badge/DB-SQLite-003B57?logo=sqlite&logoColor=white)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey)

**moeda**는 수입·지출 기록부터 예산 관리, 저축 목표, 자산/부채 현황, 카테고리별·기간별 통계까지 한눈에 관리할 수 있는 가계부 앱입니다.
모든 데이터는 기기의 SQLite에만 저장되며, 서버 전송이나 외부 API 호출이 없습니다.

> **참고**: 현재 버전에는 AI 기능이 없습니다. 대시보드의 지표(지출 속도 경고, 오늘의 권장 지출액 등)는 모두 규칙 기반 계산입니다.
> AI 인사이트는 [로드맵](#로드맵)에 있는 예정 항목입니다.

## 스크린샷

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
  - 금액은 원 단위 정수(`INTEGER`)로 저장합니다 (스키마 v4).
  - 스키마 변경은 `lib/core/database/app_database.dart`의 `onUpgrade`에서 버전별로 마이그레이션합니다.

## 프로젝트 구조

기능(도메인) 단위로 폴더를 나누는 Feature-first 구조를 따릅니다.

```
lib/
├── main.dart             # 앱 진입점 (ProviderScope, MaterialApp)
├── core/
│   ├── database/         # SQLite 연결·스키마·마이그레이션
│   ├── theme/            # 공용 색상
│   └── utils/            # 금액 포맷 등 공용 유틸
└── features/
    ├── dashboard/        # 메인 대시보드 화면, 순자산 카드
    ├── ledger/           # 수입/지출 내역
    ├── category/         # 카테고리
    ├── budget/           # 월별 예산
    ├── goal/             # 저축 목표
    ├── asset/            # 자산/부채
    └── stats/            # 통계 화면
```

각 도메인은 다음 계층으로 구성됩니다.

- `models/` — 데이터 모델
- `services/` — SQLite 접근 (`AppDatabase.instance` 경유)
- `controllers/` — Riverpod `StateNotifier` 기반 상태·비즈니스 로직
- `views/` — `ConsumerWidget` 기반 UI (화면, 카드, 다이얼로그)

## 시작하기

### 요구 사항

- Flutter SDK 3.44 이상 (Dart 3.13 이상, `pubspec.lock` 기준)
- iOS 시뮬레이터 또는 Android 에뮬레이터/실기기

### 실행

```bash
flutter pub get
flutter run
```

### 정적 분석 · 테스트

```bash
flutter analyze
flutter test
```

DB 마이그레이션 테스트(`test/core/database/`)는 `sqflite_common_ffi`로 데스크톱 SQLite를 사용하므로 기기 없이 실행됩니다.
PR과 `main` 푸시마다 GitHub Actions에서 같은 명령이 실행됩니다.

## 로드맵

- [ ] AI 인사이트: 소비 패턴 요약, 예산 초과 예측 등 (현재 미구현)
- [ ] 카테고리 소프트 삭제 + `ledgers.categoryId` 외래 키 제약
- [ ] 데이터 백업/내보내기 (CSV)
- [ ] 스크린샷 추가
