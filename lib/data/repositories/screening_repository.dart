import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/screening.dart';
import '../../domain/models/screening_domain_score.dart';
import '../../domain/models/screening_response.dart';
import '../local/database.dart';

/// Lưu và truy vấn kết quả sàng lọc trên bảng `screenings`, `screening_responses`,
/// và `screening_domain_scores`.
class ScreeningRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ScreeningRepository(this._db);

  /// Lưu 1 bản ghi sàng lọc cơ bản (backward compatibility).
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

  /// Lưu 1 lần làm bài sàng lọc hoàn chỉnh trong 1 transaction:
  /// - 1 bản ghi vào `screenings`
  /// - các bản ghi chi tiết câu trả lời vào `screening_responses` (50 câu)
  /// - các bản ghi điểm từng lĩnh vực vào `screening_domain_scores` (7 lĩnh vực)
  Future<Screening> saveScreeningSession({
    required String childId,
    required String toolName,
    required String score,
    required String resultSummary,
    required DateTime performedAt,
    required List<({String cauHoiId, String linhVuc, String giaTri})> responses,
    required List<({
      String linhVuc,
      int soCauThietKe,
      int soCauHopLe,
      int diemTho,
      double? diemPhanTram,
    })> domainScores,
  }) async {
    final now = DateTime.now();
    final screening = Screening(
      id: _uuid.v4(),
      childId: childId,
      toolName: toolName,
      score: score,
      resultSummary: resultSummary,
      performedAt: performedAt,
      createdAt: now,
    );

    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('screenings', _toRow(screening));

      for (final r in responses) {
        await txn.insert('screening_responses', {
          'id': _uuid.v4(),
          'screening_id': screening.id,
          'cau_hoi_id': r.cauHoiId,
          'linh_vuc': r.linhVuc,
          'gia_tri': r.giaTri,
          'created_at': now.toIso8601String(),
        });
      }

      for (final d in domainScores) {
        await txn.insert('screening_domain_scores', {
          'id': _uuid.v4(),
          'screening_id': screening.id,
          'linh_vuc': d.linhVuc,
          'so_cau_thiet_ke': d.soCauThietKe,
          'so_cau_hop_le': d.soCauHopLe,
          'diem_tho': d.diemTho,
          'diem_phan_tram': d.diemPhanTram,
          'created_at': now.toIso8601String(),
        });
      }
    });

    return screening;
  }

  Future<List<Screening>> getForChild(String childId) async {
    return getScreeningsByChildId(childId);
  }

  /// Trả về danh sách các lần sàng lọc của ĐÚNG child_id truyền vào,
  /// sắp xếp mới nhất trước, lọc trực tiếp bằng SQL `WHERE child_id = ?`.
  Future<List<Screening>> getScreeningsByChildId(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screenings',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'performed_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Lấy 1 bản ghi sàng lọc theo ID cụ thể.
  Future<Screening?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'screenings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
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

  Future<List<ScreeningResponse>> getResponses(String screeningId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_responses',
      where: 'screening_id = ?',
      whereArgs: [screeningId],
      orderBy: 'cau_hoi_id ASC',
    );
    return rows
        .map(
          (row) => ScreeningResponse(
            id: row['id'] as String,
            screeningId: row['screening_id'] as String,
            cauHoiId: row['cau_hoi_id'] as String,
            linhVuc: row['linh_vuc'] as String,
            giaTri: row['gia_tri'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<List<ScreeningDomainScore>> getDomainScores(String screeningId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_domain_scores',
      where: 'screening_id = ?',
      whereArgs: [screeningId],
    );
    return rows
        .map(
          (row) => ScreeningDomainScore(
            id: row['id'] as String,
            screeningId: row['screening_id'] as String,
            linhVuc: row['linh_vuc'] as String,
            soCauThietKe: row['so_cau_thiet_ke'] as int,
            soCauHopLe: row['so_cau_hop_le'] as int,
            diemTho: row['diem_tho'] as int,
            diemPhanTram: (row['diem_phan_tram'] as num?)?.toDouble(),
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  /// Đúng nguyên tắc đã chốt trong roadmap: không có dòng nào cho child_id
  /// tương ứng chính là tín hiệu "chưa sàng lọc" — không dùng cột trạng
  /// thái riêng.
  Future<bool> hasScreening(String childId) async {
    final db = await _db.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM screenings WHERE child_id = ?', [
        childId,
      ]),
    );
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
