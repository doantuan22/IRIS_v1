import 'package:flutter_test/flutter_test.dart';

import '../scripts/validate_so_sanh_data.dart';

/// Test logic validate dữ liệu `so_sanh` (không gọi API, không cần database)
/// — xem `validateSoSanhData` trong `scripts/validate_so_sanh_data.dart`.
void main() {
  Map<String, dynamic> entry({
    required String id,
    String contentType = 'so_sanh',
    String? linhVuc = 'ngon_ngu',
    String? phanLoai = 'binh_thuong',
    int? min = 15,
    int? max = 17,
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

  test('dữ liệu hợp lệ, không gap: không có lỗi cấu trúc, không có gap', () {
    final entries = [
      entry(id: 'a', min: 15, max: 17),
      entry(id: 'b', min: 18, max: 23),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, true);
    expect(report.fieldIssues, isEmpty);
    expect(report.ageRangeIssues, isEmpty);
    expect(report.duplicateIssues, isEmpty);
    expect(report.gapMessages, isEmpty);
    // ignore: avoid_print
    print('PASS: dữ liệu hợp lệ liên tục không bị báo lỗi/gap');
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
      entry(id: 'first', min: 15, max: 17),
      entry(id: 'second-duplicate', min: 15, max: 17),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, false);
    expect(report.duplicateIssues.length, 1);
    expect(report.duplicateIssues.first.entryId, 'second-duplicate');
    // ignore: avoid_print
    print('PASS: entry trùng khoá bị phát hiện, entry gốc không bị báo lỗi');
  });

  test('phát hiện khoảng trống tuổi (age gap) giữa 2 dải không liền kề', () {
    final entries = [
      entry(id: 'band-1', min: 15, max: 17),
      // Thiếu dải 18-23 — nhảy thẳng sang 24-29.
      entry(id: 'band-3', min: 24, max: 29),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, true); // gap chỉ là cảnh báo, không phải lỗi cấu trúc
    expect(report.gapMessages.length, 1);
    expect(report.gapMessages.first, contains('linh_vuc=ngon_ngu'));
    expect(report.gapMessages.first, contains('phan_loai=binh_thuong'));
    expect(report.gapMessages.first, contains('18'));
    expect(report.gapMessages.first, contains('23'));
    // ignore: avoid_print
    print('PASS: gap tuổi giữa 2 dải không liền kề được phát hiện đúng khoảng thiếu');
  });

  test('không báo gap giả khi 2 nhóm phan_loai khác nhau có dải tuổi khác hệ', () {
    // roi_loan_pho_tu_ky dùng hệ dải tuổi khác binh_thuong — không được lẫn
    // gap của nhóm này vào nhóm kia.
    final entries = [
      entry(id: 'bt-1', phanLoai: 'binh_thuong', min: 15, max: 17),
      entry(id: 'bt-2', phanLoai: 'binh_thuong', min: 18, max: 23),
      entry(id: 'asd-1', phanLoai: 'roi_loan_pho_tu_ky', min: 15, max: 23),
      entry(id: 'asd-2', phanLoai: 'roi_loan_pho_tu_ky', min: 24, max: 47),
    ];

    final report = validateSoSanhData(entries);

    expect(report.isStructurallyValid, true);
    expect(report.gapMessages, isEmpty);
    // ignore: avoid_print
    print('PASS: 2 nhóm phan_loai với 2 hệ dải tuổi khác nhau không tạo gap giả');
  });

  test('báo cáo tổng hợp phân biệt đúng placeholder vs nội dung thật theo (linh_vuc, phan_loai)', () {
    final entries = [
      entry(id: 'placeholder-1', linhVuc: 'quan_he_xa_hoi', min: 15, max: 17),
      entry(
        id: 'real-1',
        linhVuc: 'quan_he_xa_hoi',
        min: 18,
        max: 23,
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
