/// Model điểm 1 lĩnh vực của 1 lần làm bài sàng lọc mới, ánh xạ tới bảng
/// `screening_domain_results`. 1 `ScreeningSession` có đúng 5 bản ghi
/// (5 lĩnh vực) — kể cả lĩnh vực `van_dong` (gộp cả câu thô + tinh) cũng
/// chỉ 1 bản ghi, không tách riêng.
class ScreeningDomainResult {
  final String id;
  final String screeningId;
  final String childId;
  final String linhVuc;

  /// Tổng điểm thô (0-3/câu) của các câu ĐÃ trả lời, tối đa 12.
  final int diemTho;

  /// Số câu có điểm (không N/A), tối đa 4.
  final int soCauTraLoi;

  /// Số câu N/A, tối đa 4.
  final int soCauNa;

  /// Điểm quy đổi thang 12 — `null` khi [mucLinhVuc] = `'chua_du_du_lieu'`
  /// (≥2/4 câu N/A). Xem
  /// `ScreeningScoringService._calculateDomainScore` để biết công thức.
  final double? diemQuyDoi12;

  /// `'du_lieu_du'` | `'chua_du_du_lieu'`.
  final String mucLinhVuc;
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
