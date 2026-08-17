// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/core/constants/domains.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/overview_summary_repository.dart';
import 'package:iris_app/domain/models/overview_summary.dart';
import 'package:iris_app/features/assessment/overview/overview_portrait_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Xác nhận banner mời "Kết nối chuyên gia/trung tâm" hiển thị ở CẢ 3 mức
/// tổng quan sau khi Chân dung toàn cảnh đã tính xong — trước đây banner
/// này CHỈ hiện ở mức [tierChuyenMonSom], nay phải hiện ở cả 3 mức.
void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  Future<void> pumpOverviewFor(WidgetTester tester, String tier) async {
    final child = await ChildRepository(
      AppDatabase.instance,
    ).create(name: 'Bé Test Pump $tier', ageYears: 3);

    final assessmentRepo = AssessmentRepository(AppDatabase.instance);
    for (final domain in domains) {
      await assessmentRepo.save(
        childId: child.id,
        linhVuc: domain.code,
        contentType: 'mo_ta',
        content: 'Mô tả biểu hiện lĩnh vực ${domain.code}',
      );
    }
    await OverviewSummaryRepository(AppDatabase.instance).save(
      childId: child.id,
      tier: tier,
      soLinhVucCanTheoDoi: tier == tierThuongGap ? 0 : (tier == tierCanTheoDoi ? 2 : 5),
      soLinhVucThieuDuLieu: 0,
    );

    await tester.pumpWidget(
      MaterialApp(home: OverviewPortraitPage(child: child)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Test 1: Mức "Trong giới hạn thường gặp" (tierThuongGap) -> banner + nút Kết nối vẫn hiện',
      (tester) async {
    await pumpOverviewFor(tester, tierThuongGap);

    expect(find.text('Kết nối chuyên gia/trung tâm'), findsOneWidget);
    expect(
      find.textContaining('Bé đang trong giới hạn thường gặp'),
      findsOneWidget,
    );

    print('PASS Test 1: Banner + nút Kết nối hiện đúng ở mức Thường gặp');
  });

  testWidgets(
      'Test 2: Mức "Có điểm cần theo dõi" (tierCanTheoDoi) -> banner + nút Kết nối hiện',
      (tester) async {
    await pumpOverviewFor(tester, tierCanTheoDoi);

    expect(find.text('Kết nối chuyên gia/trung tâm'), findsOneWidget);
    expect(
      find.textContaining('Một số lĩnh vực có điểm cần theo dõi'),
      findsOneWidget,
    );

    print('PASS Test 2: Banner + nút Kết nối hiện đúng ở mức Cần theo dõi');
  });

  testWidgets(
      'Test 3: Mức "Nên tìm đánh giá chuyên môn sớm" (tierChuyenMonSom) -> banner + nút Kết nối hiện (như trước)',
      (tester) async {
    await pumpOverviewFor(tester, tierChuyenMonSom);

    expect(find.text('Kết nối chuyên gia/trung tâm'), findsOneWidget);
    expect(
      find.textContaining('Nên tìm đánh giá chuyên môn sớm'),
      findsWidgets,
    );

    print('PASS Test 3: Banner + nút Kết nối hiện đúng ở mức Chuyên môn sớm');
  });

  testWidgets(
      'Test 4: Bấm nút "Kết nối chuyên gia/trung tâm" điều hướng đúng sang ExpertConnectPage',
      (tester) async {
    await pumpOverviewFor(tester, tierThuongGap);

    await tester.ensureVisible(find.text('Kết nối chuyên gia/trung tâm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết nối chuyên gia/trung tâm'));
    await tester.pumpAndSettle();

    expect(find.text('Kết nối chuyên gia/trung tâm'), findsOneWidget); // AppBar title
    await tester.dragUntilVisible(
      find.textContaining('Trung Tâm Hỗ Trợ Phát Triển Giáo Dục Hòa Nhập Tường Minh'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(
      find.textContaining('Trung Tâm Hỗ Trợ Phát Triển Giáo Dục Hòa Nhập Tường Minh'),
      findsOneWidget,
    );

    print('PASS Test 4: Bấm nút điều hướng đúng sang ExpertConnectPage, hiện đúng trung tâm thật');
  });
}
