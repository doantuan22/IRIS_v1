import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/core/constants/screening_domains.dart';
import 'package:iris_app/domain/services/screening_loader_service.dart';
import 'package:iris_app/domain/services/screening_scoring_service.dart';

/// Test đối chiếu bộ sàng lọc mới (4 mức tuổi × 20 câu × 5 lĩnh vực) với
/// dữ liệu THẬT đã chuyển đổi từ 2 tài liệu gốc:
/// - `Bo_cau_hoi_sang_loc_phat_trien_tre_em_2-5_tuoi_ban_chinh_sua.docx`
///   (nội dung câu hỏi)
/// - `Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx` (thang
///   điểm 0-3, thuật toán 3 giai đoạn, 3 ví dụ chấm điểm mẫu)
void main() {
  late ScreeningQuestionnaireData questionnaireData;

  setUpAll(() {
    final jsonString = File(
      'assets/reference/sang_loc_20_cau_4_muc_tuoi.json',
    ).readAsStringSync();
    questionnaireData = ScreeningLoaderService.parseJson(jsonString);
  });

  group('Cấu trúc dữ liệu JSON thật', () {
    test('đúng 4 mức tuổi × 20 câu = 80 câu tổng', () {
      expect(questionnaireData.tiers, hasLength(4));
      var total = 0;
      for (final tier in questionnaireData.tiers) {
        expect(
          tier.cauHoi,
          hasLength(20),
          reason: 'mức ${tier.mucTuoi} phải có đúng 20 câu',
        );
        total += tier.cauHoi.length;
      }
      expect(total, 80);
    });

    test('mỗi mức đúng 5 lĩnh vực × 4 câu', () {
      const expectedDomains = [
        'ngon_ngu_giao_tiep',
        'nhan_thuc_giai_quyet_van_de',
        'van_dong',
        'xa_hoi_cam_xuc',
        'tu_lap',
      ];
      for (final tier in questionnaireData.tiers) {
        final byDomain = <String, int>{};
        for (final q in tier.cauHoi) {
          byDomain[q.linhVuc] = (byDomain[q.linhVuc] ?? 0) + 1;
        }
        expect(
          byDomain.keys.toSet(),
          expectedDomains.toSet(),
          reason: 'mức ${tier.mucTuoi} phải đúng 5 lĩnh vực',
        );
        for (final domain in expectedDomains) {
          expect(
            byDomain[domain],
            4,
            reason: 'mức ${tier.mucTuoi} lĩnh vực $domain phải có 4 câu',
          );
        }
      }
    });

    test('lĩnh vực van_dong mỗi mức đúng 2 câu tho + 2 câu tinh, 4 lĩnh vực còn lại nhom_van_dong=null', () {
      for (final tier in questionnaireData.tiers) {
        final vanDongQuestions = tier.cauHoi
            .where((q) => q.linhVuc == 'van_dong')
            .toList();
        final tho = vanDongQuestions.where((q) => q.nhomVanDong == 'tho');
        final tinh = vanDongQuestions.where((q) => q.nhomVanDong == 'tinh');
        expect(tho, hasLength(2), reason: '${tier.mucTuoi}: van_dong tho');
        expect(tinh, hasLength(2), reason: '${tier.mucTuoi}: van_dong tinh');

        final others = tier.cauHoi.where((q) => q.linhVuc != 'van_dong');
        for (final q in others) {
          expect(
            q.nhomVanDong,
            isNull,
            reason: '${q.id}: lĩnh vực ${q.linhVuc} không phải van_dong nên nhom_van_dong phải null',
          );
        }
      }
    });

    test('không trùng id trong toàn bộ 80 câu', () {
      final allIds = <String>[];
      for (final tier in questionnaireData.tiers) {
        for (final q in tier.cauHoi) {
          allIds.add(q.id);
        }
      }
      expect(allIds.toSet(), hasLength(allIds.length));
    });

    test('nội dung 8 câu mẫu (>=2/mức, rải đều lĩnh vực) khớp nguyên văn tài liệu Word gốc', () {
      // Đối chiếu thủ công đã thực hiện trước khi ingest — test này giữ lại
      // 8 câu mẫu đó làm regression: nếu ai sửa nhầm nội dung sau này, test
      // sẽ báo đỏ ngay.
      final samples = <String, String>{
        'sl_2t_ngon_ngu_giao_tiep_01':
            'Trẻ có thể chủ động ghép ít nhất hai từ có nghĩa để diễn đạt điều mình muốn hoặc đang quan tâm không?',
        'sl_2t_van_dong_tho_02':
            'Trẻ có thể đá một quả bóng đang đứng yên về phía trước không?',
        'sl_3t_nhan_thuc_giai_quyet_van_de_03':
            'Trẻ có thể hoàn thành một trò chơi ghép hình đơn giản bằng cách đặt các mảnh vào đúng vị trí không?',
        'sl_3t_van_dong_tinh_03':
            'Trẻ có thể xâu các vật có lỗ lớn, chẳng hạn hạt lớn hoặc vòng, vào dây không?',
        'sl_4t_xa_hoi_cam_xuc_04':
            'Khi buồn, giận hoặc thất vọng, trẻ có thể dần bình tĩnh trở lại bằng lời nhắc hoặc hướng dẫn đơn giản của người lớn không?',
        'sl_4t_tu_lap_01':
            'Trẻ có thể tự mặc và cởi phần lớn quần áo hằng ngày (chưa cần thành thạo cài khuy, kéo khóa) không?',
        'sl_5t_ngon_ngu_giao_tiep_04':
            'Trẻ có thể diễn đạt nhu cầu, suy nghĩ hoặc trải nghiệm của mình bằng lời nói đủ rõ để người không thường xuyên chăm sóc trẻ vẫn có thể hiểu phần lớn nội dung không?',
        'sl_5t_nhan_thuc_giai_quyet_van_de_01':
            'Trẻ có thể đếm đúng một nhóm đồ vật có số lượng nhỏ bằng cách đếm mỗi vật một lần không?',
      };

      final idToContent = <String, String>{};
      for (final tier in questionnaireData.tiers) {
        for (final q in tier.cauHoi) {
          idToContent[q.id] = q.noiDung;
        }
      }

      samples.forEach((id, expectedText) {
        expect(
          idToContent[id],
          expectedText,
          reason: 'câu $id phải khớp nguyên văn tài liệu Word gốc',
        );
      });
    });
  });

  group('ScreeningScoringService — thuật toán chấm điểm (dùng câu hỏi thật)', () {
    ScreeningTierQuestionnaire tierFor(String muc) =>
        questionnaireData.forTier(muc)!;

    test('cả 5 lĩnh vực đủ dữ liệu (0 N/A, toàn bộ điểm 3) -> domain12=12.0 mỗi lĩnh vực, tong60=60.0, Giai đoạn 1', () {
      final tier = tierFor('2_tuoi');
      final answers = <String, ScreeningRawAnswer>{
        for (final q in tier.cauHoi) q.id: (diem: 3, laNa: false),
      };
      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questions: tier.cauHoi,
      );
      expect(result.tongDiem60, 60.0);
      expect(result.giaiDoan, giaiDoan1);
      for (final d in result.domainResults) {
        expect(d.diemQuyDoi12, 12.0);
        expect(d.mucLinhVuc, mucLinhVucDuDuLieu);
      }
    });

    test('1 lĩnh vực có đúng 1 câu N/A (3,2,3,N/A) -> quy đổi = 8/9*12 = 10.7/12', () {
      final tier = tierFor('3_tuoi');
      final domainQuestions = tier.cauHoi
          .where((q) => q.linhVuc == 'ngon_ngu_giao_tiep')
          .toList();
      final answers = <String, ScreeningRawAnswer>{
        for (final q in tier.cauHoi) q.id: (diem: 3, laNa: false),
      };
      answers[domainQuestions[0].id] = (diem: 3, laNa: false);
      answers[domainQuestions[1].id] = (diem: 2, laNa: false);
      answers[domainQuestions[2].id] = (diem: 3, laNa: false);
      answers[domainQuestions[3].id] = (diem: null, laNa: true);

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questions: tier.cauHoi,
      );
      final ngonNguResult = result.domainResults.firstWhere(
        (d) => d.linhVuc == 'ngon_ngu_giao_tiep',
      );
      expect(ngonNguResult.diemQuyDoi12, 10.7);
      expect(ngonNguResult.mucLinhVuc, mucLinhVucDuDuLieu);
    });

    test('1 lĩnh vực có >=2 câu N/A -> chua_du_du_lieu, tong60=null, giai_doan=chua_du_du_lieu', () {
      final tier = tierFor('4_tuoi');
      final domainQuestions = tier.cauHoi
          .where((q) => q.linhVuc == 'tu_lap')
          .toList();
      final answers = <String, ScreeningRawAnswer>{
        for (final q in tier.cauHoi) q.id: (diem: 3, laNa: false),
      };
      answers[domainQuestions[0].id] = (diem: 3, laNa: false);
      answers[domainQuestions[1].id] = (diem: 2, laNa: false);
      answers[domainQuestions[2].id] = (diem: null, laNa: true);
      answers[domainQuestions[3].id] = (diem: null, laNa: true);

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questions: tier.cauHoi,
      );
      final tuLapResult = result.domainResults.firstWhere(
        (d) => d.linhVuc == 'tu_lap',
      );
      expect(tuLapResult.mucLinhVuc, mucLinhVucChuaDuDuLieu);
      expect(tuLapResult.diemQuyDoi12, isNull);
      expect(result.tongDiem60, isNull);
      expect(result.giaiDoan, giaiDoanChuaDuDuLieu);
    });

  });

  group('Vận động thô + tinh PHẢI gộp thành 1 lĩnh vực "van_dong" duy nhất', () {
    test('van_dong chỉ có ĐÚNG 1 dòng kết quả (không tách van_dong_tho/van_dong_tinh)', () {
      final tier = questionnaireData.forTier('2_tuoi')!;
      final answers = <String, ScreeningRawAnswer>{
        for (final q in tier.cauHoi) q.id: (diem: 3, laNa: false),
      };
      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questions: tier.cauHoi,
      );
      final vanDongResults = result.domainResults
          .where((d) => d.linhVuc.startsWith('van_dong'))
          .toList();
      expect(
        vanDongResults,
        hasLength(1),
        reason: 'phải đúng 1 dòng linh_vuc=van_dong, không tách van_dong_tho/van_dong_tinh riêng',
      );
      expect(vanDongResults.single.linhVuc, 'van_dong');
    });

    test('domain12 của van_dong tính GỘP trên cả 4 câu (2 tho + 2 tinh), không phải 2 phép tính riêng', () {
      // tho=3,3 · tinh=2,2 -> tổng thô 10/12 câu trả lời đủ 4 câu
      // -> domain12 = 10/(3*4)*12 = 10.0 (gộp chung, KHÔNG phải
      // trung bình cộng 2 phép tính con (3+3)/6*12=12.0 và (2+2)/6*12=8.0).
      final tier = questionnaireData.forTier('3_tuoi')!;
      final vanDongQuestions = tier.cauHoi
          .where((q) => q.linhVuc == 'van_dong')
          .toList();
      final thoQuestions = vanDongQuestions
          .where((q) => q.nhomVanDong == 'tho')
          .toList();
      final tinhQuestions = vanDongQuestions
          .where((q) => q.nhomVanDong == 'tinh')
          .toList();
      expect(thoQuestions, hasLength(2));
      expect(tinhQuestions, hasLength(2));

      final answers = <String, ScreeningRawAnswer>{
        thoQuestions[0].id: (diem: 3, laNa: false),
        thoQuestions[1].id: (diem: 3, laNa: false),
        tinhQuestions[0].id: (diem: 2, laNa: false),
        tinhQuestions[1].id: (diem: 2, laNa: false),
      };
      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questions: vanDongQuestions,
      );
      final vanDong = result.domainResults.single;
      expect(vanDong.diemTho, 10);
      expect(vanDong.soCauTraLoi, 4);
      expect(
        vanDong.diemQuyDoi12,
        10.0,
        reason: 'domain12 = 10/(3*4)*12 = 10.0, tính gộp trên cả 4 câu van_dong',
      );
    });

    test('1 câu N/A trong nhóm "tho" -> quy đổi tính trên 3 câu còn lại của CẢ van_dong (không tính rớt riêng theo nhóm con)', () {
      final tier = questionnaireData.forTier('4_tuoi')!;
      final vanDongQuestions = tier.cauHoi
          .where((q) => q.linhVuc == 'van_dong')
          .toList();
      final thoQuestions = vanDongQuestions
          .where((q) => q.nhomVanDong == 'tho')
          .toList();
      final tinhQuestions = vanDongQuestions
          .where((q) => q.nhomVanDong == 'tinh')
          .toList();

      // tho[0]=N/A, tho[1]=3, tinh[0]=3, tinh[1]=2 -> 3 câu có điểm
      // (tổng thô 8), 1 câu N/A -> domain12 = 8/(3*3)*12 = 10.7
      final answers = <String, ScreeningRawAnswer>{
        thoQuestions[0].id: (diem: null, laNa: true),
        thoQuestions[1].id: (diem: 3, laNa: false),
        tinhQuestions[0].id: (diem: 3, laNa: false),
        tinhQuestions[1].id: (diem: 2, laNa: false),
      };
      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questions: vanDongQuestions,
      );
      final vanDong = result.domainResults.single;
      expect(vanDong.soCauTraLoi, 3);
      expect(vanDong.soCauNa, 1);
      expect(vanDong.mucLinhVuc, mucLinhVucDuDuLieu);
      expect(
        vanDong.diemQuyDoi12,
        10.7,
        reason: '1 câu N/A trong nhóm tho vẫn quy đổi trên 3 câu còn lại của CẢ lĩnh vực van_dong, không tính rớt riêng theo tho/tinh',
      );
    });
  });

  group('3 ví dụ chấm điểm mẫu — mục 9 tài liệu "Hướng dẫn chấm điểm..."', () {
    // Dựng bộ câu trả lời để domain12 khớp đúng số liệu ví dụ, dùng câu hỏi
    // thật của mức 3 tuổi (không quan trọng mức nào vì thuật toán không phụ
    // thuộc mức tuổi/nội dung câu, chỉ phụ thuộc điểm số).
    late ScreeningTierQuestionnaire tier3t;
    setUpAll(() {
      tier3t = questionnaireData.forTier('3_tuoi')!;
    });

    ScreeningScoreResult buildScore(Map<String, int> domainRawTotals) {
      final answers = <String, ScreeningRawAnswer>{};
      for (final domain in domainRawTotals.keys) {
        final questions = tier3t.cauHoi
            .where((q) => q.linhVuc == domain)
            .toList();
        var remaining = domainRawTotals[domain]!;
        for (final q in questions) {
          final point = remaining >= 3 ? 3 : (remaining < 0 ? 0 : remaining);
          remaining -= point;
          answers[q.id] = (diem: point, laNa: false);
        }
      }
      return ScreeningScoringService.calculateScore(
        answers: answers,
        questions: tier3t.cauHoi,
      );
    }

    test('Ví dụ A: Ngôn ngữ 11, Nhận thức 10, Vận động 10, Xã hội-cảm xúc 9, Tự lập 11 -> Giai đoạn 1 (tổng 51/60)', () {
      final result = buildScore({
        'ngon_ngu_giao_tiep': 11,
        'nhan_thuc_giai_quyet_van_de': 10,
        'van_dong': 10,
        'xa_hoi_cam_xuc': 9,
        'tu_lap': 11,
      });
      expect(result.tongDiem60, 51.0);
      expect(result.giaiDoan, giaiDoan1);
    });

    test('Ví dụ B: Ngôn ngữ 11, Nhận thức 10, Vận động 9, Xã hội-cảm xúc 8, Tự lập 11 -> Giai đoạn 2 (tổng 49/60, Xã hội-cảm xúc=8<9)', () {
      final result = buildScore({
        'ngon_ngu_giao_tiep': 11,
        'nhan_thuc_giai_quyet_van_de': 10,
        'van_dong': 9,
        'xa_hoi_cam_xuc': 8,
        'tu_lap': 11,
      });
      expect(result.tongDiem60, 49.0);
      expect(result.giaiDoan, giaiDoan2);
    });

    test('Ví dụ C: Ngôn ngữ 11, Nhận thức 10, Vận động 10, Xã hội-cảm xúc 5, Tự lập 10 -> Giai đoạn 3 (tổng 46/60, có lĩnh vực <6, không bị bù điểm)', () {
      final result = buildScore({
        'ngon_ngu_giao_tiep': 11,
        'nhan_thuc_giai_quyet_van_de': 10,
        'van_dong': 10,
        'xa_hoi_cam_xuc': 5,
        'tu_lap': 10,
      });
      expect(result.tongDiem60, 46.0);
      expect(result.giaiDoan, giaiDoan3);
    });

    test('Mục 8 tài liệu gốc: Ngôn ngữ 5, Nhận thức 11, Vận động 11, Xã hội-cảm xúc 10, Tự lập 10 -> Giai đoạn 3 (tổng 47/60, KHÔNG bị "bù điểm")', () {
      final result = buildScore({
        'ngon_ngu_giao_tiep': 5,
        'nhan_thuc_giai_quyet_van_de': 11,
        'van_dong': 11,
        'xa_hoi_cam_xuc': 10,
        'tu_lap': 10,
      });
      expect(result.tongDiem60, 47.0);
      expect(
        result.giaiDoan,
        giaiDoan3,
        reason: 'tổng 47 không thấp nhưng Ngôn ngữ=5/12<6 phải ép về Giai đoạn 3',
      );
    });

    test('Biên tong60: 34.9 -> Giai đoạn 3, 35.0 -> KHÔNG Giai đoạn 3 (đúng chiều so sánh <, không <=)', () {
      // domain12 = raw/(3*4)*12 = raw. Dùng raw lẻ không khả thi với điểm
      // nguyên 0-3/câu nên test trực tiếp qua raw nguyên gần biên nhất có
      // thể đạt được (34 và 35 tổng nguyên, do mỗi domain12 luôn là số
      // nguyên khi đủ 4 câu điểm nguyên) — vẫn xác nhận đúng chiều <.
      final below = buildScore({
        'ngon_ngu_giao_tiep': 7,
        'nhan_thuc_giai_quyet_van_de': 7,
        'van_dong': 7,
        'xa_hoi_cam_xuc': 7,
        'tu_lap': 6,
      }); // tong = 34
      expect(below.tongDiem60, 34.0);
      expect(below.giaiDoan, giaiDoan3);

      final atOrAbove = buildScore({
        'ngon_ngu_giao_tiep': 7,
        'nhan_thuc_giai_quyet_van_de': 7,
        'van_dong': 7,
        'xa_hoi_cam_xuc': 7,
        'tu_lap': 7,
      }); // tong = 35 đúng biên
      expect(atOrAbove.tongDiem60, 35.0);
      expect(
        atOrAbove.giaiDoan,
        isNot(giaiDoan3),
        reason: 'tong60=35.0 đúng biên KHÔNG được rơi Giai đoạn 3 (điều kiện là <35.0)',
      );
    });

    test('Biên domain12: 1 lĩnh vực=5 (<6) -> Giai đoạn 3; 1 lĩnh vực=6 (đúng biên) -> KHÔNG Giai đoạn 3 do domain', () {
      final domainBelow6 = buildScore({
        'ngon_ngu_giao_tiep': 12,
        'nhan_thuc_giai_quyet_van_de': 12,
        'van_dong': 12,
        'xa_hoi_cam_xuc': 12,
        'tu_lap': 5,
      });
      expect(domainBelow6.giaiDoan, giaiDoan3);

      final domainAt6 = buildScore({
        'ngon_ngu_giao_tiep': 12,
        'nhan_thuc_giai_quyet_van_de': 12,
        'van_dong': 12,
        'xa_hoi_cam_xuc': 12,
        'tu_lap': 6,
      });
      expect(
        domainAt6.giaiDoan,
        isNot(giaiDoan3),
        reason: 'domain12=6.0 đúng biên KHÔNG được Giai đoạn 3 (điều kiện là <6.0)',
      );
    });
  });

  group('resolveScreeningAgeTier — kẹp về 2 đầu, không bao giờ trả null', () {
    // Biên các mốc chuyển mức: 23/24, 35/36, 47/48, 59/60, 71/72, cộng các
    // mốc rất xa 2 đầu (0, 1, 200) để xác nhận kẹp đúng, không riêng biên.
    final cases = <int, String>{
      0: '2_tuoi',
      1: '2_tuoi',
      23: '2_tuoi', // dưới 24 tháng -> kẹp về mức thấp nhất
      24: '2_tuoi',
      35: '2_tuoi',
      36: '3_tuoi',
      47: '3_tuoi',
      48: '4_tuoi',
      59: '4_tuoi',
      60: '5_tuoi',
      71: '5_tuoi',
      72: '5_tuoi', // trên 71 tháng -> kẹp về mức cao nhất
      200: '5_tuoi',
    };

    cases.forEach((months, expectedTier) {
      test('$months tháng -> $expectedTier', () {
        final range = resolveScreeningAgeTier(months);
        expect(
          range.tier,
          expectedTier,
          reason: 'resolveScreeningAgeTier phải luôn trả về 1 trong 4 mức, không bao giờ null/lỗi',
        );
      });
    });
  });
}
