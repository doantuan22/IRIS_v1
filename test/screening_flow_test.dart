import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/history_log_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:iris_app/domain/services/active_child_service.dart';
import 'package:iris_app/features/child_profile/create_profile/create_profile_page.dart';
import 'package:iris_app/features/child_profile/profile_detail/profile_detail_page.dart';
import 'package:iris_app/features/home/home_page.dart';
import 'package:iris_app/features/multi_child_dashboard/multi_child_dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pumpFrames(WidgetTester tester, {int times = 30}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> fillAndSaveCreateProfileForm(
  WidgetTester tester,
  String name,
) async {
  expect(find.byType(CreateProfilePage), findsOneWidget);

  await tester.enterText(find.byType(TextFormField).first, name);
  await tester.tap(find.text('Theo số tuổi (năm)'));
  await pumpFrames(tester);
  await tester.enterText(find.byType(TextFormField).at(1), '3');

  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'Lưu hồ sơ'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await pumpFrames(tester, times: 5);
  await tester.tap(find.widgetWithText(FilledButton, 'Lưu hồ sơ'));
  await pumpFrames(tester);
}

/// Trả lời 50 câu hỏi 1 câu / 1 màn hình bằng cách chọn '0 — Không / Hiếm khi'
Future<void> answer50Questions(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    final option0 = find.text('0 — Không / Hiếm khi');
    expect(option0, findsOneWidget);
    await tester.tap(option0);
    // Chờ auto-advance 140ms
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }
  // Chờ lưu DB và chuyển màn hình kết quả
  await pumpFrames(tester, times: 15);
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  testWidgets(
    'Tạo hồ sơ → nhánh "Có" sàng lọc 50 câu → xem kết quả → vào thẳng Trang chủ với đúng active child',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await pumpFrames(tester);

      // 1. Tạo hồ sơ
      await fillAndSaveCreateProfileForm(tester, 'Bé Có Sàng Lọc');

      expect(find.byType(ProfileDetailPage), findsNothing);
      expect(find.text('Tạo hồ sơ thành công!'), findsNothing);
      expect(
        find.textContaining('Bạn có muốn thực hiện bài sàng lọc'),
        findsOneWidget,
      );
      expect(find.text('Có'), findsOneWidget);
      expect(find.text('Chưa muốn'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: sau khi tạo hồ sơ, vào thẳng màn hỏi sàng lọc');

      await tester.tap(find.widgetWithText(FilledButton, 'Có'));
      await pumpFrames(tester);

      expect(
        find.text('Bộ câu hỏi sàng lọc 50 câu (7 lĩnh vực)'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Bắt đầu'));
      await pumpFrames(tester);

      // 2. Làm bài sàng lọc 50 câu
      await answer50Questions(tester);

      // 3. Màn hình kết quả
      expect(find.text('Kết quả sàng lọc cho Bé Có Sàng Lọc'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(8)); // 1 điểm tổng quan + 7 điểm lĩnh vực
      expect(find.text('Mức 1 - Ít biểu hiện'), findsOneWidget);
      expect(find.text('Điểm theo 7 lĩnh vực'), findsOneWidget);
      expect(
        find.textContaining('Đây là bản sàng lọc/thử nghiệm để rà soát mức độ biểu hiện'),
        findsOneWidget,
      );
      // ignore: avoid_print
      print('PASS: hoàn thành sàng lọc 50 câu, hiện đúng màn kết quả breakdown 7 lĩnh vực');

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Tiếp tục'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFrames(tester, times: 5);
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
      await pumpFrames(tester);

      // Nhánh Onboarding dẫn thẳng tới HomePage
      expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Bé Có Sàng Lọc'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: nhánh "Có" — sau khi xem kết quả, vào thẳng Trang chủ');

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isFalse);

      final db = await AppDatabase.instance.database;
      final childRows = await db.query('children');
      expect(childRows.length, 1);
      final childId = childRows.first['id'] as String;

      final activeChildId = await ActiveChildService().getActiveChildId();
      expect(activeChildId, childId);

      final screeningRepo = ScreeningRepository(AppDatabase.instance);
      expect(await screeningRepo.hasScreening(childId), isTrue);

      final latestScreening = await screeningRepo.getLatestForChild(childId);
      expect(latestScreening, isNotNull);
      expect(latestScreening!.toolName, 'sang_loc_50_cau_7_linh_vuc_v1');

      final responses = await screeningRepo.getResponses(latestScreening.id);
      expect(responses.length, 50);

      final domainScores = await screeningRepo.getDomainScores(latestScreening.id);
      expect(domainScores.length, 7);

      final historyLogRepo = HistoryLogRepository(AppDatabase.instance);
      final logs = await historyLogRepo.getForChild(childId);
      expect(logs.length, 1);
      expect(logs.first.eventType, 'sang_loc');
      // ignore: avoid_print
      print('PASS: Đã lưu trọn vẹn 50 responses và 7 domain scores vào SQLite');
    },
  );

  testWidgets(
    'Tạo hồ sơ → nhánh "Chưa muốn" sàng lọc → vào thẳng Trang chủ với đúng active child',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await pumpFrames(tester);

      await fillAndSaveCreateProfileForm(tester, 'Bé Chưa Sàng Lọc');

      expect(find.byType(ProfileDetailPage), findsNothing);
      expect(
        find.textContaining('Bạn có muốn thực hiện bài sàng lọc'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Chưa muốn'));
      await pumpFrames(tester);

      expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Bé Chưa Sàng Lọc'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: nhánh "Chưa muốn" — vào thẳng Trang chủ ngay, không tạo bản ghi screenings');

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isFalse);

      final db = await AppDatabase.instance.database;
      final childRows = await db.query('children');
      expect(childRows.length, 1);
      final childId = childRows.first['id'] as String;

      final activeChildId = await ActiveChildService().getActiveChildId();
      expect(activeChildId, childId);

      final screeningRepo = ScreeningRepository(AppDatabase.instance);
      expect(await screeningRepo.hasScreening(childId), isFalse);
    },
  );

  testWidgets(
    '"Xem hồ sơ" từ Dashboard vẫn mở đúng ProfileDetailPage, luồng sàng lọc từ đó không đổi',
    (tester) async {
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Xem Hồ Sơ',
        ageYears: 3,
      );
      await ActiveChildService().setActiveChildId(child.id);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await pumpFrames(tester);

      await tester.tap(find.text('Tài khoản'));
      await pumpFrames(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Đổi tài khoản'));
      await pumpFrames(tester);

      expect(find.byType(MultiChildDashboardPage), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await pumpFrames(tester);
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Xem hồ sơ'));
      await pumpFrames(tester);

      expect(find.byType(ProfileDetailPage), findsOneWidget);
      expect(find.text('Chưa sàng lọc'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Sàng lọc'));
      await pumpFrames(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Chưa muốn'));
      await pumpFrames(tester);

      expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: luồng sàng lọc gọi từ ProfileDetailPage (không phải onboarding) vẫn dẫn vào Bước 4 như cũ');
    },
  );
}
