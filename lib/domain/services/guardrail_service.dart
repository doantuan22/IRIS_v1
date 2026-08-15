import '../models/scored_chunk.dart';

/// Guardrail (hàm Dart thuần) — xác định Trạng thái 1/2/3 cho hỏi đáp AI
/// dựa trên kết quả retrieval. Trạng thái được xác định bằng code, KHÔNG
/// giao cho LLM tự quyết định.
///
/// 1 — [insufficientData]: không có chunk profile liên quan + chưa có sàng lọc.
/// 2 — [hasScreening]: có kết quả sàng lọc nhưng không có mô tả liên quan
///     trực tiếp câu hỏi.
/// 3 — [hasProfessionalAssessment]: có mô tả/nhận xét liên quan trực tiếp từ
///     phụ huynh/giáo viên/chuyên gia.
enum AiState { insufficientData, hasScreening, hasProfessionalAssessment }

class GuardrailService {
  static const double relevanceThreshold = 0.75;

  ({AiState state, List<ScoredProfileChunk> groundingChunks}) determineState({
    required List<ScoredProfileChunk> retrievedProfileChunks,
    required bool hasScreeningResult,
  }) {
    final relevant = retrievedProfileChunks
        .where((c) => c.similarity >= relevanceThreshold)
        .toList();
    final hasRelevantDescription = relevant.any(
      (c) => ['phu_huynh', 'giao_vien', 'chuyen_gia'].contains(c.chunk.nguon),
    );
    if (hasRelevantDescription) {
      return (
        state: AiState.hasProfessionalAssessment,
        groundingChunks: relevant,
      );
    }
    if (hasScreeningResult) {
      return (
        state: AiState.hasScreening,
        groundingChunks: <ScoredProfileChunk>[],
      );
    }
    return (
      state: AiState.insufficientData,
      groundingChunks: <ScoredProfileChunk>[],
    );
  }
}
