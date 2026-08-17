import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/local/tables/children_table.dart';
import 'package:iris_app/data/local/tables/domain_overview_labels_table.dart';
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/data/local/tables/overview_summaries_table.dart';
import 'package:iris_app/data/local/tables/screening_domain_scores_table.dart';
import 'package:iris_app/data/local/tables/screening_responses_table.dart';
import 'package:iris_app/data/local/tables/screenings_table.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema version 8 -> 9 (chạy qua đường `AppDatabase` thật,
/// hiện đã ở version 10):
/// 1. Xoá sạch dữ liệu tĩnh `content_type IN ('chia_se_phu_huynh', 'bac_si')` trong `expert_knowledge_chunks`.
/// 2. Mọi bảng khác (children, screenings, assessments, overview_summaries...) không bị ảnh hưởng.
///
/// LƯU Ý (từ bản sửa BUG-01/02 — migration version 10): dòng `so_sanh` KHÔNG
/// còn được giữ nguyên qua migration như tên gọi ban đầu của test — version
/// 10 xoá sạch mọi dòng `content_type='so_sanh'` (bất kể nội dung/id) để tự
/// "chữa lành" dữ liệu cũ/sai, rồi `onOpen` tự seed lại từ
/// `expert_knowledge_seed.json`. Trong môi trường test Dart VM thuần (không
/// có asset channel thật) bước seed lại thất bại ngầm (best-effort), nên kết
/// quả `so_sanh` sau khi mở là RỖNG — đúng thiết kế mới, không phải bug.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 8 -> 9: xoá sạch chia_se_phu_huynh và bac_si trong expert_knowledge_chunks, '
      'bảo toàn nguyên vẹn so_sanh', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_v8_v9_migration_test_');
    final dbPath = '${tempDir.path}/iris_v8.db';

    try {
      // Bước 1 — tạo database ở schema version 8 (đầy đủ các bảng đến v8)
      final oldDb = await openDatabase(
        dbPath,
        version: 8,
        onCreate: (db, version) async {
          await db.execute(childrenTableCreate);
          await db.execute(screeningsTableCreate);
          await db.execute(expertKnowledgeChunksTableCreate);
          await db.execute(domainOverviewLabelsTableCreate);
          await db.execute(overviewSummariesTableCreate);
          await db.execute(screeningResponsesTableCreate);
          await db.execute(screeningDomainScoresTableCreate);
        },
      );

      final dummyEmbedding = encodeEmbedding([0.1, 0.2, 0.3]);

      // Thêm các chunk vào expert_knowledge_chunks (gồm so_sanh, chia_se_phu_huynh, bac_si)
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-ss-1',
        'content': 'So sánh bình thường - ngôn ngữ',
        'content_type': 'so_sanh',
        'phan_loai': 'binh_thuong',
        'linh_vuc': 'ngon_ngu',
        'do_tuoi_thang_min': 24,
        'do_tuoi_thang_max': 47,
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-ss-2',
        'content': 'So sánh cần quan sát - nhận thức',
        'content_type': 'so_sanh',
        'phan_loai': 'roi_loan_pho_tu_ky',
        'linh_vuc': 'nhan_thuc',
        'do_tuoi_thang_min': 24,
        'do_tuoi_thang_max': 47,
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-cs-1',
        'content': 'Chia sẻ từ phụ huynh - ở nhà',
        'content_type': 'chia_se_phu_huynh',
        'nhom_tre': 'binh_thuong',
        'boi_canh': 'o_nha',
        'linh_vuc': 'quan_he_xa_hoi',
        'do_tuoi_thang_min': 48,
        'do_tuoi_thang_max': 71,
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-bs-1',
        'content': 'Thông tin từ bác sĩ - mốc phát triển',
        'content_type': 'bac_si',
        'phan_loai': 'moc_phat_trien',
        'linh_vuc': 'cam_xuc',
        'do_tuoi_thang_min': 48,
        'do_tuoi_thang_max': 71,
        'embedding': dummyEmbedding,
      });

      final countBefore = await oldDb.query('expert_knowledge_chunks');
      expect(countBefore, hasLength(4));
      await oldDb.close();

      // Bước 2 — mở lại bằng AppDatabase thật của app (version 9 + onUpgrade)
      AppDatabase.debugPathOverride = dbPath;
      final expertRepo = ExpertKnowledgeRepository(AppDatabase.instance);

      final allAfter = await expertRepo.getAll();
      // chia_se_phu_huynh/bac_si bị xoá bởi migration v9; 2 dòng so_sanh cũ
      // (chunk-ss-1/2) bị xoá bởi migration v10 (xoá sạch mọi so_sanh cũ để
      // seed lại từ file mới) — seed lại thất bại ngầm trong môi trường test
      // thuần, nên kết quả cuối là RỖNG hoàn toàn.
      expect(allAfter, isEmpty);

      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
