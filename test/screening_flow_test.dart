import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/history_log_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:iris_app/features/child_profile/child_list_page.dart';
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

/// Kiểm chứng full luồng Giai đoạn 2 bằng widget test (lái UI thật qua
/// Navigator, không cần build APK) — thay thế chạy tay trên emulator vì
/// build Android bị chặn bởi lỗi tương thích toolchain CameraX/Gradle
/// không liên quan tới code app (xem SETUP_REPORT.md mục Giai đoạn 2).
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
    // `CreateProfilePage` giờ gọi `ActiveChildService` (shared_preferences)
    // ngay sau khi lưu hồ sơ — cần mock giá trị ban đầu vì widget test không
    // có platform channel thật cho shared_preferences.
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  testWidgets('Tạo hồ sơ → Chưa muốn sàng lọc → Có sàng lọc → badge cập nhật đúng',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChildListPage()));
    await pumpFrames(tester);

    expect(find.text('Chưa có hồ sơ trẻ nào. Bấm "+" để tạo hồ sơ mới.'), findsOneWidget);

    // --- Nhiệm vụ 1: tạo hồ sơ trẻ mới (dùng số tuổi thay vì date picker) ---
    await tester.tap(find.byIcon(Icons.add));
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Bé Test Flow');
    await tester.tap(find.text('Theo số tuổi (năm)'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextFormField).at(1), '3');

    // Form giờ dài hơn viewport mặc định của widget test (thêm 2 trường
    // "Người đánh giá"/"Vai trò" + nút chọn giới tính dạng segmented) — nút
    // "Lưu hồ sơ" có thể chưa được build sẵn (ngoài cache extent mặc định
    // của ListView), nên cuộn dần bằng `scrollUntilVisible` (tự build thêm
    // item khi cuộn) thay vì `ensureVisible` (yêu cầu widget đã tồn tại
    // trong cây sẵn). `.first` vì mỗi `TextFormField` cũng tự có 1
    // `Scrollable` nội bộ (cuộn text trong ô nhập) — Scrollable đầu tiên
    // theo thứ tự duyệt cây luôn là của `ListView` bọc ngoài form.
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Lưu hồ sơ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, times: 5);
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu hồ sơ'));
    await pumpFrames(tester);

    // Sau khi lưu, giờ hiện màn tóm tắt (Bước 2) thay vì quay thẳng về danh
    // sách — "Bé Test Flow" có thể tồn tại đồng thời ở cả màn tóm tắt lẫn
    // ChildListPage bên dưới (đã reload qua `result: true`), nên dùng
    // findsWidgets thay vì findsOneWidget cho tên trẻ.
    expect(find.text('Tạo hồ sơ thành công!'), findsOneWidget);
    expect(find.text('Bé Test Flow'), findsWidgets);
    // ignore: avoid_print
    print('PASS: tạo hồ sơ trẻ "Bé Test Flow" thành công, hiện màn tóm tắt hồ sơ');

    // --- Bấm "Xem hồ sơ" vào chi tiết hồ sơ ---
    await tester.tap(find.widgetWithText(FilledButton, 'Xem hồ sơ'));
    await pumpFrames(tester);

    expect(find.text('Chưa sàng lọc'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: hồ sơ mới hiển thị badge "Chưa sàng lọc" đúng');

    // --- Nhiệm vụ 2, nhánh "Chưa muốn": không tạo bản ghi screenings,
    // vẫn dẫn tiếp vào Bước 4 (tổng hợp & đề xuất) trước khi quay lại hồ sơ ---
    await tester.tap(find.widgetWithText(FilledButton, 'Sàng lọc'));
    await pumpFrames(tester);

    expect(find.text('Có'), findsOneWidget);
    expect(find.text('Chưa muốn'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Chưa muốn'));
    await pumpFrames(tester);

    expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsOneWidget);
    expect(find.text('Chưa sàng lọc'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: nhánh "Chưa muốn" dẫn vào Bước 4 (Tổng hợp & đề xuất), không tạo bản ghi screenings');

    // Quay lại hồ sơ (Bước 4 -> Intro -> ProfileDetail) — badge vẫn "Chưa sàng lọc".
    await tester.pageBack();
    await pumpFrames(tester);
    await tester.pageBack();
    await pumpFrames(tester);

    expect(find.text('Chưa sàng lọc'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: quay lại hồ sơ sau nhánh "Chưa muốn", badge vẫn "Chưa sàng lọc"');

    // --- Nhiệm vụ 2, nhánh "Có": trả lời bộ câu hỏi mock, lưu kết quả ---
    // "Bé Test Flow" 3 tuổi (36 tháng) → thuộc dải tuổi Bộ B (31 tháng trở lên).
    await tester.tap(find.widgetWithText(FilledButton, 'Sàng lọc'));
    await pumpFrames(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Có'));
    await pumpFrames(tester);

    // Bước 3 giờ có thêm màn xác nhận công cụ sàng lọc trước khi vào câu hỏi.
    expect(find.text('Công cụ sẽ sử dụng: Bộ B (31 tháng trở lên)'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: trẻ 36 tháng tuổi được chọn đúng Bộ B (31 tháng trở lên) ở màn xác nhận công cụ');

    await tester.tap(find.widgetWithText(FilledButton, 'Bắt đầu'));
    await pumpFrames(tester);

    expect(find.text('Công cụ sàng lọc: Bộ B (31 tháng trở lên)'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: bấm "Bắt đầu" vào đúng bảng câu hỏi Bộ B (31 tháng trở lên)');

    // ListView.builder chỉ dựng sẵn item trong viewport — phải scroll từng
    // câu vào tầm nhìn trước khi tap (không thể tap thẳng item ngoài màn hình).
    for (var i = 0; i < 6; i++) {
      final noButton = find.byKey(ValueKey('answer_no_$i'));
      await tester.scrollUntilVisible(noButton, 200, scrollable: find.byType(Scrollable));
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

    expect(find.text('Đây là kết quả sàng lọc, không phải kết luận chẩn đoán.'), findsOneWidget);
    expect(find.text('Điểm: 0/6'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: hoàn thành bộ câu hỏi mock (6 câu "Không"), kết quả "0/6" + dòng chữ disclaimer hiển thị đúng');

    // --- Bước 4: tổng hợp & đề xuất, đọc đúng dữ liệu thật sau khi sàng lọc ---
    // Màn kết quả giờ cuộn được (thêm vòng tròn điểm số) — cuộn tới nút
    // trước khi bấm, cùng cách xử lý như màn tạo hồ sơ ở trên.
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Tiếp tục'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, times: 5);
    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await pumpFrames(tester);

    expect(find.text('Tổng hợp hồ sơ & đề xuất'), findsOneWidget);
    expect(find.text('Đã sàng lọc'), findsOneWidget);
    expect(find.text('Kết quả sàng lọc gần nhất: 0/6'), findsOneWidget);
    // Bước 4 giờ chia thành nhiều khối (Card) — cuộn tới khối cuối để xác
    // nhận cả nội dung lẫn nút đều có mặt.
    await tester.scrollUntilVisible(
      find.text('Đã có mô tả cho 0/7 lĩnh vực'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, times: 5);
    expect(find.text('Đã có mô tả cho 0/7 lĩnh vực'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Bắt đầu đánh giá'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, times: 5);
    expect(find.widgetWithText(FilledButton, 'Bắt đầu đánh giá'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: Bước 4 hiển thị đúng dữ liệu thật sau khi sàng lọc (đã sàng lọc, điểm 0/6, 0/7 lĩnh vực)');

    // Quay lại hồ sơ (Bước 4 -> ToolConfirm -> Intro -> ProfileDetail, thêm 1
    // bước so với nhánh "Chưa muốn" vì giờ có thêm màn xác nhận công cụ) —
    // badge cập nhật đúng.
    await tester.pageBack();
    await pumpFrames(tester);
    await tester.pageBack();
    await pumpFrames(tester);
    await tester.pageBack();
    await pumpFrames(tester);

    expect(find.text('Đã sàng lọc'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: sau khi sàng lọc "Có", quay lại hồ sơ, badge cập nhật đúng thành "Đã sàng lọc"');

    // --- Xác nhận dữ liệu lưu đúng trực tiếp qua repository (raw data) ---
    final db = await AppDatabase.instance.database;
    final childRows = await db.query('children');
    expect(childRows.length, 1); // chỉ 1 hồ sơ được tạo trong suốt test này
    final childId = childRows.first['id'] as String;

    final screeningRepo = ScreeningRepository(AppDatabase.instance);
    final hasScreening = await screeningRepo.hasScreening(childId);
    expect(hasScreening, true);

    final screenings = await screeningRepo.getForChild(childId);
    expect(screenings.length, 1);
    expect(screenings.first.score, '0/6');
    expect(screenings.first.toolName, contains('mock'));
    // ignore: avoid_print
    print('PASS: ScreeningRepository.hasScreening() xác nhận đã có bản ghi screenings cho trẻ');

    // --- Giai đoạn 6: xác nhận đã ghi history_logs (event_type='sang_loc') ---
    final historyLogRepo = HistoryLogRepository(AppDatabase.instance);
    final logs = await historyLogRepo.getForChild(childId);
    expect(logs.length, 1);
    expect(logs.first.eventType, 'sang_loc');
    expect(logs.first.description, contains('0/6'));
    // ignore: avoid_print
    print('PASS: hoàn thành sàng lọc ghi đúng 1 dòng history_logs (event_type=sang_loc)');
  });
}
