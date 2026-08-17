import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/local/tables/children_table.dart';
import 'package:iris_app/data/local/tables/domain_overview_labels_table.dart';
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/overview_summary_repository.dart';
import 'package:iris_app/domain/models/overview_summary.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema version 6 -> 7:
/// 1. Xoá sạch dữ liệu tĩnh `content_type='chan_dung'` trong `expert_knowledge_chunks`.
/// 2. Bổ sung cột `mo_ta_tong_hop TEXT` vào `overview_summaries`.
/// 3. Dữ liệu `overview_summaries` cũ (tier, so_linh_vuc_can_theo_doi...) không bị mất,
///    cột mới nhận giá trị NULL cho dòng cũ và đọc/ghi/update bình thường.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 6 -> 7: xoá sạch chan_dung trong expert_knowledge_chunks, '
      'thêm cột mo_ta_tong_hop trong overview_summaries và bảo toàn dữ liệu cũ', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_v6_v7_migration_test_');
    final dbPath = '${tempDir.path}/iris_v6.db';

    try {
      // Bước 1 — tạo database ở schema version 6 (chưa có cột mo_ta_tong_hop ở overview_summaries)
      final oldDb = await openDatabase(
        dbPath,
        version: 6,
        onCreate: (db, version) async {
          await db.execute(childrenTableCreate);
          await db.execute(expertKnowledgeChunksTableCreate);
          await db.execute(domainOverviewLabelsTableCreate);
          // Tạo bảng overview_summaries ở schema version 6 cũ (chưa có mo_ta_tong_hop)
          await db.execute('''
            CREATE TABLE overview_summaries (
              id TEXT PRIMARY KEY,
              child_id TEXT NOT NULL REFERENCES children(id),
              tier TEXT NOT NULL,
              so_linh_vuc_can_theo_doi INTEGER NOT NULL,
              so_linh_vuc_thieu_du_lieu INTEGER NOT NULL,
              computed_at TEXT NOT NULL
            );
          ''');
        },
      );

      // Thêm 1 trẻ
      await oldDb.insert('children', {
        'id': 'child-v6-1',
        'name': 'Bé Migration V7',
        'age_years': 4,
        'status': 'active',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });

      final dummyEmbedding = encodeEmbedding([0.1, 0.2, 0.3]);

      // Thêm các chunk vào expert_knowledge_chunks (gồm cả chan_dung, so_sanh, bac_si)
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-cd-1',
        'content': 'Chân dung điểm mạnh 1',
        'content_type': 'chan_dung',
        'phan_loai': 'diem_manh',
        'linh_vuc': 'quan_he_xa_hoi',
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-cd-2',
        'content': 'Chân dung khác biệt 2',
        'content_type': 'chan_dung',
        'phan_loai': 'khac_biet',
        'linh_vuc': 'quan_he_xa_hoi',
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-ss-1',
        'content': 'So sánh bình thường',
        'content_type': 'so_sanh',
        'phan_loai': 'binh_thuong',
        'linh_vuc': 'ngon_ngu',
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'chunk-bs-1',
        'content': 'Bác sĩ lưu ý',
        'content_type': 'bac_si',
        'phan_loai': 'dau_hieu_luu_y',
        'linh_vuc': 'cam_xuc',
        'embedding': dummyEmbedding,
      });

      // Thêm 1 dòng overview_summaries cũ
      await oldDb.insert('overview_summaries', {
        'id': 'summary-old-1',
        'child_id': 'child-v6-1',
        'tier': tierCanTheoDoi,
        'so_linh_vuc_can_theo_doi': 3,
        'so_linh_vuc_thieu_du_lieu': 0,
        'computed_at': '2026-08-15T09:00:00.000',
      });

      expect(await oldDb.query('expert_knowledge_chunks'), hasLength(4));
      expect(await oldDb.query('overview_summaries'), hasLength(1));
      await oldDb.close();

      // Bước 2 — Mở lại bằng AppDatabase (version 7 + onUpgrade)
      AppDatabase.debugPathOverride = dbPath;
      final db = await AppDatabase.instance.database;

      // 1. Xác nhận version DB là 9 (sau khi có migration v9)
      expect(await db.getVersion(), 10);

      // 2. Xác nhận expert_knowledge_chunks đã xoá sạch chan_dung/bac_si (v7/v9)
      // VÀ so_sanh (v10 — sửa BUG-01/02, xoá sạch so_sanh cũ để seed lại từ
      // file mới; seed lại thất bại ngầm trong môi trường test thuần không
      // có asset channel thật, nên kết quả cuối là RỖNG hoàn toàn).
      final expertRepo = ExpertKnowledgeRepository(AppDatabase.instance);
      final allChunks = await expertRepo.getAll();
      expect(allChunks, isEmpty);

      // 3. Xác nhận overview_summaries cũ còn nguyên dữ liệu, moTaTongHop là null
      final summaryRepo = OverviewSummaryRepository(AppDatabase.instance);
      final oldSummary = await summaryRepo.getLatestForChild('child-v6-1');
      expect(oldSummary, isNotNull);
      expect(oldSummary!.id, 'summary-old-1');
      expect(oldSummary.tier, tierCanTheoDoi);
      expect(oldSummary.soLinhVucCanTheoDoi, 3);
      expect(oldSummary.soLinhVucThieuDuLieu, 0);
      expect(oldSummary.moTaTongHop, isNull);

      // 4. Xác nhận updateMoTaTongHop hoạt động đúng cho dòng cũ
      await summaryRepo.updateMoTaTongHop('summary-old-1', 'Đoạn mô tả tổng hợp cập nhật sau');
      final updatedOld = await summaryRepo.getLatestForChild('child-v6-1');
      expect(updatedOld?.moTaTongHop, 'Đoạn mô tả tổng hợp cập nhật sau');

      // 5. Xác nhận lưu mới overview_summaries có moTaTongHop hoạt động đúng
      final newSummary = await summaryRepo.save(
        childId: 'child-v6-1',
        tier: tierThuongGap,
        soLinhVucCanTheoDoi: 1,
        soLinhVucThieuDuLieu: 0,
        moTaTongHop: 'Bé phát triển ổn định trong dải tuổi.',
      );
      expect(newSummary.moTaTongHop, 'Bé phát triển ổn định trong dải tuổi.');

      final readBackLatest = await summaryRepo.getLatestForChild('child-v6-1');
      expect(readBackLatest?.id, newSummary.id);
      expect(readBackLatest?.tier, tierThuongGap);
      expect(readBackLatest?.moTaTongHop, 'Bé phát triển ổn định trong dải tuổi.');

      // ignore: avoid_print
      print(
        'PASS: migration version 6 -> 7 xoá sạch chan_dung, thêm cột mo_ta_tong_hop, '
        'bảo toàn và đọc/ghi đúng dữ liệu overview_summaries',
      );
    } finally {
      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
      await tempDir.delete(recursive: true);
    }
  });
}
