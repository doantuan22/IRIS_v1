import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/ai_conversations_table.dart';
import 'tables/assessments_table.dart';
import 'tables/children_table.dart';
import 'tables/domain_overview_labels_table.dart';
import 'tables/expert_knowledge_chunks_table.dart';
import 'tables/history_logs_table.dart';
import 'tables/overview_summaries_table.dart';
import 'tables/profile_chunks_table.dart';
import 'tables/screenings_table.dart';
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
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute(childrenTableCreate);
        await db.execute(screeningsTableCreate);
        await db.execute(assessmentsTableCreate);
        await db.execute(historyLogsTableCreate);
        await db.execute(profileChunksTableCreate);
        await db.execute(expertKnowledgeChunksTableCreate);
        await db.execute(videosTableCreate);
        await db.execute(aiConversationsTableCreate);
        await db.execute(domainOverviewLabelsTableCreate);
        await db.execute(overviewSummariesTableCreate);
      },
      // Version 2 — thêm 2 cột `nguoi_danh_gia`/`vai_tro` vào `children` cho
      // hồ sơ trẻ đã tồn tại từ trước (cài mới đã có sẵn 2 cột này qua
      // `childrenTableCreate` ở onCreate, không đi qua đường này).
      // `ALTER TABLE ... ADD COLUMN` không đụng tới dữ liệu dòng đã có —
      // các dòng cũ tự động nhận giá trị NULL cho 2 cột mới.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE children ADD COLUMN nguoi_danh_gia TEXT');
          await db.execute('ALTER TABLE children ADD COLUMN vai_tro TEXT');
        }
        // Version 3 — thêm cột `phan_loai` vào `expert_knowledge_chunks` cho
        // dữ liệu tham khảo đã có sẵn từ trước; `ALTER TABLE ADD COLUMN`
        // không đụng dữ liệu dòng cũ, chỉ nhận NULL cho cột mới.
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE expert_knowledge_chunks ADD COLUMN phan_loai TEXT');
        }
        // Version 4 — thêm cột `nhom_tre`/`boi_canh` vào
        // `expert_knowledge_chunks` (dùng cho content_type='chia_se_phu_huynh')
        // cho dữ liệu tham khảo đã có sẵn từ trước; không đụng dữ liệu dòng cũ.
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE expert_knowledge_chunks ADD COLUMN nhom_tre TEXT');
          await db.execute('ALTER TABLE expert_knowledge_chunks ADD COLUMN boi_canh TEXT');
        }
        // Version 5 — thêm 2 bảng MỚI cho "Chân dung toàn cảnh"
        // (`domain_overview_labels`, `overview_summaries`); không đụng tới
        // bảng/dữ liệu đã có sẵn nào.
        if (oldVersion < 5) {
          await db.execute(domainOverviewLabelsTableCreate);
          await db.execute(overviewSummariesTableCreate);
        }
      },
    );
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'iris.db');
  }
}
