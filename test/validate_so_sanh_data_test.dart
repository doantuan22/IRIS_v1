import 'package:flutter_test/flutter_test.dart';

import '../scripts/validate_so_sanh_data.dart';

/// Test logic validate dữ liệu `so_sanh` (không gọi API, không cần database)
/// — xem `validateSoSanhData` trong `scripts/validate_so_sanh_data.dart`.
///
/// Cấu trúc đối xứng đã chốt: 7 linh_vuc × 3 dải tuổi (15-23, 24-47, 48-60) ×
/// 2 phan_loai (binh_thuong, roi_loan_pho_tu_ky).
void main() {
  Map<String, dynamic> entry({
    required String id,
    String contentType = 'so_sanh',
    String? linhVuc = 'ngon_ngu',
    String? phanLoai = 'binh_thuong',
    int? min = 15,
    int? max = 23,
    String content = placeholderContent,
    String? nguon = '[Chưa có nguồn]',
  }) => {
        'id': id,
        'content_type': contentType,
        'linh_vuc': linhVuc,
        'phan_loai': phanLoai,
        'do_tuoi_thang_min': min,
        'do_tuoi_thang_max': max,
        'content': content,
        'nguon_tai_lieu': nguon,
      };

  /// Sinh đủ 42 entry hợp lệ (7 linh_vuc × 3 dải × 2 phan_loai) để làm nền
  /// cho các test chỉ muốn kiểm tra 1 khía cạnh cụ thể.
  List<Map<String, dynamic>> fullValidDataset() {
    final entries = <Map<String, dynamic>>[];
    for (final linhVuc in expectedLinhVucs) {
      for (final phanLoai in expectedPhanLoais) {
        for (final band in expectedAgeBands) {
          entries.add(
            entry(
              id: 'so_sanh_${linhVuc}_${phanLoai}_${band.$1}_${band.$2}',
              linhVuc: linhVuc,
              phanLoai: phanLoai,
              min: band.$1,
              max: band.$2,
            ),
          );
        }
      }
    }
    return entries;
  }

  test('42 entry đúng cấu trúc (7 linh_vuc x 3 dải x 2 phan_loai): hợp lệ, không lỗi', () {
    final report = validateSoSanhData(fullValidDataset());

    expect(report.isStructurallyValid, true);
    expect(report.fieldIssues, isEmpty);
    expect(report.ageRangeIssues, isEmpty);
    expect(report.duplicateIssues, isEmpty);
    expect(report.unexpectedLinhVucIssues, isEmpty);
    expect(report.bandMismatchMessages, isEmpty);

    final text = report.buildReport();
    expect(text, contains('Tổng cộng: 42 entry'));
    // ignore: avoid_print
    print('PASS: bộ dữ liệu 42 entry đúng cấu trúc mới không bị báo lỗi');
  });

  test('thiếu/rỗng trường bắt buộc bị phát hiện', () {
    final entries = [
      entry(id: 'missing-linh-vuc', linhVuc: null),
      entry(id: 'empty-content', content: ''),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(report.fieldIssues.length, 2);
    expect(report.fieldIssues.any((i) => i.entryId == 'missing-linh-vuc'), true);
    expect(report.fieldIssues.any((i) => i.entryId == 'empty-content'), true);
    // ignore: avoid_print
    print('PASS: thiếu/rỗng trường bắt buộc bị phát hiện đúng entry');
  });

  test('do_tuoi_thang_min > do_tuoi_thang_max bị phát hiện', () {
    final entries = [entry(id: 'bad-range', min: 30, max: 20)];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(report.ageRangeIssues.length, 1);
    expect(report.ageRangeIssues.first.entryId, 'bad-range');
    // ignore: avoid_print
    print('PASS: min > max bị phát hiện');
  });

  test('trùng (linh_vuc, content_type, phan_loai, min, max) bị phát hiện', () {
    final entries = [
      entry(id: 'first', min: 15, max: 23),
      entry(id: 'second-duplicate', min: 15, max: 23),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(report.duplicateIssues.length, 1);
    expect(report.duplicateIssues.first.entryId, 'second-duplicate');
    // ignore: avoid_print
    print('PASS: entry trùng khoá bị phát hiện, entry gốc không bị báo lỗi');
  });

  test('linh_vuc đã gỡ (hanh_vi/ung_xu) bị phát hiện là linh_vuc lạ', () {
    final entries = [
      entry(id: 'hanh-vi-1', linhVuc: 'hanh_vi'),
      entry(id: 'ung-xu-1', linhVuc: 'ung_xu'),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(report.unexpectedLinhVucIssues.length, 2);
    expect(report.unexpectedLinhVucIssues.any((i) => i.entryId == 'hanh-vi-1'), true);
    expect(report.unexpectedLinhVucIssues.any((i) => i.entryId == 'ung-xu-1'), true);
    // ignore: avoid_print
    print('PASS: linh_vuc đã gỡ (hanh_vi/ung_xu) bị phát hiện đúng');
  });

  test('thiếu 1 trong 3 dải mong đợi của 1 nhóm (linh_vuc, phan_loai) bị phát hiện', () {
    final entries = [
      entry(id: 'band-1', min: 15, max: 23),
      // Thiếu dải 24-47 và 48-60 cho ngon_ngu/binh_thuong.
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(
      report.bandMismatchMessages.any(
        (m) => m.contains('linh_vuc=ngon_ngu') && m.contains('phan_loai=binh_thuong') && m.contains('24-47'),
      ),
      true,
    );
    expect(
      report.bandMismatchMessages.any(
        (m) => m.contains('linh_vuc=ngon_ngu') && m.contains('phan_loai=binh_thuong') && m.contains('48-60'),
      ),
      true,
    );
    // ignore: avoid_print
    print('PASS: thiếu dải tuổi mong đợi bị phát hiện đúng nhóm');
  });

  test('dải tuổi lạ (không thuộc 15-23/24-47/48-60) bị phát hiện', () {
    final entries = [entry(id: 'legacy-band', linhVuc: 'quan_he_xa_hoi', phanLoai: 'binh_thuong', min: 48, max: 71)];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(
      report.bandMismatchMessages.any((m) => m.contains('có dải lạ 48-71')),
      true,
    );
    // ignore: avoid_print
    print('PASS: dải tuổi lạ ngoài 3 dải mong đợi bị phát hiện');
  });

  test('không còn phân biệt 2 hệ dải tuổi khác nhau — cả 2 phan_loai dùng chung 3 dải', () {
    final entries = [
      entry(id: 'bt-1', phanLoai: 'binh_thuong', min: 15, max: 23),
      entry(id: 'bt-2', phanLoai: 'binh_thuong', min: 24, max: 47),
      entry(id: 'bt-3', phanLoai: 'binh_thuong', min: 48, max: 60),
      entry(id: 'asd-1', phanLoai: 'roi_loan_pho_tu_ky', min: 15, max: 23),
      entry(id: 'asd-2', phanLoai: 'roi_loan_pho_tu_ky', min: 24, max: 47),
      entry(id: 'asd-3', phanLoai: 'roi_loan_pho_tu_ky', min: 48, max: 60),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false); // vẫn thiếu 6 linh_vuc còn lại
    // Nhưng riêng nhóm ngon_ngu (linh_vuc mặc định của helper entry()) với cả
    // 2 phan_loai đã đủ đúng 3 dải, không bị báo lệch dải.
    expect(
      report.bandMismatchMessages.where((m) => m.contains('linh_vuc=ngon_ngu')),
      isEmpty,
    );
    // ignore: avoid_print
    print('PASS: 2 phan_loai dùng chung đúng 3 dải tuổi không bị báo lệch giả');
  });

  test('báo cáo tổng hợp phân biệt đúng placeholder vs nội dung thật theo (linh_vuc, phan_loai)', () {
    final entries = [
      entry(id: 'placeholder-1', linhVuc: 'quan_he_xa_hoi', min: 15, max: 23),
      entry(
        id: 'real-1',
        linhVuc: 'quan_he_xa_hoi',
        min: 24,
        max: 47,
        content: 'Nội dung thật đã biên soạn, không phải placeholder.',
      ),
    ];

    final report = validateSoSanhData(entries);

    final summary = report.groupSummaries['quan_he_xa_hoi|binh_thuong']!;
    expect(summary.total, 2);
    expect(summary.placeholderCount, 1);
    expect(summary.realCount, 1);

    final text = report.buildReport();
    expect(text, contains('quan_he_xa_hoi / binh_thuong: 2 entry'));
    expect(text, contains('placeholder: 1'));
    expect(text, contains('nội dung thật: 1'));
    // ignore: avoid_print
    print('PASS: báo cáo tổng hợp đếm đúng placeholder vs nội dung thật theo nhóm');
  });
}
