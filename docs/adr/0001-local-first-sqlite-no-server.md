# 로컬 우선: 모든 데이터는 기기 안 SQLite에만 두고 서버를 두지 않는다

가계부 데이터는 `sqflite`로 기기 안 `moeda.db` 하나에만 저장하고, 서버 · 계정 · 외부 API 호출이 없다(의존성도 `flutter_riverpod` · `sqflite` · `path`뿐). 금융 기록을 기기 밖으로 내보내지 않고 오프라인에서도 바로 쓰는 대신, 기기를 잃으면 데이터도 잃고 여러 기기 동기화가 없다. 백업 · 내보내기(CSV)는 로드맵에 남아 있고, 서버를 붙이게 되면 ID 체계 · 스키마 마이그레이션 방식까지 함께 바뀐다.

근거: README 머리말 · "기술 스택", `pubspec.yaml`, `lib/core/database/app_database.dart`, PR #3("로컬 우선 개인 가계부"로 README 정정, AI 기능은 #1 로드맵으로).
