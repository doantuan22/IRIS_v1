/// Model chunk dữ liệu hồ sơ trẻ, ánh xạ tới bảng `profile_chunks`. Đây là
/// dữ liệu RIÊNG của 1 trẻ (mục 1 "Mô tả biểu hiện" + ghi chú case-specific
/// từ chuyên gia), dùng cho retrieval khi hỏi đáp AI.
class ProfileChunk {
  final String id;
  final String childId;
  final String content;
  final String? linhVuc;
  final String? nguon;
  final List<double> embedding;
  final DateTime createdAt;

  const ProfileChunk({
    required this.id,
    required this.childId,
    required this.content,
    this.linhVuc,
    this.nguon,
    required this.embedding,
    required this.createdAt,
  });
}
