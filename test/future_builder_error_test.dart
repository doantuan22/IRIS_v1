import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/features/child_profile/child_list_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mục 4.5 audit — xác nhận `FutureBuilder` ở trang chính hiện đúng trạng
/// thái lỗi (thông báo + nút "Thử lại") thay vì màn trắng/treo im lặng khi
/// truy vấn database thất bại. Dùng `ChildListPage` làm đại diện — cùng
/// pattern xử lý lỗi được áp dụng giống hệt (nhân bản có chủ đích, mỗi trang
/// độc lập theo đúng phong cách hiện có của codebase) cho
/// `MultiChildDashboardPage`, `HistoryPage`, `VideoListPage`.
Future<void> pumpFrames(WidgetTester tester, {int times = 30}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
    AppDatabase.resetForTest();
  });

  testWidgets(
      'ChildListPage: hiện rõ trạng thái lỗi khi query thất bại, nút "Thử lại" khôi phục đúng sau khi hết lỗi',
      (tester) async {
    // Mở rồi đóng database thật để lần query đầu tiên của trang thất bại
    // (giả lập lỗi truy vấn thật, không phải mock/suy đoán).
    final db = await AppDatabase.instance.database;
    await db.close();

    await tester.pumpWidget(const MaterialApp(home: ChildListPage()));
    await pumpFrames(tester);

    expect(find.textContaining('Không tải được danh sách hồ sơ'), findsOneWidget);
    final retryButton = find.widgetWithText(OutlinedButton, 'Thử lại');
    expect(retryButton, findsOneWidget);
    // ignore: avoid_print
    print('PASS: ChildListPage hiện rõ thông báo lỗi + nút "Thử lại" khi query database thất bại');

    // "Hết lỗi": reset để lần mở database tiếp theo tạo kết nối mới hợp lệ,
    // rồi bấm "Thử lại" — đúng hành vi FutureBuilder gọi lại repository.
    AppDatabase.resetForTest();
    AppDatabase.debugPathOverride = inMemoryDatabasePath;

    await tester.tap(retryButton);
    await pumpFrames(tester);

    expect(find.text('Chưa có hồ sơ trẻ nào. Bấm "+" để tạo hồ sơ mới.'), findsOneWidget);
    // ignore: avoid_print
    print('PASS: bấm "Thử lại" sau khi hết lỗi tải lại đúng dữ liệu, không còn kẹt ở trạng thái lỗi');
  });
}
