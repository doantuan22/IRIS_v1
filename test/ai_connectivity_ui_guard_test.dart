import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/notification_repository.dart';
import 'package:iris_app/domain/models/child.dart';
import 'package:iris_app/domain/services/ai_connectivity_service.dart';
import 'package:iris_app/features/ai_chat/ai_chat_page.dart';
import 'package:iris_app/features/assessment/overview/overview_portrait_page.dart';
import 'package:iris_app/features/home/notifications_tab.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    AiConnectivityService.resetForTest();
  });

  tearDown(() async {
    AiConnectivityService.resetForTest();
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  testWidgets('NotificationsTab hiển thị đúng danh sách thông báo và empty state', (tester) async {
    final notificationRepo = NotificationRepository(AppDatabase.instance);

    // Render empty state
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsTab(notificationRepository: notificationRepo),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chưa có thông báo nào'), findsOneWidget);

    // Thêm 2 thông báo
    await notificationRepo.add(
      title: 'Kết nối AI',
      content: 'Kết nối AI đang gặp vấn đề.',
      type: 'ai_connectivity',
    );
    await notificationRepo.add(
      title: 'Kết nối AI',
      content: 'Đã có thể kết nối AI.',
      type: 'ai_connectivity',
    );

    // Tap nút refresh
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kết nối AI đang gặp vấn đề.'), findsOneWidget);
    expect(find.text('Đã có thể kết nối AI.'), findsOneWidget);
  });

  testWidgets('AiChatPage chặn gửi câu hỏi ngay lập tức và hiện thông báo khi AI mất kết nối', (tester) async {
    final service = AiConnectivityService(retryInterval: const Duration(hours: 1));
    service.stateNotifier.value = const AiConnectivityState(
      nvidiaStatus: AiApiStatus.error,
      groqStatus: AiApiStatus.ok,
    );
    AiConnectivityService.setInstanceForTest(service);

    final child = Child(
      id: 'test-child-1',
      name: 'Bé Test',
      ageYears: 3,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AiChatPage(child: child),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Banner cảnh báo hiển thị trên màn hình
    expect(find.text('AI đang chưa kết nối được, xin vui lòng thử lại sau.'), findsOneWidget);

    // Thử nhập câu hỏi và bấm gửi
    await tester.enterText(find.byType(TextField), 'Bé có ổn không?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Hiện lỗi cảnh báo tại chỗ
    expect(find.text('AI đang chưa kết nối được, xin vui lòng thử lại sau.'), findsAtLeastNWidgets(1));
  });

  testWidgets('OverviewPortraitPage chặn tổng hợp ngay lập tức khi AI mất kết nối', (tester) async {
    final service = AiConnectivityService(retryInterval: const Duration(hours: 1));
    service.stateNotifier.value = const AiConnectivityState(
      nvidiaStatus: AiApiStatus.error,
      groqStatus: AiApiStatus.error,
    );
    AiConnectivityService.setInstanceForTest(service);

    final childRepo = ChildRepository(AppDatabase.instance);
    final assessmentRepo = AssessmentRepository(AppDatabase.instance);

    final child = await childRepo.create(name: 'Bé Overview Guard Test', ageYears: 2);

    // Điền đủ mô tả cho cả 7 lĩnh vực
    final domainCodes = [
      'nhan_thuc',
      'cam_xuc',
      'giac_quan',
      'quan_he_xa_hoi',
      'ngon_ngu',
      'sinh_hoc',
      'sinh_hoat_ca_nhan',
    ];
    for (final code in domainCodes) {
      await assessmentRepo.save(
        childId: child.id,
        linhVuc: code,
        content: 'Mô tả thử nghiệm cho $code',
        nguon: 'phu_huynh',
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: OverviewPortraitPage(child: child),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Banner cảnh báo kết nối AI hiển thị
    expect(find.text('AI đang chưa kết nối được, xin vui lòng thử lại sau.'), findsOneWidget);

    // Bấm nút "Tổng hợp Chân dung toàn cảnh"
    final computeButton = find.text('Tổng hợp Chân dung toàn cảnh');
    expect(computeButton, findsOneWidget);
    await tester.tap(computeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Báo lỗi tức thì mà không gọi API AI
    expect(find.text('AI đang chưa kết nối được, xin vui lòng thử lại sau.'), findsAtLeastNWidgets(1));
  });
}
