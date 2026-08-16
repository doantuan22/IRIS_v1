import 'dart:math';

import '../../data/repositories/expert_knowledge_repository.dart';
import '../../data/repositories/profile_chunk_repository.dart';
import '../models/scored_chunk.dart';

/// Vector search thuần Dart bằng cosine similarity — không cần extension
/// vector cho SQLite ở quy mô dữ liệu nhỏ của dự án này.
class VectorSearchService {
  final ProfileChunkRepository _profileChunkRepository;
  final ExpertKnowledgeRepository _expertKnowledgeRepository;

  VectorSearchService(
    this._profileChunkRepository,
    this._expertKnowledgeRepository,
  );

  /// Trả 0 (coi như không liên quan) thay vì ném lỗi khi 2 vector khác chiều
  /// dài — dữ liệu embedding không đồng nhất/corrupt (VD đổi model embedding
  /// giữa các lần ingest) không được phép làm crash luồng hỏi đáp AI, đúng
  /// cách xử lý đã dùng cho trường hợp vector rỗng (`normA/normB == 0`) bên
  /// dưới.
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Lấy toàn bộ `profile_chunks` của [childId] (CHỈ mục "1. Mô tả biểu
  /// hiện" do người dùng nhập riêng cho trẻ này), tính similarity với
  /// [queryEmbedding], sắp xếp giảm dần, trả về [topK] chunk điểm cao nhất.
  Future<List<ScoredProfileChunk>> searchProfileChunks(
    String childId,
    List<double> queryEmbedding, {
    int topK = 8,
  }) async {
    final chunks = await _profileChunkRepository.getForChild(childId);
    final scored =
        chunks
            .map(
              (chunk) => ScoredProfileChunk(
                chunk: chunk,
                similarity: cosineSimilarity(chunk.embedding, queryEmbedding),
              ),
            )
            .toList()
          ..sort((a, b) => b.similarity.compareTo(a.similarity));
    return scored.take(topK).toList();
  }

  /// Lọc `expert_knowledge_chunks` theo độ tuổi TRƯỚC (`do_tuoi_thang_min
  /// <= ageMonths <= do_tuoi_thang_max`), rồi mới tính similarity trên tập
  /// đã lọc — [ageMonths] phải lấy qua `childAgeInMonths()`, không so trực
  /// tiếp `age_years`.
  Future<List<ScoredExpertChunk>> searchExpertChunks(
    int ageMonths,
    List<double> queryEmbedding, {
    int topK = 3,
  }) async {
    final chunks = await _expertKnowledgeRepository.query(
      ageInMonths: ageMonths,
      contentType: 'so_sanh',
    );
    final scored =
        chunks
            .map(
              (chunk) => ScoredExpertChunk(
                chunk: chunk,
                similarity: cosineSimilarity(chunk.embedding, queryEmbedding),
              ),
            )
            .toList()
          ..sort((a, b) => b.similarity.compareTo(a.similarity));
    return scored.take(topK).toList();
  }
}
