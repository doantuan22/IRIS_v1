import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/screening.dart';
import '../local/database.dart';

/// Lưu và truy vấn kết quả sàng lọc trên bảng `screenings`. Không có bản ghi
/// nào cho một child_id nghĩa là trẻ đó chưa sàng lọc — đây là tín hiệu
/// trung lập, không phải "kết quả âm tính" hay kết luận gì khác.
class ScreeningRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ScreeningRepository(this._db);

  Future<Screening> save({
    required String childId,
    String? toolName,
    String? score,
    String? resultSummary,
    DateTime? performedAt,
  }) async {
    final screening = Screening(
      id: _uuid.v4(),
      childId: childId,
      toolName: toolName,
      score: score,
      resultSummary: resultSummary,
      performedAt: performedAt,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('screenings', _toRow(screening));
    return screening;
  }

  Future<List<Screening>> getForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screenings',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'performed_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Screening?> getLatestForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screenings',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'performed_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Đúng nguyên tắc đã chốt trong roadmap: không có dòng nào cho child_id
  /// tương ứng chính là tín hiệu "chưa sàng lọc" — không dùng cột trạng
  /// thái riêng.
  Future<bool> hasScreening(String childId) async {
    final db = await _db.database;
    final result = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM screenings WHERE child_id = ?',
      [childId],
    ));
    return (result ?? 0) > 0;
  }

  Map<String, Object?> _toRow(Screening screening) => {
        'id': screening.id,
        'child_id': screening.childId,
        'tool_name': screening.toolName,
        'score': screening.score,
        'result_summary': screening.resultSummary,
        'performed_at': screening.performedAt?.toIso8601String(),
        'created_at': screening.createdAt.toIso8601String(),
      };

  Screening _fromRow(Map<String, Object?> row) => Screening(
        id: row['id'] as String,
        childId: row['child_id'] as String,
        toolName: row['tool_name'] as String?,
        score: row['score'] as String?,
        resultSummary: row['result_summary'] as String?,
        performedAt: row['performed_at'] == null
            ? null
            : DateTime.parse(row['performed_at'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
