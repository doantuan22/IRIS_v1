import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/ai_conversations_table.dart';
import 'tables/assessments_table.dart';
import 'tables/children_table.dart';
import 'tables/expert_knowledge_chunks_table.dart';
import 'tables/history_logs_table.dart';
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
      version: 1,
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
      },
    );
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'iris.db');
  }
}
