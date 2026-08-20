/// 1 câu hỏi trong bộ sàng lọc mới (4 mức tuổi × 20 câu × 5 lĩnh vực).
class ScreeningQuestion {
  final String id;
  final String linhVuc;
  final String? nhomVanDong; // 'tho' | 'tinh', CHỈ khi linhVuc == 'van_dong'
  final int thuTuTrongLinhVuc;
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

/// Điểm 1 lĩnh vực sau khi chấm.
class DomainScoreCalculation {
  final String linhVuc;
  final int diemTho;
  final int soCauTraLoi;
  final int soCauNa;
  final double? diemQuyDoi12; // null nếu chưa đủ dữ liệu
  final String mucLinhVuc; // 'du_lieu_du' | 'chua_du_du_lieu'

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
  static ScreeningScoreResult calculateScore({
    required Map<String, ScreeningRawAnswer> answers,
    required List<ScreeningQuestion> questions,
  }) {
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

    final domain12Values = domainResults
        .map((d) => d.diemQuyDoi12!)
        .toList();
    final tong60 = domain12Values.fold<double>(0, (sum, v) => sum + v);
    final minDomain12 = domain12Values.reduce((a, b) => a < b ? a : b);

    final String giaiDoan;
    if (tong60 < nguongTong60GiaiDoan3 || minDomain12 < nguongDomain12GiaiDoan3) {
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
    final rounded = (raw * 10).round() / 10;

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
