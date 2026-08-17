// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _nvidiaEmbeddingEndpoint =
    'https://integrate.api.nvidia.com/v1/embeddings';
const String _nvidiaEmbeddingModel = 'nvidia/nv-embedqa-e5-v5';

/// Script ingest 136 entry dữ liệu tham khảo So sánh dải tuổi 48-60 tháng
/// vào SQLite database `expert_knowledge_chunks` sử dụng NVIDIA NIM Embedding API.
///
/// Chạy:
///   dart run scripts/ingest_so_sanh_48_60.dart
void main(List<String> args) async {
  print('=== INGEST DỮ LIỆU SO SÁNH 48-60 THÁNG ===');

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Đọc API key từ dart_define.json hoặc biến môi trường
  var apiKey = Platform.environment['NVIDIA_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    final defineFile = File('dart_define.json');
    if (defineFile.existsSync()) {
      try {
        final map =
            jsonDecode(defineFile.readAsStringSync()) as Map<String, dynamic>;
        apiKey = (map['NVIDIA_API_KEY'] as String?) ?? '';
      } catch (_) {}
    }
  }

  if (apiKey.isEmpty) {
    print(
      'LỖI: Chưa có NVIDIA_API_KEY! Hãy cấu hình trong dart_define.json hoặc biến môi trường.',
    );
    exit(1);
  }

  final jsonFile = File('so_sanh_48_60_thang.json');
  if (!jsonFile.existsSync()) {
    print('LỖI: Không tìm thấy file so_sanh_48_60_thang.json!');
    exit(1);
  }

  final data = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
  final entries =
      (data['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
  print('Đã đọc ${entries.length} entry từ so_sanh_48_60_thang.json.');

  final dbPath = args.isNotEmpty ? args.first : 'iris_so_sanh_48_60.db';
  print('Target SQLite DB: $dbPath');

  final db = await openDatabase(
    dbPath,
    version: 9,
    onCreate: (db, version) async {
      await db.execute(expertKnowledgeChunksTableCreate);
    },
  );

  // Xoá sạch toàn bộ dữ liệu dải 48-60 cũ (nếu có)
  final deleted = await db.delete(
    'expert_knowledge_chunks',
    where: "content_type = 'so_sanh' AND do_tuoi_thang_min = 48 AND do_tuoi_thang_max = 60",
  );
  print('Đã xoá $deleted dòng dải 48-60 cũ trước khi insert.');

  print('Bắt đầu gọi NVIDIA Embedding API và nạp vào database...');

  final client = http.Client();
  var successCount = 0;
  var failCount = 0;
  final failedIds = <String>[];

  const batchSize = 10;
  for (var i = 0; i < entries.length; i += batchSize) {
    final end =
        (i + batchSize < entries.length) ? i + batchSize : entries.length;
    final batch = entries.sublist(i, end);
    final texts = batch.map((e) => e['content'] as String).toList();

    try {
      final response = await client.post(
        Uri.parse(_nvidiaEmbeddingEndpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'input': texts,
          'model': _nvidiaEmbeddingModel,
          'input_type': 'query',
          'encoding_format': 'float',
        }),
      );

      if (response.statusCode != 200) {
        print(
          '\nLỗi gọi API NVIDIA batch $i-$end: ${response.statusCode} - ${response.body}',
        );
        failCount += batch.length;
        failedIds.addAll(batch.map((e) => e['id'] as String));
        continue;
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final responseData = decoded['data'] as List<dynamic>;

      for (var j = 0; j < batch.length; j++) {
        final entry = batch[j];
        final embedding = (responseData[j]['embedding'] as List)
            .map((v) => (v as num).toDouble())
            .toList();

        await db.delete(
          'expert_knowledge_chunks',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );

        await db.insert('expert_knowledge_chunks', {
          'id': entry['id'] as String,
          'content': entry['content'] as String,
          'content_type': entry['content_type'] as String,
          'phan_loai': entry['phan_loai'] as String?,
          'nhom_tre': null,
          'boi_canh': null,
          'linh_vuc': entry['linh_vuc'] as String?,
          'do_tuoi_thang_min': entry['do_tuoi_thang_min'] as int?,
          'do_tuoi_thang_max': entry['do_tuoi_thang_max'] as int?,
          'nguon_tai_lieu': entry['nguon_tai_lieu'] as String?,
          'embedding': encodeEmbedding(embedding),
        });
        successCount++;
      }
      stdout.write('.');
    } catch (e) {
      print('\nException batch $i-$end: $e');
      failCount += batch.length;
      failedIds.addAll(batch.map((e) => e['id'] as String));
    }
  }

  print('');
  client.close();
  print('=== HOÀN TẤT INGEST ===');
  print('Thành công: $successCount, Thất bại: $failCount');
  if (failedIds.isNotEmpty) {
    print('Các ID thất bại: $failedIds');
  }

  final countRows = await db.rawQuery(
    "SELECT COUNT(*) as count FROM expert_knowledge_chunks WHERE content_type='so_sanh' AND do_tuoi_thang_min=48 AND do_tuoi_thang_max=60",
  );
  final count = countRows.first['count'];
  print('Tổng số dòng dải 48-60 tháng trong DB: $count');

  final byDomain = await db.rawQuery('''
    SELECT linh_vuc, phan_loai, COUNT(*) as count 
    FROM expert_knowledge_chunks 
    WHERE content_type='so_sanh' AND do_tuoi_thang_min=48 AND do_tuoi_thang_max=60
    GROUP BY linh_vuc, phan_loai
    ORDER BY linh_vuc, phan_loai
  ''');

  print('Phân bổ chi tiết 7 lĩnh vực:');
  for (final row in byDomain) {
    print(' - ${row['linh_vuc']} | ${row['phan_loai']}: ${row['count']}');
  }

  final byDomainTotal = await db.rawQuery('''
    SELECT linh_vuc, COUNT(*) as count 
    FROM expert_knowledge_chunks 
    WHERE content_type='so_sanh' AND do_tuoi_thang_min=48 AND do_tuoi_thang_max=60
    GROUP BY linh_vuc
    ORDER BY linh_vuc
  ''');

  print('Tổng cộng từng lĩnh vực:');
  for (final row in byDomainTotal) {
    print(' - ${row['linh_vuc']}: ${row['count']}');
  }

  await db.close();
}
