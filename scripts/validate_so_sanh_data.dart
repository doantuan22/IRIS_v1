import 'dart:convert';
import 'dart:io';

/// Validate dữ liệu `content_type='so_sanh'` (mục "So sánh với trẻ cùng độ
/// tuổi") trước khi ingest vào `expert_knowledge_chunks`.
///
/// Cấu trúc ĐỐI XỨNG đã chốt: 7 linh_vuc × 3 dải tuổi × 2 phan_loai.
/// Cả 2 nhóm `phan_loai` (`binh_thuong`: biểu hiện thường gặp,
/// `roi_loan_pho_tu_ky`: dấu hiệu cần quan sát thêm) dùng CHUNG đúng 3 dải
/// tuổi: 15-23, 24-47, 48-60 tháng — không còn 2 hệ dải tuổi khác nhau như
/// trước. Do dải tuổi cố định, không cần dò "khoảng trống tuổi" (age gap)
/// phức tạp nữa — chỉ cần so khớp tập hợp dải thực tế với tập hợp dải mong
/// đợi cho từng (linh_vuc, phan_loai).
///
/// Chạy độc lập (từ thư mục gốc repo):
///   dart run scripts/validate_so_sanh_data.dart
/// hoặc trỏ tới file khác:
///   dart run scripts/validate_so_sanh_data.dart path/to/file.json
///
/// Logic validate tách khỏi `main()` (`validateSoSanhData`) để test được
/// bằng dữ liệu giả, không cần đọc file — xem `test/validate_so_sanh_data_test.dart`.

/// 7 lĩnh vực hợp lệ (đã bỏ `hanh_vi`, `ung_xu` — 2 lĩnh vực này bị gỡ khỏi
/// app ở đợt migration DB version 6).
const List<String> expectedLinhVucs = [
  'nhan_thuc',
  'cam_xuc',
  'giac_quan',
  'quan_he_xa_hoi',
  'ngon_ngu',
  'sinh_hoc',
  'sinh_hoat_ca_nhan',
];

const List<String> expectedPhanLoais = ['binh_thuong', 'roi_loan_pho_tu_ky'];

/// 3 dải tuổi (tháng) dùng chung cho cả 2 phan_loai.
const List<(int min, int max)> expectedAgeBands = [(15, 23), (24, 47), (48, 60)];

/// 7 trường nội dung bắt buộc, không tính `id` (khoá định danh, không phải
/// nội dung tham khảo).
const List<String> requiredSoSanhFields = [
  'content_type',
  'linh_vuc',
  'phan_loai',
  'do_tuoi_thang_min',
  'do_tuoi_thang_max',
  'content',
  'nguon_tai_lieu',
];

const String placeholderContent = '[Placeholder - chưa có nội dung thật]';

class ValidationIssue {
  final String? entryId;
  final String message;

  const ValidationIssue(this.message, {this.entryId});

  @override
  String toString() => entryId != null ? '  - [$entryId] $message' : '  - $message';
}

/// Thống kê 1 nhóm (linh_vuc, phan_loai): tổng số entry, bao nhiêu đang là
/// placeholder (nội dung mẫu minh hoạ), bao nhiêu đã có nội dung thật.
class GroupSummary {
  final String linhVuc;
  final String phanLoai;
  int total = 0;
  int placeholderCount = 0;
  int realCount = 0;

  GroupSummary(this.linhVuc, this.phanLoai);
}

class SoSanhValidationReport {
  final List<ValidationIssue> fieldIssues;
  final List<ValidationIssue> ageRangeIssues;
  final List<ValidationIssue> duplicateIssues;
  final List<ValidationIssue> unexpectedLinhVucIssues;
  final List<String> bandMismatchMessages;
  final Map<String, GroupSummary> groupSummaries;

  const SoSanhValidationReport({
    required this.fieldIssues,
    required this.ageRangeIssues,
    required this.duplicateIssues,
    required this.unexpectedLinhVucIssues,
    required this.bandMismatchMessages,
    required this.groupSummaries,
  });

