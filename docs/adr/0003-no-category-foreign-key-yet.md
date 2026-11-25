---
status: accepted (#2에서 대체 예정)
---

# `ledgers.categoryId`에 외래 키를 걸지 않는다(카테고리 소프트 삭제 전까지)

카테고리 삭제는 지금 하드 삭제이고, 그 카테고리를 가리키던 내역은 지워지지 않은 채 화면에서 '미분류'로 보인다. 외래 키를 걸면 RESTRICT는 쓰던 카테고리 삭제를 실패시키고 CASCADE는 내역을 함께 지워, 어느 쪽이든 지금 동작과 데이터가 바뀐다. 그래서 v4 마이그레이션 때도 걸지 않았고, 소프트 삭제(`isActive = 0`) · 고아 내역을 '미분류' 시스템 카테고리로 옮기는 v5 마이그레이션 · `PRAGMA foreign_keys = ON`을 한 묶음으로 #2에서 처리한다. 그 전까지 내역 → 카테고리 참조가 깨질 수 있다고 보고 코드를 쓴다.

근거: 이슈 #2, PR #3 "하지 않은 것", `CategoryService.deleteCategory`, '미분류' 대체(`ledger_view.dart` · `recent_transactions_card.dart` · `stats_provider.dart`).
