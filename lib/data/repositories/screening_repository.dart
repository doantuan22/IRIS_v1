import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/screening_answer.dart';
import '../../domain/models/screening_domain_result.dart';
import '../../domain/models/screening_session.dart';
import '../local/database.dart';

/// Lưu và truy vấn kết quả sàng lọc trên bảng `screening_sessions`,
/// `screening_domain_results`, và `screening_answers` (bộ sàng lọc mới —
/// 4 mức tuổi × 20 câu × 5 lĩnh vực).
class ScreeningRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ScreeningRepository(this._db);

  /// Lưu 1 lần làm bài sàng lọc hoàn chỉnh trong 1 transaction:
  /// - 1 bản ghi vào `screening_sessions`
  /// - các bản ghi chi tiết câu trả lời vào `screening_answers` (20 câu)
  /// - các bản ghi điểm từng lĩnh vực vào `screening_domain_results` (5 lĩnh vực)
  Future<ScreeningSession> saveScreeningSession({
    required String childId,
    required String mucTuoiLamBai,
    required double? tongDiem60,
    required String giaiDoan,
    required bool coCanhBao,
    required DateTime ngayThucHien,
    required List<
      ({
        String cauHoiId,
        String linhVuc,
        String? nhomVanDong,
        int? diem,
        bool laNa,
      })
    >
    answers,
    required List<
      ({
        String linhVuc,
        int diemTho,
        int soCauTraLoi,
        int soCauNa,
        double? diemQuyDoi12,
        String mucLinhVuc,
      })
    >
    domainResults,
  }) async {
    final now = DateTime.now();
    final session = ScreeningSession(
      id: _uuid.v4(),
      childId: childId,
      mucTuoiLamBai: mucTuoiLamBai,
      tongDiem60: tongDiem60,
      giaiDoan: giaiDoan,
      coCanhBao: coCanhBao,
      ngayThucHien: ngayThucHien,
      createdAt: now,
    );

    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('screening_sessions', _sessionToRow(session));

      for (final a in answers) {
        await txn.insert('screening_answers', {
          'id': _uuid.v4(),
          'screening_id': session.id,
          'child_id': childId,
          'muc_tuoi_lam_bai': mucTuoiLamBai,
          'cau_hoi_id': a.cauHoiId,
          'linh_vuc': a.linhVuc,
          'nhom_van_dong': a.nhomVanDong,
          'diem': a.diem,
          'la_na': a.laNa ? 1 : 0,
          'created_at': now.toIso8601String(),
        });
      }

      for (final d in domainResults) {
        await txn.insert('screening_domain_results', {
          'id': _uuid.v4(),
          'screening_id': session.id,
          'child_id': childId,
          'linh_vuc': d.linhVuc,
          'diem_tho': d.diemTho,
          'so_cau_tra_loi': d.soCauTraLoi,
          'so_cau_na': d.soCauNa,
          'diem_quy_doi_12': d.diemQuyDoi12,
          'muc_linh_vuc': d.mucLinhVuc,
          'created_at': now.toIso8601String(),
        });
      }
    });

    return session;
  }

  Future<List<ScreeningSession>> getForChild(String childId) async {
    return getSessionsByChildId(childId);
  }

  /// Trả về danh sách các lần sàng lọc của ĐÚNG child_id truyền vào,
  /// sắp xếp mới nhất trước, lọc trực tiếp bằng SQL `WHERE child_id = ?`.
  Future<List<ScreeningSession>> getSessionsByChildId(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_sessions',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'ngay_thuc_hien DESC',
    );
    return rows.map(_sessionFromRow).toList();
  }

  /// Lấy 1 bản ghi sàng lọc theo ID cụ thể.
  Future<ScreeningSession?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _sessionFromRow(rows.first);
  }

  Future<ScreeningSession?> getLatestForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_sessions',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'ngay_thuc_hien DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _sessionFromRow(rows.first);
  }

  Future<List<ScreeningAnswer>> getAnswers(String screeningId) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_answers',
      where: 'screening_id = ?',
      whereArgs: [screeningId],
      orderBy: 'cau_hoi_id ASC',
    );
    return rows.map(_answerFromRow).toList();
  }

  Future<List<ScreeningDomainResult>> getDomainResults(
    String screeningId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'screening_domain_results',
      where: 'screening_id = ?',
      whereArgs: [screeningId],
    );
    return rows.map(_domainResultFromRow).toList();
  }

  /// Đúng nguyên tắc đã chốt trong roadmap: không có dòng nào cho child_id
  /// tương ứng chính là tín hiệu "chưa sàng lọc" — không dùng cột trạng
  /// thái riêng.
  Future<bool> hasScreening(String childId) async {
    final db = await _db.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM screening_sessions WHERE child_id = ?',
        [childId],
      ),
    );
    return (result ?? 0) > 0;
  }

  Map<String, Object?> _sessionToRow(ScreeningSession s) => {
    'id': s.id,
    'child_id': s.childId,
    'muc_tuoi_lam_bai': s.mucTuoiLamBai,
    'tong_diem_60': s.tongDiem60,
    'giai_doan': s.giaiDoan,
    'co_canh_bao': s.coCanhBao ? 1 : 0,
    'ngay_thuc_hien': s.ngayThucHien.toIso8601String(),
    'created_at': s.createdAt.toIso8601String(),
  };

  ScreeningSession _sessionFromRow(Map<String, Object?> row) =>
      ScreeningSession(
        id: row['id'] as String,
        childId: row['child_id'] as String,
        mucTuoiLamBai: row['muc_tuoi_lam_bai'] as String,
        tongDiem60: (row['tong_diem_60'] as num?)?.toDouble(),
        giaiDoan: row['giai_doan'] as String,
        coCanhBao: (row['co_canh_bao'] as int) == 1,
        ngayThucHien: DateTime.parse(row['ngay_thuc_hien'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  ScreeningAnswer _answerFromRow(Map<String, Object?> row) => ScreeningAnswer(
    id: row['id'] as String,
    screeningId: row['screening_id'] as String,
    childId: row['child_id'] as String,
    mucTuoiLamBai: row['muc_tuoi_lam_bai'] as String,
    cauHoiId: row['cau_hoi_id'] as String,
    linhVuc: row['linh_vuc'] as String,
    nhomVanDong: row['nhom_van_dong'] as String?,
    diem: row['diem'] as int?,
    laNa: (row['la_na'] as int) == 1,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  ScreeningDomainResult _domainResultFromRow(Map<String, Object?> row) =>
      ScreeningDomainResult(
        id: row['id'] as String,
        screeningId: row['screening_id'] as String,
        childId: row['child_id'] as String,
        linhVuc: row['linh_vuc'] as String,
        diemTho: row['diem_tho'] as int,
        soCauTraLoi: row['so_cau_tra_loi'] as int,
        soCauNa: row['so_cau_na'] as int,
        diemQuyDoi12: (row['diem_quy_doi_12'] as num?)?.toDouble(),
        mucLinhVuc: row['muc_linh_vuc'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
