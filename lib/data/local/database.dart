import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/services/expert_knowledge_seed_service.dart';
import 'tables/ai_conversations_table.dart';
import 'tables/assessments_table.dart';
import 'tables/children_table.dart';
import 'tables/domain_overview_labels_table.dart';
import 'tables/expert_knowledge_chunks_table.dart';
import 'tables/history_logs_table.dart';
import 'tables/notifications_table.dart';
import 'tables/overview_summaries_table.dart';
import 'tables/profile_chunks_table.dart';
import 'tables/screening_answers_table.dart';
import 'tables/screening_domain_results_table.dart';
import 'tables/screening_sessions_table.dart';
import 'tables/videos_table.dart';

/// Khởi tạo và quản lý kết nối SQLite (sqflite) dùng chung cho toàn app.
/// Toàn bộ dữ liệu lưu local trên thiết bị, không có backend riêng.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static Database? _db;

  /// Chỉ dùng trong test — cho phép ghi đè đường dẫn DB (VD:
  /// `inMemoryDatabasePath` của sqflite_common_ffi) để chạy trên Dart VM
  /// test mà không phụ thuộc path_provider (cần platform channel thật).
  static String? debugPathOverride;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  /// Chỉ dùng trong test — đóng cache để lần gọi `database` kế tiếp mở lại
  /// một database sạch.
  static void resetForTest() {
    _db = null;
  }

  Future<Database> _initDatabase() async {
    final path = debugPathOverride ?? await _defaultPath();

    return openDatabase(
      path,
      version: 13,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // Chạy ở MỌI lần mở DB (không chỉ lần đầu tạo bảng) — tự seed dữ liệu
      // "So sánh" (content_type='so_sanh') nếu bảng đang rỗng. Đây là cơ chế
      // sửa BUG-01: trước đây dữ liệu này chỉ vào được DB qua nút debug, bị
      // loại khỏi bản release do `kDebugMode` — cài app mới (debug lẫn
      // release) giờ luôn tự có sẵn dữ liệu, không cần thao tác gì thêm. Chỉ
      // đọc file JSON local (đã có sẵn embedding tính trước) + ghi SQLite,
      // KHÔNG gọi API, chạy dưới vài giây. Xem
      // `ExpertKnowledgeSeedService` để biết quy trình cập nhật nội dung sau này.
      //
      // CHỈ chạy khi `debugPathOverride == null` (tức đang mở DB thật của
      // app, không phải DB test) — theo đúng mô tả của field đó ("Chỉ dùng
      // trong test"). Tất cả ~24 file test hiện có đều set
      // `debugPathOverride` trước khi mở DB để tự kiểm soát dữ liệu
      // `expert_knowledge_chunks`/so_sanh của riêng test đó; nếu auto-seed
      // chạy cả trong test sẽ tự nhét thêm 532 dòng thật vào DB in-memory
      // của mọi test, phá vỡ hàng loạt assertion đếm số dòng không liên quan.
      onOpen: (db) async {
        if (debugPathOverride == null) {
          await ExpertKnowledgeSeedService.seedIfEmpty(db);
        }
      },
      onCreate: (db, version) async {
        await db.execute(childrenTableCreate);
        await db.execute(assessmentsTableCreate);
        await db.execute(historyLogsTableCreate);
        await db.execute(profileChunksTableCreate);
        await db.execute(expertKnowledgeChunksTableCreate);
        await db.execute(videosTableCreate);
        await db.execute(aiConversationsTableCreate);
        await db.execute(domainOverviewLabelsTableCreate);
        await db.execute(overviewSummariesTableCreate);
        await db.execute(notificationsTableCreate);
        await db.execute(screeningSessionsTableCreate);
        await db.execute(screeningDomainResultsTableCreate);
        await db.execute(screeningAnswersTableCreate);
      },
      // Version 2 — thêm 2 cột `nguoi_danh_gia`/`vai_tro` vào `children` cho
      // hồ sơ trẻ đã tồn tại từ trước (cài mới đã có sẵn 2 cột này qua
      // `childrenTableCreate` ở onCreate, không đi qua đường này).
      // `ALTER TABLE ... ADD COLUMN` không đụng tới dữ liệu dòng đã có —
      // các dòng cũ tự động nhận giá trị NULL cho 2 cột mới.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE children ADD COLUMN nguoi_danh_gia TEXT',
          );
          await db.execute('ALTER TABLE children ADD COLUMN vai_tro TEXT');
        }
        // Version 3 — thêm cột `phan_loai` vào `expert_knowledge_chunks` cho
        // dữ liệu tham khảo đã có sẵn từ trước; `ALTER TABLE ADD COLUMN`
        // không đụng dữ liệu dòng cũ, chỉ nhận NULL cho cột mới.
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE expert_knowledge_chunks ADD COLUMN phan_loai TEXT',
          );
        }
        // Version 4 — thêm cột `nhom_tre`/`boi_canh` vào
        // `expert_knowledge_chunks` (dùng cho content_type='chia_se_phu_huynh')
        // cho dữ liệu tham khảo đã có sẵn từ trước; không đụng dữ liệu dòng cũ.
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE expert_knowledge_chunks ADD COLUMN nhom_tre TEXT',
          );
          await db.execute(
            'ALTER TABLE expert_knowledge_chunks ADD COLUMN boi_canh TEXT',
          );
        }
        // Version 5 — thêm 2 bảng MỚI cho "Chân dung toàn cảnh"
        // (`domain_overview_labels`, `overview_summaries`); không đụng tới
        // bảng/dữ liệu đã có sẵn nào.
        if (oldVersion < 5) {
          await db.execute(domainOverviewLabelsTableCreate);
          await db.execute(overviewSummariesTableCreate);
        }
        // Version 6 — dọn dữ liệu cho 2 lĩnh vực bị loại bỏ ('hanh_vi', 'ung_xu')
        // từ 9 lĩnh vực xuống 7 lĩnh vực.
        if (oldVersion < 6) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('assessments', 'profile_chunks', 'domain_overview_labels', 'expert_knowledge_chunks')",
          );
          final tableNames = tables.map((r) => r['name'] as String).toSet();
          if (tableNames.contains('assessments')) {
            try {
              await db.execute(
                "DELETE FROM assessments WHERE linh_vuc IN ('hanh_vi', 'ung_xu')",
              );
            } catch (_) {}
          }
          if (tableNames.contains('profile_chunks')) {
            try {
              await db.execute(
                "DELETE FROM profile_chunks WHERE linh_vuc IN ('hanh_vi', 'ung_xu')",
              );
            } catch (_) {}
          }
          if (tableNames.contains('domain_overview_labels')) {
            try {
              await db.execute(
                "DELETE FROM domain_overview_labels WHERE linh_vuc IN ('hanh_vi', 'ung_xu')",
              );
            } catch (_) {}
          }
          if (tableNames.contains('expert_knowledge_chunks')) {
            try {
              await db.execute(
                "DELETE FROM expert_knowledge_chunks WHERE linh_vuc IN ('hanh_vi', 'ung_xu')",
              );
            } catch (_) {}
          }
        }
        // Version 7 — xoá sạch dữ liệu tĩnh 'chan_dung' và thêm cột 'mo_ta_tong_hop' vào overview_summaries
        if (oldVersion < 7) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('expert_knowledge_chunks', 'overview_summaries')",
          );
          final tableNames = tables.map((r) => r['name'] as String).toSet();
          if (tableNames.contains('expert_knowledge_chunks')) {
            try {
              await db.execute(
                "DELETE FROM expert_knowledge_chunks WHERE content_type = 'chan_dung'",
              );
            } catch (_) {}
          }
          if (tableNames.contains('overview_summaries')) {
            try {
              await db.execute(
                'ALTER TABLE overview_summaries ADD COLUMN mo_ta_tong_hop TEXT',
              );
            } catch (_) {}
          }
        }
        // Version 8 — (LỊCH SỬ) từng thêm 2 bảng `screening_responses` và
        // `screening_domain_scores` cho bộ sàng lọc 50 câu/7 lĩnh vực cũ.
        // Cả 2 bảng đó (+ bảng `screenings`) đã bị DROP hoàn toàn ở version
        // 12 (thay bằng bộ sàng lọc mới) — bước tạo bảng ở đây không còn ý
        // nghĩa với mọi user (kể cả user đang ở version < 8), nên bỏ trống
        // có chủ đích, giữ lại comment để không mất dấu lịch sử migration.
        if (oldVersion < 8) {
          // no-op — xem giải thích ở trên.
        }
        // Version 9 — xoá dữ liệu `chia_se_phu_huynh` và `bac_si` khỏi `expert_knowledge_chunks`
        // rút gọn mỗi lĩnh vực chỉ còn 2 phần: Mô tả biểu hiện & So sánh với trẻ cùng độ tuổi.
        if (oldVersion < 9) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = 'expert_knowledge_chunks'",
          );
          if (tables.isNotEmpty) {
            try {
              await db.execute(
                "DELETE FROM expert_knowledge_chunks WHERE content_type IN ('chia_se_phu_huynh', 'bac_si')",
              );
            } catch (_) {}
          }
        }
        // Version 10 — sửa BUG-01/BUG-02: xoá SẠCH mọi dòng `content_type='so_sanh'`
        // hiện có, bất kể nội dung/id — có thể là dữ liệu placeholder cũ, nội
        // dung văn phong CŨ (từ trước đợt sửa văn phong), hoặc dòng mang UUID
        // tự sinh bởi nút debug cũ (không khớp `id` trong `video_manifest.json`).
        // Xoá xong, `onOpen` (chạy ngay sau `onUpgrade`) sẽ tự seed lại đúng
        // 532 dòng từ `expert_knowledge_seed.json` — id gốc + nội dung mới
        // nhất, không cần người dùng thao tác gì.
        if (oldVersion < 10) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = 'expert_knowledge_chunks'",
          );
          if (tables.isNotEmpty) {
            try {
              await db.execute(
                "DELETE FROM expert_knowledge_chunks WHERE content_type = 'so_sanh'",
              );
            } catch (_) {}
          }
        }
        // Version 11 — thêm bảng `notifications` lưu thông báo kết nối AI và hệ thống.
        if (oldVersion < 11) {
          await db.execute(notificationsTableCreate);
        }
        // Version 12 — thay THẾ HOÀN TOÀN bộ sàng lọc cũ (50 câu/7 lĩnh vực,
        // bảng `screenings`/`screening_responses`/`screening_domain_scores`)
        // bằng bộ sàng lọc mới (4 mức tuổi 2/3/4/5 tuổi × 20 câu × 5 lĩnh vực
        // độc lập với 7 lĩnh vực đánh giá, thang điểm 0-3 + N/A). Theo quyết
        // định của cố vấn chuyên môn — bộ cũ không còn giá trị tham chiếu,
        // xóa sạch dữ liệu cũ (không migrate/convert), người dùng làm lại
        // bài sàng lọc theo bộ mới. Xem KE_HOACH_CAU_TRUC_SANG_LOC_MOI.md.
        if (oldVersion < 12) {
          await db.execute('DROP TABLE IF EXISTS screening_responses');
          await db.execute('DROP TABLE IF EXISTS screening_domain_scores');
          await db.execute('DROP TABLE IF EXISTS screenings');
          await db.execute(screeningSessionsTableCreate);
          await db.execute(screeningDomainResultsTableCreate);
          await db.execute(screeningAnswersTableCreate);
        }
        // Version 13 — xóa sạch `expert_knowledge_chunks` content_type='so_sanh'
        // hiện có (cùng pattern version 10) để `onOpen` tự seed lại từ
        // `expert_knowledge_seed.json` đã sửa dải tuổi đầu 15-23 -> 12-23
        // tháng (2 dải 24-47/48-60 giữ nguyên). Không cần UPDATE thủ công
        // từng dòng, không cần gọi lại NVIDIA API (embedding không đổi vì
        // nội dung `content` không đổi, chỉ đổi field số do_tuoi_thang_min).
        if (oldVersion < 13) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = 'expert_knowledge_chunks'",
          );
          if (tables.isNotEmpty) {
            try {
              await db.execute(
                "DELETE FROM expert_knowledge_chunks WHERE content_type = 'so_sanh'",
              );
            } catch (_) {}
          }
        }
      },
    );
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'iris.db');
  }
}
