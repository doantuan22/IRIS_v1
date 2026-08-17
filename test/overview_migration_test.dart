import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/domain_overview_label_repository.dart';
import 'package:iris_app/data/repositories/overview_summary_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema version 4 → 5 (thêm bảng MỚI `domain_overview_labels`
/// + `overview_summaries` cho "Chân dung toàn cảnh") — mô phỏng đúng tình
/// huống rủi ro nhất: máy đã có dữ liệu thật ở schema CŨ (version 4, chưa có
/// 2 bảng mới), rồi mở app sau khi cập nhật. Không được mất dữ liệu cũ hoặc
/// crash khi mở lại, và 2 bảng mới phải dùng được ngay sau migration.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 4 → 5: giữ nguyên dữ liệu children cũ, tạo được '
      'domain_overview_labels + overview_summaries mới, đọc/ghi đúng sau migration', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_overview_migration_test_');
    final dbPath = '${tempDir.path}/iris_v4.db';

    try {
      // Bước 1 — tạo 1 database THẬT ở đúng schema version 4 (chưa có 2 bảng
      // mới), có sẵn 1 hồ sơ trẻ — mô phỏng máy người dùng đã dùng app từ
      // trước khi cập nhật.
      final oldDb = await openDatabase(
        dbPath,
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE children (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              dob TEXT,
              age_years INTEGER,
              gender TEXT,
              nguoi_danh_gia TEXT,
              vai_tro TEXT,
              status TEXT DEFAULT 'active',
              created_at TEXT NOT NULL
            );
          ''');
        },
      );
      await oldDb.insert('children', {
        'id': 'child-old-1',
        'name': 'Bé Cũ',
        'age_years': 4,
        'status': 'active',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      expect(await oldDb.query('children'), hasLength(1));
      await oldDb.close();

      // Bước 2 — mở lại ĐÚNG bằng AppDatabase thật của app (version 5 +
      // onUpgrade), trỏ vào cùng file.
      AppDatabase.debugPathOverride = dbPath;

      final db = await AppDatabase.instance.database;
      final children = await db.query('children');
      expect(children, hasLength(1));
      expect(children.single['name'], 'Bé Cũ');

      // Bước 3 — 2 bảng mới phải tồn tại và dùng được ngay, không lỗi "no
      // such table", thông qua đúng repository thật của app.
      final labelRepo = DomainOverviewLabelRepository(AppDatabase.instance);
      final summaryRepo = OverviewSummaryRepository(AppDatabase.instance);

      final label = await labelRepo.save(
        childId: 'child-old-1',
        linhVuc: 'ngon_ngu',
        nhan: 'thuong_gap',
        lyDoNganGon: 'Phù hợp dữ liệu tham khảo',
      );
      expect(label.childId, 'child-old-1');

      final latest = await labelRepo.getLatestForChild('child-old-1');
      expect(latest['ngon_ngu']?.nhan, 'thuong_gap');

      final summary = await summaryRepo.save(
        childId: 'child-old-1',
        tier: 'thuong_gap',
        soLinhVucCanTheoDoi: 0,
        soLinhVucThieuDuLieu: 0,
      );
      expect(summary.childId, 'child-old-1');

      final latestSummary = await summaryRepo.getLatestForChild('child-old-1');
      expect(latestSummary?.id, summary.id);

      // Bước 4 — chạy lại migration lần 2 (mở app lần nữa) không được lỗi vì
      // CREATE TABLE chạy trùng — đúng cách sqflite chỉ chạy onUpgrade 1 lần
      // dựa theo version đã lưu, không phải test lại logic sqflite, chỉ xác
      // nhận version cuối cùng đã được nâng cấp.
      expect(db.getVersion(), completion(10));

      // ignore: avoid_print
      print(
        'PASS: migration version 4 → 5 giữ nguyên dữ liệu children cũ, '
        'tạo được domain_overview_labels + overview_summaries mới, đọc/ghi đúng qua repository thật',
      );
    } finally {
      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
      await tempDir.delete(recursive: true);
    }
  });
}
