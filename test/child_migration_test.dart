import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema `children` version 1 → 2 (thêm cột
/// `nguoi_danh_gia`/`vai_tro`) — mô phỏng đúng tình huống rủi ro nhất:
/// người dùng đã cài app từ trước, đã có hồ sơ trẻ lưu trên máy theo schema
/// CŨ (không có 2 cột mới), rồi mở app sau khi cập nhật lên bản có 2 cột
/// mới. Không được để mất dữ liệu hồ sơ cũ hoặc crash khi mở lại.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 1 → 2: giữ nguyên dữ liệu hồ sơ trẻ cũ, 2 cột mới NULL cho hồ sơ cũ, '
      'hoạt động đúng cho hồ sơ tạo sau migration', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_migration_test_');
    final dbPath = '${tempDir.path}/iris_v1.db';

    try {
      // Bước 1 — tạo 1 database THẬT ở đúng schema version 1 (trước khi có
      // 2 cột mới), có sẵn 1 hồ sơ trẻ — mô phỏng máy người dùng trước khi
      // cập nhật app.
      final oldDb = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE children (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              dob TEXT,
              age_years INTEGER,
              gender TEXT,
              status TEXT DEFAULT 'active',
              created_at TEXT NOT NULL
            );
          ''');
        },
      );
      await oldDb.insert('children', {
        'id': 'old-child-1',
        'name': 'Bé Hồ Sơ Cũ',
        'age_years': 5,
        'gender': 'nam',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      expect(await oldDb.query('children'), hasLength(1));
      await oldDb.close();

      // Bước 2 — mở lại ĐÚNG bằng AppDatabase thật của app (version 2 +
      // onUpgrade), trỏ vào cùng file — mô phỏng người dùng mở app sau khi
      // cập nhật, không phải tạo database mới.
      AppDatabase.debugPathOverride = dbPath;
      final childRepo = ChildRepository(AppDatabase.instance);

      final oldChild = await childRepo.getById('old-child-1');
      expect(oldChild, isNotNull);
      expect(oldChild!.name, 'Bé Hồ Sơ Cũ');
      expect(oldChild.ageYears, 5);
      expect(oldChild.gender, 'nam');
      expect(oldChild.nguoiDanhGia, isNull);
      expect(oldChild.vaiTro, isNull);

      // Bước 3 — hồ sơ tạo MỚI sau migration phải dùng đúng 2 cột mới,
      // không lỗi vì cột đã tồn tại (không bị ALTER TABLE trùng lần 2).
      final newChild = await childRepo.create(
        name: 'Bé Hồ Sơ Mới',
        ageYears: 3,
        nguoiDanhGia: 'Chị Lan',
        vaiTro: 'Giáo viên',
      );
      final readBack = await childRepo.getById(newChild.id);
      expect(readBack!.nguoiDanhGia, 'Chị Lan');
      expect(readBack.vaiTro, 'Giáo viên');

      // Cả hồ sơ cũ lẫn mới cùng tồn tại — migration không xoá nhầm dữ liệu.
      expect(await childRepo.getAll(), hasLength(2));

      // ignore: avoid_print
      print(
        'PASS: migration version 1 → 2 giữ nguyên dữ liệu hồ sơ cũ (2 cột mới = NULL), '
        'không crash, hồ sơ mới dùng đúng 2 cột mới',
      );
    } finally {
      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
      await tempDir.delete(recursive: true);
    }
  });
}
