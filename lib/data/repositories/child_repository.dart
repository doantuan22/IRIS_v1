import 'package:uuid/uuid.dart';

import '../../domain/models/child.dart';
import '../local/database.dart';
import 'video_repository.dart';

/// CRUD hồ sơ trẻ trên bảng `children`.
class ChildRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ChildRepository(this._db);

  Future<Child> create({
    required String name,
    String? dob,
    int? ageYears,
    String? gender,
    String? nguoiDanhGia,
    String? vaiTro,
  }) async {
    final child = Child(
      id: _uuid.v4(),
      name: name,
      dob: dob,
      ageYears: ageYears,
      gender: gender,
      nguoiDanhGia: nguoiDanhGia,
      vaiTro: vaiTro,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('children', _toRow(child));
    return child;
  }

  Future<List<Child>> getAll({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'children',
      where: includeArchived ? null : 'status = ?',
      whereArgs: includeArchived ? null : ['active'],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Child?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('children', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> update(Child child) async {
    final db = await _db.database;
    await db.update(
      'children',
      _toRow(child),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<void> archive(String id) async {
    final db = await _db.database;
    await db.update(
      'children',
      {'status': 'archived'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _db.database;
    await db.update(
      'children',
      {'status': 'active'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xoá hồ sơ trẻ. `PRAGMA foreign_keys = ON` (bật trong [AppDatabase]) chặn
  /// xoá thẳng `children` nếu còn dòng tham chiếu ở bảng khác — không bảng
  /// nào khai báo `ON DELETE CASCADE` trong schema, nên phải tự xoá đúng thứ
  /// tự các bảng con trước, trong 1 transaction để đảm bảo toàn vẹn (không để
  /// xoá dở dang nếu có lỗi giữa chừng). `expert_knowledge_chunks` không có
  /// child_id (dữ liệu tham khảo dùng chung) nên không đụng tới.
  ///
  /// File `.mp4` vật lý của các video thuộc trẻ này được xoá SAU khi
  /// transaction DB đã commit thành công — mỗi file xoá độc lập (lỗi ở 1
  /// file không chặn các file còn lại), vì DB đã xoá xong rồi nên không có
  /// gì để rollback nữa.
  Future<void> delete(String id) async {
    final db = await _db.database;

    final videoRows = await db.query(
      'videos',
      columns: ['file_path'],
      where: 'child_id = ?',
      whereArgs: [id],
    );
    final filePaths = videoRows
        .map((row) => row['file_path'] as String)
        .toList();

    await db.transaction((txn) async {
      await txn.delete(
        'screening_responses',
        where:
            'screening_id IN (SELECT id FROM screenings WHERE child_id = ?)',
        whereArgs: [id],
      );
      await txn.delete(
        'screening_domain_scores',
        where:
            'screening_id IN (SELECT id FROM screenings WHERE child_id = ?)',
        whereArgs: [id],
      );
      await txn.delete('screenings', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('assessments', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('history_logs', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete(
        'profile_chunks',
        where: 'child_id = ?',
        whereArgs: [id],
      );
      await txn.delete('videos', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete(
        'ai_conversations',
        where: 'child_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'domain_overview_labels',
        where: 'child_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'overview_summaries',
        where: 'child_id = ?',
        whereArgs: [id],
      );
      await txn.delete('children', where: 'id = ?', whereArgs: [id]);
    });

    for (final filePath in filePaths) {
      await VideoRepository.deletePhysicalFile(filePath);
    }
  }

  Map<String, Object?> _toRow(Child child) => {
    'id': child.id,
    'name': child.name,
    'dob': child.dob,
    'age_years': child.ageYears,
    'gender': child.gender,
    'nguoi_danh_gia': child.nguoiDanhGia,
    'vai_tro': child.vaiTro,
    'status': child.status,
    'created_at': child.createdAt.toIso8601String(),
  };

  Child _fromRow(Map<String, Object?> row) => Child(
    id: row['id'] as String,
    name: row['name'] as String,
    dob: row['dob'] as String?,
    ageYears: row['age_years'] as int?,
    gender: row['gender'] as String?,
    nguoiDanhGia: row['nguoi_danh_gia'] as String?,
    vaiTro: row['vai_tro'] as String?,
    status: row['status'] as String? ?? 'active',
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
