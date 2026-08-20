/// Model 1 lần làm bài sàng lọc mới, ánh xạ tới bảng `screening_sessions`.
/// [tongDiem60] null khi bất kỳ lĩnh vực nào chưa đủ dữ liệu.
/// [giaiDoan] là 1 trong '1'/'2'/'3'/'chua_du_du_lieu'.
class ScreeningSession {
  final String id;
  final String childId;
  final String mucTuoiLamBai;
  final double? tongDiem60;
  final String giaiDoan;
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
