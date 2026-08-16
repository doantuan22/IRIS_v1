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

/// Test kiểm chứng nghiêm ngặt logic lọc theo độ tuổi cho dải 15-23 tháng:
/// 1. Trẻ 18 tháng (giữa dải 15-23) -> CÓ dữ liệu đầy đủ 7 lĩnh vực (tổng 200).
/// 2. Trẻ 15 tháng (chính xác biên dưới) -> CÓ dữ liệu.
/// 3. Trẻ 23 tháng (chính xác biên trên) -> CÓ dữ liệu.
/// 4. Trẻ 14 tháng (ngay dưới biên) -> RỖNG (0 kết quả).
/// 5. Trẻ 24 tháng (ngay trên biên) -> RỖNG đối với dải 15-23.
/// 6. Trẻ 40 tháng (lớn hơn nhiều) -> RỖNG đối với dải 15-23.
/// 7. Trẻ 60 tháng (lớn hơn nhiều) -> RỖNG đối với dải 15-23.
/// 8. VectorSearchService.searchExpertChunks: trả về rỗng khi ngoài khoảng tuổi, không fallback.
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

    // Nạp toàn bộ 200 entry từ file so_sanh_15_23_thang.json vào DB in-memory
    final file = File('so_sanh_15_23_thang.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entries = (data['entries'] as List<dynamic>).cast<Map<String, dynamic>>();

    final dummyEmbedding = [0.1, 0.2, 0.3, 0.4];

    final db = await appDatabase.database;
    for (final entry in entries) {
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
        'embedding': encodeEmbedding(dummyEmbedding),
      });
    }

    // Thêm 1 entry dải khác (24-36 tháng) để kiểm tra cách ly
    await expertRepo.add(
      content: 'Mốc ngôn ngữ 24-36 tháng riêng biệt',
      contentType: 'so_sanh',
      linhVuc: 'ngon_ngu',
      doTuoiThangMin: 24,
      doTuoiThangMax: 36,
      embedding: dummyEmbedding,
    );
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('Test 1: Trẻ 18 tháng (giữa dải 15-23) -> Trả về đúng 200 entry trên 7 lĩnh vực', () async {
    final all18 = await expertRepo.query(ageInMonths: 18, contentType: 'so_sanh');
    // Chỉ lấy 200 entry của dải 15-23, không lẫn entry 24-36
    expect(all18.length, 200);

    // Kiểm tra số lượng từng lĩnh vực khớp chính xác số liệu kiểm chứng
    final nhanThuc = await expertRepo.query(linhVuc: 'nhan_thuc', ageInMonths: 18, contentType: 'so_sanh');
    expect(nhanThuc.length, 26);
    expect(nhanThuc.where((c) => c.phanLoai == 'binh_thuong').length, 13);
    expect(nhanThuc.where((c) => c.phanLoai == 'roi_loan_pho_tu_ky').length, 13);

    final camXuc = await expertRepo.query(linhVuc: 'cam_xuc', ageInMonths: 18, contentType: 'so_sanh');
    expect(camXuc.length, 14);

    final quanHeXaHoi = await expertRepo.query(linhVuc: 'quan_he_xa_hoi', ageInMonths: 18, contentType: 'so_sanh');
    expect(quanHeXaHoi.length, 21);

    final ngonNgu = await expertRepo.query(linhVuc: 'ngon_ngu', ageInMonths: 18, contentType: 'so_sanh');
    expect(ngonNgu.length, 56);

    final sinhHoc = await expertRepo.query(linhVuc: 'sinh_hoc', ageInMonths: 18, contentType: 'so_sanh');
    expect(sinhHoc.length, 43);

    final sinhHoat = await expertRepo.query(linhVuc: 'sinh_hoat_ca_nhan', ageInMonths: 18, contentType: 'so_sanh');
    expect(sinhHoat.length, 30);

    final giacQuan = await expertRepo.query(linhVuc: 'giac_quan', ageInMonths: 18, contentType: 'so_sanh');
    expect(giacQuan.length, 10);

    // ignore: avoid_print
    print('PASS Test 1: Trẻ 18 tháng truy vấn nhận đủ 200 entry 7 lĩnh vực chuẩn xác');
  });

  test('Test 2: Trẻ CHÍNH XÁC 15 tháng (biên dưới) -> CÓ dữ liệu đầy đủ', () async {
    final result15 = await expertRepo.query(ageInMonths: 15, contentType: 'so_sanh');
    expect(result15.length, 200);

    final nhanThuc = await expertRepo.query(linhVuc: 'nhan_thuc', ageInMonths: 15, contentType: 'so_sanh');
    expect(nhanThuc.length, 26);

    // ignore: avoid_print
    print('PASS Test 2: Trẻ đúng 15 tháng nhận đủ dữ liệu biên dưới');
  });

  test('Test 3: Trẻ CHÍNH XÁC 23 tháng (biên trên) -> CÓ dữ liệu đầy đủ', () async {
    final result23 = await expertRepo.query(ageInMonths: 23, contentType: 'so_sanh');
    expect(result23.length, 200);

    final ngonNgu = await expertRepo.query(linhVuc: 'ngon_ngu', ageInMonths: 23, contentType: 'so_sanh');
    expect(ngonNgu.length, 56);

    // ignore: avoid_print
    print('PASS Test 3: Trẻ đúng 23 tháng nhận đủ dữ liệu biên trên');
  });

  test('Test 4: Trẻ 14 tháng (ngay dưới biên) -> RỖNG TUYỆT ĐỐI (0 kết quả)', () async {
    final result14 = await expertRepo.query(ageInMonths: 14, contentType: 'so_sanh');
    expect(result14, isEmpty);

    final nhanThuc14 = await expertRepo.query(linhVuc: 'nhan_thuc', ageInMonths: 14, contentType: 'so_sanh');
    expect(nhanThuc14, isEmpty);

    // ignore: avoid_print
    print('PASS Test 4: Trẻ 14 tháng trả về RỖNG, không bị gán nhầm dải 15-23');
  });

  test('Test 5: Trẻ 24 tháng (ngay trên biên) -> KHÔNG nhận dữ liệu của dải 15-23', () async {
    // Với lĩnh vực nhận thức (chỉ có dải 15-23) -> RỖNG
    final nhanThuc24 = await expertRepo.query(linhVuc: 'nhan_thuc', ageInMonths: 24, contentType: 'so_sanh');
    expect(nhanThuc24, isEmpty);

    // Với lĩnh vực ngôn ngữ (có 1 chunk 24-36) -> CHỈ nhận chunk 24-36, KHÔNG nhận chunk 15-23
    final ngonNgu24 = await expertRepo.query(linhVuc: 'ngon_ngu', ageInMonths: 24, contentType: 'so_sanh');
    expect(ngonNgu24.length, 1);
    expect(ngonNgu24.single.content, 'Mốc ngôn ngữ 24-36 tháng riêng biệt');

    // ignore: avoid_print
    print('PASS Test 5: Trẻ 24 tháng không nhận bất kỳ entry nào từ dải 15-23');
  });

  test('Test 6: Trẻ 40 tháng (lớn hơn nhiều) -> RỖNG TUYỆT ĐỐI', () async {
    final result40 = await expertRepo.query(ageInMonths: 40, contentType: 'so_sanh');
    expect(result40, isEmpty);

    for (final domain in ['nhan_thuc', 'cam_xuc', 'quan_he_xa_hoi', 'ngon_ngu', 'sinh_hoc', 'sinh_hoat_ca_nhan', 'giac_quan']) {
      final domainResult = await expertRepo.query(linhVuc: domain, ageInMonths: 40, contentType: 'so_sanh');
      expect(domainResult, isEmpty);
    }

    // ignore: avoid_print
    print('PASS Test 6: Trẻ 40 tháng trả về RỖNG trên toàn bộ 7 lĩnh vực');
  });

  test('Test 7: Trẻ 60 tháng (5 tuổi, ngoài khoảng) -> RỖNG TUYỆT ĐỐI', () async {
    final result60 = await expertRepo.query(ageInMonths: 60, contentType: 'so_sanh');
    expect(result60, isEmpty);

    // ignore: avoid_print
    print('PASS Test 7: Trẻ 60 tháng trả về RỖNG trên toàn bộ 7 lĩnh vực');
  });

  test('Test 8: VectorSearchService.searchExpertChunks lọc tuổi trước similarity -> Không trả về dải 15-23 cho trẻ 40 tháng', () async {
    final queryEmbedding = [0.1, 0.2, 0.3, 0.4];

    // Trẻ 18 tháng -> Có kết quả
    final results18 = await vectorSearchService.searchExpertChunks(18, queryEmbedding, topK: 5);
    expect(results18.isNotEmpty, isTrue);
    expect(results18.every((r) => r.chunk.doTuoiThangMin == 15 && r.chunk.doTuoiThangMax == 23), isTrue);

    // Trẻ 40 tháng -> RỖNG
    final results40 = await vectorSearchService.searchExpertChunks(40, queryEmbedding, topK: 5);
    expect(results40, isEmpty);

    // Trẻ 14 tháng -> RỖNG
    final results14 = await vectorSearchService.searchExpertChunks(14, queryEmbedding, topK: 5);
    expect(results14, isEmpty);

    // ignore: avoid_print
    print('PASS Test 8: VectorSearchService lọc tuổi trước khi tính similarity, hoàn toàn không có fallback');
  });

  test('Test 9: Child model childAgeInMonths quy đổi chính xác từ dob sang tháng tuổi', () {
    final now = DateTime.now();

    // Trẻ sinh cách đây đúng 18 tháng
    final dob18 = dobForMonthsAgo(18);
    final child18 = Child(
      id: 'c-18',
      name: 'Bé 18m',
      dob: dob18.toIso8601String(),
      createdAt: now,
    );
    expect(childAgeInMonths(child18), 18);

    // Trẻ sinh cách đây đúng 15 tháng
    final dob15 = dobForMonthsAgo(15);
    final child15 = Child(
      id: 'c-15',
      name: 'Bé 15m',
      dob: dob15.toIso8601String(),
      createdAt: now,
    );
    expect(childAgeInMonths(child15), 15);

    // Trẻ sinh cách đây đúng 40 tháng
    final dob40 = dobForMonthsAgo(40);
    final child40 = Child(
      id: 'c-40',
      name: 'Bé 40m',
      dob: dob40.toIso8601String(),
      createdAt: now,
    );
    expect(childAgeInMonths(child40), 40);

    // ignore: avoid_print
    print('PASS Test 9: childAgeInMonths quy đổi dob sang số tháng hoàn toàn chính xác');
  });

  testWidgets('Test 10: ComparisonVideoPage với trẻ 18 tháng -> Tải và hiển thị dữ liệu So sánh dải 15-23', (tester) async {
    final now = DateTime.now();
    final dob18 = dobForMonthsAgo(18);
    final child18 = Child(
      id: 'c-18-ui',
      name: 'Bé Test 18 Tháng',
      dob: dob18.toIso8601String(),
      createdAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonVideoPage(
          child: child18,
          linhVuc: 'nhan_thuc',
          linhVucLabel: 'Nhận thức',
        ),
      ),
    );

    await pumpFrames(tester);

    // Xác nhận tiêu đề và không có thông báo rỗng
    expect(find.text('Nhận thức — So sánh nhanh'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu so sánh cho lĩnh vực này ở độ tuổi hiện tại.'), findsNothing);
    expect(find.text('Xem chi tiết so sánh'), findsOneWidget);

    // ignore: avoid_print
    print('PASS Test 10: ComparisonVideoPage hiển thị dữ liệu thành công cho trẻ 18 tháng');
  });

  testWidgets('Test 11: ComparisonVideoPage với trẻ 40 tháng -> Hiển thị đúng trạng thái RỖNG, không crash, không lẫn dữ liệu 15-23', (tester) async {
    final now = DateTime.now();
    final dob40 = dobForMonthsAgo(40);
    final child40 = Child(
      id: 'c-40-ui',
      name: 'Bé Test 40 Tháng',
      dob: dob40.toIso8601String(),
      createdAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonVideoPage(
          child: child40,
          linhVuc: 'nhan_thuc',
          linhVucLabel: 'Nhận thức',
        ),
      ),
    );

    await pumpFrames(tester);

    // Xác nhận tiêu đề, 2 tab, và thông báo rỗng đúng cho tab đang hiện
    // (mặc định tab 0 = "Trẻ bình thường") — không hiện bảng trống.
    expect(find.text('Nhận thức — So sánh nhanh'), findsOneWidget);
    expect(find.text('Trẻ bình thường'), findsOneWidget);
    expect(find.text('Trẻ tự kỷ'), findsOneWidget);
    expect(
      find.text(
        'Chưa có dữ liệu so sánh cho trẻ bình thường ở lĩnh vực này, độ tuổi hiện tại.',
      ),
      findsOneWidget,
    );
    expect(find.text('Xem chi tiết so sánh'), findsNothing);

    // Chuyển sang tab "Trẻ tự kỷ" -> cũng đúng thông báo rỗng riêng cho tab đó
    await tester.tap(find.text('Trẻ tự kỷ'));
    await pumpFrames(tester);
    expect(
      find.text(
        'Chưa có dữ liệu so sánh cho trẻ tự kỷ ở lĩnh vực này, độ tuổi hiện tại.',
      ),
      findsOneWidget,
    );

    // ignore: avoid_print
    print('PASS Test 11: ComparisonVideoPage hiển thị đúng trạng thái RỖNG cho trẻ 40 tháng');
  });
}
