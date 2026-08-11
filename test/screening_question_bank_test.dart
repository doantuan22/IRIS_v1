import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/services/screening_question_bank.dart';

/// Chức năng #3 roadmap — "Xác định hướng đánh giá theo độ tuổi": xác nhận
/// [selectScreeningQuestionSet] chọn đúng bộ câu hỏi sàng lọc mock theo dải
/// tuổi (đơn vị tháng), không còn dùng cứng 1 bộ cho mọi độ tuổi.
void main() {
  test('selectScreeningQuestionSet: trẻ 20 tháng (trong dải 16-30 tháng) → Bộ A', () {
    final set = selectScreeningQuestionSet(20);
    expect(set.label, screeningQuestionSetA.label);
    expect(set.questions, screeningQuestionSetA.questions);
    expect(set.questions.length, 6);
    // ignore: avoid_print
    print('PASS: 20 tháng → ${set.label}');
  });

  test('selectScreeningQuestionSet: trẻ 36 tháng (trên 30 tháng) → Bộ B', () {
    final set = selectScreeningQuestionSet(36);
    expect(set.label, screeningQuestionSetB.label);
    expect(set.questions, screeningQuestionSetB.questions);
    expect(set.questions.length, 6);
    // ignore: avoid_print
    print('PASS: 36 tháng → ${set.label}');
  });

  test('selectScreeningQuestionSet: ranh giới đúng 30 tháng → vẫn Bộ A, 31 tháng → Bộ B', () {
    expect(selectScreeningQuestionSet(30).label, screeningQuestionSetA.label);
    expect(selectScreeningQuestionSet(31).label, screeningQuestionSetB.label);
    // ignore: avoid_print
    print('PASS: ranh giới 30/31 tháng phân nhánh đúng giữa Bộ A và Bộ B');
  });

  test('selectScreeningQuestionSet: hai bộ câu hỏi khác nội dung nhau', () {
    expect(screeningQuestionSetA.questions, isNot(equals(screeningQuestionSetB.questions)));
    // ignore: avoid_print
    print('PASS: Bộ A và Bộ B có nội dung câu hỏi khác nhau');
  });
}
