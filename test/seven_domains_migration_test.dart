import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/local/tables/assessments_table.dart';
import 'package:iris_app/data/local/tables/children_table.dart';
import 'package:iris_app/data/local/tables/domain_overview_labels_table.dart';
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/data/local/tables/overview_summaries_table.dart';
import 'package:iris_app/data/local/tables/profile_chunks_table.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test migration schema version 5 -> 6 (dọn dẹp dữ liệu 2 lĩnh vực 'hanh_vi' và 'ung_xu'
/// khi chuyển đổi từ 9 lĩnh vực xuống 7 lĩnh vực).
/// Mô phỏng máy người dùng có dữ liệu ở cả 4 bảng: assessments, profile_chunks,
/// domain_overview_labels, expert_knowledge_chunks với các lĩnh vực hanh_vi, ung_xu,
/// ngon_ngu, cam_xuc.
/// Sau migration, toàn bộ dòng hanh_vi và ung_xu bị xoá sạch, các lĩnh vực khác giữ nguyên.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
      'Migration version 5 -> 6: xoá sạch dữ liệu hanh_vi và ung_xu ở cả 4 bảng, '
      'giữ nguyên dữ liệu 7 lĩnh vực còn lại', () async {
    final tempDir = await Directory.systemTemp.createTemp('iris_seven_domains_migration_test_');
    final dbPath = '${tempDir.path}/iris_v5.db';

    try {
      // Bước 1 — tạo database ở schema version 5 có đầy đủ bảng và dữ liệu 9 lĩnh vực
      final oldDb = await openDatabase(
        dbPath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute(childrenTableCreate);
          await db.execute(assessmentsTableCreate);
          await db.execute(profileChunksTableCreate);
          await db.execute(expertKnowledgeChunksTableCreate);
          await db.execute(domainOverviewLabelsTableCreate);
          await db.execute(overviewSummariesTableCreate);
        },
      );

      // Thêm 1 trẻ
      await oldDb.insert('children', {
        'id': 'child-mig-1',
        'name': 'Bé Migration 7 Lĩnh Vực',
        'age_years': 3,
        'status': 'active',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });

      final dummyEmbedding = encodeEmbedding([0.1, 0.2, 0.3]);

      // 1. assessments: 2 dòng hanh_vi/ung_xu + 2 dòng ngon_ngu/cam_xuc
      await oldDb.insert('assessments', {
        'id': 'ass-1',
        'child_id': 'child-mig-1',
        'linh_vuc': 'hanh_vi',
        'content_type': 'mo_ta',
        'content': 'Mô tả hành vi cũ',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('assessments', {
        'id': 'ass-2',
        'child_id': 'child-mig-1',
        'linh_vuc': 'ung_xu',
        'content_type': 'mo_ta',
        'content': 'Mô tả ứng xử cũ',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('assessments', {
        'id': 'ass-3',
        'child_id': 'child-mig-1',
        'linh_vuc': 'ngon_ngu',
        'content_type': 'mo_ta',
        'content': 'Mô tả ngôn ngữ',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('assessments', {
        'id': 'ass-4',
        'child_id': 'child-mig-1',
        'linh_vuc': 'cam_xuc',
        'content_type': 'mo_ta',
        'content': 'Mô tả cảm xúc',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });

      // 2. profile_chunks: 2 dòng hanh_vi/ung_xu + 1 dòng ngon_ngu
      await oldDb.insert('profile_chunks', {
        'id': 'pc-1',
        'child_id': 'child-mig-1',
        'linh_vuc': 'hanh_vi',
        'content': 'Chunk hành vi',
        'embedding': dummyEmbedding,
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('profile_chunks', {
        'id': 'pc-2',
        'child_id': 'child-mig-1',
        'linh_vuc': 'ung_xu',
        'content': 'Chunk ứng xử',
        'embedding': dummyEmbedding,
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('profile_chunks', {
        'id': 'pc-3',
        'child_id': 'child-mig-1',
        'linh_vuc': 'ngon_ngu',
        'content': 'Chunk ngôn ngữ',
        'embedding': dummyEmbedding,
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });

      // 3. domain_overview_labels: 2 dòng hanh_vi/ung_xu + 1 dòng cam_xuc
      await oldDb.insert('domain_overview_labels', {
        'id': 'dol-1',
        'child_id': 'child-mig-1',
        'linh_vuc': 'hanh_vi',
        'nhan': 'thuong_gap',
        'computed_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('domain_overview_labels', {
        'id': 'dol-2',
        'child_id': 'child-mig-1',
        'linh_vuc': 'ung_xu',
        'nhan': 'can_theo_doi',
        'computed_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await oldDb.insert('domain_overview_labels', {
        'id': 'dol-3',
        'child_id': 'child-mig-1',
        'linh_vuc': 'cam_xuc',
        'nhan': 'thuong_gap',
        'computed_at': DateTime(2025, 1, 1).toIso8601String(),
      });

      // 4. expert_knowledge_chunks: 2 dòng hanh_vi/ung_xu + 1 dòng ngon_ngu
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'ekc-1',
        'content': 'Tham khảo hành vi',
        'content_type': 'so_sanh',
        'linh_vuc': 'hanh_vi',
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'ekc-2',
        'content': 'Tham khảo ứng xử',
        'content_type': 'so_sanh',
        'linh_vuc': 'ung_xu',
        'embedding': dummyEmbedding,
      });
      await oldDb.insert('expert_knowledge_chunks', {
        'id': 'ekc-3',
        'content': 'Tham khảo ngôn ngữ',
        'content_type': 'so_sanh',
        'linh_vuc': 'ngon_ngu',
        'embedding': dummyEmbedding,
      });

      expect(await oldDb.query('assessments'), hasLength(4));
      expect(await oldDb.query('profile_chunks'), hasLength(3));
      expect(await oldDb.query('domain_overview_labels'), hasLength(3));
      expect(await oldDb.query('expert_knowledge_chunks'), hasLength(3));
      await oldDb.close();

      // Bước 2 — Mở lại bằng AppDatabase thật (version 6 + onUpgrade)
      AppDatabase.debugPathOverride = dbPath;

      final db = await AppDatabase.instance.database;

      // Bước 3 — Xác nhận version và dữ liệu đã được dọn sạch
      expect(await db.getVersion(), 9);

      // Kiểm tra assessments
      final assessments = await db.query('assessments');
      expect(assessments, hasLength(2));
      expect(assessments.any((r) => r['linh_vuc'] == 'hanh_vi'), isFalse);
      expect(assessments.any((r) => r['linh_vuc'] == 'ung_xu'), isFalse);
      expect(assessments.any((r) => r['linh_vuc'] == 'ngon_ngu'), isTrue);
      expect(assessments.any((r) => r['linh_vuc'] == 'cam_xuc'), isTrue);

      // Kiểm tra profile_chunks
      final profileChunks = await db.query('profile_chunks');
      expect(profileChunks, hasLength(1));
      expect(profileChunks.single['linh_vuc'], 'ngon_ngu');

      // Kiểm tra domain_overview_labels
      final domainLabels = await db.query('domain_overview_labels');
      expect(domainLabels, hasLength(1));
      expect(domainLabels.single['linh_vuc'], 'cam_xuc');

      // Kiểm tra expert_knowledge_chunks
      final expertChunks = await db.query('expert_knowledge_chunks');
      expect(expertChunks, hasLength(1));
      expect(expertChunks.single['linh_vuc'], 'ngon_ngu');

      // ignore: avoid_print
      print(
        'PASS: migration version 5 -> 6 xoá sạch hanh_vi và ung_xu ở cả 4 bảng, '
        'giữ nguyên toàn bộ dữ liệu của 7 lĩnh vực còn lại',
      );
    } finally {
      final db = await AppDatabase.instance.database;
      await db.close();
      AppDatabase.resetForTest();
      await tempDir.delete(recursive: true);
    }
  });
}
