class ScreeningDomainScore {
  final String id;
  final String screeningId;
  final String linhVuc;
  final int soCauThietKe;
  final int soCauHopLe;
  final int diemTho;
  final double? diemPhanTram;
  final DateTime createdAt;

  const ScreeningDomainScore({
    required this.id,
    required this.screeningId,
    required this.linhVuc,
    required this.soCauThietKe,
    required this.soCauHopLe,
    required this.diemTho,
    this.diemPhanTram,
    required this.createdAt,
  });
}
