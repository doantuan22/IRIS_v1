import 'package:uuid/uuid.dart';

import '../../domain/models/assessment.dart';
import '../local/database.dart';

/// Lưu và truy vấn dữ liệu đánh giá 9 lĩnh vực (chỉ dữ liệu riêng của trẻ:
/// mô tả biểu hiện / ghi chú chuyên gia case-specific) trên bảng
/// `assessments`. KHÔNG chứa nội dung tham khảo chung.
class AssessmentRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  AssessmentRepository(this._db);

  Future<Assessment> save({
    required String childId,
    required String linhVuc,
    String contentType = 'mo_ta',
    required String content,
    String? nguon,
    String? performedBy,
  }) async {
    final assessment = Assessment(
      id: _uuid.v4(),
      childId: childId,
      linhVuc: linhVuc,
      contentType: contentType,
      content: content,
      nguon: nguon,
      performedBy: performedBy,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('assessments', _toRow(assessment));
    return assessment;
  }

  Future<List<Assessment>> getForChild(String childId, {String? linhVuc}) async {
    final db = await _db.database;
    final rows = await db.query(
      'assessments',
      where: linhVuc == null ? 'child_id = ?' : 'child_id = ? AND linh_vuc = ?',
      whereArgs: linhVuc == null ? [childId] : [childId, linhVuc],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _toRow(Assessment assessment) => {
        'id': assessment.id,
        'child_id': assessment.childId,
        'linh_vuc': assessment.linhVuc,
        'content_type': assessment.contentType,
        'content': assessment.content,
        'nguon': assessment.nguon,
        'performed_by': assessment.performedBy,
        'created_at': assessment.createdAt.toIso8601String(),
      };

  Assessment _fromRow(Map<String, Object?> row) => Assessment(
        id: row['id'] as String,
        childId: row['child_id'] as String,
        linhVuc: row['linh_vuc'] as String,
        contentType: row['content_type'] as String,
        content: row['content'] as String,
        nguon: row['nguon'] as String?,
        performedBy: row['performed_by'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
