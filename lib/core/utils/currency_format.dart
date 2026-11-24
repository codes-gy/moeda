/// 금액을 천 단위 콤마가 들어간 원화 문자열로 변환한다 (부호 제외, 절댓값 기준).
String formatWon(num amount) {
  final rounded = amount.abs().toInt();
  return rounded.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}
