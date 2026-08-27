
enum CategoryType {
  income,   // 수입 (예: 월급, 용돈, 이자)
  expense,  // 지출 (예: 식비, 교통비, 쇼핑)
  transfer, // 이체 (예: 계좌 이체, 적금 납입)
}

class Category {
  /// 카테고리 고유 식별자 (PK). DB 자동 증가(Auto-Increment) 값 또는 정수형 고유 ID입니다.
  final int id;

  /// 카테고리 명칭 (예: "식비", "교통비"). UI에 직접 노출되는 이름입니다.
  final String name;

  /// 카테고리 성격 (수입, 지출, 이체). enum으로 관리하여 타입 안정성을 확보하고 잘못된 값 입력을 방지합니다.
  final CategoryType type;

  /// 상위 카테고리 ID (대분류-소분류 계층 구조). null이면 스스로가 '대분류'가 되고, 값이 있으면 해당 ID를 부모로 갖는 '소분류'가 됩니다.
  final String? parentId;

  /// 화면 노출 정렬 순서. 카테고리 순서 변경(드래그 앤 드롭 등) 기능 구현 시 DB 정렬(ORDER BY) 기준으로 사용합니다.
  final int displayOrder;

  /// 대표 색상 HEX 코드 (예: "#FF5733"). 차트 시각화 및 내역 태그 표시에 쓰이며, 미지정 시 null을 허용합니다.
  final String? colorHex;

  /// 대표 아이콘 키 이름 (예: "restaurant", "bus"). DB에 IconData 객체를 직접 저장할 수 없으므로 매핑용 문자열 키로 저장합니다.
  final String? iconName;

  /// 시스템 기본 카테고리 여부. 앱 설치 시 기본 제공되는 항목(true)은 사용자가 임의로 삭제하거나 핵심 속성을 수정하지 못하도록 방어 로직을 걸 때 사용합니다.
  final bool isSystem;

  /// 노출 활성화 여부 (Soft Delete). 카테고리 삭제 시 실제 DB 레코드를 지우면 과거 지출 내역과의 연결이 깨지므로, false로 바꿔 목록에서만 숨깁니다.
  final bool isActive;

  /// 데이터 생성 일시. 생성 시점 기록 및 정렬, 백업용 타임스탬프입니다.
  final DateTime createdAt;

  /// 데이터 최종 수정 일시. 이름/색상 변경 시 갱신되며, 추후 서버 동기화(Sync) 진행 시 최신 데이터 판별 기준이 됩니다.
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.displayOrder,
    this.colorHex,
    this.iconName,
    this.isSystem = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMainCategory => parentId == null;
}

