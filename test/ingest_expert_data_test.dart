import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scripts/ingest_expert_data.dart' show ingestEntries;

/// Test logic ingest bằng embedding GIẢ — không gọi NVIDIA API thật (chưa
/// có key trong môi trường này). Xác nhận parse + insert đúng vào
/// `expert_knowledge_chunks`, và 1 entry lỗi không làm hỏng các entry khác.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute(expertKnowledgeChunksTableCreate),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('ingestEntries: embed giả, insert đúng field + đúng embedding vào expert_knowledge_chunks', () async {
    final entries = [
      {
        'content': 'Nội dung mẫu 1',
        'content_type': 'so_sanh',
        'phan_loai': 'thuong_gap',
        'linh_vuc': 'ngon_ngu',
        'do_tuoi_thang_min': 24,
        'do_tuoi_thang_max': 36,
      },
      {
        'content': 'Nội dung mẫu 2',
        'content_type': 'chan_dung',
        'linh_vuc': 'hanh_vi',
      },
    ];

    final result = await ingestEntries(
      entries,
      embed: (text) async => List<double>.generate(8, (i) => i + text.length.toDouble()),
      db: db,
    );

    expect(result.total, 2);
    expect(result.success, 2);
    expect(result.failed, 0);

    final rows = await db.query('expert_knowledge_chunks', orderBy: 'content');
    expect(rows.length, 2);

    final row1 = rows.firstWhere((r) => r['content'] == 'Nội dung mẫu 1');
    expect(row1['content_type'], 'so_sanh');
    expect(row1['phan_loai'], 'thuong_gap');
    expect(row1['linh_vuc'], 'ngon_ngu');
    expect(row1['do_tuoi_thang_min'], 24);
    expect(row1['do_tuoi_thang_max'], 36);
    final decodedEmbedding = decodeEmbedding(row1['embedding'] as Uint8List);
    expect(decodedEmbedding.length, 8);

    final row2 = rows.firstWhere((r) => r['content'] == 'Nội dung mẫu 2');
    expect(row2['linh_vuc'], 'hanh_vi');
    expect(row2['do_tuoi_thang_min'], null);
    expect(row2['phan_loai'], null);
    // ignore: avoid_print
    print('PASS: ingestEntries insert đúng field + đúng embedding cho từng entry');
  });

  test('ingestEntries: 1 entry embed lỗi không làm hỏng các entry còn lại', () async {
    final entries = [
      {'content': 'Entry OK', 'content_type': 'so_sanh'},
      {'content': 'Entry LỖI', 'content_type': 'so_sanh'},
      {'content': 'Entry OK 2', 'content_type': 'so_sanh'},
    ];

    final result = await ingestEntries(
      entries,
      embed: (text) async {
        if (text == 'Entry LỖI') throw Exception('giả lập lỗi mạng');
        return [0.1, 0.2];
      },
      db: db,
    );

    expect(result.total, 3);
    expect(result.success, 2);
    expect(result.failed, 1);

    final rows = await db.query('expert_knowledge_chunks');
    expect(rows.length, 2);
    expect(rows.any((r) => r['content'] == 'Entry LỖI'), false);
    // ignore: avoid_print
    print('PASS: 1 entry embed lỗi bị bỏ qua, không ảnh hưởng các entry khác, đếm đúng success/failed');
  });
}
