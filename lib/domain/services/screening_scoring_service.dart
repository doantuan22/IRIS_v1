/// 1 câu hỏi trong bộ sàng lọc mới (4 mức tuổi × 20 câu × 5 lĩnh vực).
class ScreeningQuestion {
  /// Khóa duy nhất của câu hỏi trong toàn bộ 80 câu (4 mức × 20 câu),
  /// khớp `screening_answers.cau_hoi_id`.
  final String id;

  /// 1 trong 5 mã lĩnh vực chuẩn (`screeningDomains` trong
  /// `screening_domains.dart`). Với lĩnh vực `van_dong`, đây LUÔN là
  /// `'van_dong'` dù câu hỏi thuộc nhóm con thô hay tinh — việc CHẤM ĐIỂM
  /// gộp chung cả 4 câu vận động vào 1 lĩnh vực duy nhất, phân biệt nhóm
  /// con chỉ để HIỂN THỊ qua [nhomVanDong].
  final String linhVuc;

  /// `'tho'` | `'tinh'` — CHỈ khác `null` khi [linhVuc] == `'van_dong'`.
  /// Đây là field DUY NHẤT tách vận động thô/tinh; tuyệt đối không dùng
  /// field này để nhóm câu hỏi khi tính điểm (xem
  /// `ScreeningScoringService._calculateDomainScore`).
  final String? nhomVanDong;

  /// Thứ tự câu hỏi TRONG lĩnh vực (1-4), không phải thứ tự trong cả bài.
  final int thuTuTrongLinhVuc;

  /// Nội dung câu hỏi hiển thị cho người dùng.
  final String noiDung;

  const ScreeningQuestion({
    required this.id,
    required this.linhVuc,
    this.nhomVanDong,
    required this.thuTuTrongLinhVuc,
    required this.noiDung,
  });

  factory ScreeningQuestion.fromJson(Map<String, dynamic> json) =>
      ScreeningQuestion(
        id: json['id'] as String,
        linhVuc: json['linh_vuc'] as String,
        nhomVanDong: json['nhom_van_dong'] as String?,
        thuTuTrongLinhVuc: json['thu_tu_trong_linh_vuc'] as int,
        noiDung: json['noi_dung'] as String,
      );
}

/// Bộ 20 câu của ĐÚNG 1 mức tuổi (2/3/4/5 tuổi).
class ScreeningTierQuestionnaire {
  final String mucTuoi; // '2_tuoi' | '3_tuoi' | '4_tuoi' | '5_tuoi'
  final int thangTuoiMin;
  final int thangTuoiMax;
  final List<ScreeningQuestion> cauHoi;

  const ScreeningTierQuestionnaire({
    required this.mucTuoi,
    required this.thangTuoiMin,
    required this.thangTuoiMax,
    required this.cauHoi,
  });

