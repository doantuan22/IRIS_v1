import 'package:uuid/uuid.dart';

import '../../domain/models/video.dart';
import '../local/database.dart';

/// Lưu và truy vấn video quay tình huống trên bảng `videos`. File video lưu
/// local qua `path_provider`; bảng này chỉ lưu metadata + đường dẫn.
class VideoRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  VideoRepository(this._db);

  Future<Video> save({
    required String childId,
    required String filePath,
    String? situation,
    String status = 'not_sent',
  }) async {
    final video = Video(
      id: _uuid.v4(),
      childId: childId,
      situation: situation,
      filePath: filePath,
      status: status,
      recordedAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('videos', _toRow(video));
    return video;
  }

  Future<List<Video>> getForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'videos',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'recorded_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> updateStatus(String id, String status, {String? expertNote}) async {
    final db = await _db.database;
    final values = <String, Object?>{'status': status};
    if (expertNote != null) values['expert_note'] = expertNote;
    await db.update('videos', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('videos', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(Video video) => {
        'id': video.id,
        'child_id': video.childId,
        'situation': video.situation,
        'file_path': video.filePath,
        'status': video.status,
        'expert_note': video.expertNote,
        'recorded_at': video.recordedAt.toIso8601String(),
      };

  Video _fromRow(Map<String, Object?> row) => Video(
        id: row['id'] as String,
        childId: row['child_id'] as String,
        situation: row['situation'] as String?,
        filePath: row['file_path'] as String,
        status: row['status'] as String? ?? 'not_sent',
        expertNote: row['expert_note'] as String?,
        recordedAt: DateTime.parse(row['recorded_at'] as String),
      );
}
