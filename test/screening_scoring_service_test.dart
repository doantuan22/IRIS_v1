import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/services/screening_loader_service.dart';
import 'package:iris_app/domain/services/screening_scoring_service.dart';

void main() {
  late ScreeningQuestionnaireData questionnaire;

  setUpAll(() {
    final file = File('assets/data/sang_loc_50_cau_7_linh_vuc.json');
    final jsonString = file.readAsStringSync();
    questionnaire = ScreeningLoaderService.parseJson(jsonString);
  });

  group('ScreeningLoaderService & Questionnaire Data Structure', () {
    test('Parse JSON đầy đủ 50 câu và 7 lĩnh vực', () {
      expect(questionnaire.meta.tongSoCau, 50);
      expect(questionnaire.meta.boCauHoiId, 'sang_loc_50_cau_7_linh_vuc_v1');
      expect(questionnaire.meta.thangDiem.length, 4);
      expect(questionnaire.meta.mucMoTa.length, 3);
      expect(questionnaire.linhVucTongHop.length, 7);
      expect(questionnaire.cauHoi.length, 50);

      final domainCounts = <String, int>{};
      for (final q in questionnaire.cauHoi) {
        domainCounts[q.linhVuc] = (domainCounts[q.linhVuc] ?? 0) + 1;
      }

      expect(domainCounts['nhan_thuc'], 7);
      expect(domainCounts['cam_xuc'], 6);
      expect(domainCounts['giac_quan'], 5);
      expect(domainCounts['quan_he_xa_hoi'], 8);
      expect(domainCounts['ngon_ngu'], 8);
      expect(domainCounts['sinh_hoc'], 10);
      expect(domainCounts['sinh_hoat_ca_nhan'], 6);

      // ignore: avoid_print
      print('PASS: Cấu trúc 50 câu và 7 lĩnh vực chuẩn xác');
    });

    test('Lưu ý không chẩn đoán nguyên văn có trong meta', () {
      expect(
        questionnaire.meta.luuYKhongChanDoan,
        'Đây là bản sàng lọc/thử nghiệm để rà soát mức độ biểu hiện và định hướng hỗ trợ. '
        'Không dùng tổng điểm hoặc các mức mô tả để kết luận/chẩn đoán rối loạn phổ tự kỷ hay thay thế đánh giá chuyên môn.',
      );
    });
  });

  group('ScreeningScoringService - Quy tắc chấm điểm', () {
    test('Tất cả câu trả lời 0 -> 0%, Mức 1 - Ít biểu hiện', () {
      final answers = <String, String>{
        for (final q in questionnaire.cauHoi) q.id: '0',
      };

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questionnaire: questionnaire,
      );

      expect(result.soCauHopLeToanBai, 50);
      expect(result.soCauNAToanBai, 0);
      expect(result.diemThoToanBai, 0);
      expect(result.diemToanBaiPhanTram, 0.0);
      expect(result.mucMoTaLevel, 1);
      expect(result.mucMoTaTen, 'Mức 1 - Ít biểu hiện');

      for (final d in result.domainScores) {
        expect(d.soCauHopLe, d.soCauThietKe);
        expect(d.diemTho, 0);
        expect(d.diemPhanTram, 0.0);
      }
    });

    test('Tất cả câu trả lời 2 -> 100%, Mức 3 - Nhiều biểu hiện khó khăn', () {
      final answers = <String, String>{
        for (final q in questionnaire.cauHoi) q.id: '2',
      };

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questionnaire: questionnaire,
      );

      expect(result.soCauHopLeToanBai, 50);
      expect(result.soCauNAToanBai, 0);
      expect(result.diemThoToanBai, 100);
      expect(result.diemToanBaiPhanTram, 100.0);
      expect(result.mucMoTaLevel, 3);
      expect(result.mucMoTaTen, 'Mức 3 - Nhiều biểu hiện khó khăn');

      for (final d in result.domainScores) {
        expect(d.soCauHopLe, d.soCauThietKe);
        expect(d.diemTho, d.soCauThietKe * 2);
        expect(d.diemPhanTram, 100.0);
      }
    });

    test('Tất cả câu trả lời 1 -> 50%, Mức 2 - Có biểu hiện cần theo dõi', () {
      final answers = <String, String>{
        for (final q in questionnaire.cauHoi) q.id: '1',
      };

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questionnaire: questionnaire,
      );

      expect(result.soCauHopLeToanBai, 50);
      expect(result.diemThoToanBai, 50);
      expect(result.diemToanBaiPhanTram, 50.0);
      expect(result.mucMoTaLevel, 2);
      expect(result.mucMoTaTen, 'Mức 2 - Có biểu hiện cần theo dõi');
    });

    test('Xử lý N/A: N/A KHÔNG tính vào mẫu số chuẩn hoá % và KHÔNG quy thành 0', () {
      // 7 câu nhan_thuc: 6 câu chọn 2 (điểm thô = 12), 1 câu chọn N/A.
      // Các câu còn lại chọn 0.
      final answers = <String, String>{};
      final nhanThucQuestions = questionnaire.cauHoi
          .where((q) => q.linhVuc == 'nhan_thuc')
          .toList();

      for (int i = 0; i < nhanThucQuestions.length; i++) {
        if (i == 0) {
          answers[nhanThucQuestions[i].id] = 'N/A';
        } else {
          answers[nhanThucQuestions[i].id] = '2';
        }
      }

      for (final q in questionnaire.cauHoi) {
        if (q.linhVuc != 'nhan_thuc') {
          answers[q.id] = '0';
        }
      }

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questionnaire: questionnaire,
      );

      final nhanThucScore = result.domainScores.firstWhere(
        (d) => d.linhVuc == 'nhan_thuc',
      );

      // 6 câu hợp lệ x 2 = 12 tối đa. Điểm thô = 12.
      // Điểm % = (12 / 12) * 100 = 100%. Nếu coi N/A là 0 hoặc mẫu số vẫn là 7x2=14 thì sẽ ra 12/14 = 85.7% (SAI).
      expect(nhanThucScore.soCauThietKe, 7);
      expect(nhanThucScore.soCauHopLe, 6);
      expect(nhanThucScore.diemTho, 12);
      expect(nhanThucScore.diemPhanTram, 100.0);
    });

    test('Lĩnh vực toàn N/A -> diemPhanTram là NULL (hiển thị chưa đủ dữ liệu, không ra 0%)', () {
      final answers = <String, String>{};

      // giac_quan (5 câu): toàn bộ N/A
      for (final q in questionnaire.cauHoi) {
        if (q.linhVuc == 'giac_quan') {
          answers[q.id] = 'N/A';
        } else {
          answers[q.id] = '1';
        }
      }

      final result = ScreeningScoringService.calculateScore(
        answers: answers,
        questionnaire: questionnaire,
      );

      final giacQuanScore = result.domainScores.firstWhere(
        (d) => d.linhVuc == 'giac_quan',
      );

      expect(giacQuanScore.soCauThietKe, 5);
      expect(giacQuanScore.soCauHopLe, 0);
      expect(giacQuanScore.diemTho, 0);
      expect(giacQuanScore.diemPhanTram, isNull);
      expect(giacQuanScore.hasValidData, false);

      // Điểm toàn bài tính trên 45 câu còn lại (mỗi câu 1 điểm -> 45 / (45*2) * 100 = 50%)
      expect(result.soCauHopLeToanBai, 45);
      expect(result.soCauNAToanBai, 5);
      expect(result.diemToanBaiPhanTram, 50.0);
    });

    test('Ngưỡng ranh giới mức mô tả: 33% -> Mức 1, 34% -> Mức 2, 66% -> Mức 2, 67% -> Mức 3', () {
      // Test 33%: 33 điểm trên 100 (ví dụ 33 câu '1', 17 câu '0' -> 33 / (50*2) * 100 = 33%)
      final answers33 = <String, String>{};
      for (int i = 0; i < questionnaire.cauHoi.length; i++) {
        answers33[questionnaire.cauHoi[i].id] = (i < 33) ? '1' : '0';
      }
      final result33 = ScreeningScoringService.calculateScore(
        answers: answers33,
        questionnaire: questionnaire,
      );
      expect(result33.diemToanBaiPhanTram, 33.0);
      expect(result33.mucMoTaLevel, 1);
      expect(result33.mucMoTaTen, 'Mức 1 - Ít biểu hiện');

      // Test 34%: 34 điểm trên 100 -> 34%
      final answers34 = <String, String>{};
      for (int i = 0; i < questionnaire.cauHoi.length; i++) {
        answers34[questionnaire.cauHoi[i].id] = (i < 34) ? '1' : '0';
      }
      final result34 = ScreeningScoringService.calculateScore(
        answers: answers34,
        questionnaire: questionnaire,
      );
      expect(result34.diemToanBaiPhanTram, 34.0);
      expect(result34.mucMoTaLevel, 2);
      expect(result34.mucMoTaTen, 'Mức 2 - Có biểu hiện cần theo dõi');

      // Test 66%: 66 điểm trên 100 (33 câu '2', 17 câu '0' -> 66 / 100 = 66%)
      final answers66 = <String, String>{};
      for (int i = 0; i < questionnaire.cauHoi.length; i++) {
        answers66[questionnaire.cauHoi[i].id] = (i < 33) ? '2' : '0';
      }
      final result66 = ScreeningScoringService.calculateScore(
        answers: answers66,
        questionnaire: questionnaire,
      );
      expect(result66.diemToanBaiPhanTram, 66.0);
      expect(result66.mucMoTaLevel, 2);
      expect(result66.mucMoTaTen, 'Mức 2 - Có biểu hiện cần theo dõi');

      // Test 67%: (17 câu '2' + 33 câu '1' = 34 + 33 = 67 điểm trên 100 -> 67%)
      final answers67 = <String, String>{};
      for (int i = 0; i < questionnaire.cauHoi.length; i++) {
        if (i < 17) {
          answers67[questionnaire.cauHoi[i].id] = '2';
        } else {
          answers67[questionnaire.cauHoi[i].id] = '1';
        }
      }
      final result67 = ScreeningScoringService.calculateScore(
        answers: answers67,
        questionnaire: questionnaire,
      );
      expect(result67.diemToanBaiPhanTram, 67.0);
      expect(result67.mucMoTaLevel, 3);
      expect(result67.mucMoTaTen, 'Mức 3 - Nhiều biểu hiện khó khăn');
    });
  });
}
