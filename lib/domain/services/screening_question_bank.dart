/// Bộ câu hỏi sàng lọc MOCK (demo) — chưa phải bộ công cụ chuẩn thật (VD
/// M-CHAT-R/F) — phân nhánh theo dải tuổi trẻ (Chức năng #3 roadmap: "Xác
/// định hướng đánh giá theo độ tuổi"). Mốc 30 tháng tham khảo ranh giới độ
/// tuổi khuyến nghị của M-CHAT-R/F (16–30 tháng) trong mockup UI gốc.
class ScreeningQuestionSet {
  final String label;
  final List<String> questions;

  const ScreeningQuestionSet({required this.label, required this.questions});
}

const List<String> _mockQuestionsA = [
  'Trẻ có tránh giao tiếp bằng mắt khi được gọi tên không?',
  'Trẻ có ít khi chỉ tay vào đồ vật để chia sẻ sự thích thú không?',
  'Trẻ có lặp đi lặp lại một số hành động hoặc từ ngữ không?',
  'Trẻ có phản ứng bất thường với âm thanh (quá nhạy hoặc không phản ứng) không?',
  'Trẻ có khó thích nghi khi thay đổi thói quen hàng ngày không?',
  'Trẻ có ít chơi giả vờ (VD: giả vờ nấu ăn, chăm búp bê) so với bạn cùng tuổi không?',
];

const List<String> _mockQuestionsB = [
  'Trẻ có gặp khó khăn khi chơi cùng bạn bè cùng tuổi không?',
  'Trẻ có khó hiểu hoặc làm theo yêu cầu gồm 2 bước không (VD "lấy giày rồi để lên kệ")?',
  'Trẻ có ít dùng câu từ 3 từ trở lên để giao tiếp không?',
  'Trẻ có phản ứng mạnh khi phải chuyển đổi giữa các hoạt động không?',
  'Trẻ có ít tham gia trò chơi tưởng tượng cùng bạn (VD đóng vai) không?',
  'Trẻ có gặp khó khăn khi tự thực hiện sinh hoạt cá nhân cơ bản so với bạn cùng tuổi không (VD tự xúc ăn, tự mặc áo đơn giản)?',
];

const ScreeningQuestionSet screeningQuestionSetA = ScreeningQuestionSet(
  label: 'Bộ A (16–30 tháng)',
  questions: _mockQuestionsA,
);

const ScreeningQuestionSet screeningQuestionSetB = ScreeningQuestionSet(
  label: 'Bộ B (31 tháng trở lên)',
  questions: _mockQuestionsB,
);

/// Chọn bộ câu hỏi sàng lọc mock phù hợp theo tuổi trẻ (đơn vị THÁNG — dùng
/// chung [childAgeInMonths] đã có sẵn, không viết hàm quy đổi tuổi mới).
ScreeningQuestionSet selectScreeningQuestionSet(int ageMonths) {
  return ageMonths <= 30 ? screeningQuestionSetA : screeningQuestionSetB;
}
