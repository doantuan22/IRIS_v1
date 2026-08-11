import 'package:uuid/uuid.dart';

import '../../domain/models/history_log.dart';
import '../local/database.dart';

/// Lưu và truy vấn lịch sử tổng hợp trên bảng `history_logs`.
class HistoryLogRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  HistoryLogRepository(this._db);

  Future<HistoryLog> add({
    required String childId,
    required String eventType,
    String? description,
    DateTime? eventDate,
  }) async {
    final log = HistoryLog(
      id: _uuid.v4(),
      childId: childId,
      eventType: eventType,
      description: description,
      eventDate: eventDate ?? DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('history_logs', _toRow(log));
    return log;
  }

  Future<List<HistoryLog>> getForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'history_logs',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'event_date DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _toRow(HistoryLog log) => {
        'id': log.id,
        'child_id': log.childId,
        'event_type': log.eventType,
        'description': log.description,
        'event_date': log.eventDate.toIso8601String(),
      };

  HistoryLog _fromRow(Map<String, Object?> row) => HistoryLog(
        id: row['id'] as String,
        childId: row['child_id'] as String,
        eventType: row['event_type'] as String,
        description: row['description'] as String?,
        eventDate: DateTime.parse(row['event_date'] as String),
      );
}
