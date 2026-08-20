/// Model 1 lần làm bài sàng lọc mới, ánh xạ tới bảng `screening_sessions`.
class ScreeningSession {
  final String id;
  final String childId;

  /// '2_tuoi' | '3_tuoi' | '4_tuoi' | '5_tuoi' — mức tuổi bộ câu hỏi đã
  /// dùng, xác định bởi `resolveScreeningAgeTier()` tại thời điểm làm bài
  /// (không đổi về sau dù trẻ lớn thêm tuổi).
  final String mucTuoiLamBai;

  /// `null` khi bất kỳ lĩnh vực nào trong 5 lĩnh vực chưa đủ dữ liệu (xem
  /// `ScreeningScoringService.calculateScore`), khác thì trong khoảng
  /// 0.0-60.0.
  final double? tongDiem60;

  /// '1' | '2' | '3' | 'chua_du_du_lieu' — tính 100% bằng code
  /// (`ScreeningScoringService`), không phải người dùng tự chọn.
  final String giaiDoan;

  /// LUÔN `false` kể từ khi màn hỏi "cờ cảnh báo" (mất kỹ năng đã từng có
  /// / lo ngại phát triển rõ rệt) bị bỏ khỏi luồng làm bài — xem
  /// `SETUP_REPORT.md` (mục "Bỏ hẳn màn hỏi cờ cảnh báo"). Cột DB vẫn giữ
  /// nguyên (không migration) để tránh đổi schema không cần thiết, nhưng
  /// KHÔNG còn ý nghĩa nghiệp vụ nào — đừng dựa vào field này để hiển thị
  /// hay quyết định logic gì trong code mới.
  final bool coCanhBao;

  final DateTime ngayThucHien;
  final DateTime createdAt;

  const ScreeningSession({
    required this.id,
    required this.childId,
    required this.mucTuoiLamBai,
    this.tongDiem60,
    required this.giaiDoan,
    required this.coCanhBao,
    required this.ngayThucHien,
    required this.createdAt,
  });
}
