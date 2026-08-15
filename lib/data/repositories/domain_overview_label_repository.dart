import 'package:uuid/uuid.dart';

import '../../domain/models/domain_overview_label.dart';
import '../local/database.dart';

/// Lưu và truy vấn nhãn tổng quan từng lĩnh vực (`domain_overview_labels`).
/// [save] luôn INSERT dòng MỚI (lịch sử theo `computed_at`), không UPDATE
/// đè — "nhãn hiện hành" của 1 lĩnh vực là dòng mới nhất, xem
/// [getLatestForChild].
class DomainOverviewLabelRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DomainOverviewLabelRepository(this._db);

  Future<DomainOverviewLabel> save({
    required String childId,
    required String linhVuc,
    required String nhan,
    String? lyDoNganGon,
  }) async {
    final label = DomainOverviewLabel(
      id: _uuid.v4(),
      childId: childId,
      linhVuc: linhVuc,
      nhan: nhan,
      lyDoNganGon: lyDoNganGon,
      computedAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('domain_overview_labels', _toRow(label));
    return label;
  }

  /// Nhãn MỚI NHẤT (theo `computed_at`) cho MỖI lĩnh vực đã từng gắn nhãn
  /// của [childId] — key là `linh_vuc`. Lĩnh vực chưa từng gắn nhãn lần nào
  /// sẽ không xuất hiện trong map trả về (không có giá trị mặc định).
  Future<Map<String, DomainOverviewLabel>> getLatestForChild(
    String childId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'domain_overview_labels',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'computed_at DESC',
    );
    final latest = <String, DomainOverviewLabel>{};
    for (final row in rows) {
      final label = _fromRow(row);
      // Đã sort computed_at DESC — dòng đầu tiên gặp cho mỗi linh_vuc chính
      // là dòng mới nhất, các dòng cũ hơn cùng linh_vuc bị bỏ qua.
      latest.putIfAbsent(label.linhVuc, () => label);
    }
    return latest;
  }

  Map<String, Object?> _toRow(DomainOverviewLabel label) => {
    'id': label.id,
    'child_id': label.childId,
    'linh_vuc': label.linhVuc,
    'nhan': label.nhan,
    'ly_do_ngan_gon': label.lyDoNganGon,
    'computed_at': label.computedAt.toIso8601String(),
  };

  DomainOverviewLabel _fromRow(Map<String, Object?> row) => DomainOverviewLabel(
    id: row['id'] as String,
    childId: row['child_id'] as String,
    linhVuc: row['linh_vuc'] as String,
    nhan: row['nhan'] as String,
    lyDoNganGon: row['ly_do_ngan_gon'] as String?,
    computedAt: DateTime.parse(row['computed_at'] as String),
  );
}