  /// Không có lỗi cấu trúc (thiếu trường / min>max / trùng / linh_vuc lạ /
  /// lệch dải tuổi mong đợi) — dữ liệu đủ điều kiện để ingest.
  bool get isStructurallyValid =>
      fieldIssues.isEmpty &&
      ageRangeIssues.isEmpty &&
      duplicateIssues.isEmpty &&
      unexpectedLinhVucIssues.isEmpty &&
      bandMismatchMessages.isEmpty;

  String buildReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== BÁO CÁO VALIDATE DỮ LIỆU so_sanh ===\n');

    buffer.writeln('1. Trường bắt buộc thiếu/rỗng: ${fieldIssues.length}');
    for (final issue in fieldIssues) {
      buffer.writeln(issue);
    }

    buffer.writeln('\n2. do_tuoi_thang_min > do_tuoi_thang_max: ${ageRangeIssues.length}');
    for (final issue in ageRangeIssues) {
      buffer.writeln(issue);
    }

    buffer.writeln(
      '\n3. Trùng (linh_vuc, content_type, phan_loai, min, max): ${duplicateIssues.length}',
    );
    for (final issue in duplicateIssues) {
      buffer.writeln(issue);
    }

    buffer.writeln('\n4. linh_vuc không nằm trong 7 lĩnh vực hợp lệ: ${unexpectedLinhVucIssues.length}');
    for (final issue in unexpectedLinhVucIssues) {
      buffer.writeln(issue);
    }

    buffer.writeln(
      '\n5. Lệch dải tuổi mong đợi (mỗi linh_vuc × phan_loai phải có đúng 3 dải '
      '15-23, 24-47, 48-60): ${bandMismatchMessages.length}',
    );
    for (final msg in bandMismatchMessages) {
      buffer.writeln('  - $msg');
    }

    buffer.writeln('\n6. Tổng số entry theo (linh_vuc, phan_loai):');
    final sortedKeys = groupSummaries.keys.toList()..sort();
    for (final key in sortedKeys) {
      final s = groupSummaries[key]!;
      buffer.writeln(
        '  - ${s.linhVuc} / ${s.phanLoai}: ${s.total} entry '
        '(placeholder: ${s.placeholderCount}, nội dung thật: ${s.realCount})',
      );
    }

    final totalPlaceholder = groupSummaries.values.fold<int>(0, (a, s) => a + s.placeholderCount);
    final totalReal = groupSummaries.values.fold<int>(0, (a, s) => a + s.realCount);
    buffer.writeln(
      '\nTổng cộng: ${totalPlaceholder + totalReal} entry — '
      '$totalPlaceholder placeholder, $totalReal nội dung thật '
      '(mong đợi: ${expectedLinhVucs.length * expectedPhanLoais.length * expectedAgeBands.length} entry).',
    );

    buffer.writeln(
      '\nKết luận: ${isStructurallyValid ? 'HỢP LỆ về cấu trúc, sẵn sàng ingest.' : 'CÓ LỖI CẤU TRÚC — xem mục 1-5 ở trên.'}',
    );

