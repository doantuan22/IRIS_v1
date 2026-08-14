import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/models/domain_overview_label.dart';
import 'package:iris_app/domain/models/overview_summary.dart';
import 'package:iris_app/domain/services/overview_tier_calculator.dart';

/// Test hàm tổng hợp mức cuối cùng (mục 3) — 100% CODE THUẦN, KHÔNG gọi AI.
/// Bao phủ đủ ranh giới ngưỡng + trường hợp thiếu dữ liệu, đúng yêu cầu tiêu
/// chí hoàn thành ("test bao phủ đủ các trường hợp biên").
void main() {
  List<String> labels({int thuongGap = 0, int canTheoDoi = 0, int thieu = 0}) => [
        ...List.filled(thuongGap, labelThuongGap),
        ...List.filled(canTheoDoi, labelCanTheoDoi),
        ...List.filled(thieu, labelChuaDuDuLieu),
      ];

  test('hằng số ngưỡng đúng giá trị đã chốt (2 / 5 / 4)', () {
    expect(nguongThuongGap, 2);
    expect(nguongCanTheoDoi, 5);
    expect(nguongThieuDuLieuToiThieu, 4);
  });

  group('đủ dữ liệu (so_thieu < 4) — xếp tier theo so_can_theo_doi', () {
    test('0 can_theo_doi => thuong_gap', () {
      final result = calculateOverviewTier(labels(thuongGap: 9));
      expect(result.status, OverviewTierStatus.computed);
      expect(result.tier, tierThuongGap);
      expect(result.soCanTheoDoi, 0);
      expect(result.soThieu, 0);
    });

    test('ranh giới trên: đúng 2 can_theo_doi vẫn => thuong_gap', () {
      final result = calculateOverviewTier(labels(canTheoDoi: 2, thuongGap: 7));
      expect(result.tier, tierThuongGap);
    });

    test('ranh giới dưới kế tiếp: đúng 3 can_theo_doi => can_theo_doi', () {
      final result = calculateOverviewTier(labels(canTheoDoi: 3, thuongGap: 6));
      expect(result.tier, tierCanTheoDoi);
    });

    test('ranh giới trên: đúng 5 can_theo_doi vẫn => can_theo_doi', () {
      final result = calculateOverviewTier(labels(canTheoDoi: 5, thuongGap: 4));
      expect(result.tier, tierCanTheoDoi);
    });

    test('ranh giới kế tiếp: đúng 6 can_theo_doi => chuyen_mon_som', () {
      final result = calculateOverviewTier(labels(canTheoDoi: 6, thuongGap: 3));
      expect(result.tier, tierChuyenMonSom);
    });

    test('toàn bộ 9 can_theo_doi => chuyen_mon_som', () {
      final result = calculateOverviewTier(labels(canTheoDoi: 9));
      expect(result.tier, tierChuyenMonSom);
      expect(result.soCanTheoDoi, 9);
    });

    test('có lẫn chua_du_du_lieu nhưng dưới ngưỡng (3 thiếu) vẫn tính tier bình thường', () {
      final result = calculateOverviewTier(labels(thieu: 3, canTheoDoi: 3, thuongGap: 3));
      expect(result.status, OverviewTierStatus.computed);
      expect(result.tier, tierCanTheoDoi);
      expect(result.soThieu, 3);
      expect(result.soCanTheoDoi, 3);
    });
    // ignore: avoid_print
  });

  group('thiếu dữ liệu (so_thieu >= 4) — KHÔNG tính tier', () {
    test('ranh giới: đúng 4 thiếu => insufficientData, tier = null', () {
      final result = calculateOverviewTier(labels(thieu: 4, canTheoDoi: 5));
      expect(result.status, OverviewTierStatus.insufficientData);
      expect(result.isInsufficientData, true);
      expect(result.tier, isNull);
      expect(result.soThieu, 4);
      // so_can_theo_doi vẫn được đếm đúng dù không dùng để tính tier — hữu
      // ích cho log/debug.
      expect(result.soCanTheoDoi, 5);
    });

    test('toàn bộ 9 lĩnh vực đều thiếu dữ liệu => insufficientData', () {
      final result = calculateOverviewTier(labels(thieu: 9));
      expect(result.status, OverviewTierStatus.insufficientData);
      expect(result.soThieu, 9);
    });

    test('7 thiếu, 2 can_theo_doi => vẫn insufficientData dù can_theo_doi thấp', () {
      final result = calculateOverviewTier(labels(thieu: 7, canTheoDoi: 2));
      expect(result.status, OverviewTierStatus.insufficientData);
    });
  });

  test('tierDisplayLabel trả đúng 3 tên đã chốt, không dùng nhãn cấm', () {
    expect(tierDisplayLabel(tierThuongGap), 'Trong giới hạn thường gặp');
    expect(tierDisplayLabel(tierCanTheoDoi), 'Có điểm cần theo dõi');
    expect(tierDisplayLabel(tierChuyenMonSom), 'Nên tìm đánh giá chuyên môn sớm');

    for (final tier in [tierThuongGap, tierCanTheoDoi, tierChuyenMonSom]) {
      final display = tierDisplayLabel(tier);
      expect(display.toLowerCase(), isNot(contains('bình thường')));
      expect(display.toLowerCase(), isNot(contains('nghi ngờ')));
      expect(display.toLowerCase(), isNot(contains('nguy hiểm')));
    }
    // ignore: avoid_print
    print('PASS: calculateOverviewTier đúng mọi ranh giới ngưỡng + trường hợp thiếu dữ liệu, '
        'tierDisplayLabel đúng 3 tên đã chốt, không dùng nhãn cấm');
  });
}
