import 'dart:convert';
import 'dart:io';

import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ingest_expert_data.dart' show IngestResult, ingestEntries;
import 'validate_so_sanh_data.dart' show SoSanhValidationReport, validateSoSanhData;

/// Script chạy 1 lần: đọc `assets/reference/expert_content_so_sanh.json`,
/// validate (xem `validate_so_sanh_data.dart`), CHỈ ingest các entry hợp lệ
/// về cấu trúc, embed qua NVIDIA API thật (tái dùng `ingestEntries` từ
/// `ingest_expert_data.dart`) và ghi vào bảng `expert_knowledge_chunks`.
///
/// Chạy bằng (từ thư mục gốc repo, cần API key NVIDIA thật):
///   dart run scripts/ingest_so_sanh_data.dart --dart-define=NVIDIA_API_KEY=xxx
///
/// Cùng ghi chú về database như `ingest_expert_data.dart`: script này KHÔNG
/// dùng `AppDatabase`/`ExpertKnowledgeRepository` (2 class đó kéo theo
/// `path_provider` → cần Flutter engine, không chạy được qua `dart run`
/// thuần) — tự mở kết nối SQLite qua `sqflite_common_ffi`, ghi thẳng theo
/// đúng schema `expertKnowledgeChunksTableCreate` dùng chung với app.
///
/// Sau khi ingest, script ĐỌC LẠI trực tiếp từ file database vừa ghi (không
/// chỉ tin số liệu log) để in báo cáo xác nhận theo (linh_vuc, phan_loai).
///
/// File kết quả mặc định `iris_so_sanh_seed.db` nằm ở thư mục gốc repo —
/// KHÔNG phải database thật trên thiết bị/emulator. Để đưa dữ liệu vào app
/// thật, dùng nút "Debug: Nạp dữ liệu tham khảo" trong `ChildDebugPage`
/// sau khi đã thêm `expert_content_so_sanh.json` vào danh sách file mà nút
/// đó đọc (file JSON của "so sánh" tách riêng khỏi `expert_content.json`
/// theo đúng yêu cầu, không gộp chung).

/// Kết quả 1 lần ingest: báo cáo validate đầy đủ (kể cả entry bị bỏ qua),
/// số entry bị loại vì lỗi cấu trúc, và kết quả ingest (`ingestEntries`) trên
/// phần còn lại.
class SoSanhIngestOutcome {
  final SoSanhValidationReport report;
  final int invalidCount;
  final IngestResult ingestResult;

  const SoSanhIngestOutcome({
    required this.report,
    required this.invalidCount,
    required this.ingestResult,
  });
}

/// Validate [soSanhEntries], loại các entry lỗi cấu trúc (thiếu trường /
/// min>max / trùng khoá), rồi ingest phần còn lại vào [db] qua [embed] —
/// tách riêng khỏi `main()` để test được bằng embedding giả + database thật
/// (in-memory hoặc file), không cần gọi NVIDIA API thật.
Future<SoSanhIngestOutcome> ingestValidSoSanhEntries(
  List<Map<String, dynamic>> soSanhEntries, {
  required Future<List<double>> Function(String text) embed,
  required Database db,
}) async {
  final report = validateSoSanhData(soSanhEntries);

  final invalidIds = <String>{
    ...report.fieldIssues.map((i) => i.entryId).whereType<String>(),
    ...report.ageRangeIssues.map((i) => i.entryId).whereType<String>(),
    ...report.duplicateIssues.map((i) => i.entryId).whereType<String>(),
    ...report.unexpectedLinhVucIssues.map((i) => i.entryId).whereType<String>(),
  };
  final validEntries =
      soSanhEntries.where((e) => !invalidIds.contains(e['id']?.toString())).toList();

  final ingestResult = await ingestEntries(validEntries, embed: embed, db: db);

  return SoSanhIngestOutcome(
    report: report,
    invalidCount: invalidIds.length,
    ingestResult: ingestResult,
  );
}

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final jsonFile = File('assets/reference/expert_content_so_sanh.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln(
      'Không tìm thấy ${jsonFile.path} — hãy chạy script từ thư mục gốc repo '
      '(dart run scripts/ingest_so_sanh_data.dart).',
    );
    exitCode = 1;
    return;
  }

  final allEntries = (jsonDecode(await jsonFile.readAsString()) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final soSanhEntries = allEntries.where((e) => e['content_type'] == 'so_sanh').toList();

  final dbPath = args.isNotEmpty ? args.first : 'iris_so_sanh_seed.db';
  final db = await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) => db.execute(expertKnowledgeChunksTableCreate),
    ),
  );

  final nvidiaApiClient = NvidiaApiClient();
  final outcome = await ingestValidSoSanhEntries(
    soSanhEntries,
    embed: nvidiaApiClient.embed,
    db: db,
  );

  // ignore: avoid_print
  print(outcome.report.buildReport());
  // ignore: avoid_print
  print(
    '\nBỏ qua ${outcome.invalidCount} entry lỗi cấu trúc, ingest '
    '${outcome.ingestResult.total}/${soSanhEntries.length} entry hợp lệ.',
  );
  // ignore: avoid_print
  print(
    'Hoàn tất: ${outcome.ingestResult.success} thành công, '
    '${outcome.ingestResult.failed} lỗi / ${outcome.ingestResult.total} entry.',
  );

  // Đọc lại từ chính database vừa ghi (không tin log) để xác nhận thật sự
  // đã có dữ liệu, theo đúng (linh_vuc, phan_loai).
  final rows = await db.query(
    'expert_knowledge_chunks',
    where: 'content_type = ?',
    whereArgs: ['so_sanh'],
  );
  final countByGroup = <String, int>{};
  for (final row in rows) {
    final key = '${row['linh_vuc']}|${row['phan_loai']}';
    countByGroup[key] = (countByGroup[key] ?? 0) + 1;
  }
  // ignore: avoid_print
  print('\nXác nhận đọc lại từ $dbPath (${rows.length} dòng so_sanh):');
  final sortedKeys = countByGroup.keys.toList()..sort();
  for (final key in sortedKeys) {
    final parts = key.split('|');
    // ignore: avoid_print
    print('  - linh_vuc=${parts[0]} phan_loai=${parts[1]}: ${countByGroup[key]} dòng');
  }

  await db.close();
}
