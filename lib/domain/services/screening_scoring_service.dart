/// Mô tả câu hỏi trong bộ câu hỏi sàng lọc 50 câu 7 lĩnh vực.
class ScreeningQuestion {
  final String id;
  final int stt;
  final String linhVuc;
  final String tieuLinhVuc;
  final String noiDung;
  final String goiYQuanSat;

  const ScreeningQuestion({
    required this.id,
    required this.stt,
    required this.linhVuc,
    required this.tieuLinhVuc,
    required this.noiDung,
    required this.goiYQuanSat,
  });

  factory ScreeningQuestion.fromJson(Map<String, dynamic> json) =>
      ScreeningQuestion(
        id: json['id'] as String,
        stt: json['stt'] as int,
        linhVuc: json['linh_vuc'] as String,
        tieuLinhVuc: json['tieu_linh_vuc'] as String? ?? '',
        noiDung: json['noi_dung'] as String,
        goiYQuanSat: json['goi_y_quan_sat'] as String? ?? '',
      );
}

/// Thông tin tổng hợp thiết kế cho 1 lĩnh vực.
class ScreeningDomainSummaryInfo {
  final String linhVuc;
  final String tenHienThi;
  final int soCau;
  final int diemToiDa;

  const ScreeningDomainSummaryInfo({
    required this.linhVuc,
    required this.tenHienThi,
    required this.soCau,
    required this.diemToiDa,
  });

  factory ScreeningDomainSummaryInfo.fromJson(Map<String, dynamic> json) =>
      ScreeningDomainSummaryInfo(
        linhVuc: json['linh_vuc'] as String,
        tenHienThi: json['ten_hien_thi'] as String,
        soCau: json['so_cau'] as int,
        diemToiDa: json['diem_toi_da'] as int,
      );
}

/// Lựa chọn thang điểm.
class ScreeningScaleOption {
  final dynamic giaTri; // 0, 1, 2, "N/A"
  final String nhan;
  final String yNghia;
  final String cachHieu;

  const ScreeningScaleOption({
    required this.giaTri,
    required this.nhan,
    required this.yNghia,
    required this.cachHieu,
  });

  factory ScreeningScaleOption.fromJson(Map<String, dynamic> json) =>
      ScreeningScaleOption(
        giaTri: json['gia_tri'],
        nhan: json['nhan'] as String,
        yNghia: json['y_nghia'] as String? ?? '',
        cachHieu: json['cach_hieu'] as String? ?? '',
      );
}

/// Mức mô tả kết quả.
class ScreeningLevelDescription {
  final int muc;
  final String ten;
  final int phanTramMin;
  final int phanTramMax;
  final String yNghia;

  const ScreeningLevelDescription({
    required this.muc,
    required this.ten,
    required this.phanTramMin,
    required this.phanTramMax,
    required this.yNghia,
  });

  factory ScreeningLevelDescription.fromJson(Map<String, dynamic> json) =>
      ScreeningLevelDescription(
        muc: json['muc'] as int,
        ten: json['ten'] as String,
        phanTramMin: json['phan_tram_min'] as int,
        phanTramMax: json['phan_tram_max'] as int,
        yNghia: json['y_nghia'] as String? ?? '',
      );
}

/// Metadata bộ câu hỏi.
class ScreeningQuestionnaireMeta {
  final String boCauHoiId;
  final String phienBan;
  final String nguon;
  final String luuYKhongChanDoan;
  final int tongSoCau;
  final List<ScreeningScaleOption> thangDiem;
  final List<ScreeningLevelDescription> mucMoTa;

  const ScreeningQuestionnaireMeta({
    required this.boCauHoiId,
    required this.phienBan,
    required this.nguon,
    required this.luuYKhongChanDoan,
    required this.tongSoCau,
    required this.thangDiem,
    required this.mucMoTa,
  });

