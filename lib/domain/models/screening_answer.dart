/// Model câu trả lời 1 câu hỏi trong bài sàng lọc mới, ánh xạ tới bảng
/// `screening_answers`. 1 `ScreeningSession` có đúng 20 bản ghi (đúng số
/// câu của mức tuổi tương ứng).
class ScreeningAnswer {
  final String id;
  final String screeningId;
  final String childId;

  /// Trùng `ScreeningSession.mucTuoiLamBai` của cùng lần làm bài — lưu lặp
  /// lại ở đây để truy vấn câu trả lời theo mức tuổi mà không cần JOIN.
  final String mucTuoiLamBai;

  /// Khớp `ScreeningQuestion.id`.
  final String cauHoiId;

  /// 1 trong 5 mã lĩnh vực — với câu vận động, LUÔN là `'van_dong'` dù
  /// thuộc nhóm thô hay tinh (xem [nhomVanDong]).
  final String linhVuc;

  /// `'tho'` | `'tinh'` — CHỈ khác `null` khi [linhVuc] == `'van_dong'`,
  /// dùng để hiển thị breakdown tham khảo, KHÔNG dùng khi chấm điểm (chấm
  /// điểm luôn gộp theo [linhVuc]).
  final String? nhomVanDong;

  /// 0-3, `null` khi [laNa] = `true`.
  final int? diem;

  /// `true` = "chưa quan sát được" (không tính vào điểm thô/mẫu số).
  final bool laNa;

  final DateTime createdAt;

  const ScreeningAnswer({
    required this.id,
    required this.screeningId,
    required this.childId,
    required this.mucTuoiLamBai,
    required this.cauHoiId,
    required this.linhVuc,
    this.nhomVanDong,
    this.diem,
    required this.laNa,
    required this.createdAt,
  });
}
