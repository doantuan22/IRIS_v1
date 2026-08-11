/// Model 1 lượt hỏi đáp AI, ánh xạ tới bảng `ai_conversations`. [state] là
/// Trạng thái 1/2/3 do `GuardrailService` xác định bằng code, lưu lại để có
/// thể xem lại lịch sử hỏi đáp đúng theo trạng thái đã dùng lúc trả lời.
class AiConversation {
  final String id;
  final String childId;
  final String question;
  final String answer;
  final int state;
  final DateTime createdAt;

  const AiConversation({
    required this.id,
    required this.childId,
    required this.question,
    required this.answer,
    required this.state,
    required this.createdAt,
  });
}
