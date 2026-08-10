/// Model kết quả sàng lọc, ánh xạ tới bảng `screenings`. Chỉ tồn tại khi
/// người dùng thực sự chọn "Có" ở Bước 3 và hoàn thành bài sàng lọc.
class Screening {
  final String id;
  final String childId;
  final String? toolName;
  final String? score;
  final String? resultSummary;
  final DateTime? performedAt;
  final DateTime createdAt;

  const Screening({
    required this.id,
    required this.childId,
    this.toolName,
    this.score,
    this.resultSummary,
    this.performedAt,
    required this.createdAt,
  });
}
