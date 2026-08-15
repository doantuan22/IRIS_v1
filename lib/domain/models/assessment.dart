/// Model dữ liệu đánh giá 7 lĩnh vực, ánh xạ tới bảng `assessments`.
/// Chỉ chứa dữ liệu riêng của trẻ (mô tả biểu hiện / ghi chú chuyên gia
/// case-specific), không phải nội dung tham khảo chung.
class Assessment {
  final String id;
  final String childId;
  final String linhVuc;
  final String contentType;
  final String content;
  final String? nguon;
  final String? performedBy;
  final DateTime createdAt;

  const Assessment({
    required this.id,
    required this.childId,
    required this.linhVuc,
    required this.contentType,
    required this.content,
    this.nguon,
    this.performedBy,
    required this.createdAt,
  });
}
