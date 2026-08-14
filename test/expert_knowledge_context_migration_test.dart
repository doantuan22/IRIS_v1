import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema `expert_knowledge_chunks` version 3 → 4 (thêm cột
/// `nhom_tre`/`boi_canh`) — cùng kỹ thuật đã dùng ở `expert_knowledge_migration_test.dart`
/// (mục 16, cột `phan_loai`) và `child_migration_test.dart` (mục 15): mô
/// phỏng đúng tình huống rủi ro nhất — máy đã có sẵn dữ liệu tham khảo
/// ingest từ trước (schema CŨ, không có `nhom_tre`/`boi_canh`), rồi mở app
/// sau khi cập nhật lên bản có 2 cột mới. Không được để mất dữ liệu tham
/// khảo đã có hoặc crash khi mở lại.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 3 → 4: giữ nguyên dữ liệu expert_knowledge_chunks cũ, cột nhom_tre/boi_canh '
      'NULL cho dòng cũ, hoạt động đúng cho dòng ingest sau migration', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_expert_context_migration_test_');
    final dbPath = '${tempDir.path}/iris_v3.db';

    try {
      // Bước 1 — tạo 1 database THẬT ở đúng schema version 3 (đã có
      // phan_loai nhưng CHƯA có nhom_tre/boi_canh), có sẵn 1 chunk
      // "chia_se_phu_huynh" — mô phỏng máy người dùng đã ingest dữ liệu
      // trước khi cập nhật app.
      final oldDb = await openDatabase(
        dbPath,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE expert_knowledge_chunks (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              content_type TEXT NOT NULL,
              phan_loai TEXT,
              linh_vuc TEXT,
              do_tuoi_thang_min INTEGER,
              do_tuoi_thang_max INTEGER,
              nguon_tai_lieu TEXT,
              embedding BLOB NOT NULL
            );
          ''');
        },
      );
      final oldEmbedding = encodeEmbedding([0.1, 0.2, 0.3]);
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'old-chunk-1',
        'content': 'Chia sẻ phụ huynh cũ, chưa có nhom_tre/boi_canh',
        'content_type': 'chia_se_phu_huynh',
        'linh_vuc': 'quan_he_xa_hoi',
        'do_tuoi_thang_min': 48,
        'do_tuoi_thang_max': 71,
        'nguon_tai_lieu': 'Mẹ bé cũ',
        'embedding': oldEmbedding,
      });
      expect(await oldDb.query('expert_knowledge_chunks'), hasLength(1));
      await oldDb.close();

      // Bước 2 — mở lại ĐÚNG bằng AppDatabase thật của app (version 4 +
      // onUpgrade), trỏ vào cùng file — mô phỏng người dùng mở app sau khi
      // cập nhật, không phải tạo database mới.
      AppDatabase.debugPathOverride = dbPath;
      final expertRepo = ExpertKnowledgeRepository(AppDatabase.instance);

      final all = await expertRepo.getAll();
      expect(all, hasLength(1));
      final oldChunk = all.single;
      expect(oldChunk.id, 'old-chunk-1');
      expect(oldChunk.content, 'Chia sẻ phụ huynh cũ, chưa có nhom_tre/boi_canh');
      expect(oldChunk.nguonTaiLieu, 'Mẹ bé cũ');
      expect(oldChunk.nhomTre, isNull);
      expect(oldChunk.boiCanh, isNull);
      expect(oldChunk.embedding.length, 3);

      // Bước 3 — chunk ingest MỚI sau migration phải dùng đúng 2 cột mới,
      // không lỗi vì cột đã tồn tại (không bị ALTER TABLE trùng lần 2).
      final newChunk = await expertRepo.add(
        content: 'Chia sẻ phụ huynh mới, đã có nhom_tre/boi_canh',
        contentType: 'chia_se_phu_huynh',
        nhomTre: 'asd',
        boiCanh: 'o_truong',
        linhVuc: 'quan_he_xa_hoi',
        doTuoiThangMin: 48,
        doTuoiThangMax: 71,
        embedding: [0.4, 0.5],
      );
      final queried = await expertRepo.query(
        linhVuc: 'quan_he_xa_hoi',
        ageInMonths: 60,
        contentType: 'chia_se_phu_huynh',
      );
      expect(queried, hasLength(2));
      final readBack = queried.firstWhere((c) => c.id == newChunk.id);
      expect(readBack.nhomTre, 'asd');
      expect(readBack.boiCanh, 'o_truong');

      // ignore: avoid_print
      print(
        'PASS: migration version 3 → 4 giữ nguyên dữ liệu expert_knowledge_chunks cũ '
        '(nhom_tre/boi_canh = NULL), không crash, chunk mới dùng đúng 2 cột mới',
      );
    } finally {
      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
      await tempDir.delete(recursive: true);
    }
  });
}
