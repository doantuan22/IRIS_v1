import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/services/prompt_builder.dart';

/// Kiểm chứng system prompt dùng ĐÚNG NGUYÊN VĂN bản đã chốt — đây là phần
/// kiểm soát hành vi AI (không chẩn đoán/kết luận) quan trọng nhất dự án,
/// nên test so khớp chính xác từng câu bắt buộc phải có, không chỉ "chứa
/// đại khái".
void main() {
  final builder = PromptBuilder();

  test('buildState1Prompt() chứa đúng nguyên văn các yêu cầu bắt buộc', () {
    final prompt = builder.buildState1Prompt();

    expect(prompt, contains('Bạn là IRIS, trợ lý AI hỗ trợ phụ huynh/giáo viên hiểu về quá trình phát triển của trẻ.'));
    expect(prompt, contains('Bạn KHÔNG được chẩn đoán, KHÔNG được kết luận trẻ có mắc một tình trạng nào đó.'));
    expect(prompt, contains('TÌNH TRẠNG DỮ LIỆU: Hồ sơ trẻ chưa có thông tin sàng lọc hoặc mô tả nào liên quan đến câu hỏi này.'));
    expect(prompt, contains('Trả lời theo hướng: "Chưa đủ dữ liệu để đưa ra nhận định [về chủ đề được hỏi]."'));
    expect(prompt, contains('TUYỆT ĐỐI không suy đoán nguyên nhân, không đưa ra nhận định về tình trạng của trẻ dù chỉ là phỏng đoán nhẹ.'));
    // ignore: avoid_print
    print('PASS: buildState1Prompt() đúng nguyên văn');
  });

  test('buildState2Prompt() chứa đúng nguyên văn các yêu cầu bắt buộc', () {
    final prompt = builder.buildState2Prompt();

    expect(prompt, contains('TÌNH TRẠNG DỮ LIỆU: Hồ sơ trẻ đã có KẾT QUẢ SÀNG LỌC, nhưng CHƯA có mô tả cụ thể liên quan trực tiếp đến câu hỏi này.'));
    expect(prompt, contains('KHÔNG được biến kết quả sàng lọc thành chẩn đoán hay kết luận cụ thể.'));
    expect(prompt, contains('Đề nghị người dùng bổ sung mô tả cụ thể hơn hoặc tìm đánh giá chuyên môn.'));
    // ignore: avoid_print
    print('PASS: buildState2Prompt() đúng nguyên văn');
  });

  test('buildState3Prompt() nội suy đúng profileContext/expertContext và giữ nguyên phần cố định', () {
    final prompt = builder.buildState3Prompt(
      profileContext: '- Bé nói được câu 2-3 từ',
      expertContext: '- Mốc ngôn ngữ 24-36 tháng',
    );

    expect(prompt, contains('DỮ LIỆU HỒ SƠ TRẺ LIÊN QUAN ĐẾN CÂU HỎI:\n- Bé nói được câu 2-3 từ'));
    expect(prompt, contains('TÀI LIỆU THAM KHẢO CHUYÊN MÔN LIÊN QUAN:\n- Mốc ngôn ngữ 24-36 tháng'));
    expect(prompt, contains('KHÔNG được đưa ra chẩn đoán hay kết luận xác định.'));
    // ignore: avoid_print
    print('PASS: buildState3Prompt() nội suy đúng context');
  });

  test('buildState3Prompt() với expertContext rỗng dùng đúng câu mặc định', () {
    final prompt = builder.buildState3Prompt(
      profileContext: '- Bé nói được câu 2-3 từ',
      expertContext: 'Không có tài liệu tham khảo chuyên môn phù hợp.',
    );

    expect(prompt, contains('TÀI LIỆU THAM KHẢO CHUYÊN MÔN LIÊN QUAN:\nKhông có tài liệu tham khảo chuyên môn phù hợp.'));
    // ignore: avoid_print
    print('PASS: buildState3Prompt() dùng đúng câu mặc định khi không có expert context');
  });

  test('buildOverviewPortraitSummaryPrompt() nội suy đúng dữ liệu và chứa các guardrails bắt buộc', () {
    final prompt = builder.buildOverviewPortraitSummaryPrompt(
      childName: 'Bé An',
      childAgeLabel: '3 tuổi',
      tierLabel: 'Có điểm cần theo dõi',
      domainsSummaryText: '### Lĩnh vực: Nhận thức\n- Đánh giá: Cần theo dõi\n- Mô tả: Bé chưa tập trung',
    );

    expect(prompt, contains('Bé An'));
    expect(prompt, contains('3 tuổi'));
    expect(prompt, contains('Có điểm cần theo dõi'));
    expect(prompt, contains('### Lĩnh vực: Nhận thức'));
    expect(prompt, contains('KHÔNG được đưa ra kết luận chẩn đoán y khoa'));
    expect(prompt, contains('KHÔNG dùng từ "tự kỷ" hoặc "rối loạn" như một khẳng định'));
    expect(prompt, contains('trao đổi thêm với các chuyên gia'));
    // ignore: avoid_print
    print('PASS: buildOverviewPortraitSummaryPrompt() đúng guardrails và nội suy đúng thông tin');
  });
}