  factory ScreeningTierQuestionnaire.fromJson(Map<String, dynamic> json) =>
      ScreeningTierQuestionnaire(
        mucTuoi: json['muc_tuoi'] as String,
        thangTuoiMin: json['thang_tuoi_min'] as int,
        thangTuoiMax: json['thang_tuoi_max'] as int,
        cauHoi: (json['cau_hoi'] as List<dynamic>)
            .map((e) => ScreeningQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Toàn bộ bộ câu hỏi sàng lọc mới — 4 mức tuổi.
class ScreeningQuestionnaireData {
  final List<ScreeningTierQuestionnaire> tiers;

  const ScreeningQuestionnaireData({required this.tiers});

  factory ScreeningQuestionnaireData.fromJsonList(List<dynamic> jsonList) =>
      ScreeningQuestionnaireData(
        tiers: jsonList
            .map(
              (e) => ScreeningTierQuestionnaire.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  /// Trả về bộ 20 câu của ĐÚNG mức tuổi, `null` nếu không có (dữ liệu thiếu).
  ScreeningTierQuestionnaire? forTier(String mucTuoi) {
    for (final t in tiers) {
      if (t.mucTuoi == mucTuoi) return t;
    }
    return null;
  }
}

/// Điểm 1 lĩnh vực sau khi chấm — xem `_calculateDomainScore` để biết cách
/// tính từng field.
class DomainScoreCalculation {
  final String linhVuc;

  /// Tổng điểm thô (0-3) của các câu ĐÃ trả lời (không tính N/A) — tối đa
  /// 12 nếu cả 4 câu đều đạt điểm 3.
  final int diemTho;

  /// Số câu có điểm 0-3 (không N/A), tối đa 4.
  final int soCauTraLoi;

  /// Số câu N/A (không tính vào [diemTho]/[soCauTraLoi]), tối đa 4.
  final int soCauNa;

  /// Điểm quy đổi về thang 12, `null` khi [mucLinhVuc] =
  /// [mucLinhVucChuaDuDuLieu] (≥2 câu N/A). Đây là giá trị DUY NHẤT của
  /// lĩnh vực này tham gia thuật toán phân giai đoạn — không dùng
  /// [diemTho] trực tiếp vì số câu trả lời có thể khác 4 khi có N/A.
  final double? diemQuyDoi12;

  /// [mucLinhVucDuDuLieu] | [mucLinhVucChuaDuDuLieu].
  final String mucLinhVuc;

  const DomainScoreCalculation({
    required this.linhVuc,
    required this.diemTho,
    required this.soCauTraLoi,
    required this.soCauNa,
    this.diemQuyDoi12,
    required this.mucLinhVuc,
  });

  bool get duDuLieu => mucLinhVuc == mucLinhVucDuDuLieu;
}

const String mucLinhVucDuDuLieu = 'du_lieu_du';
const String mucLinhVucChuaDuDuLieu = 'chua_du_du_lieu';

const String giaiDoan1 = '1';
const String giaiDoan2 = '2';
const String giaiDoan3 = '3';
const String giaiDoanChuaDuDuLieu = 'chua_du_du_lieu';

/// Nhãn ngắn hiển thị cho từng giá trị `giai_doan`.
String screeningGiaiDoanLabel(String giaiDoan) {
  switch (giaiDoan) {
    case giaiDoan1:
      return 'Giai đoạn 1';
    case giaiDoan2:
      return 'Giai đoạn 2';
    case giaiDoan3:
      return 'Giai đoạn 3';
    default:
      return 'Chưa đủ dữ liệu';
  }
}

/// Mô tả ý nghĩa ngắn gọn cho từng giá trị `giai_doan`, phỏng theo NGUYÊN
/// VĂN bảng "Ý nghĩa sử dụng" trong
/// `Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx` (mục 5),
/// rút gọn nhẹ cho vừa màn hình di động — không đổi ý nghĩa. Trả `null`
/// cho `chua_du_du_lieu` — giữ nguyên hiện trạng (trước đây KHÔNG có mô tả
/// riêng cho trường hợp này, chỉ có nhãn ngắn), không tự bịa thêm nội
/// dung mới. Nguồn DUY NHẤT cho mô tả này, không hardcode lặp lại ở UI.
String? screeningGiaiDoanDescription(String giaiDoan) {
  switch (giaiDoan) {
    case giaiDoan1:
      return 'Phát triển tương đối phù hợp theo bộ câu hỏi. Tiếp tục tạo '
          'cơ hội phát triển và theo dõi định kỳ.';
    case giaiDoan2:
      return 'Có lĩnh vực cần theo dõi và tăng cường hỗ trợ. Nên đánh giá '
          'lại sau một khoảng thời gian theo dõi phù hợp.';
    case giaiDoan3:
      return 'Có lĩnh vực cần được quan tâm nhiều hơn. Nên tìm đánh giá '
          'thêm từ bác sĩ/chuyên gia phát triển trẻ em.';
    default:
      return null;
  }
}

/// Kết quả chấm điểm toàn bài.
class ScreeningScoreResult {
  final double? tongDiem60; // null nếu bất kỳ lĩnh vực nào chưa đủ dữ liệu
  final String giaiDoan; // '1' | '2' | '3' | 'chua_du_du_lieu'
  final List<DomainScoreCalculation> domainResults;

  const ScreeningScoreResult({
    required this.tongDiem60,
    required this.giaiDoan,
    required this.domainResults,
  });
}

/// Ngưỡng thang điểm 60 — GIẢ ĐỊNH NỘI BỘ của dự án, CHƯA chuẩn hóa lâm
/// sàng, KHÔNG dùng để chẩn đoán. Xem
/// `Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx` (tài liệu
/// gốc của cố vấn chuyên môn).
const double nguongTong60GiaiDoan3 = 35.0;
const double nguongTong60GiaiDoan2 = 50.0;
const double nguongDomain12GiaiDoan3 = 6.0;
const double nguongDomain12GiaiDoan2 = 9.0;

/// Số câu tối thiểu CÓ điểm (không N/A) trong 1 lĩnh vực (4 câu/lĩnh vực)
/// để coi là đủ dữ liệu chấm điểm lĩnh vực đó.
const int soCauToiThieuDuDuLieu = 3;

/// Câu trả lời 1 câu hỏi — dùng làm input cho [ScreeningScoringService].
typedef ScreeningRawAnswer = ({int? diem, bool laNa});

/// Service chấm điểm chính thức cho bộ sàng lọc mới (hàm Dart thuần,
/// không I/O). Thay thế hoàn toàn thuật toán 50 câu/7 lĩnh vực cũ.
class ScreeningScoringService {
  /// Chấm điểm toàn bài dựa trên [answers] (cau_hoi_id -> điểm/N/A) và
  /// [questions] (đúng 20 câu của mức tuổi đang làm).
  ///
  /// Thứ tự xử lý, đúng "Thứ tự ra quyết định" (mục 6) của tài liệu gốc
  /// `Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx`:
  /// 1. Tính điểm từng lĩnh vực (gộp theo `linhVuc`, KHÔNG tách
  ///    `nhomVanDong` — xem [_calculateDomainScore]).
  /// 2. Nếu bất kỳ lĩnh vực nào chưa đủ dữ liệu (≥2 câu N/A) → dừng ngay,
  ///    trả `giaiDoanChuaDuDuLieu`, KHÔNG tính điểm tổng — vì tổng chỉ có ý
  ///    nghĩa khi cả 5 lĩnh vực đều có số liệu đáng tin.
  /// 3. Nếu đủ dữ liệu: kiểm tra ĐIỀU KIỆN GIAI ĐOẠN 3 TRƯỚC (tổng <35
  ///    HOẶC có lĩnh vực <6/12), rồi mới tới Giai đoạn 2. Thứ tự ưu tiên
  ///    này (3→2→1, không phải chấm điểm cộng dồn rồi so ngưỡng cuối) là
  ///    quy tắc CỐT LÕI của thuật toán: nếu chỉ dùng tổng điểm, 1 lĩnh vực
  ///    yếu rõ rệt có thể bị các lĩnh vực mạnh khác "bù điểm" che lấp (ví
  ///    dụ tài liệu gốc mục 8: Ngôn ngữ 5/12 nhưng 4 lĩnh vực còn lại cao
  ///    → tổng 47/60 nằm ở vùng "theo dõi" nếu chỉ nhìn tổng, nhưng vì có
  ///    lĩnh vực <6 nên PHẢI xếp Giai đoạn 3).
  static ScreeningScoreResult calculateScore({
    required Map<String, ScreeningRawAnswer> answers,
    required List<ScreeningQuestion> questions,
  }) {
    // Gộp câu hỏi theo linhVuc (KHÔNG theo nhomVanDong) — đây là bước đảm
    // bảo van_dong (2 câu thô + 2 câu tinh) được chấm như 1 lĩnh vực duy
    // nhất thay vì tách thành 2 lĩnh vực con.
    final questionsByDomain = <String, List<ScreeningQuestion>>{};
    for (final q in questions) {
      questionsByDomain.putIfAbsent(q.linhVuc, () => []).add(q);
    }

    final domainResults = <DomainScoreCalculation>[];
    for (final entry in questionsByDomain.entries) {
      domainResults.add(_calculateDomainScore(entry.key, entry.value, answers));
    }

    final anyInsufficient = domainResults.any((d) => !d.duDuLieu);

    if (anyInsufficient) {
      return ScreeningScoreResult(
        tongDiem60: null,
        giaiDoan: giaiDoanChuaDuDuLieu,
        domainResults: domainResults,
      );
    }

    final domain12Values = domainResults.map((d) => d.diemQuyDoi12!).toList();
    final tong60 = domain12Values.fold<double>(0, (sum, v) => sum + v);
    final minDomain12 = domain12Values.reduce((a, b) => a < b ? a : b);

    // Kiểm tra Giai đoạn 3 TRƯỚC Giai đoạn 2, Giai đoạn 2 TRƯỚC Giai đoạn
    // 1 — đúng thứ tự ưu tiên đã giải thích ở docstring trên. Đảo ngược
    // thứ tự (kiểm tra GĐ1 trước) sẽ làm sai hoàn toàn ý nghĩa "chống bù
    // điểm" của thuật toán.
    final String giaiDoan;
    if (tong60 < nguongTong60GiaiDoan3 ||
        minDomain12 < nguongDomain12GiaiDoan3) {
      giaiDoan = giaiDoan3;
    } else if (tong60 < nguongTong60GiaiDoan2 ||
        minDomain12 < nguongDomain12GiaiDoan2) {
      giaiDoan = giaiDoan2;
    } else {
      giaiDoan = giaiDoan1;
    }

    return ScreeningScoreResult(
      tongDiem60: tong60,
      giaiDoan: giaiDoan,
      domainResults: domainResults,
    );
  }

  /// Tính điểm 1 lĩnh vực (4 câu — với `van_dong`, [domainQuestions] gồm
  /// CẢ 2 câu tho + 2 câu tinh, xem [calculateScore]).
  ///
  /// Quy tắc "chưa đủ dữ liệu" (mục 3 tài liệu gốc): 1 câu N/A vẫn được
  /// phép quy đổi bù (coi như "chưa có cơ hội quan sát", không tính là
  /// điểm kém); nhưng ≥2 câu N/A trong CÙNG 1 lĩnh vực thì mẫu số còn lại
  /// quá nhỏ để tin cậy → đánh dấu [mucLinhVucChuaDuDuLieu], không chấm
  /// điểm lĩnh vực đó (và kéo theo không chấm được điểm tổng — xem
  /// [calculateScore]).
  ///
  /// Công thức quy đổi khi đủ dữ liệu (>=3 câu có điểm):
  /// `domain12 = diemTho / (3 * soCauTraLoi) * 12`
  /// Lý do quy đổi thay vì lấy thẳng [diemTho]: mẫu số `3 * soCauTraLoi` là
  /// điểm TỐI ĐA CÓ THỂ ĐẠT với đúng [soCauTraLoi] câu đã trả lời (mỗi câu
  /// tối đa 3 điểm) — quy đổi tỷ lệ này về thang 12 (thang chuẩn cho 4
  /// câu) để 1 lĩnh vực có 3/4 câu (1 câu N/A) không bị mặc định thấp hơn
  /// lĩnh vực có đủ 4/4 câu chỉ vì thiếu 1 cơ hội quan sát. Làm tròn 1 chữ
  /// số thập phân theo đúng tài liệu gốc (mục 3, ví dụ: 3,2,3,N/A → tổng
  /// thô 8/9 → 8/9×12 = 10,7/12).
  static DomainScoreCalculation _calculateDomainScore(
    String linhVuc,
    List<ScreeningQuestion> domainQuestions,
    Map<String, ScreeningRawAnswer> answers,
  ) {
    int diemTho = 0;
    int soCauTraLoi = 0;
    int soCauNa = 0;

    for (final q in domainQuestions) {
      final answer = answers[q.id];
      // Câu chưa trả lời (không có trong `answers`) được coi như N/A —
      // KHÔNG ép về điểm 0, tránh phạt oan trẻ chưa có cơ hội quan sát.
      if (answer == null || answer.laNa) {
        soCauNa++;
        continue;
      }
      soCauTraLoi++;
      diemTho += answer.diem ?? 0;
    }

    if (soCauTraLoi < soCauToiThieuDuDuLieu) {
      return DomainScoreCalculation(
        linhVuc: linhVuc,
        diemTho: diemTho,
        soCauTraLoi: soCauTraLoi,
        soCauNa: soCauNa,
        diemQuyDoi12: null,
        mucLinhVuc: mucLinhVucChuaDuDuLieu,
      );
    }

    final raw = diemTho / (3 * soCauTraLoi) * 12;
    final rounded = (raw * 10).round() / 10; // làm tròn 1 chữ số thập phân

    return DomainScoreCalculation(
      linhVuc: linhVuc,
      diemTho: diemTho,
      soCauTraLoi: soCauTraLoi,
      soCauNa: soCauNa,
      diemQuyDoi12: rounded,
      mucLinhVuc: mucLinhVucDuDuLieu,
    );
  }
}
