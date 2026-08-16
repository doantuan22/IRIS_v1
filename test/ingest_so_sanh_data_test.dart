import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scripts/ingest_so_sanh_data.dart' show ingestValidSoSanhEntries;

/// Test logic ingest dữ liệu `so_sanh` bằng embedding GIẢ — không gọi NVIDIA
/// API thật. Quan trọng: đọc lại từ chính DATABASE (file sqlite thật qua
/// `sqflite_common_ffi`, không phải in-memory) để xác nhận dữ liệu thật sự
/// được ghi, thay vì chỉ tin số liệu trả về từ hàm ingest.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late String dbPath;

  setUp(() async {
    dbPath = '${Directory.systemTemp.path}/iris_so_sanh_test_${DateTime.now().microsecondsSinceEpoch}.db';
    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute(expertKnowledgeChunksTableCreate),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();
  });

  test('chỉ ingest entry hợp lệ, entry lỗi cấu trúc bị loại trước khi gọi embed', () async {
    final entries = [
      {
        'id': 'ok-1',
        'content_type': 'so_sanh',
        'linh_vuc': 'ngon_ngu',
        'phan_loai': 'binh_thuong',
        'do_tuoi_thang_min': 15,
        'do_tuoi_thang_max': 17,
        'content': '[Placeholder - chưa có nội dung thật]',
        'nguon_tai_lieu': '[Chưa có nguồn]',
      },
      {
        // min > max — lỗi cấu trúc, phải bị loại, KHÔNG được gọi embed.
        'id': 'bad-range',
        'content_type': 'so_sanh',
        'linh_vuc': 'ngon_ngu',
        'phan_loai': 'binh_thuong',
        'do_tuoi_thang_min': 30,
        'do_tuoi_thang_max': 20,
        'content': '[Placeholder - chưa có nội dung thật]',
        'nguon_tai_lieu': '[Chưa có nguồn]',
      },
    ];

    final embedCalls = <String>[];
    final outcome = await ingestValidSoSanhEntries(
      entries,
      embed: (text) async {
        embedCalls.add(text);
        return List<double>.generate(4, (i) => i.toDouble());
      },
      db: db,
    );

    expect(outcome.invalidCount, 1);
    expect(outcome.ingestResult.total, 1);
    expect(outcome.ingestResult.success, 1);
    expect(embedCalls.length, 1);

    // Đóng và mở lại kết nối tới CHÍNH FILE db vừa ghi, để chắc chắn dữ liệu
    // đã thật sự nằm trên đĩa chứ không chỉ trong bộ nhớ của kết nối cũ.
    await db.close();
    final reopened = await databaseFactory.openDatabase(dbPath);
    final rows = await reopened.query('expert_knowledge_chunks');
    expect(rows.length, 1);
    expect(rows.first['linh_vuc'], 'ngon_ngu');
    expect(rows.first['phan_loai'], 'binh_thuong');
    expect(rows.first['do_tuoi_thang_min'], 15);
    expect(rows.first['do_tuoi_thang_max'], 17);
    await reopened.close();
    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1),
    );
    // ignore: avoid_print
    print('PASS: entry lỗi cấu trúc bị loại trước khi embed, chỉ entry hợp lệ được ghi vào file db thật');
  });

  test('ingest toàn bộ 42 entry hợp lệ từ file JSON thật, đọc lại đúng số dòng theo nhóm', () async {
    final jsonFile = File('assets/reference/expert_content_so_sanh.json');
    final entries = (jsonDecode(await jsonFile.readAsString()) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final outcome = await ingestValidSoSanhEntries(
      entries,
      embed: (text) async => [text.length.toDouble()],
      db: db,
    );

    expect(outcome.invalidCount, 0);
    expect(outcome.ingestResult.success, 42);

    await db.close();
    final reopened = await databaseFactory.openDatabase(dbPath);
    final rows = await reopened.query('expert_knowledge_chunks');
    expect(rows.length, 42);

    final binhThuongCount = rows.where((r) => r['phan_loai'] == 'binh_thuong').length;
    final roiLoanCount = rows.where((r) => r['phan_loai'] == 'roi_loan_pho_tu_ky').length;
    // 7 linh_vuc x 3 dải tuổi (đối xứng, đúng như nhau cho cả 2 phan_loai).
    expect(binhThuongCount, 7 * 3);
    expect(roiLoanCount, 7 * 3);

    await reopened.close();
    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1),
    );
    // ignore: avoid_print
    print('PASS: ingest đủ 42 entry so_sanh thật từ JSON, đọc lại từ file db thật khớp đúng 21 binh_thuong + 21 roi_loan_pho_tu_ky');
  });
}
