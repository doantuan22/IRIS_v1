import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/features/assessment/domain_hub_page.dart';
import 'package:iris_app/features/assessment/nine_domains/comparison_video/comparison_video_page.dart';
import 'package:iris_app/features/assessment/nine_domains/description/description_page.dart';
import 'package:iris_app/features/assessment/nine_domains/expert_input/expert_input_page.dart';
import 'package:iris_app/features/assessment/nine_domains/parent_input/parent_input_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pumpFrames(WidgetTester tester, {int times = 15}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await pumpFrames(tester, times: 3);
  await tester.tap(finder);
  await pumpFrames(tester);
}

NvidiaApiClient mockNvidiaClient() => NvidiaApiClient(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'embedding': [0.1, 0.2, 0.3], 'index': 0},
            ],
          }),
          200,
        );
      }),
    );

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
      'Test 1: Từ Hub, vào thẳng "So sánh" khi CHƯA có mô tả nào -> Mở thành công, không crash, không bị chặn',
      (tester) async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Test Hub', ageYears: 3);

    // Thêm dữ liệu so sánh mẫu
    await ExpertKnowledgeRepository(AppDatabase.instance).add(
      content: 'Biểu hiện so sánh ngôn ngữ thường gặp ở trẻ 3 tuổi',
      contentType: 'so_sanh',
      phanLoai: 'thuong_gap',
      linhVuc: 'ngon_ngu',
      doTuoiThangMin: 24,
      doTuoiThangMax: 48,
      embedding: [0.1, 0.2],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DomainHubPage(
          child: child,
          linhVuc: 'ngon_ngu',
          linhVucLabel: 'Ngôn ngữ',
          nvidiaApiClient: mockNvidiaClient(),
        ),
      ),
    );
    await pumpFrames(tester);

    // Xác nhận giao diện Hub hiển thị đầy đủ 4 thẻ
    expect(find.text('Ngôn ngữ — Bé Test Hub'), findsOneWidget);
    expect(find.text('Mô tả biểu hiện của trẻ'), findsOneWidget);
    expect(find.text('Quan trọng'), findsOneWidget);
    expect(find.text('Chưa có ghi nhận nào'), findsOneWidget);
    expect(find.text('So sánh với trẻ cùng độ tuổi'), findsOneWidget);
    expect(find.text('Chia sẻ từ phụ huynh'), findsOneWidget);
    expect(find.text('Thông tin từ bác sĩ'), findsOneWidget);

    // Bấm vào thẻ "So sánh với trẻ cùng độ tuổi" khi CHƯA từng mở "Mô tả"
    await tapVisible(tester, find.text('So sánh với trẻ cùng độ tuổi'));

    // Xác nhận đã vào màn ComparisonVideoPage thành công
    expect(find.byType(ComparisonVideoPage), findsOneWidget);
    expect(find.text('Ngôn ngữ — So sánh nhanh'), findsOneWidget);
    expect(find.text('Biểu hiện so sánh ngôn ngữ thường gặp ở trẻ 3 tuổi'), findsOneWidget);
    expect(find.text('Biểu hiện thường gặp'), findsOneWidget);

    // ignore: avoid_print
    print('PASS Test 1: Vào thẳng So sánh khi chưa có mô tả nào thành công, không bị chặn');
  });

  testWidgets(
      'Test 2: Vào từng phần trong 4 phần rồi bấm Back -> Quay đúng về Hub, Hub còn nguyên 4 thẻ',
      (tester) async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Test Back', ageYears: 4);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainHubPage(
          child: child,
          linhVuc: 'cam_xuc',
          linhVucLabel: 'Cảm xúc',
          nvidiaApiClient: mockNvidiaClient(),
        ),
      ),
    );
    await pumpFrames(tester);

    // 1. Vào Mô tả -> Back
    await tapVisible(tester, find.text('Mô tả biểu hiện của trẻ'));
    expect(find.byType(DescriptionPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);
    expect(find.byType(DomainHubPage), findsOneWidget);

    // 2. Vào So sánh -> Back
    await tapVisible(tester, find.text('So sánh với trẻ cùng độ tuổi'));
    expect(find.byType(ComparisonVideoPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);
    expect(find.byType(DomainHubPage), findsOneWidget);

    // 3. Vào Chia sẻ phụ huynh -> Back
    await tapVisible(tester, find.text('Chia sẻ từ phụ huynh'));
    expect(find.byType(ParentInputPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);
    expect(find.byType(DomainHubPage), findsOneWidget);

    // 4. Vào Thông tin từ bác sĩ -> Back
    await tapVisible(tester, find.text('Thông tin từ bác sĩ'));
    expect(find.byType(ExpertInputPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);
    expect(find.byType(DomainHubPage), findsOneWidget);

    // Xác nhận Hub vẫn nguyên vẹn 4 thẻ
    expect(find.text('Mô tả biểu hiện của trẻ'), findsOneWidget);
    expect(find.text('So sánh với trẻ cùng độ tuổi'), findsOneWidget);
    expect(find.text('Chia sẻ từ phụ huynh'), findsOneWidget);
    expect(find.text('Thông tin từ bác sĩ'), findsOneWidget);

    // ignore: avoid_print
    print('PASS Test 2: Vào từng phần và Back quay lại Hub hoàn toàn ổn định');
  });

  testWidgets(
      'Test 3: Thử thứ tự ngẫu nhiên (Bác sĩ -> Chia sẻ -> Mô tả & Lưu -> So sánh) -> Hoạt động trơn tru',
      (tester) async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Test Random Flow', ageYears: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainHubPage(
          child: child,
          linhVuc: 'nhan_thuc',
          linhVucLabel: 'Nhận thức',
          nvidiaApiClient: mockNvidiaClient(),
        ),
      ),
    );
    await pumpFrames(tester);

    // Bước 1: Vào Bác sĩ trước
    await tapVisible(tester, find.text('Thông tin từ bác sĩ'));
    expect(find.byType(ExpertInputPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);

    // Bước 2: Vào Chia sẻ từ phụ huynh
    await tapVisible(tester, find.text('Chia sẻ từ phụ huynh'));
    expect(find.byType(ParentInputPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);

    // Bước 3: Vào Mô tả biểu hiện -> Nhập và Lưu mô tả
    await tapVisible(tester, find.text('Mô tả biểu hiện của trẻ'));
    expect(find.byType(DescriptionPage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bé nhận biết được màu sắc cơ bản và hình khối');
    await pumpFrames(tester);

    await tapVisible(tester, find.text('Lưu mô tả'));

    // Xác nhận đã lưu trong database thật
    final repo = AssessmentRepository(AppDatabase.instance);
    final saved = await repo.getForChild(child.id, linhVuc: 'nhan_thuc');
    expect(saved.length, 1);
    expect(saved.first.content, 'Bé nhận biết được màu sắc cơ bản và hình khối');

    await tester.pageBack();
    await pumpFrames(tester);

    // Xác nhận Hub cập nhật trạng thái "Đã có 1 ghi nhận biểu hiện"
    expect(find.text('Đã có 1 ghi nhận biểu hiện'), findsOneWidget);

    // Bước 4: Vào So sánh với trẻ cùng độ tuổi
    await tapVisible(tester, find.text('So sánh với trẻ cùng độ tuổi'));
    expect(find.byType(ComparisonVideoPage), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester);

    expect(find.byType(DomainHubPage), findsOneWidget);

    // ignore: avoid_print
    print('PASS Test 3: Thứ tự ngẫu nhiên Bác sĩ -> Chia sẻ -> Mô tả (Lưu) -> So sánh thành công 100%');
  });

  testWidgets(
      'Test 4: Xác nhận nút "Lưu" CHỈ tồn tại ở màn Mô tả, KHÔNG tồn tại ở 3 màn tham khảo',
      (tester) async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Test Buttons', ageYears: 4);

    // 1. Kiểm tra DescriptionPage: CÓ nút "Lưu mô tả"
    await tester.pumpWidget(
      MaterialApp(
        home: DescriptionPage(
          child: child,
          linhVuc: 'quan_he_xa_hoi',
          linhVucLabel: 'Quan hệ xã hội',
          nvidiaApiClient: mockNvidiaClient(),
        ),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('Lưu mô tả'), findsOneWidget);

    // 2. Kiểm tra ComparisonVideoPage: KHÔNG CÓ bất kỳ nút Lưu nào
    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonVideoPage(
          child: child,
          linhVuc: 'quan_he_xa_hoi',
          linhVucLabel: 'Quan hệ xã hội',
        ),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('Lưu'), findsNothing);
    expect(find.text('Lưu mô tả'), findsNothing);
    expect(find.text('Lưu & tiếp tục'), findsNothing);
    expect(find.text('Tiếp theo'), findsNothing);

    // 3. Kiểm tra ParentInputPage: KHÔNG CÓ bất kỳ nút Lưu nào
    await tester.pumpWidget(
      MaterialApp(
        home: ParentInputPage(
          child: child,
          linhVuc: 'quan_he_xa_hoi',
          linhVucLabel: 'Quan hệ xã hội',
        ),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('Lưu'), findsNothing);
    expect(find.text('Lưu mô tả'), findsNothing);
    expect(find.text('Lưu & tiếp tục'), findsNothing);
    expect(find.text('Tiếp theo'), findsNothing);

    // 4. Kiểm tra ExpertInputPage: KHÔNG CÓ bất kỳ nút Lưu nào
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertInputPage(
          child: child,
          linhVuc: 'quan_he_xa_hoi',
          linhVucLabel: 'Quan hệ xã hội',
        ),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('Lưu'), findsNothing);
    expect(find.text('Lưu mô tả'), findsNothing);
    expect(find.text('Lưu & tiếp tục'), findsNothing);
    expect(find.text('Hoàn tất'), findsNothing);

    // ignore: avoid_print
    print('PASS Test 4: Nút Lưu CHỈ tồn tại ở màn Mô tả biểu hiện, không tồn tại ở 3 màn tham khảo');
  });
}
