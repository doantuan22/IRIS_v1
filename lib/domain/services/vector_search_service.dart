import '../models/ai_chunk.dart';

/// Vector search thuần Dart bằng cosine similarity — không cần extension
/// vector cho SQLite ở quy mô dữ liệu nhỏ của dự án này.
class VectorSearchService {
  double cosineSimilarity(List<double> a, List<double> b) {
    throw UnimplementedError('TODO: tính cosine similarity giữa 2 vector');
  }

  List<AiChunk> topK(List<AiChunk> chunks, List<double> queryEmbedding, int k) {
    throw UnimplementedError('TODO: sắp xếp chunks theo cosine similarity giảm dần, lấy k phần tử đầu');
  }
}
