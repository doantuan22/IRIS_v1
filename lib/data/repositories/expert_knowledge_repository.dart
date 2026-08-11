import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../domain/models/expert_knowledge_chunk.dart';
import '../../domain/services/embedding_codec.dart';
import '../local/database.dart';

/// Lưu và truy vấn chunk dữ liệu tham khảo (`expert_knowledge_chunks`) —
/// nội dung tĩnh dùng chung cho mọi trẻ, lọc theo lĩnh vực/độ tuổi/loại
/// nội dung.
class ExpertKnowledgeRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ExpertKnowledgeRepository(this._db);

  Future<ExpertKnowledgeChunk> add({
    required String content,
    required String contentType,
    String? linhVuc,
    int? doTuoiThangMin,
    int? doTuoiThangMax,
    String? nguonTaiLieu,
    required List<double> embedding,
  }) async {
    final chunk = ExpertKnowledgeChunk(
      id: _uuid.v4(),
      content: content,
      contentType: contentType,
      linhVuc: linhVuc,
      doTuoiThangMin: doTuoiThangMin,
      doTuoiThangMax: doTuoiThangMax,
      nguonTaiLieu: nguonTaiLieu,
      embedding: embedding,
    );
    final db = await _db.database;
    await db.insert('expert_knowledge_chunks', _toRow(chunk));
    return chunk;
  }

  /// Lấy toàn bộ chunk — dùng để kiểm tra đã ingest dữ liệu tham khảo hay
  /// chưa trước khi chạy ingest lại (tránh insert trùng).
  Future<List<ExpertKnowledgeChunk>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('expert_knowledge_chunks');
    return rows.map(_fromRow).toList();
  }

  /// Lọc theo [linhVuc] (bỏ qua nếu null), theo [ageInMonths] — ĐƠN VỊ
  /// THÁNG, khớp `do_tuoi_thang_min`/`do_tuoi_thang_max` — nằm trong khoảng
  /// `do_tuoi_thang_min <= ageInMonths <= do_tuoi_thang_max`, và theo
  /// [contentType] (bỏ qua nếu null). Dùng `childAgeInMonths()` để quy đổi
  /// từ `Child.ageYears`/`dob` trước khi gọi hàm này.
  Future<List<ExpertKnowledgeChunk>> query({
    String? linhVuc,
    required int ageInMonths,
    String? contentType,
  }) async {
    final db = await _db.database;
    final conditions = <String>[
      '(do_tuoi_thang_min IS NULL OR do_tuoi_thang_min <= ?)',
      '(do_tuoi_thang_max IS NULL OR do_tuoi_thang_max >= ?)',
    ];
    final args = <Object?>[ageInMonths, ageInMonths];

    if (linhVuc != null) {
      conditions.add('linh_vuc = ?');
      args.add(linhVuc);
    }
    if (contentType != null) {
      conditions.add('content_type = ?');
      args.add(contentType);
    }

    final rows = await db.query(
      'expert_knowledge_chunks',
      where: conditions.join(' AND '),
      whereArgs: args,
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _toRow(ExpertKnowledgeChunk chunk) => {
        'id': chunk.id,
        'content': chunk.content,
        'content_type': chunk.contentType,
        'linh_vuc': chunk.linhVuc,
        'do_tuoi_thang_min': chunk.doTuoiThangMin,
        'do_tuoi_thang_max': chunk.doTuoiThangMax,
        'nguon_tai_lieu': chunk.nguonTaiLieu,
        'embedding': encodeEmbedding(chunk.embedding),
      };

  ExpertKnowledgeChunk _fromRow(Map<String, Object?> row) => ExpertKnowledgeChunk(
        id: row['id'] as String,
        content: row['content'] as String,
        contentType: row['content_type'] as String,
        linhVuc: row['linh_vuc'] as String?,
        doTuoiThangMin: row['do_tuoi_thang_min'] as int?,
        doTuoiThangMax: row['do_tuoi_thang_max'] as int?,
        nguonTaiLieu: row['nguon_tai_lieu'] as String?,
        embedding: decodeEmbedding(row['embedding'] as Uint8List),
      );
}
