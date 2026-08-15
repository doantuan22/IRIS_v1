import 'package:uuid/uuid.dart';

import '../../domain/models/overview_summary.dart';
import '../local/database.dart';

/// Lưu và truy vấn kết quả tổng hợp "Chân dung toàn cảnh" (`overview_summaries`).
/// [save] luôn INSERT dòng MỚI (lịch sử theo `computed_at`) — "kết quả hiện
/// hành" là dòng mới nhất, xem [getLatestForChild].
class OverviewSummaryRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  OverviewSummaryRepository(this._db);

  Future<OverviewSummary> save({
    required String childId,
    required String tier,
    required int soLinhVucCanTheoDoi,
    required int soLinhVucThieuDuLieu,
    String? moTaTongHop,
  }) async {
    final summary = OverviewSummary(
      id: _uuid.v4(),
      childId: childId,
      tier: tier,
      soLinhVucCanTheoDoi: soLinhVucCanTheoDoi,
      soLinhVucThieuDuLieu: soLinhVucThieuDuLieu,
      moTaTongHop: moTaTongHop,
      computedAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('overview_summaries', _toRow(summary));
    return summary;
  }

  /// Cập nhật đoạn mô tả tổng hợp cho bản ghi [id] đã có sẵn (dùng khi thử lại
  /// bước sinh mô tả bằng AI mà không cần tính lại tier).
  Future<void> updateMoTaTongHop(String id, String moTaTongHop) async {
    final db = await _db.database;
    await db.update(
      'overview_summaries',
      {'mo_ta_tong_hop': moTaTongHop},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Kết quả tổng hợp mới nhất của [childId], `null` nếu chưa từng tổng hợp
  /// thành công lần nào.
  Future<OverviewSummary?> getLatestForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'overview_summaries',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'computed_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Map<String, Object?> _toRow(OverviewSummary summary) => {
        'id': summary.id,
        'child_id': summary.childId,
        'tier': summary.tier,
        'so_linh_vuc_can_theo_doi': summary.soLinhVucCanTheoDoi,
        'so_linh_vuc_thieu_du_lieu': summary.soLinhVucThieuDuLieu,
        'mo_ta_tong_hop': summary.moTaTongHop,
        'computed_at': summary.computedAt.toIso8601String(),
      };

  OverviewSummary _fromRow(Map<String, Object?> row) => OverviewSummary(
        id: row['id'] as String,
        childId: row['child_id'] as String,
        tier: row['tier'] as String,
        soLinhVucCanTheoDoi: row['so_linh_vuc_can_theo_doi'] as int,
        soLinhVucThieuDuLieu: row['so_linh_vuc_thieu_du_lieu'] as int,
        moTaTongHop: row['mo_ta_tong_hop'] as String?,
        computedAt: DateTime.parse(row['computed_at'] as String),
      );
}
