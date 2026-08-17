// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/features/expert_connect/expert_connect_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Fake platform để kiểm tra `launchUrl` được gọi đúng URL mà KHÔNG thực sự
/// mở trình duyệt (test không có platform channel thật).
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;
  PreferredLaunchMode? lastMode;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastMode = options.mode;
    return true;
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
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  testWidgets(
      'Test 1: Trang Kết nối chuyên gia/trung tâm hiển thị đúng thông tin '
      'THẬT của Trung tâm Tường Minh, không còn danh sách minh hoạ cũ',
      (tester) async {
    final child = await ChildRepository(
      AppDatabase.instance,
    ).create(name: 'Bé Test Expert Connect', ageYears: 3);

    final fakePlatform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;

    await tester.pumpWidget(
      MaterialApp(home: ExpertConnectPage(child: child)),
    );
    await tester.pumpAndSettle();

    // Tên đầy đủ + tên gọi thường của trung tâm thật.
    expect(
      find.textContaining(
        'Trung Tâm Hỗ Trợ Phát Triển Giáo Dục Hòa Nhập Tường Minh',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Trung tâm Giáo dục Tường Minh'), findsOneWidget);

    // Đủ 3 địa chỉ cơ sở.
    expect(
      find.textContaining('Số 37, đường 2, Khu đô thị Vạn Phúc'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Số 449/41, đường Trường Chinh'),
      findsOneWidget,
    );
    expect(find.textContaining('Số 25, đường 44, P. Tân Phong'), findsOneWidget);

    // Số điện thoại + email thật.
    expect(
      find.textContaining('0919 795 574 – 0827 377 607 – 0942 211 000'),
      findsOneWidget,
    );
    expect(
      find.textContaining('trungtamtuongminhthuduc@gmail.com'),
      findsOneWidget,
    );

    // Nút mở website.
    expect(find.text('Truy cập website'), findsOneWidget);

    // KHÔNG còn danh sách minh hoạ cũ.
    expect(find.textContaining('Trung tâm Can thiệp sớm Ánh Dương'), findsNothing);
    expect(find.textContaining('danh sách minh hoạ'), findsNothing);

    // Disclaimer "không phải chẩn đoán" PHẢI xuất hiện (trước đây thiếu).
    // Cuộn xuống hết ListView vì Sliver chỉ build phần trong cacheExtent.
    await tester.dragUntilVisible(
      find.textContaining('không phải chỉ định hay chẩn đoán y khoa'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.textContaining('không phải chỉ định hay chẩn đoán y khoa'), findsOneWidget);

    print('PASS Test 1: Trang hiển thị đúng thông tin thật Trung tâm Tường Minh, có disclaimer, hết danh sách minh hoạ');
  });

  testWidgets(
      'Test 2: Bấm "Truy cập website" mở đúng URL thật bằng externalApplication, không nhúng webview',
      (tester) async {
    final child = await ChildRepository(
      AppDatabase.instance,
    ).create(name: 'Bé Test Website', ageYears: 4);

    final fakePlatform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;

    await tester.pumpWidget(
      MaterialApp(home: ExpertConnectPage(child: child)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Truy cập website'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Truy cập website'));
    await tester.pumpAndSettle();

    expect(fakePlatform.lastLaunchedUrl, 'https://tuongminhcenter.com.vn/');
    expect(fakePlatform.lastMode, PreferredLaunchMode.externalApplication);

    print('PASS Test 2: Bấm nút mở đúng https://tuongminhcenter.com.vn/ bằng externalApplication');
  });
}
