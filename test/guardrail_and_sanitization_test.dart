import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/models/profile_chunk.dart';
import 'package:iris_app/data/repositories/ai_repository.dart';
import 'package:iris_app/domain/models/scored_chunk.dart';
import 'package:iris_app/domain/services/guardrail_service.dart';
import 'package:iris_app/domain/services/prompt_builder.dart';

void main() {
  group('GuardrailService & Domain Filter Tests', () {
    final guardrailService = GuardrailService();

    test('relevanceThreshold phải bằng đúng 0.72 theo chuẩn an toàn', () {
      expect(GuardrailService.relevanceThreshold, equals(0.72));
    });

    test('isChildDevelopmentQuery: phân biệt chính xác domain trẻ em vs ngoài domain (Word Boundary)', () {
      // Các câu hỏi trong domain trẻ em
      expect(GuardrailService.isChildDevelopmentQuery('Bé 3 tuổi chưa nói được từ nào'), isTrue);
      expect(GuardrailService.isChildDevelopmentQuery('Con tôi có hay bịt tai khi nghe tiếng ồn không?'), isTrue);
      expect(GuardrailService.isChildDevelopmentQuery('Khả năng phát triển ngôn ngữ của trẻ ra sao?'), isTrue);
      expect(GuardrailService.isChildDevelopmentQuery('Bé đi nhón gót và khó ngủ ban đêm'), isTrue);

      // Các câu hỏi ngoài domain (bao gồm outlier Giá xăng dầu và các từ con)
      expect(GuardrailService.isChildDevelopmentQuery('Giá xăng dầu trong nước hiện tại là bao nhiêu?'), isFalse);
      expect(GuardrailService.isChildDevelopmentQuery('Hôm nay thời tiết ở Hà Nội thế nào?'), isFalse);
      expect(GuardrailService.isChildDevelopmentQuery('Thủ đô của nước Pháp là thành phố nào?'), isFalse);
      expect(GuardrailService.isChildDevelopmentQuery('Làm thế nào để học lập trình Flutter hiệu quả?'), isFalse);
    });

    test('determineState: Outlier ngoài domain phải lập tức rơi vào Trạng thái 1 (insufficientData)', () {
      // Dù có chunk điểm cao giả lập 0.85
      final dummyChunk = ScoredProfileChunk(
        chunk: ProfileChunk(
          id: 'chunk-1',
          childId: 'child-1',
          linhVuc: 'sinh_hoc',
          content: 'Bé khó ngủ và đi nhón gót',
          nguon: 'phu_huynh',
          createdAt: DateTime.now(),
          embedding: const [],
        ),
        similarity: 0.85, // Giả lập similarity cao
      );

      final result = guardrailService.determineState(
        retrievedProfileChunks: [dummyChunk],
        hasScreeningResult: false,
        userQuestion: 'Giá xăng dầu trong nước hiện tại là bao nhiêu?',
      );

      expect(result.state, equals(AiState.insufficientData));
      expect(result.groundingChunks, isEmpty);
    });

    test('determineState: Câu hỏi trong domain với similarity >= 0.72 chuyển sang Trạng thái 3', () {
      final relevantChunk = ScoredProfileChunk(
        chunk: ProfileChunk(
          id: 'chunk-2',
          childId: 'child-1',
          linhVuc: 'ngon_ngu',
          content: 'Bé chưa nói được từ đơn có nghĩa',
          nguon: 'phu_huynh',
          createdAt: DateTime.now(),
          embedding: const [],
        ),
        similarity: 0.7358,
      );

      final result = guardrailService.determineState(
        retrievedProfileChunks: [relevantChunk],
        hasScreeningResult: false,
        userQuestion: 'Bé 3 tuổi chưa nói được từ nào thì có sao không?',
      );

      expect(result.state, equals(AiState.hasProfessionalAssessment));
      expect(result.groundingChunks.length, equals(1));
    });

    test('determineState: Câu hỏi trong domain với similarity < 0.72 rơi vào Trạng thái 1 an toàn', () {
      final weakChunk = ScoredProfileChunk(
        chunk: ProfileChunk(
          id: 'chunk-3',
          childId: 'child-1',
          linhVuc: 'cam_xuc',
          content: 'Bé hay cáu gắt',
          nguon: 'phu_huynh',
          createdAt: DateTime.now(),
          embedding: const [],
        ),
        similarity: 0.7108, // Kẹo ngọt < 0.72
      );

      final result = guardrailService.determineState(
        retrievedProfileChunks: [weakChunk],
        hasScreeningResult: false,
        userQuestion: 'Con tôi thích ăn loại kẹo ngọt và đồ uống gì nhất?',
      );

      expect(result.state, equals(AiState.insufficientData));
      expect(result.groundingChunks, isEmpty);
    });
  });

  group('AiRepository.sanitizeAiAnswer Tests (Làm sạch Markdown)', () {
    test('Xóa sạch dấu in đậm **, in nghiêng *, tiêu đề #, gạch đầu dòng -, và bảng biểu |', () {
      const rawMarkdown = '''
### Đánh giá khả năng ngôn ngữ của bé

Dưới đây là một số quan sát:
- **Khả năng nói**: Bé chưa có từ đơn có nghĩa; chỉ phát âm *ê a* vô nghĩa.
- **Tương tác**: Bé ít nhìn mắt người khác khi trò chuyện.

| Tiêu chí | Đánh giá |
|---|---|
| Từ vựng | Chưa đạt chuẩn |
| Phản xạ | Nhại lời vô thức |

> Lưu ý: Phụ huynh nên quan sát thêm và quay video khi cần.
''';

      final clean = AiRepository.sanitizeAiAnswer(rawMarkdown);

      expect(clean.contains('**'), isFalse);
      expect(clean.contains('###'), isFalse);
      expect(clean.contains('|---|'), isFalse);
      expect(clean.contains('- '), isFalse);
      expect(clean.contains('>'), isFalse);
      expect(clean.contains('Khả năng nói: Bé chưa có từ đơn có nghĩa; chỉ phát âm ê a vô nghĩa.'), isTrue);
      expect(clean.contains('Tương tác: Bé ít nhìn mắt người khác khi trò chuyện.'), isTrue);
    });
  });

  group('PromptBuilder Prompts Tests', () {
    final builder = PromptBuilder();

    test('Tất cả 3 state prompts đều có chỉ dẫn cấm markdown và yêu cầu văn xuôi tự nhiên', () {
      final p1 = builder.buildState1Prompt();
      final p2 = builder.buildState2Prompt();
      final p3 = builder.buildState3Prompt(
        profileContext: 'Mô tả bé',
        expertContext: 'Tài liệu tham khảo',
      );

      for (final p in [p1, p2, p3]) {
        expect(p.contains('VĂN XUÔI TỰ NHIÊN'), isTrue);
        expect(p.contains('KHÔNG dùng bất kỳ cú pháp Markdown'), isTrue);
        expect(p.contains('100 đến 180 từ'), isTrue);
      }
    });
  });
}
