import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../domain/models/profile_chunk.dart';
import '../../domain/services/embedding_codec.dart';
import '../local/database.dart';

/// Lưu và truy vấn chunk dữ liệu hồ sơ trẻ (`profile_chunks`) dùng cho RAG.
/// Embedding nhận vào/trả ra dạng `List<double>` — repository tự lo việc
/// encode/decode sang BLOB khi đọc/ghi SQLite.
class ProfileChunkRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ProfileChunkRepository(this._db);

  Future<ProfileChunk> add({
    required String childId,
    required String content,
    String? linhVuc,
    String? nguon,
    required List<double> embedding,
  }) async {
    final chunk = ProfileChunk(
      id: _uuid.v4(),
      childId: childId,
      content: content,
      linhVuc: linhVuc,
      nguon: nguon,
      embedding: embedding,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('profile_chunks', _toRow(chunk));
    return chunk;
  }

  Future<List<ProfileChunk>> getForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'profile_chunks',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _toRow(ProfileChunk chunk) => {
    'id': chunk.id,
    'child_id': chunk.childId,
    'content': chunk.content,
    'linh_vuc': chunk.linhVuc,
    'nguon': chunk.nguon,
    'embedding': encodeEmbedding(chunk.embedding),
    'created_at': chunk.createdAt.toIso8601String(),
  };

  ProfileChunk _fromRow(Map<String, Object?> row) => ProfileChunk(
    id: row['id'] as String,
    childId: row['child_id'] as String,
    content: row['content'] as String,
    linhVuc: row['linh_vuc'] as String?,
    nguon: row['nguon'] as String?,
    embedding: decodeEmbedding(row['embedding'] as Uint8List),
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
