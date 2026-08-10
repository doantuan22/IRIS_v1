import '../../domain/models/child.dart';
import '../local/database.dart';

/// CRUD hồ sơ trẻ trên bảng `children`.
class ChildRepository {
  final AppDatabase _db;

  ChildRepository(this._db);

  Future<List<Child>> getAll() async {
    throw UnimplementedError('TODO: SELECT * FROM children');
  }

  Future<void> create(Child child) async {
    throw UnimplementedError('TODO: INSERT INTO children');
  }
}
