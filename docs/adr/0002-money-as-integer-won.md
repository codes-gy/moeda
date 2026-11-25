# 금액은 원 단위 INTEGER로 저장하고, 모델은 아직 double로 둔다

스키마 v4부터 모든 금액 컬럼(`ledgers.amount`, `budgets.amount`, `goals.targetAmount` · `currentAmount`, `assets.amount`)을 REAL이 아닌 원 단위 INTEGER로 저장한다. 원화에는 소수 단위가 없고 REAL은 합계에서 부동소수점 오차를 낳기 때문이다. SQLite는 컬럼 타입을 바꿀 수 없어 v4 마이그레이션은 테이블을 새로 만들어 `CAST(ROUND(x) AS INTEGER)`로 복사한 뒤 바꿔 끼운다. 모델의 `double`은 UI 입력 파싱까지 바뀌어 일을 키우므로 그대로 두고, Service가 저장할 때 `round()`, 읽을 때 `toDouble()`만 한다. 금액 컬럼을 새로 만들 때도 INTEGER로 둔다.

근거: 커밋 22510a4, PR #3 "금액 컬럼 REAL → INTEGER" · "하지 않은 것", `test/core/database/app_database_migration_test.dart`.
