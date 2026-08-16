import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:iris_app/domain/services/active_child_service.dart';
import 'package:iris_app/features/home/home_page.dart';
import 'package:iris_app/features/screening/screening_history_list_page.dart';
import 'package:iris_app/features/screening/screening_result_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pumpFrames(WidgetTester tester, {int times = 10}) async {
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
    'Lịch sử sàng lọc: Cách ly 100% dữ liệu giữa các trẻ (Trẻ A vs Trẻ B)',
    (tester) async {
      final childRepo = ChildRepository(AppDatabase.instance);
      final screeningRepo = ScreeningRepository(AppDatabase.instance);
      final activeChildService = ActiveChildService();

      // 1. Tạo 2 hồ sơ trẻ
      final childA = await childRepo.create(name: 'Bé An (Trẻ A)', ageYears: 3);
      final childB = await childRepo.create(name: 'Bé Bình (Trẻ B)', ageYears: 4);

      // 2. Tạo bài sàng lọc cho Trẻ A (20% - Mức 1)
      await screeningRepo.saveScreeningSession(
        childId: childA.id,
        toolName: 'sang_loc_50_cau_7_linh_vuc_v1',
        score: '20%',
        resultSummary: 'Mức 1 - Ít biểu hiện',
        performedAt: DateTime(2026, 8, 1, 9, 30),
        responses: [
          (cauHoiId: 'sl50_q01', linhVuc: 'nhan_thuc', giaTri: '0'),
        ],
        domainScores: [
          (
            linhVuc: 'nhan_thuc',
            soCauThietKe: 7,
            soCauHopLe: 7,
            diemTho: 2,
            diemPhanTram: 20.0,
          ),
        ],
      );

      // 3. Tạo bài sàng lọc cho Trẻ B (80% - Mức 3)
      await screeningRepo.saveScreeningSession(
        childId: childB.id,
        toolName: 'sang_loc_50_cau_7_linh_vuc_v1',
        score: '80%',
        resultSummary: 'Mức 3 - Nhiều biểu hiện khó khăn',
        performedAt: DateTime(2026, 8, 15, 14, 00),
        responses: [
          (cauHoiId: 'sl50_q01', linhVuc: 'nhan_thuc', giaTri: '2'),
        ],
        domainScores: [
          (
            linhVuc: 'nhan_thuc',
            soCauThietKe: 7,
            soCauHopLe: 7,
            diemTho: 11,
            diemPhanTram: 80.0,
          ),
        ],
      );

      // 4. Set active child = Trẻ A -> Mở ScreeningHistoryListPage
      await activeChildService.setActiveChildId(childA.id);

      await tester.pumpWidget(
        MaterialApp(home: ScreeningHistoryListPage(key: UniqueKey())),
      );
      await pumpFrames(tester);

      // Xác nhận CHỈ thấy dữ liệu của Trẻ A
      expect(find.text('Lịch sử sàng lọc — Bé An (Trẻ A)'), findsOneWidget);
      expect(find.text('Mức 1 - Ít biểu hiện'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      // Tuyệt đối KHÔNG thấy dữ liệu của Trẻ B
      expect(find.text('Mức 3 - Nhiều biểu hiện khó khăn'), findsNothing);
      expect(find.text('80%'), findsNothing);
      expect(find.textContaining('Bé Bình'), findsNothing);
      // ignore: avoid_print
      print('PASS: Khi active child là Trẻ A, chỉ hiển thị đúng lịch sử của Trẻ A');

      // 5. Đổi active child = Trẻ B -> Dựng lại màn hình
      await activeChildService.setActiveChildId(childB.id);

      await tester.pumpWidget(
        MaterialApp(home: ScreeningHistoryListPage(key: UniqueKey())),
      );
      await pumpFrames(tester);

      // Xác nhận CHỈ thấy dữ liệu của Trẻ B
      expect(find.text('Lịch sử sàng lọc — Bé Bình (Trẻ B)'), findsOneWidget);
      expect(find.text('Mức 3 - Nhiều biểu hiện khó khăn'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);

      // Tuyệt đối KHÔNG thấy dữ liệu của Trẻ A
      expect(find.text('Mức 1 - Ít biểu hiện'), findsNothing);
      expect(find.text('20%'), findsNothing);
      expect(find.textContaining('Bé An'), findsNothing);
      // ignore: avoid_print
      print('PASS: Khi đổi sang Trẻ B, chỉ hiển thị đúng lịch sử của Trẻ B');
    },
  );

  testWidgets(
    'Mở chi tiết từ lịch sử sàng lọc: Tự query DB theo screening_id, đối chiếu dữ liệu chính xác',
    (tester) async {
      final childRepo = ChildRepository(AppDatabase.instance);
      final screeningRepo = ScreeningRepository(AppDatabase.instance);
      final activeChildService = ActiveChildService();

      final child = await childRepo.create(name: 'Bé Chi Tiết', ageYears: 3);
      await activeChildService.setActiveChildId(child.id);

      await screeningRepo.saveScreeningSession(
        childId: child.id,
        toolName: 'sang_loc_50_cau_7_linh_vuc_v1',
        score: '65%',
        resultSummary: 'Mức 2 - Có biểu hiện cần theo dõi',
        performedAt: DateTime(2026, 8, 10, 10, 0),
        responses: [
          (cauHoiId: 'sl50_q01', linhVuc: 'nhan_thuc', giaTri: '1'),
        ],
        domainScores: [
          (
            linhVuc: 'nhan_thuc',
            soCauThietKe: 7,
            soCauHopLe: 7,
            diemTho: 9,
            diemPhanTram: 64.28,
          ),
          (
            linhVuc: 'cam_xuc',
            soCauThietKe: 6,
            soCauHopLe: 0,
            diemTho: 0,
            diemPhanTram: null,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(home: ScreeningHistoryListPage()),
      );
      await pumpFrames(tester);

      // Tap vào thẻ sàng lọc
      await tester.tap(find.text('Mức 2 - Có biểu hiện cần theo dõi'));
      await pumpFrames(tester);

      // Màn hình kết quả sàng lọc mở ra
      expect(find.byType(ScreeningResultPage), findsOneWidget);
      expect(find.text('Kết quả sàng lọc cho Bé Chi Tiết'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Mức 2 - Có biểu hiện cần theo dõi'), findsOneWidget);
      expect(find.text('Nhận thức'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('Cảm xúc'), findsOneWidget);
      expect(find.text('Chưa đủ dữ liệu cho lĩnh vực này (toàn bộ câu trả lời N/A)'), findsOneWidget);
      expect(
        find.textContaining('Đây là bản sàng lọc/thử nghiệm để rà soát mức độ biểu hiện'),
        findsOneWidget,
      );

      // Bấm Tiếp tục -> Quay về trang lịch sử
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Tiếp tục'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFrames(tester, times: 3);
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
      await pumpFrames(tester);

      expect(find.byType(ScreeningHistoryListPage), findsOneWidget);
      // ignore: avoid_print
      print('PASS: Mở chi tiết từ lịch sử đọc chuẩn xác 100% từ SQLite và quay lại được');
    },
  );

  testWidgets(
    'Trạng thái rỗng: Trẻ chưa từng làm sàng lọc hiển thị thông báo trống chuẩn',
    (tester) async {
      final childRepo = ChildRepository(AppDatabase.instance);
      final activeChildService = ActiveChildService();

      final child = await childRepo.create(name: 'Bé Chưa Sàng Lọc', ageYears: 2);
      await activeChildService.setActiveChildId(child.id);

      await tester.pumpWidget(
        const MaterialApp(home: ScreeningHistoryListPage()),
      );
      await pumpFrames(tester);

      expect(find.text('Lịch sử sàng lọc — Bé Chưa Sàng Lọc'), findsOneWidget);
      expect(
        find.text('Chưa có lịch sử sàng lọc cho Bé Chưa Sàng Lọc'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Trẻ chưa thực hiện bài sàng lọc nào'),
        findsOneWidget,
      );
      // ignore: avoid_print
      print('PASS: Trạng thái rỗng hiển thị chuẩn xác kèm tên trẻ');
    },
  );

  testWidgets(
    'Tab Tài khoản: Nút "Lịch sử sàng lọc" mở đúng ScreeningHistoryListPage của active child',
    (tester) async {
      final childRepo = ChildRepository(AppDatabase.instance);
      final activeChildService = ActiveChildService();

      final child = await childRepo.create(name: 'Bé Tab Tài Khoản', ageYears: 3);
      await activeChildService.setActiveChildId(child.id);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await pumpFrames(tester);

      // Vào tab Tài khoản
      await tester.tap(find.text('Tài khoản'));
      await pumpFrames(tester);

      expect(find.widgetWithText(OutlinedButton, 'Lịch sử sàng lọc'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Lịch sử sàng lọc'));
      await pumpFrames(tester);

      expect(find.byType(ScreeningHistoryListPage), findsOneWidget);
      expect(find.text('Lịch sử sàng lọc — Bé Tab Tài Khoản'), findsOneWidget);
      // ignore: avoid_print
      print('PASS: Nút Lịch sử sàng lọc trong tab Tài khoản hoạt động chính xác');
    },
  );
}
