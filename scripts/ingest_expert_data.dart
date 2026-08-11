import 'dart:convert';
import 'dart:io';

import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Script chạy 1 lần: đọc `assets/reference/expert_content.json`, embed từng
/// entry qua NVIDIA API, và ghi vào bảng `expert_knowledge_chunks`.
///
/// Chạy bằng (từ thư mục gốc repo, cần API key NVIDIA thật):
///   dart run scripts/ingest_expert_data.dart --dart-define=NVIDIA_API_KEY=xxx
///
/// LƯU Ý QUAN TRỌNG — vì sao KHÔNG dùng `AppDatabase`/`ExpertKnowledgeRepository`
/// của app: cả 2 class đó import `path_provider`, mà `path_provider` lại
/// import `package:flutter/foundation.dart` (transitively cần `dart:ui`) —
/// thư viện chỉ tồn tại trong engine Flutter, không có trong Dart VM thuần.
/// Script này chạy qua `dart run` (không phải `flutter run`), nên bất kỳ
/// import nào chạm tới Flutter sẽ làm biên dịch thất bại. Do đó script tự mở
/// kết nối SQLite qua `sqflite_common_ffi` (Flutter-free) và ghi thẳng theo
/// đúng schema `expertKnowledgeChunksTableCreate` dùng chung với app, thay
/// vì gọi qua `ExpertKnowledgeRepository`.
///
/// File kết quả `iris_expert_seed.db` nằm ngay tại thư mục gốc repo — đây
/// KHÔNG phải database thật trên thiết bị/emulator (app đọc dữ liệu qua
/// `path_provider`, chỉ tồn tại khi chạy trong Flutter engine thật).
///
/// ĐỂ NẠP DỮ LIỆU VÀO APP THẬT: dùng nút "Debug: Nạp dữ liệu tham khảo"
/// trong `ProfileDetailPage` (chỉ hiện ở debug mode) — nút đó đọc đúng file
/// JSON này qua `rootBundle` và insert thẳng vào database thật của app đang
/// chạy qua `ExpertKnowledgeRepository`. Script này chỉ dùng để test nhanh
/// logic parse/gọi API trên desktop (xem `test/ingest_expert_data_test.dart`),
/// không dùng để đưa dữ liệu vào app thật.
Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final jsonFile = File('assets/reference/expert_content.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln(
      'Không tìm thấy ${jsonFile.path} — hãy chạy script từ thư mục gốc repo '
      '(dart run scripts/ingest_expert_data.dart).',
    );
    exitCode = 1;
    return;
  }

  final entries = (jsonDecode(await jsonFile.readAsString()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final db = await databaseFactory.openDatabase(
    'iris_expert_seed.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) => db.execute(expertKnowledgeChunksTableCreate),
    ),
  );

  final nvidiaApiClient = NvidiaApiClient();
  final result = await ingestEntries(entries, embed: nvidiaApiClient.embed, db: db);

  // ignore: avoid_print
  print('Hoàn tất: ${result.success} thành công, ${result.failed} lỗi / ${result.total} entry.');
  // ignore: avoid_print
  print('Đã ghi vào ${db.path} — xem ghi chú trong file này về bước đưa dữ liệu vào thiết bị thật.');

  await db.close();
}

/// Logic ingest thật — tách riêng khỏi `main()` để test được bằng embedding
/// giả + database in-memory, không cần gọi NVIDIA API thật.
Future<IngestResult> ingestEntries(
  List<Map<String, dynamic>> entries, {
  required Future<List<double>> Function(String text) embed,
  required Database db,
}) async {
  const uuid = Uuid();
  var success = 0;
  var failed = 0;

  for (final entry in entries) {
    final content = entry['content'] as String;
    try {
      final embedding = await embed(content);
      await db.insert('expert_knowledge_chunks', {
        'id': uuid.v4(),
        'content': content,
        'content_type': entry['content_type'] as String,
        'linh_vuc': entry['linh_vuc'] as String?,
        'do_tuoi_thang_min': entry['do_tuoi_thang_min'] as int?,
        'do_tuoi_thang_max': entry['do_tuoi_thang_max'] as int?,
        'nguon_tai_lieu': entry['nguon_tai_lieu'] as String?,
        'embedding': encodeEmbedding(embedding),
      });
      success++;
    } catch (e) {
      failed++;
      stderr.writeln(
        'Lỗi khi ingest "${content.substring(0, content.length.clamp(0, 40))}...": $e',
      );
    }
  }

  return IngestResult(success: success, failed: failed, total: entries.length);
}

class IngestResult {
  final int success;
  final int failed;
  final int total;

  const IngestResult({required this.success, required this.failed, required this.total});
}
