import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/domain/models/child.dart';
import 'package:iris_app/features/child_profile/create_profile/create_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  late ChildRepository childRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    appDatabase = AppDatabase.instance;
    childRepository = ChildRepository(appDatabase);
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  testWidgets('Tạo hồ sơ với số tháng tuổi (18 tháng) -> Lưu đúng dob, ageYears = null, childAgeInMonths() = 18', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateProfilePage(),
      ),
    );
    await pumpFrames(tester);

    // Nhập tên trẻ
    await tester.enterText(find.byType(TextFormField).first, 'Bé Thảo (18 tháng)');

    // Chọn 'Theo số tháng tuổi'
    await tester.tap(find.text('Theo số tháng tuổi'));
    await pumpFrames(tester);

    // Xác nhận ô nhập số tháng tuổi và preview xuất hiện
    expect(find.text('Số tháng tuổi *'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '18');
    await pumpFrames(tester);

    // Xác nhận dòng preview tuổi hiển thị đúng
    expect(find.text('≈ 1 tuổi 6 tháng'), findsOneWidget);

    // Cuộn và bấm 'Lưu hồ sơ'
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Lưu hồ sơ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, times: 5);
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu hồ sơ'));
    await pumpFrames(tester, times: 20);

    // Đọc lại từ SQLite DB thật
    final children = await childRepository.getAll();
    expect(children.length, 1);

    final savedChild = children.first;
    expect(savedChild.name, 'Bé Thảo (18 tháng)');
    expect(savedChild.dob, isNotNull);
    expect(savedChild.ageYears, isNull); // Hồ sơ mới KHÔNG lưu age_years

    // Kiểm chứng hàm tính tuổi và format label chuẩn xác
    final months = childAgeInMonths(savedChild);
    expect(months, 18);
    expect(formatAgeLabel(savedChild), '1 tuổi 6 tháng');
  });

  testWidgets('Validate số tháng tuổi để trống -> Báo lỗi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateProfilePage(),
      ),
    );
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Bé Test Validate');
    await tester.tap(find.text('Theo số tháng tuổi'));
    await pumpFrames(tester);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Lưu hồ sơ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu hồ sơ'));
    await pumpFrames(tester, times: 10);
    expect(find.text('Vui lòng nhập số tháng tuổi'), findsOneWidget);
  });

  testWidgets('Validate số tháng tuổi ngoài khoảng 1-120 -> Báo lỗi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateProfilePage(),
      ),
    );
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Bé Test Validate');
    await tester.tap(find.text('Theo số tháng tuổi'));
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextFormField).at(1), '150');
    await pumpFrames(tester);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Lưu hồ sơ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu hồ sơ'));
    await pumpFrames(tester, times: 10);
    expect(find.text('Số tháng tuổi không hợp lệ (1-120 tháng)'), findsOneWidget);
  });

  testWidgets('Hồ sơ cũ (chỉ có age_years = 2, dob = null) vẫn hoạt động 100% bình thường', (tester) async {
    final legacyChild = Child(
      id: 'legacy-child-2y',
      name: 'Bé Hồ Sơ Cũ',
      ageYears: 2,
      dob: null,
      createdAt: DateTime.now(),
    );

    expect(childAgeInMonths(legacyChild), 24);
    expect(formatAgeLabel(legacyChild), '2 tuổi');
  });
}