  factory ScreeningQuestionnaireMeta.fromJson(Map<String, dynamic> json) =>
      ScreeningQuestionnaireMeta(
        boCauHoiId: json['bo_cau_hoi_id'] as String? ?? '',
        phienBan: json['phien_ban'] as String? ?? '1.0',
        nguon: json['nguon'] as String? ?? '',
        luuYKhongChanDoan: json['luu_y_khong_chan_doan'] as String? ?? '',
        tongSoCau: json['tong_so_cau'] as int? ?? 50,
        thangDiem: (json['thang_diem'] as List<dynamic>? ?? [])
            .map((e) => ScreeningScaleOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        mucMoTa: (json['muc_mo_ta'] as List<dynamic>? ?? [])
            .map((e) => ScreeningLevelDescription.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Cấu trúc đầy đủ của bộ câu hỏi sàng lọc 50 câu 7 lĩnh vực.
class ScreeningQuestionnaireData {
  final ScreeningQuestionnaireMeta meta;
  final List<ScreeningDomainSummaryInfo> linhVucTongHop;
  final List<ScreeningQuestion> cauHoi;

  const ScreeningQuestionnaireData({
    required this.meta,
    required this.linhVucTongHop,
    required this.cauHoi,
  });

  factory ScreeningQuestionnaireData.fromJson(Map<String, dynamic> json) =>
      ScreeningQuestionnaireData(
        meta: ScreeningQuestionnaireMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? {},
        ),
        linhVucTongHop: (json['linh_vuc_tong_hop'] as List<dynamic>? ?? [])
            .map(
              (e) => ScreeningDomainSummaryInfo.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
        cauHoi: (json['cau_hoi'] as List<dynamic>? ?? [])
            .map((e) => ScreeningQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Kết quả tính điểm cho 1 lĩnh vực.
class DomainScoreCalculation {
  final String linhVuc;
  final String tenHienThi;
  final int soCauThietKe;
  final int soCauHopLe;
  final int diemTho;
  final double? diemPhanTram; // null khi soCauHopLe == 0

  const DomainScoreCalculation({
    required this.linhVuc,
    required this.tenHienThi,
    required this.soCauThietKe,
    required this.soCauHopLe,
    required this.diemTho,
    this.diemPhanTram,
  });

  bool get hasValidData => soCauHopLe > 0 && diemPhanTram != null;
}

/// Kết quả chấm điểm toàn bài sàng lọc.
class ScreeningScoreResult {
  final int soCauHopLeToanBai;
  final int soCauNAToanBai;
  final int diemThoToanBai;
  final double? diemToanBaiPhanTram;
  final String mucMoTaTen; // VD: "Mức 1 - Ít biểu hiện"
  final String mucMoTaYNghia;
  final int mucMoTaLevel; // 1, 2, 3
  final List<DomainScoreCalculation> domainScores;
  final String luuYKhongChanDoan;

  const ScreeningScoreResult({
    required this.soCauHopLeToanBai,
    required this.soCauNAToanBai,
    required this.diemThoToanBai,
    required this.diemToanBaiPhanTram,
    required this.mucMoTaTen,
    required this.mucMoTaYNghia,
    required this.mucMoTaLevel,
    required this.domainScores,
    required this.luuYKhongChanDoan,
  });
}

/// Service chấm điểm chính thức (hàm Dart thuần, không I/O).
class ScreeningScoringService {
  /// Tính điểm toàn bài và điểm từng lĩnh vực theo đúng quy tắc:
  /// 1. Đáp án: '0' (0 điểm), '1' (1 điểm), '2' (2 điểm), 'N/A' (không tính điểm).
  /// 2. N/A KHÔNG được quy đổi thành 0, KHÔNG tính vào mẫu số khi chuẩn hoá %.
  /// 3. Điểm lĩnh vực (%) = [Tổng điểm đạt được trong lĩnh vực / (Số câu hợp lệ × 2)] × 100
  ///    Nếu số câu hợp lệ = 0 -> diemPhanTram = null (hiển thị "Chưa đủ dữ liệu cho lĩnh vực này").
  /// 4. Điểm toàn bài (%) = [Tổng điểm đạt được toàn bài / (Số câu hợp lệ toàn bài × 2)] × 100
  /// 5. 3 mức mô tả (lấy từ meta.muc_mo_ta):
  ///    - 0-33%: Mức 1 - Ít biểu hiện
  ///    - 34-66%: Mức 2 - Có biểu hiện cần theo dõi
  ///    - 67-100%: Mức 3 - Nhiều biểu hiện khó khăn
  static ScreeningScoreResult calculateScore({
    required Map<String, String> answers, // cau_hoi_id -> '0' | '1' | '2' | 'N/A'
    required ScreeningQuestionnaireData questionnaire,
  }) {
    final domainMap = <String, ScreeningDomainSummaryInfo>{};
    for (final d in questionnaire.linhVucTongHop) {
      domainMap[d.linhVuc] = d;
    }

    // Nhóm câu hỏi theo lĩnh vực
    final questionsByDomain = <String, List<ScreeningQuestion>>{};
    for (final q in questionnaire.cauHoi) {
      questionsByDomain.putIfAbsent(q.linhVuc, () => []).add(q);
    }

    final domainScoreResults = <DomainScoreCalculation>[];
    int totalValidCount = 0;
    int totalNACount = 0;
    int totalRawScore = 0;

    for (final d in questionnaire.linhVucTongHop) {
      final domainQuestions = questionsByDomain[d.linhVuc] ?? [];
      int domainValidCount = 0;
      int domainRawScore = 0;

      for (final q in domainQuestions) {
        final answer = answers[q.id]?.trim();
        if (answer == '0') {
          domainValidCount++;
        } else if (answer == '1') {
          domainValidCount++;
          domainRawScore += 1;
        } else if (answer == '2') {
          domainValidCount++;
          domainRawScore += 2;
        } else if (answer == 'N/A' || answer == 'na' || answer == 'NA') {
          totalNACount++;
        }
      }

      totalValidCount += domainValidCount;
      totalRawScore += domainRawScore;

      final double? domainPct;
      if (domainValidCount > 0) {
        domainPct = (domainRawScore / (domainValidCount * 2)) * 100.0;
      } else {
        domainPct = null;
      }

      domainScoreResults.add(
        DomainScoreCalculation(
          linhVuc: d.linhVuc,
          tenHienThi: d.tenHienThi,
          soCauThietKe: d.soCau,
          soCauHopLe: domainValidCount,
          diemTho: domainRawScore,
          diemPhanTram: domainPct,
        ),
      );
    }

    final double? totalPct;
    if (totalValidCount > 0) {
      totalPct = (totalRawScore / (totalValidCount * 2)) * 100.0;
    } else {
      totalPct = null;
    }

    // Xác định mức mô tả dựa trên totalPct
    final levelResult = _determineLevel(totalPct, questionnaire.meta.mucMoTa);

    return ScreeningScoreResult(
      soCauHopLeToanBai: totalValidCount,
      soCauNAToanBai: totalNACount,
      diemThoToanBai: totalRawScore,
      diemToanBaiPhanTram: totalPct,
      mucMoTaTen: levelResult.ten,
      mucMoTaYNghia: levelResult.yNghia,
      mucMoTaLevel: levelResult.muc,
      domainScores: domainScoreResults,
      luuYKhongChanDoan: questionnaire.meta.luuYKhongChanDoan,
    );
  }

  static ({int muc, String ten, String yNghia}) _determineLevel(
    double? totalPct,
    List<ScreeningLevelDescription> mucMoTaList,
  ) {
    if (totalPct == null) {
      return (
        muc: 0,
        ten: 'Chưa đủ dữ liệu',
        yNghia: 'Tất cả các câu hỏi đều được chọn N/A nên chưa đủ dữ liệu để tính điểm.',
      );
    }

    final roundedPct = totalPct.round();

    // Tìm trong danh sách mucMoTa từ JSON
    for (final m in mucMoTaList) {
      if (roundedPct >= m.phanTramMin && roundedPct <= m.phanTramMax) {
        return (muc: m.muc, ten: m.ten, yNghia: m.yNghia);
      }
    }

    // Fallback chuẩn 3 mức nếu không match danh sách
    if (roundedPct <= 33) {
      return (
        muc: 1,
        ten: 'Mức 1 - Ít biểu hiện',
        yNghia: 'Ít biểu hiện khó khăn được ghi nhận trong bộ câu hỏi hiện tại.',
      );
    } else if (roundedPct <= 66) {
      return (
        muc: 2,
        ten: 'Mức 2 - Có biểu hiện cần theo dõi',
        yNghia: 'Một số khó khăn xuất hiện khá rõ ở một hoặc nhiều lĩnh vực.',
      );
    } else {
      return (
        muc: 3,
        ten: 'Mức 3 - Nhiều biểu hiện khó khăn',
        yNghia:
            'Nhiều biểu hiện được ghi nhận thường xuyên/rõ rệt; nên cân nhắc trao đổi với chuyên gia phù hợp.',
      );
    }
  }
}
