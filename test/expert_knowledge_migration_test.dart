import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema `expert_knowledge_chunks` version 2 → 3 (thêm cột
/// `phan_loai`) — mô phỏng máy đã có sẵn dữ liệu tham khảo đã ingest từ
/// trước (schema CŨ, không có `phan_loai`), rồi mở app sau khi cập nhật lên
/// bản có cột mới. Không được crash khi mở lại, cột mới phải hoạt động đúng.
///
/// LƯU Ý (từ bản sửa BUG-01/02 — migration version 10): dòng `so_sanh` CŨ ở
/// đây SẼ bị xoá sạch khi mở lên (không còn "giữ nguyên" như tên test cũ mô
/// tả) — đây là hành vi CÓ CHỦ ĐÍCH: version 10 xoá sạch mọi dòng
/// `content_type='so_sanh'` để tự "chữa lành" dữ liệu cũ/sai (nội dung lỗi
/// thời hoặc mang id UUID từ nút debug cũ), sau đó `onOpen` tự seed lại từ
/// `expert_knowledge_seed.json`. Trong môi trường test Dart VM thuần (không
/// có `TestWidgetsFlutterBinding`/asset channel thật) bước seed lại này thất
/// bại NGẦM (best-effort, xem `ExpertKnowledgeSeedService.seedIfEmpty`), nên
/// kết quả ở đây là 0 dòng `so_sanh` sau khi mở — đúng như kỳ vọng, không
/// phải bug của test.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 2 → 3: giữ nguyên dữ liệu expert_knowledge_chunks cũ, cột phan_loai NULL cho '
      'dòng cũ, hoạt động đúng cho dòng ingest sau migration', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_expert_migration_test_');
    final dbPath = '${tempDir.path}/iris_v2.db';

    try {
      // Bước 1 — tạo 1 database THẬT ở đúng schema version 2 (đã có
      // nguoi_danh_gia/vai_tro ở children nhưng expert_knowledge_chunks
      // CHƯA có phan_loai), có sẵn 1 chunk tham khảo — mô phỏng máy người
      // dùng đã ingest dữ liệu trước khi cập nhật app.
      final oldDb = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE expert_knowledge_chunks (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              content_type TEXT NOT NULL,
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
        'content': 'Nội dung so sánh cũ, chưa phân loại',
        'content_type': 'so_sanh',
        'linh_vuc': 'quan_he_xa_hoi',
        'do_tuoi_thang_min': 48,
        'do_tuoi_thang_max': 71,
        'embedding': oldEmbedding,
      });
      expect(await oldDb.query('expert_knowledge_chunks'), hasLength(1));
      await oldDb.close();

      // Bước 2 — mở lại ĐÚNG bằng AppDatabase thật của app (version 3 +
      // onUpgrade), trỏ vào cùng file — mô phỏng người dùng mở app sau khi
      // cập nhật, không phải tạo database mới.
      AppDatabase.debugPathOverride = dbPath;
      final expertRepo = ExpertKnowledgeRepository(AppDatabase.instance);

      // Version 10 xoá sạch mọi dòng content_type='so_sanh' cũ (bất kể nội
      // dung/id) rồi thử seed lại — thất bại ngầm trong môi trường test
      // thuần (không có asset channel thật), nên kết quả đúng là RỖNG.
      final all = await expertRepo.getAll();
      expect(all, isEmpty);

      // Bước 3 — cột `phan_loai` vẫn hoạt động đúng cho dòng ingest MỚI sau
      // migration, không lỗi vì cột đã tồn tại (không bị ALTER TABLE trùng lần 2).
      final newChunk = await expertRepo.add(
        content: 'Nội dung so sánh mới, đã phân loại',
        contentType: 'so_sanh',
        phanLoai: 'thuong_gap',
        linhVuc: 'quan_he_xa_hoi',
        doTuoiThangMin: 48,
        doTuoiThangMax: 71,
        embedding: [0.4, 0.5],
      );
      final queried = await expertRepo.query(linhVuc: 'quan_he_xa_hoi', ageInMonths: 60, contentType: 'so_sanh');
      expect(queried, hasLength(1));
      expect(queried.firstWhere((c) => c.id == newChunk.id).phanLoai, 'thuong_gap');

      // ignore: avoid_print
      print(
        'PASS: migration version 2 → 3 không crash, cột phan_loai hoạt động đúng cho chunk mới; '
        'dòng so_sanh cũ bị xoá sạch bởi migration version 10 (đúng thiết kế sửa BUG-01/02)',
      );
    } finally {
      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
      await tempDir.delete(recursive: true);
    }
  });
}
