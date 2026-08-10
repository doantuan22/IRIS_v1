import '../../domain/models/screening.dart';
import '../local/database.dart';

/// Lưu và truy vấn kết quả sàng lọc trên bảng `screenings`. Không có bản ghi
/// nào cho một child_id nghĩa là trẻ đó chưa sàng lọc (không phải kết luận).
class ScreeningRepository {
  final AppDatabase _db;

  ScreeningRepository(this._db);

  Future<Screening?> getLatestForChild(String childId) async {
    throw UnimplementedError('TODO: SELECT ... WHERE child_id = ? ORDER BY performed_at DESC LIMIT 1');
  }

  Future<void> save(Screening screening) async {
    throw UnimplementedError('TODO: INSERT INTO screenings');
  }
}
