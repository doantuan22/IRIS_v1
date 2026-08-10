import '../local/database.dart';

/// Lưu và truy vấn video quay tình huống trên bảng `videos`. File video lưu
/// local qua `path_provider`; bảng này chỉ lưu metadata + đường dẫn.
class VideoRepository {
  final AppDatabase _db;

  VideoRepository(this._db);

  Future<void> save({
    required String childId,
    required String filePath,
    String? situation,
  }) async {
    throw UnimplementedError('TODO: INSERT INTO videos');
  }
}
