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

DateTime dobForMonthsAgo(int months) {
  final now = DateTime.now();
  var year = now.year;
  var month = now.month - months;
  while (month <= 0) {
    month += 12;
    year -= 1;
  }
  return DateTime(year, month, now.day);
}

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
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('Test 1: Tổng số dòng 24-47 tháng đúng 196 và phân bổ chính xác 7 lĩnh vực', () async {
    final chunks2447 = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 30,
    );

    expect(chunks2447.length, 196);

    final byDomain = <String, int>{};
    final byPhanLoai = <String, int>{};
    for (final c in chunks2447) {
      byDomain[c.linhVuc ?? 'none'] = (byDomain[c.linhVuc ?? 'none'] ?? 0) + 1;
      byPhanLoai[c.phanLoai ?? 'none'] =
          (byPhanLoai[c.phanLoai ?? 'none'] ?? 0) + 1;
    }

    expect(byDomain['nhan_thuc'], 22);
    expect(byDomain['giac_quan'], 8);
    expect(byDomain['quan_he_xa_hoi'], 22);
    expect(byDomain['ngon_ngu'], 64);
    expect(byDomain['sinh_hoc'], 50);
    expect(byDomain['sinh_hoat_ca_nhan'], 18);
    expect(byDomain['cam_xuc'], 12);

    expect(byPhanLoai['binh_thuong'], 98);
    expect(byPhanLoai['roi_loan_pho_tu_ky'], 98);

    print('PASS Test 1: Đủ 196 entry dải 24-47 tháng trên 7 lĩnh vực (98 BT, 98 TK)');
  });

  test('Test 2: Trẻ 23 tháng (biên trên 15-23) -> Trả về dải 15-23, KHÔNG có entry 24-47', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 23,
    );

    expect(chunks.length, 200);
    for (final c in chunks) {
      expect(c.doTuoiThangMin, 15);
      expect(c.doTuoiThangMax, 23);
    }
    print('PASS Test 2: Trẻ 23 tháng nhận đúng 200 entry dải 15-23, không lẫn 24-47');
  });

  test('Test 3: Trẻ 24 tháng (biên dưới 24-47) -> Trả về dải 24-47, KHÔNG có entry 15-23', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 24,
    );

    expect(chunks.length, 196);
    for (final c in chunks) {
      expect(c.doTuoiThangMin, 24);
      expect(c.doTuoiThangMax, 47);
    }
    print('PASS Test 3: Trẻ 24 tháng nhận đúng 196 entry dải 24-47, không lẫn 15-23');
  });

  test('Test 4: Trẻ 47 tháng (biên trên 24-47) -> Trả về dải 24-47', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 47,
    );

    expect(chunks.length, 196);
    for (final c in chunks) {
      expect(c.doTuoiThangMin, 24);
      expect(c.doTuoiThangMax, 47);
    }
    print('PASS Test 4: Trẻ 47 tháng nhận đúng 196 entry dải 24-47');
  });

  test('Test 5: Trẻ 48 tháng (ngoài dải 24-47) -> KHÔNG nhận bất kỳ entry nào từ dải 24-47', () async {
    final chunks = await expertRepo.query(
      contentType: 'so_sanh',
      ageInMonths: 48,
    );

    for (final c in chunks) {
      expect(c.doTuoiThangMax, isNot(47));
    }
    print('PASS Test 5: Trẻ 48 tháng không bị nhận nhầm dữ liệu dải 24-47');
  });

  test('Test 6 (Test riêng Cảm xúc): Trẻ 30 tháng query linh_vuc=cam_xuc -> Trả về đủ 12 entry', () async {
    final camXucChunks = await expertRepo.query(
      contentType: 'so_sanh',
      linhVuc: 'cam_xuc',
      ageInMonths: 30,
    );

    expect(camXucChunks.length, 12);
    final bt = camXucChunks.where((c) => c.phanLoai == 'binh_thuong').length;
    final tk =
        camXucChunks.where((c) => c.phanLoai == 'roi_loan_pho_tu_ky').length;

    expect(bt, 6);
    expect(tk, 6);
    print('PASS Test 6: Lĩnh vực Cảm xúc 24-47 tháng có đủ 12 entry (6 BT, 6 TK), không còn rỗng');
  });

  test('Test 7: VectorSearchService lọc tuổi trước similarity -> Trẻ 30 tháng chỉ tìm trong dải 24-47', () async {
    final queryEmbedding = [0.1, 0.2, 0.3, 0.4];
    final results = await vectorSearchService.searchExpertChunks(
      30,
      queryEmbedding,
      topK: 10,
    );

    expect(results, isNotEmpty);
    for (final r in results) {
      expect(r.chunk.doTuoiThangMin, 24);
      expect(r.chunk.doTuoiThangMax, 47);
    }
    print('PASS Test 7: VectorSearchService lọc tuổi trước similarity cho dải 24-47 chuẩn xác');
  });

  testWidgets('Test 8: Widget ComparisonVideoPage trẻ 30 tháng lĩnh vực Cảm xúc hiển thị dữ liệu', (tester) async {
    final now = DateTime.now();
    final dob30 = dobFromAgeInMonths(30, now);
    final child30 = Child(
      id: 'child-30m',
      name: 'Bé Lan (30 tháng)',
      dob: dob30.toIso8601String(),
      createdAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonVideoPage(
          child: child30,
          linhVuc: 'cam_xuc',
          linhVucLabel: 'Cảm xúc',
        ),
      ),
    );

    await pumpFrames(tester, times: 30);

    expect(find.text('Cảm xúc — So sánh nhanh'), findsOneWidget);
    expect(find.text('Trẻ bình thường'), findsOneWidget);
    expect(find.text('Trẻ tự kỷ'), findsOneWidget);
    expect(find.text('Xem chi tiết so sánh'), findsOneWidget);

    print('PASS Test 8: Widget ComparisonVideoPage hiển thị dữ liệu Cảm xúc 24-47 tháng thành công');
  });
}
