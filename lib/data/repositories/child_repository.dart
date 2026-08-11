import 'package:uuid/uuid.dart';

import '../../domain/models/child.dart';
import '../local/database.dart';

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
  }) async {
    final child = Child(
      id: _uuid.v4(),
      name: name,
      dob: dob,
      ageYears: ageYears,
      gender: gender,
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
    await db.update('children', _toRow(child), where: 'id = ?', whereArgs: [child.id]);
  }

  Future<void> archive(String id) async {
    final db = await _db.database;
    await db.update('children', {'status': 'archived'}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('children', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(Child child) => {
        'id': child.id,
        'name': child.name,
        'dob': child.dob,
        'age_years': child.ageYears,
        'gender': child.gender,
        'status': child.status,
        'created_at': child.createdAt.toIso8601String(),
      };

  Child _fromRow(Map<String, Object?> row) => Child(
        id: row['id'] as String,
        name: row['name'] as String,
        dob: row['dob'] as String?,
        ageYears: row['age_years'] as int?,
        gender: row['gender'] as String?,
        status: row['status'] as String? ?? 'active',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
