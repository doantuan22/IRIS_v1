import '../../domain/models/assessment.dart';
import '../local/database.dart';

/// Lưu và truy vấn dữ liệu đánh giá 9 lĩnh vực (chỉ dữ liệu riêng của trẻ)
/// trên bảng `assessments`.
class AssessmentRepository {
  final AppDatabase _db;

  AssessmentRepository(this._db);

  Future<List<Assessment>> getForChild(String childId, {String? linhVuc}) async {
    throw UnimplementedError('TODO: SELECT ... WHERE child_id = ? [AND linh_vuc = ?]');
  }

  Future<void> save(Assessment assessment) async {
    throw UnimplementedError('TODO: INSERT INTO assessments');
  }
}
