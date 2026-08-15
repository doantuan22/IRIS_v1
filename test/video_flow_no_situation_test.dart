import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/video_repository.dart';
import 'package:iris_app/domain/models/child.dart';
import 'package:iris_app/domain/services/active_child_service.dart';
import 'package:iris_app/features/home/home_page.dart';
import 'package:iris_app/features/video_recording/video_detail_page.dart';
import 'package:iris_app/features/video_recording/video_list_page.dart';
import 'package:iris_app/features/video_recording/video_preparation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pumpFrames(WidgetTester tester, {int times = 20}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await pumpFrames(tester, times: 5);
  await tester.tap(finder);
  await pumpFrames(tester, times: 10);
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  group('Video Recording Flow Without Situation Selection', () {
    testWidgets('Test 1: Lối vào từ HomePage đi thẳng vào VideoPreparationPage (Chuẩn bị quay), không qua màn chọn tình huống', (tester) async {
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Test Video',
        ageYears: 3,
      );
      await ActiveChildService().setActiveChildId(child.id);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await pumpFrames(tester, times: 30);

      // Tìm nút "Quay video quan sát"
      final videoBtn = find.text('Quay video quan sát');
      expect(videoBtn, findsOneWidget);

      await tapVisible(tester, videoBtn);

      // Xác nhận mở màn Chuẩn bị quay (VideoPreparationPage)
      expect(find.byType(VideoPreparationPage), findsOneWidget);
      expect(find.text('Chuẩn bị quay video'), findsOneWidget);
      expect(find.text('Bắt đầu quay'), findsOneWidget);
      // Xác nhận KHÔNG có bất kỳ chữ "Tình huống:" nào trên màn chuẩn bị
      expect(find.textContaining('Tình huống:'), findsNothing);
      expect(find.textContaining('Chọn tình huống'), findsNothing);

      // ignore: avoid_print
      print('PASS Test 1: Lối vào từ HomePage đi thẳng vào Chuẩn bị quay video 100%');
    });

    testWidgets('Test 2: VideoPreparationPage hiển thị đầy đủ các tips và nút Bắt đầu quay', (tester) async {
      final child = Child(
        id: 'child-123',
        name: 'Bé Minh',
        ageYears: 3,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreparationPage(child: child),
        ),
      );
      await pumpFrames(tester, times: 10);

      expect(find.text('Chuẩn bị quay video'), findsOneWidget);
      expect(find.textContaining('Bé Minh'), findsOneWidget);
      expect(find.text('Chọn môi trường yên tĩnh, hạn chế tiếng ồn xung quanh.'), findsOneWidget);
      expect(find.text('Đảm bảo ánh sáng tốt, tránh ngược sáng.'), findsOneWidget);
      expect(find.text('Bắt đầu quay'), findsOneWidget);
      expect(find.textContaining('Tình huống:'), findsNothing);

      // ignore: avoid_print
      print('PASS Test 2: VideoPreparationPage hiển thị chuẩn xác không có tình huống');
    });

    testWidgets('Test 3: VideoListPage hiển thị đúng video mới (situation = null) và video cũ (situation != null)', (tester) async {
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé An Video',
        ageYears: 3,
      );

      final videoRepo = VideoRepository(AppDatabase.instance);

      // 1. Tạo video cũ có situation
      await videoRepo.save(
        childId: child.id,
        filePath: '/storage/video_old.mp4',
        situation: 'Trẻ chơi cùng người khác',
        status: 'reviewed',
      );

      // 2. Tạo video mới KHÔNG CÓ situation (null)
      await videoRepo.save(
        childId: child.id,
        filePath: '/storage/video_new.mp4',
        situation: null,
        status: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoListPage(child: child),
        ),
      );
      await pumpFrames(tester, times: 20);

      // Video cũ: Hiện tên tình huống
      expect(find.text('Trẻ chơi cùng người khác'), findsOneWidget);
      expect(find.textContaining('Đã có nhận xét'), findsOneWidget);

      // Video mới: Hiện "Video ngày d/m/y", KHÔNG hiện null hay "(không rõ tình huống)"
      expect(find.text('(không rõ tình huống)'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(find.textContaining('Video ngày'), findsOneWidget);
      expect(find.textContaining('Đang chờ chuyên gia'), findsOneWidget);

      // Nút FloatingActionButton mở VideoPreparationPage
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tapVisible(tester, fab);
      expect(find.byType(VideoPreparationPage), findsOneWidget);

      // ignore: avoid_print
      print('PASS Test 3: VideoListPage xử lý situation null hoàn hảo, không có chữ null thừa');
    });

    testWidgets('Test 4: VideoDetailPage ẩn hoàn toàn dòng tình huống khi situation = null', (tester) async {
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Chi Video',
        ageYears: 3,
      );

      final videoRepo = VideoRepository(AppDatabase.instance);
      final video = await videoRepo.save(
        childId: child.id,
        filePath: '/storage/video_no_situation.mp4',
        situation: null,
        status: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoDetailPage(video: video),
        ),
      );
      await pumpFrames(tester, times: 20);

      // AppBar title mặc định khi không có situation
      expect(find.text('Chi tiết video'), findsOneWidget);
      // KHÔNG có dòng "Tình huống: ..."
      expect(find.textContaining('Tình huống:'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(find.textContaining('Đang chờ chuyên gia'), findsOneWidget);

      // ignore: avoid_print
      print('PASS Test 4: VideoDetailPage ẩn hoàn toàn trường tình huống khi null');
    });
  });
}
