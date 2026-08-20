/// Model điểm 1 lĩnh vực của 1 lần làm bài sàng lọc mới, ánh xạ tới bảng
/// `screening_domain_results`. [diemQuyDoi12] null khi
/// [mucLinhVuc] = 'chua_du_du_lieu' (< 3/4 câu có điểm).
class ScreeningDomainResult {
  final String id;
  final String screeningId;
  final String childId;
  final String linhVuc;
  final int diemTho;
  final int soCauTraLoi;
  final int soCauNa;
  final double? diemQuyDoi12;
  final String mucLinhVuc; // 'du_lieu_du' | 'chua_du_du_lieu'
  final DateTime createdAt;

  const ScreeningDomainResult({
    required this.id,
    required this.screeningId,
    required this.childId,
    required this.linhVuc,
    required this.diemTho,
    required this.soCauTraLoi,
    required this.soCauNa,
    this.diemQuyDoi12,
    required this.mucLinhVuc,
    required this.createdAt,
  });
}