    return buffer.toString();
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

bool _isEmpty(Object? value) => value == null || (value is String && value.trim().isEmpty);

SoSanhValidationReport validateSoSanhData(List<Map<String, dynamic>> entries) {
  final fieldIssues = <ValidationIssue>[];
  final ageRangeIssues = <ValidationIssue>[];
  final duplicateIssues = <ValidationIssue>[];
  final unexpectedLinhVucIssues = <ValidationIssue>[];
  final groupSummaries = <String, GroupSummary>{};
  // (linh_vuc, phan_loai) -> tập hợp dải tuổi thực tế xuất hiện.
  final actualBandsByGroup = <String, Set<(int min, int max)>>{};
  final seenDupKeys = <String, String>{};

  for (final entry in entries) {
    final id = entry['id']?.toString() ?? '(không có id)';

    for (final field in requiredSoSanhFields) {
      if (_isEmpty(entry[field])) {
        fieldIssues.add(ValidationIssue('thiếu hoặc rỗng trường "$field"', entryId: id));
      }
    }

    final linhVuc = entry['linh_vuc'] as String?;
    final contentType = entry['content_type'] as String?;
    final phanLoai = entry['phan_loai'] as String?;
    final min = _asInt(entry['do_tuoi_thang_min']);
    final max = _asInt(entry['do_tuoi_thang_max']);

    if (min != null && max != null && min > max) {
      ageRangeIssues.add(
        ValidationIssue('do_tuoi_thang_min ($min) > do_tuoi_thang_max ($max)', entryId: id),
      );
    }

    if (linhVuc != null && !expectedLinhVucs.contains(linhVuc)) {
      unexpectedLinhVucIssues.add(
        ValidationIssue('linh_vuc "$linhVuc" không thuộc 7 lĩnh vực hợp lệ', entryId: id),
      );
    }

    if (linhVuc == null || contentType == null || phanLoai == null || min == null || max == null) {
      // Thiếu trường khoá để nhóm/so trùng — đã ghi nhận ở fieldIssues rồi.
      continue;
    }

    final dupKey = '$linhVuc|$contentType|$phanLoai|$min|$max';
    if (seenDupKeys.containsKey(dupKey)) {
      duplicateIssues.add(
        ValidationIssue(
          'trùng (linh_vuc, content_type, phan_loai, min, max) với entry "${seenDupKeys[dupKey]}"',
          entryId: id,
        ),
      );
    } else {
      seenDupKeys[dupKey] = id;
    }

    final groupKey = '$linhVuc|$phanLoai';
    final summary = groupSummaries.putIfAbsent(groupKey, () => GroupSummary(linhVuc, phanLoai));
    summary.total++;
    final content = entry['content'] as String? ?? '';
    if (content.trim() == placeholderContent || content.contains('[Placeholder')) {
      summary.placeholderCount++;
    } else {
      summary.realCount++;
    }

    actualBandsByGroup.putIfAbsent(groupKey, () => {}).add((min, max));
  }

  final bandMismatchMessages = <String>[];
  // Kiểm tra đủ/đúng 3 dải mong đợi cho MỌI tổ hợp (linh_vuc, phan_loai) hợp
  // lệ, kể cả tổ hợp hiện chưa có entry nào (thiếu hoàn toàn).
  for (final linhVuc in expectedLinhVucs) {
    for (final phanLoai in expectedPhanLoais) {
      final groupKey = '$linhVuc|$phanLoai';
      final actual = actualBandsByGroup[groupKey] ?? <(int, int)>{};
      final expected = expectedAgeBands.toSet();

      final missing = expected.difference(actual);
      final extra = actual.difference(expected);

      for (final band in missing) {
        bandMismatchMessages.add(
          '(linh_vuc=$linhVuc, phan_loai=$phanLoai): thiếu dải ${band.$1}-${band.$2} tháng',
        );
      }
      for (final band in extra) {
        bandMismatchMessages.add(
          '(linh_vuc=$linhVuc, phan_loai=$phanLoai): có dải lạ ${band.$1}-${band.$2} tháng '
          '(không thuộc 3 dải mong đợi 15-23/24-47/48-60)',
        );
      }
    }
  }

  return SoSanhValidationReport(
    fieldIssues: fieldIssues,
    ageRangeIssues: ageRangeIssues,
    duplicateIssues: duplicateIssues,
    unexpectedLinhVucIssues: unexpectedLinhVucIssues,
    bandMismatchMessages: bandMismatchMessages,
    groupSummaries: groupSummaries,
  );
}

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty ? args.first : 'assets/reference/expert_content_so_sanh.json';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Không tìm thấy $path — hãy chạy script từ thư mục gốc repo.');
    exitCode = 1;
    return;
  }

  final allEntries =
      (jsonDecode(await file.readAsString()) as List<dynamic>).cast<Map<String, dynamic>>();
  final soSanhEntries = allEntries.where((e) => e['content_type'] == 'so_sanh').toList();

  final report = validateSoSanhData(soSanhEntries);
  // ignore: avoid_print
  print(report.buildReport());

  if (!report.isStructurallyValid) {
    exitCode = 1;
  }
}
