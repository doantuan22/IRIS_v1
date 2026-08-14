import 'dart:convert';
import 'dart:io';

/// Validate dữ liệu `content_type='so_sanh'` (mục "So sánh với trẻ cùng độ
/// tuổi") trước khi ingest vào `expert_knowledge_chunks`.
///
/// Dữ liệu được tổ chức theo 2 nhóm `phan_loai` với 2 hệ dải tuổi KHÁC NHAU
/// (đã chốt, không phải migration schema — cột `phan_loai` dùng lại, chỉ là
/// 2 giá trị mới bên cạnh `thuong_gap`/`can_quan_sat` đã có sẵn cho các entry
/// `so_sanh` khác):
///   - `binh_thuong` (biểu hiện thường gặp): 15-17, 18-23, 24-29, 30-35,
///     36-47, 48-59, 60-71 tháng (7 dải, mốc trên cùng chốt ở 71).
///   - `roi_loan_pho_tu_ky` (dấu hiệu cần quan sát thêm): 15-23, 24-47,
///     48-59 tháng (3 dải, mốc trên cùng chốt ở 59).
///
/// Chạy độc lập (từ thư mục gốc repo):
///   dart run scripts/validate_so_sanh_data.dart
/// hoặc trỏ tới file khác:
///   dart run scripts/validate_so_sanh_data.dart path/to/file.json
///
/// Logic validate tách khỏi `main()` (`validateSoSanhData`) để test được
/// bằng dữ liệu giả, không cần đọc file — xem `test/validate_so_sanh_data_test.dart`.

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
  final List<String> gapMessages;
  final Map<String, GroupSummary> groupSummaries;

  const SoSanhValidationReport({
    required this.fieldIssues,
    required this.ageRangeIssues,
    required this.duplicateIssues,
    required this.gapMessages,
    required this.groupSummaries,
  });

  /// Không có lỗi cấu trúc (thiếu trường / min>max / trùng) — dữ liệu đủ
  /// điều kiện để ingest. Gap tuổi chỉ là CẢNH BÁO, không chặn ingest, vì có
  /// thể là do dữ liệu chưa nạp đủ 9 lĩnh vực chứ không phải lỗi cấu trúc.
  bool get isStructurallyValid =>
      fieldIssues.isEmpty && ageRangeIssues.isEmpty && duplicateIssues.isEmpty;

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

    buffer.writeln('\n4. Khoảng trống tuổi (age gap) phát hiện: ${gapMessages.length}');
    for (final gap in gapMessages) {
      buffer.writeln('  - $gap');
    }

    buffer.writeln('\n5. Tổng số entry theo (linh_vuc, phan_loai):');
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
      '$totalPlaceholder placeholder, $totalReal nội dung thật.',
    );

    buffer.writeln(
      '\nKết luận: ${isStructurallyValid ? 'HỢP LỆ về cấu trúc, sẵn sàng ingest.' : 'CÓ LỖI CẤU TRÚC — xem mục 1-3 ở trên.'}',
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
  final groupSummaries = <String, GroupSummary>{};
  final groupedForGapCheck = <String, List<(int min, int max, String id)>>{};
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

    groupedForGapCheck.putIfAbsent(groupKey, () => []).add((min, max, id));
  }

  final gapMessages = <String>[];
  final sortedGroupKeys = groupedForGapCheck.keys.toList()..sort();
  for (final groupKey in sortedGroupKeys) {
    final bands = groupedForGapCheck[groupKey]!..sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 0; i < bands.length - 1; i++) {
      final currentMax = bands[i].$2;
      final nextMin = bands[i + 1].$1;
      if (nextMin > currentMax + 1) {
        final parts = groupKey.split('|');
        gapMessages.add(
          '(linh_vuc=${parts[0]}, phan_loai=${parts[1]}): thiếu dải tuổi từ '
          '${currentMax + 1} đến ${nextMin - 1} tháng (giữa dải kết thúc ở '
          '$currentMax và dải bắt đầu ở $nextMin)',
        );
      }
    }
  }

  return SoSanhValidationReport(
    fieldIssues: fieldIssues,
    ageRangeIssues: ageRangeIssues,
    duplicateIssues: duplicateIssues,
    gapMessages: gapMessages,
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
