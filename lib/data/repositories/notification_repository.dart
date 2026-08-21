import 'package:uuid/uuid.dart';

import '../../domain/models/app_notification.dart';
import '../local/database.dart';

/// Quản lý dữ liệu thông báo trong bảng `notifications`.
class NotificationRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  NotificationRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<AppNotification> add({
    required String title,
    required String content,
    required String type,
    DateTime? createdAt,
    bool isRead = false,
  }) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      title: title,
      content: content,
      type: type,
      createdAt: createdAt ?? DateTime.now(),
      isRead: isRead,
    );
    final db = await _db.database;
    await db.insert('notifications', _toRow(notification));
    return notification;
  }

  Future<List<AppNotification>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('notifications', orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> markAsRead(String id) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await _db.database;
    await db.update('notifications', {'is_read': 1});
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('notifications');
  }

  Map<String, Object?> _toRow(AppNotification item) => {
    'id': item.id,
    'title': item.title,
    'content': item.content,
    'type': item.type,
    'created_at': item.createdAt.toIso8601String(),
    'is_read': item.isRead ? 1 : 0,
  };

  AppNotification _fromRow(Map<String, Object?> row) => AppNotification(
    id: row['id'] as String,
    title: row['title'] as String,
    content: row['content'] as String,
    type: row['type'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    isRead: (row['is_read'] as int? ?? 0) == 1,
  );
}
