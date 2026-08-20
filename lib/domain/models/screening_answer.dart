/// Model câu trả lời 1 câu hỏi trong bài sàng lọc mới, ánh xạ tới bảng
/// `screening_answers`. [diem] null khi [laNa] = true.
/// [nhomVanDong] chỉ khác null khi [linhVuc] = 'van_dong' ('tho'/'tinh').
class ScreeningAnswer {
  final String id;
  final String screeningId;
  final String childId;
  final String mucTuoiLamBai;
  final String cauHoiId;
  final String linhVuc;
  final String? nhomVanDong;
  final int? diem; // 0-3, null nếu laNa
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
