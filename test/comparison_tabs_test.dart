import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/domain/models/child.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:iris_app/domain/services/video_manifest_service.dart';
import 'package:iris_app/features/assessment/nine_domains/comparison_video/comparison_detail_page.dart';
import 'package:iris_app/features/assessment/nine_domains/comparison_video/comparison_video_page.dart';
import 'package:iris_app/features/assessment/nine_domains/comparison_video/video_illustration_player_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeVideoManifestBundle extends AssetBundle {
  /// `null` mô phỏng asset CHƯA TỒN TẠI (VD manifest chưa được tạo cho dải
  /// tuổi đó) — `loadString` sẽ ném lỗi giống hệt Flutter thật khi thiếu asset.
  final String? jsonString;
  _FakeVideoManifestBundle(this.jsonString);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == VideoManifestService.assetPath && jsonString != null) return jsonString!;
    throw FlutterError('Unable to load asset: "$key".');
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

/// Test màn "So sánh nhanh" ([ComparisonVideoPage]) và "So sánh chi tiết"
/// ([ComparisonDetailPage]) đúng cấu trúc 2 TAB ("Trẻ bình thường" /
/// "Trẻ tự kỷ") — thay cho bảng "Tiêu chí | Thường gặp | Cần quan sát" cũ
/// vốn dùng sai giá trị `phan_loai` ('thuong_gap'/'can_quan_sat' không khớp
/// dữ liệu thật 'binh_thuong'/'roi_loan_pho_tu_ky') nên cột "Thường gặp"
/// luôn trống dù có dữ liệu.
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
  late ExpertKnowledgeRepository expertRepo;
  late Child child17m;

  setUp(() async {
    // VideoManifestService cache là static toàn cục — clear trước MỖI test
    // để test dùng bundle giả không bị "ăn" cache thật đã nạp từ 1 test
    // trước đó (bất kỳ lần render ComparisonVideoPage/Detail nào cũng gọi
    // loadVideoPaths(), kể cả test không liên quan tới video).
    VideoManifestService.clearCache();
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    appDatabase = AppDatabase.instance;
    expertRepo = ExpertKnowledgeRepository(appDatabase);

    // Trẻ 17 tháng — khớp dải 15-23 đã ingest.
    final dob17MonthsAgo = DateTime.now().subtract(const Duration(days: 17 * 30));
    child17m = Child(
      id: 'child-17m',
      name: 'Bé 17 tháng',
      dob: dob17MonthsAgo.toIso8601String(),
      createdAt: DateTime.now(),
    );

    // 3 entry binh_thuong + 2 entry roi_loan_pho_tu_ky cho nhan_thuc, dải 15-23.
    for (var i = 1; i <= 3; i++) {
      await expertRepo.add(
        content: 'Biểu hiện bình thường $i — nhận thức',
        contentType: 'so_sanh',
        phanLoai: 'binh_thuong',
        linhVuc: 'nhan_thuc',
        doTuoiThangMin: 15,
        doTuoiThangMax: 23,
        embedding: [0.1, 0.2],
      );
    }
    for (var i = 1; i <= 2; i++) {
      await expertRepo.add(
        content: 'Dấu hiệu cần quan sát $i — nhận thức',
        contentType: 'so_sanh',
        phanLoai: 'roi_loan_pho_tu_ky',
        linhVuc: 'nhan_thuc',
        doTuoiThangMin: 15,
        doTuoiThangMax: 23,
        embedding: [0.1, 0.2],
      );
    }
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  testWidgets(
    'ComparisonVideoPage: tab "Trẻ bình thường" hiện đúng 3 entry binh_thuong, khớp DB thật',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComparisonVideoPage(
            child: child17m,
            linhVuc: 'nhan_thuc',
            linhVucLabel: 'Nhận thức',
          ),
        ),
      );
      await pumpFrames(tester);

      // Đối chiếu với dữ liệu thật trong DB, không chỉ tin UI.
      final expectedBinhThuong = await expertRepo.query(
        linhVuc: 'nhan_thuc',
        ageInMonths: 17,
        contentType: 'so_sanh',
        phanLoai: 'binh_thuong',
      );
      expect(expectedBinhThuong.length, 3);

      expect(find.text('Trẻ bình thường'), findsOneWidget);
      expect(find.text('Trẻ tự kỷ'), findsOneWidget);
      // Tab mặc định (index 0) = "Trẻ bình thường" — đúng 3 dòng hiện ra.
      for (final chunk in expectedBinhThuong) {
        expect(find.text(chunk.content), findsOneWidget);
      }
      // Nội dung của tab "Trẻ tự kỷ" KHÔNG được lẫn vào tab đang hiện.
      expect(find.text('Dấu hiệu cần quan sát 1 — nhận thức'), findsNothing);

      // ignore: avoid_print
      print('PASS: tab "Trẻ bình thường" hiện đúng 3 entry binh_thuong khớp DB thật');
    },
  );

  testWidgets(
    'ComparisonVideoPage: chuyển qua lại 2 tab nhiều lần -> dữ liệu không lẫn lộn',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComparisonVideoPage(
            child: child17m,
            linhVuc: 'nhan_thuc',
            linhVucLabel: 'Nhận thức',
          ),
        ),
      );
      await pumpFrames(tester);

      final expectedRoiLoan = await expertRepo.query(
        linhVuc: 'nhan_thuc',
        ageInMonths: 17,
        contentType: 'so_sanh',
        phanLoai: 'roi_loan_pho_tu_ky',
      );
      expect(expectedRoiLoan.length, 2);

      for (var round = 0; round < 3; round++) {
        // Sang tab "Trẻ tự kỷ"
        await tester.tap(find.text('Trẻ tự kỷ'));
        await pumpFrames(tester);
        for (final chunk in expectedRoiLoan) {
          expect(find.text(chunk.content), findsOneWidget);
        }
        expect(find.text('Biểu hiện bình thường 1 — nhận thức'), findsNothing);

        // Quay lại tab "Trẻ bình thường"
        await tester.tap(find.text('Trẻ bình thường'));
        await pumpFrames(tester);
        expect(find.text('Biểu hiện bình thường 1 — nhận thức'), findsOneWidget);
        expect(find.text('Dấu hiệu cần quan sát 1 — nhận thức'), findsNothing);
      }

      // ignore: avoid_print
      print('PASS: chuyển qua lại 2 tab 3 vòng liên tiếp, dữ liệu không bao giờ lẫn lộn');
    },
  );

  testWidgets(
    'ComparisonVideoPage: trẻ ngoài mọi dải tuổi đã ingest -> cả 2 tab hiện đúng thông báo trống riêng, không bảng trống',
    (tester) async {
      final dob10YearsAgo = DateTime.now().subtract(const Duration(days: 365 * 10));
      final childOutOfRange = Child(
        id: 'child-out-of-range',
        name: 'Bé 10 tuổi',
        dob: dob10YearsAgo.toIso8601String(),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComparisonVideoPage(
            child: childOutOfRange,
            linhVuc: 'nhan_thuc',
            linhVucLabel: 'Nhận thức',
          ),
        ),
      );
      await pumpFrames(tester);

      // Tab mặc định "Trẻ bình thường" -> thông báo trống riêng, không phải bảng có cột trống.
      expect(
        find.text('Chưa có dữ liệu so sánh cho trẻ bình thường ở lĩnh vực này, độ tuổi hiện tại.'),
        findsOneWidget,
      );
      expect(find.byType(Table), findsNothing);
      expect(find.text('Xem chi tiết so sánh'), findsNothing);

      await tester.tap(find.text('Trẻ tự kỷ'));
      await pumpFrames(tester);
      expect(
        find.text('Chưa có dữ liệu so sánh cho trẻ tự kỷ ở lĩnh vực này, độ tuổi hiện tại.'),
        findsOneWidget,
      );
      expect(find.byType(Table), findsNothing);

      // ignore: avoid_print
      print('PASS: trẻ ngoài mọi dải tuổi -> cả 2 tab hiện đúng thông báo trống riêng, không lỗi');
    },
  );

  testWidgets(
    'ComparisonDetailPage: tự truy vấn lại theo linhVuc, đúng 2 tab, khớp DB thật, không còn bảng "Tiêu chí | Thường gặp"',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComparisonDetailPage(
            child: child17m,
            linhVuc: 'nhan_thuc',
            linhVucLabel: 'Nhận thức',
          ),
        ),
      );
      await pumpFrames(tester);

      expect(find.text('Nhận thức — Chi tiết so sánh'), findsOneWidget);
      expect(find.text('Trẻ bình thường'), findsOneWidget);
      expect(find.text('Trẻ tự kỷ'), findsOneWidget);
      // Không còn bảng cũ 3 cột.
      expect(find.text('Tiêu chí'), findsNothing);
      expect(find.text('Thường gặp'), findsNothing);
      expect(find.text('Cần quan sát'), findsNothing);
      expect(find.byType(Table), findsNothing);

      // Tab mặc định hiện đúng 3 entry binh_thuong.
      expect(find.text('Biểu hiện bình thường 1 — nhận thức'), findsOneWidget);
      expect(find.text('Biểu hiện bình thường 2 — nhận thức'), findsOneWidget);
      expect(find.text('Biểu hiện bình thường 3 — nhận thức'), findsOneWidget);
      expect(find.text('Dấu hiệu cần quan sát 1 — nhận thức'), findsNothing);

      await tester.tap(find.text('Trẻ tự kỷ'));
      await pumpFrames(tester);
      expect(find.text('Dấu hiệu cần quan sát 1 — nhận thức'), findsOneWidget);
      expect(find.text('Dấu hiệu cần quan sát 2 — nhận thức'), findsOneWidget);
      expect(find.text('Biểu hiện bình thường 1 — nhận thức'), findsNothing);

      // ignore: avoid_print
      print('PASS: ComparisonDetailPage tự query theo tab, đúng dữ liệu, không còn bảng ghép cặp cũ');
    },
  );

  group('Nút "Xem video minh hoạ" — chỉ hiện đúng entry có trong video_manifest.json', () {
    tearDown(() {
      VideoManifestService.clearCache();
    });

    testWidgets(
      'chỉ entry có id trong manifest mới hiện nút, entry khác hoàn toàn không có nút (không mờ/disable)',
      (tester) async {
        // 3 entry cùng linh_vuc/phan_loai/dải tuổi, id CỤ THỂ (insert thẳng
        // để kiểm soát chính xác id — expertRepo.add() luôn tự sinh uuid,
        // không set được id theo ý muốn).
        final db = await appDatabase.database;
        Future<void> insertEntry(String id, String content) => db.insert('expert_knowledge_chunks', {
              'id': id,
              'content': content,
              'content_type': 'so_sanh',
              'phan_loai': 'binh_thuong',
              'nhom_tre': null,
              'boi_canh': null,
              'linh_vuc': 'cam_xuc',
              'do_tuoi_thang_min': 15,
              'do_tuoi_thang_max': 23,
              'nguon_tai_lieu': null,
              'embedding': encodeEmbedding([0.1, 0.2]),
            });

        await insertEntry('so_sanh_cam_xuc_binh_thuong_15_23_101', 'Entry CÓ video minh hoạ');
        await insertEntry('so_sanh_cam_xuc_binh_thuong_15_23_102', 'Entry KHÔNG có video minh hoạ');
        await insertEntry('so_sanh_cam_xuc_binh_thuong_15_23_103', 'Entry khác cũng KHÔNG có video');

        // Manifest giả — CHỈ đúng 1/3 id có video, khớp đúng số lượng thật
        // trong file JSON (mô phỏng đúng tình huống "phần lớn id không có video").
        await VideoManifestService.loadVideoPaths(
          bundle: _FakeVideoManifestBundle(
            jsonEncode({
              'videos': {
                'so_sanh_cam_xuc_binh_thuong_15_23_101': {
                  'file_path': 'assets/videos/cam_xuc/so_sanh_cam_xuc_binh_thuong_15_23_101.mp4',
                  'ten_file_goc': 'clip.mp4',
                  'ngay_them': '2026-08-16T10:00:00',
                },
              },
            }),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ComparisonVideoPage(child: child17m, linhVuc: 'cam_xuc', linhVucLabel: 'Cảm xúc'),
          ),
        );
        await pumpFrames(tester);

        // Đúng 3 entry đều hiện nội dung (không bị ẩn).
        expect(find.text('Entry CÓ video minh hoạ'), findsOneWidget);
        expect(find.text('Entry KHÔNG có video minh hoạ'), findsOneWidget);
        expect(find.text('Entry khác cũng KHÔNG có video'), findsOneWidget);

        // ĐÚNG 1 nút "Xem video minh hoạ" — khớp chính xác số lượng entry có
        // video trong manifest giả (1/3), không nhiều hơn, không ít hơn.
        expect(find.text('Xem video minh hoạ'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

        // ignore: avoid_print
        print('PASS: đúng 1/3 entry hiện nút video, khớp chính xác số lượng id có trong manifest');
      },
    );

    testWidgets(
      'bấm nút "Xem video minh hoạ" mở đúng trang phát video, đúng asset path của entry đó',
      (tester) async {
        final db = await appDatabase.database;
        await db.insert('expert_knowledge_chunks', {
          'id': 'so_sanh_giac_quan_binh_thuong_15_23_201',
          'content': 'Entry duy nhất có video',
          'content_type': 'so_sanh',
          'phan_loai': 'binh_thuong',
          'nhom_tre': null,
          'boi_canh': null,
          'linh_vuc': 'giac_quan',
          'do_tuoi_thang_min': 15,
          'do_tuoi_thang_max': 23,
          'nguon_tai_lieu': null,
          'embedding': encodeEmbedding([0.1, 0.2]),
        });

        await VideoManifestService.loadVideoPaths(
          bundle: _FakeVideoManifestBundle(
            jsonEncode({
              'videos': {
                'so_sanh_giac_quan_binh_thuong_15_23_201': {
                  'file_path': 'assets/videos/giac_quan/so_sanh_giac_quan_binh_thuong_15_23_201.mp4',
                  'ten_file_goc': 'clip.mp4',
                  'ngay_them': '2026-08-16T10:00:00',
                },
              },
            }),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ComparisonVideoPage(child: child17m, linhVuc: 'giac_quan', linhVucLabel: 'Giác quan'),
          ),
        );
        await pumpFrames(tester);

        expect(find.text('Xem video minh hoạ'), findsOneWidget);
        await tester.tap(find.text('Xem video minh hoạ'));
        await pumpFrames(tester);

        expect(find.byType(VideoIllustrationPlayerPage), findsOneWidget);
        final page = tester.widget<VideoIllustrationPlayerPage>(find.byType(VideoIllustrationPlayerPage));
        expect(
          page.assetPath,
          'assets/videos/giac_quan/so_sanh_giac_quan_binh_thuong_15_23_201.mp4',
          reason: 'phải mở đúng file video của entry đã bấm, không lẫn sang entry khác',
        );

        // ignore: avoid_print
        print('PASS: bấm nút mở đúng VideoIllustrationPlayerPage với đúng assetPath của entry đó');
      },
    );

    testWidgets(
      'video_manifest.json chưa tồn tại (dải tuổi chưa gắn video nào) -> toàn bộ entry không hiện nút nào, không lỗi',
      (tester) async {
        final db = await appDatabase.database;
        await db.insert('expert_knowledge_chunks', {
          'id': 'so_sanh_ngon_ngu_binh_thuong_24_47_301',
          'content': 'Entry ở dải tuổi chưa gắn video nào',
          'content_type': 'so_sanh',
          'phan_loai': 'binh_thuong',
          'nhom_tre': null,
          'boi_canh': null,
          'linh_vuc': 'ngon_ngu',
          'do_tuoi_thang_min': 15,
          'do_tuoi_thang_max': 23,
          'nguon_tai_lieu': null,
          'embedding': encodeEmbedding([0.1, 0.2]),
        });

        // Bundle mô phỏng asset chưa tồn tại -> loadString ném lỗi -> loadVideoPaths trả rỗng.
        await VideoManifestService.loadVideoPaths(bundle: _FakeVideoManifestBundle(null));

        await tester.pumpWidget(
          MaterialApp(
            home: ComparisonVideoPage(child: child17m, linhVuc: 'ngon_ngu', linhVucLabel: 'Ngôn ngữ'),
          ),
        );
        await pumpFrames(tester);

        expect(find.text('Entry ở dải tuổi chưa gắn video nào'), findsOneWidget);
        expect(find.text('Xem video minh hoạ'), findsNothing);
        expect(find.byIcon(Icons.play_circle_outline), findsNothing);

        // ignore: avoid_print
        print('PASS: manifest rỗng/chưa có -> không entry nào hiện nút video, không lỗi, không placeholder');
      },
    );
  });
}
