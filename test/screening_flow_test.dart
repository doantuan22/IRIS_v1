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

/// Bơm 1 số frame cố định thay vì `pumpAndSettle()` — trang danh sách/chi
/// tiết dùng `CircularProgressIndicator` mặc định (animation lặp vô hạn)
/// trong lúc chờ FutureBuilder, khiến `pumpAndSettle()` không bao giờ nhận
/// ra là đã "settle" và timeout, dù Future load dữ liệu đã xong từ lâu.
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

  // Form dài hơn viewport mặc định của widget test — cuộn dần bằng
  // `scrollUntilVisible` (tự build thêm item khi cuộn) thay vì `ensureVisible`
  // (yêu cầu widget đã tồn tại trong cây sẵn). `.first` vì mỗi `TextFormField`
  // cũng tự có 1 `Scrollable` nội bộ (cuộn text trong ô nhập) — Scrollable
  // đầu tiên theo thứ tự duyệt cây luôn là của `ListView` bọc ngoài form.
  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'Lưu hồ sơ'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await pumpFrames(tester, times: 5);
  await tester.tap(find.widgetWithText(FilledButton, 'Lưu hồ sơ'));
  await pumpFrames(tester);
}

/// Trả lời hết 6 câu hỏi mock bằng "Không" (bộ B — trẻ 3 tuổi = 36 tháng)
/// rồi bấm "Hoàn thành", đưa tới `ScreeningResultPage`.
Future<void> answerQuestionnaireAndFinish(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    final noButton = find.byKey(ValueKey('answer_no_$i'));
    await tester.scrollUntilVisible(
      noButton,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();
    await tester.tap(noButton);
    await tester.pump();
  }

  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'Hoàn thành'),
    200,
    scrollable: find.byType(Scrollable),
  );
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Hoàn thành'));
  await pumpFrames(tester);
}

