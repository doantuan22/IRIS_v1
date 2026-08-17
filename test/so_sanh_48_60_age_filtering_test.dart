// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/profile_chunk_repository.dart';
import 'package:iris_app/domain/models/child.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:iris_app/domain/services/vector_search_service.dart';
import 'package:iris_app/features/assessment/nine_domains/comparison_video/comparison_video_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pumpFrames(WidgetTester tester, {int times = 15}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;
  late ExpertKnowledgeRepository expertRepo;
  late ProfileChunkRepository profileRepo;
  late VectorSearchService vectorSearchService;

  setUp(() async {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    appDatabase = AppDatabase.instance;
    expertRepo = ExpertKnowledgeRepository(appDatabase);
    profileRepo = ProfileChunkRepository(appDatabase);
    vectorSearchService = VectorSearchService(profileRepo, expertRepo);

    final db = await appDatabase.database;
    final dummyEmbedding = encodeEmbedding(List<double>.filled(1024, 0.05));

    // Nạp dữ liệu 15-23 tháng (200 entry)
    final file1523 = File('assets/reference/so_sanh_15_23_thang.json');
    if (file1523.existsSync()) {
      final json1523 =
          jsonDecode(file1523.readAsStringSync()) as Map<String, dynamic>;
      final entries1523 =
          (json1523['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final e in entries1523) {
        await db.insert('expert_knowledge_chunks', {
          'id': e['id'] as String,
          'content': e['content'] as String,
          'content_type': e['content_type'] as String,
          'phan_loai': e['phan_loai'] as String?,
          'linh_vuc': e['linh_vuc'] as String?,
          'do_tuoi_thang_min': e['do_tuoi_thang_min'] as int?,
          'do_tuoi_thang_max': e['do_tuoi_thang_max'] as int?,
          'nguon_tai_lieu': e['nguon_tai_lieu'] as String?,
          'embedding': dummyEmbedding,
        });
      }
    }

    // Nạp dữ liệu 24-47 tháng (196 entry)
    final file2447 = File('assets/reference/so_sanh_24_47_thang.json');
    if (file2447.existsSync()) {
      final json2447 =
          jsonDecode(file2447.readAsStringSync()) as Map<String, dynamic>;
      final entries2447 =
          (json2447['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final e in entries2447) {
        await db.insert('expert_knowledge_chunks', {
          'id': e['id'] as String,
          'content': e['content'] as String,
          'content_type': e['content_type'] as String,
          'phan_loai': e['phan_loai'] as String?,
          'linh_vuc': e['linh_vuc'] as String?,
          'do_tuoi_thang_min': e['do_tuoi_thang_min'] as int?,
          'do_tuoi_thang_max': e['do_tuoi_thang_max'] as int?,
          'nguon_tai_lieu': e['nguon_tai_lieu'] as String?,
          'embedding': dummyEmbedding,
        });
      }
    }

    // Nạp dữ liệu 48-60 tháng (136 entry)
    final file4860 = File('assets/reference/so_sanh_48_60_thang.json');
    if (file4860.existsSync()) {
      final json4860 =
          jsonDecode(file4860.readAsStringSync()) as Map<String, dynamic>;
      final entries4860 =
          (json4860['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final e in entries4860) {
        await db.insert('expert_knowledge_chunks', {
          'id': e['id'] as String,
          'content': e['content'] as String,
          'content_type': e['content_type'] as String,
          'phan_loai': e['phan_loai'] as String?,
          'linh_vuc': e['linh_vuc'] as String?,
          'do_tuoi_thang_min': e['do_tuoi_thang_min'] as int?,
          'do_tuoi_thang_max': e['do_tuoi_thang_max'] as int?,
          'nguon_tai_lieu': e['nguon_tai_lieu'] as String?,
          'embedding': dummyEmbedding,
        });
      }
    }
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('Test 1: Tổng số dòng 48-60 tháng đúng 136 và phân bổ chính xác 7 lĩnh vực', () async {
    final chunks4860 = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 54,
    );

    expect(chunks4860.length, 136);

    final byDomain = <String, int>{};
    final byPhanLoai = <String, int>{};
    for (final c in chunks4860) {
      byDomain[c.linhVuc ?? 'none'] = (byDomain[c.linhVuc ?? 'none'] ?? 0) + 1;
      byPhanLoai[c.phanLoai ?? 'none'] =
          (byPhanLoai[c.phanLoai ?? 'none'] ?? 0) + 1;
    }

    expect(byDomain['nhan_thuc'], 28);
    expect(byDomain['cam_xuc'], 8);
    expect(byDomain['giac_quan'], 6);
    expect(byDomain['quan_he_xa_hoi'], 24);
    expect(byDomain['ngon_ngu'], 34);
    expect(byDomain['sinh_hoc'], 18);
    expect(byDomain['sinh_hoat_ca_nhan'], 18);

    expect(byPhanLoai['binh_thuong'], 68);
    expect(byPhanLoai['roi_loan_pho_tu_ky'], 68);

    print('PASS Test 1: Đủ 136 entry dải 48-60 tháng trên 7 lĩnh vực (68 BT, 68 TK)');
  });

  test('Test 2: Tổng số dòng so_sanh toàn DB = 200 + 196 + 136 = 532', () async {
    final db = await appDatabase.database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as count FROM expert_knowledge_chunks WHERE content_type='so_sanh'",
    );
    final count = res.first['count'] as int;
    expect(count, 532);
    print('PASS Test 2: Toàn bộ DB có đúng 532 entry so_sanh trên cả 3 dải tuổi');
  });

  test('Test 3: Biên tuổi 47 tháng (dải 24-47) -> Trả về 24-47, KHÔNG có entry 48-60', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 47,
    );

    expect(chunks.length, 196);
    for (final c in chunks) {
      expect(c.doTuoiThangMin, 24);
      expect(c.doTuoiThangMax, 47);
    }
    print('PASS Test 3: Trẻ 47 tháng nhận đúng 196 entry dải 24-47, không lẫn 48-60');
  });

  test('Test 4: Biên tuổi 48 tháng (bắt đầu dải 48-60) -> Trả về 48-60, KHÔNG có entry 24-47', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 48,
    );

    expect(chunks.length, 136);
    for (final c in chunks) {
      expect(c.doTuoiThangMin, 48);
      expect(c.doTuoiThangMax, 60);
    }
    print('PASS Test 4: Trẻ 48 tháng nhận đúng 136 entry dải 48-60, không lẫn 24-47');
  });

  test('Test 5: Biên tuổi 60 tháng (kết thúc dải 48-60) -> Trả về 48-60', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 60,
    );

    expect(chunks.length, 136);
    for (final c in chunks) {
      expect(c.doTuoiThangMin, 48);
      expect(c.doTuoiThangMax, 60);
    }
    print('PASS Test 5: Trẻ 60 tháng nhận đúng 136 entry dải 48-60');
  });

  test('Test 6: Trẻ 61 tháng trở lên (vùng chưa có dữ liệu) -> Trả về RỖNG TUYỆT ĐỐI', () async {
    final chunks61 = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 61,
    );
    expect(chunks61, isEmpty);

    final chunks72 = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 72,
    );
    expect(chunks72, isEmpty);

    print('PASS Test 6: Trẻ 61+ tháng trả về RỖNG TUYỆT ĐỐI, không fallback sai dải');
  });

  test('Test 7: Verify riêng lĩnh vực quan_he_xa_hoi (24 entry, bảo toàn 2 entry trùng content)', () async {
    final qhxhChunks = await expertRepo.query(
      contentType: 'so_sanh',
      linhVuc: 'quan_he_xa_hoi',
      ageInMonths: 54,
    );

    expect(qhxhChunks.length, 24);
    final bt = qhxhChunks.where((c) => c.phanLoai == 'binh_thuong').toList();
    final tk =
        qhxhChunks.where((c) => c.phanLoai == 'roi_loan_pho_tu_ky').toList();

    expect(bt.length, 12);
    expect(tk.length, 12);

    // Kiểm tra tính duy nhất của ID (tất cả ID đều phân biệt)
    final ids = qhxhChunks.map((c) => c.id).toSet();
    expect(ids.length, 24);

    print('PASS Test 7: Lĩnh vực Quan hệ xã hội 48-60 tháng đủ 24 entry, giữ trọn vẹn cả 2 entry ASD có cùng nội dung');
  });

  test('Test 8: VectorSearchService lọc tuổi trước similarity -> Trẻ 54 tháng chỉ tìm dải 48-60, trẻ 61 tháng RỖNG', () async {
    final queryEmbedding = [0.1, 0.2, 0.3, 0.4];

    // Trẻ 54 tháng -> Có kết quả thuộc dải 48-60
    final results54 = await vectorSearchService.searchExpertChunks(
      54,
      queryEmbedding,
      topK: 10,
    );
    expect(results54, isNotEmpty);
    for (final r in results54) {
      expect(r.chunk.doTuoiThangMin, 48);
      expect(r.chunk.doTuoiThangMax, 60);
    }

    // Trẻ 61 tháng -> RỖNG
    final results61 = await vectorSearchService.searchExpertChunks(
      61,
      queryEmbedding,
      topK: 10,
    );
    expect(results61, isEmpty);

    print('PASS Test 8: VectorSearchService lọc tuổi dải 48-60 và xử lý ngoài dải chính xác');
  });

  testWidgets('Test 9: Widget ComparisonVideoPage trẻ 54 tháng hiển thị đủ 2 tab có dữ liệu', (tester) async {
    final now = DateTime.now();
    final dob54 = dobFromAgeInMonths(54, now);
    final child54 = Child(
      id: 'child-54m',
      name: 'Bé Hùng (54 tháng)',
      dob: dob54.toIso8601String(),
      createdAt: now,
    );

    const domains = [
      ('nhan_thuc', 'Nhận thức'),
      ('cam_xuc', 'Cảm xúc'),
      ('giac_quan', 'Giác quan'),
      ('quan_he_xa_hoi', 'Quan hệ xã hội'),
      ('ngon_ngu', 'Ngôn ngữ'),
      ('sinh_hoc', 'Sinh học'),
      ('sinh_hoat_ca_nhan', 'Sinh hoạt cá nhân'),
    ];

    for (final (linhVuc, label) in domains) {
      await tester.pumpWidget(
        MaterialApp(
          home: ComparisonVideoPage(
            child: child54,
            linhVuc: linhVuc,
            linhVucLabel: label,
          ),
        ),
      );

      await pumpFrames(tester, times: 20);

      expect(find.text('$label — So sánh nhanh'), findsOneWidget);
      expect(find.text('Trẻ bình thường'), findsOneWidget);
      expect(find.text('Trẻ tự kỷ'), findsOneWidget);
      expect(find.text('Xem chi tiết so sánh'), findsOneWidget);
    }

    print('PASS Test 9: Widget ComparisonVideoPage trẻ 54 tháng hiển thị dữ liệu thành công trên cả 7 lĩnh vực');
  });
}
