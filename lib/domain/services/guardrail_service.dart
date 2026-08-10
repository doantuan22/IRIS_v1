/// Guardrail (hàm Dart thuần) — xác định Trạng thái 1/2/3 cho hỏi đáp AI
/// dựa trên kết quả retrieval. Trạng thái được xác định bằng code, KHÔNG
/// giao cho LLM tự quyết định.
///
/// 1 — Chưa đủ thông tin: không có chunk profile liên quan + chưa có sàng lọc.
/// 2 — Có sàng lọc: có kết quả sàng lọc nhưng không có mô tả liên quan trực
///     tiếp câu hỏi.
/// 3 — Có đánh giá chuyên môn: có mô tả/nhận xét liên quan trực tiếp từ
///     phụ huynh/giáo viên/chuyên gia.
enum AiGuardrailState { insufficientData, hasScreening, hasProfileEvidence }

class GuardrailService {
  AiGuardrailState resolveState({
    required bool hasRelevantProfileChunk,
    required bool hasScreeningResult,
  }) {
    throw UnimplementedError('TODO: áp dụng đúng logic 3 trạng thái theo roadmap mục 3');
  }
}