/// Kiểm chứng luồng điều hướng sau khi tạo hồ sơ trẻ mới (thay màn chi tiết
/// hồ sơ trung gian bằng: hỏi sàng lọc → [sàng lọc + kết quả] → Trang chủ),
/// bằng widget test lái UI thật qua Navigator, không cần build APK.
void main() {
  // sqflite_common_ffi thực hiện I/O thật (qua Isolate) — binding mặc định
  // của testWidgets dùng đồng hồ giả (FakeAsync), khiến pump() không nhường
  // đủ thời gian thực cho I/O hoàn tất (Future treo mãi ở ConnectionState.
  // waiting). Dùng LiveTestWidgetsFlutterBinding để pump() chờ thời gian
  // thực, khớp với I/O thật của sqflite_common_ffi.
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
    'Tạo hồ sơ → nhánh "Có" sàng lọc → xem kết quả → vào thẳng Trang chủ với đúng active child',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await pumpFrames(tester);

      // Chưa có hồ sơ nào — HomePage tự điều hướng vào CreateProfilePage.
      await fillAndSaveCreateProfileForm(tester, 'Bé Có Sàng Lọc');

      // Không còn dừng ở màn chi tiết hồ sơ (trùng HomePage) hay màn tóm tắt
      // — vào thẳng màn hỏi sàng lọc (Bước 3).
      expect(find.byType(ProfileDetailPage), findsNothing);
      expect(find.text('Tạo hồ sơ thành công!'), findsNothing);
      expect(
        find.textContaining('Bạn có muốn thực hiện bài sàng lọc'),
        findsOneWidget,
      );
      expect(find.text('Có'), findsOneWidget);
      expect(find.text('Chưa muốn'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: sau khi tạo hồ sơ, vào thẳng màn hỏi sàng lọc — không còn màn trung gian');

      await tester.tap(find.widgetWithText(FilledButton, 'Có'));
      await pumpFrames(tester);

      expect(
        find.text('Công cụ sẽ sử dụng: Bộ B (31 tháng trở lên)'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Bắt đầu'));
      await pumpFrames(tester);

      await answerQuestionnaireAndFinish(tester);

      expect(
        find.text('Đây là kết quả sàng lọc, không phải kết luận chẩn đoán.'),
        findsOneWidget,
      );
      expect(find.text('Điểm: 0/6'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: hoàn thành sàng lọc, hiện đúng màn kết quả (vòng tròn điểm số)');

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Tiếp tục'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFrames(tester, times: 5);
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
      await pumpFrames(tester);

      // Nhánh "Có" phải dẫn thẳng tới HomePage — không còn dừng ở Bước 4
      // (Tổng hợp hồ sơ & đề xuất) như luồng gọi từ ProfileDetailPage.
      expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Bé Có Sàng Lọc'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: nhánh "Có" — sau khi xem kết quả, vào thẳng Trang chủ');

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isFalse);
      // ignore: avoid_print
      print('PASS: không back được về màn tạo hồ sơ/sàng lọc từ Trang chủ (canPop == false)');

      final db = await AppDatabase.instance.database;
      final childRows = await db.query('children');
      expect(childRows.length, 1);
      final childId = childRows.first['id'] as String;

      final activeChildId = await ActiveChildService().getActiveChildId();
      expect(activeChildId, childId);

      final screeningRepo = ScreeningRepository(AppDatabase.instance);
      expect(await screeningRepo.hasScreening(childId), isTrue);

      final historyLogRepo = HistoryLogRepository(AppDatabase.instance);
      final logs = await historyLogRepo.getForChild(childId);
      expect(logs.length, 1);
      expect(logs.first.eventType, 'sang_loc');
      // ignore: avoid_print
      print('PASS: trẻ vừa tạo là active child đúng, đã lưu kết quả sàng lọc + history_logs');
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

      // Không tạo bản ghi screenings, không dừng ở Bước 4 — vào thẳng
      // Trang chủ ngay.
      expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Bé Chưa Sàng Lọc'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: nhánh "Chưa muốn" — vào thẳng Trang chủ ngay, không tạo bản ghi screenings');

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isFalse);
      // ignore: avoid_print
      print('PASS: không back được về màn tạo hồ sơ/sàng lọc từ Trang chủ (canPop == false)');

      final db = await AppDatabase.instance.database;
      final childRows = await db.query('children');
      expect(childRows.length, 1);
      final childId = childRows.first['id'] as String;

      final activeChildId = await ActiveChildService().getActiveChildId();
      expect(activeChildId, childId);

      final screeningRepo = ScreeningRepository(AppDatabase.instance);
      expect(await screeningRepo.hasScreening(childId), isFalse);
      // ignore: avoid_print
      print('PASS: trẻ vừa tạo là active child đúng, chưa có bản ghi sàng lọc nào');
    },
  );

  testWidgets(
    '"Xem hồ sơ" từ Dashboard vẫn mở đúng ProfileDetailPage, luồng sàng lọc từ đó không đổi',
    (tester) async {
      // Hồ sơ tạo sẵn qua repository (không qua form) để kiểm tra đúng lối
      // vào "Xem hồ sơ" đang được audit là còn dùng hợp lệ — không phải lối
      // vào ngay-sau-khi-tạo-hồ-sơ đang được nối lại ở 2 test trên.
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Xem Hồ Sơ',
        ageYears: 3,
      );
      await ActiveChildService().setActiveChildId(child.id);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await pumpFrames(tester);

      // Trang chủ → tab "Tài khoản" → "Đổi tài khoản" → Dashboard.
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
      // ignore: avoid_print
      print('PASS: "Xem hồ sơ" từ Dashboard vẫn mở đúng ProfileDetailPage (audit: giữ nguyên, không xoá)');

      await tester.tap(find.widgetWithText(FilledButton, 'Sàng lọc'));
      await pumpFrames(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Chưa muốn'));
      await pumpFrames(tester);

      // Luồng cũ (không phải onboarding) vẫn dẫn vào Bước 4 như trước —
      // không bị ảnh hưởng bởi việc nối lại luồng sau-khi-tạo-hồ-sơ.
      expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: luồng sàng lọc gọi từ ProfileDetailPage (không phải onboarding) vẫn dẫn vào Bước 4 như cũ');
    },
  );
}
