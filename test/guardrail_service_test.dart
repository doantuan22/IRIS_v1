import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/models/profile_chunk.dart';
import 'package:iris_app/domain/models/scored_chunk.dart';
import 'package:iris_app/domain/services/guardrail_service.dart';

ProfileChunk _fakeChunk({String? nguon}) => ProfileChunk(
      id: 'id',
      childId: 'child-1',
      content: 'nội dung mẫu',
      nguon: nguon,
      embedding: const [0.1, 0.2],
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final service = GuardrailService();

  test('Trạng thái 1: không có chunk liên quan + chưa sàng lọc', () {
    final result = service.determineState(
      retrievedProfileChunks: const [],
      hasScreeningResult: false,
    );

    expect(result.state, AiState.insufficientData);
    expect(result.groundingChunks, isEmpty);
    // ignore: avoid_print
    print('PASS: Trạng thái 1 (insufficientData) khi không có chunk + chưa sàng lọc');
  });

  test('Trạng thái 2: chưa có mô tả liên quan nhưng đã có sàng lọc', () {
    final result = service.determineState(
      retrievedProfileChunks: const [],
      hasScreeningResult: true,
    );

    expect(result.state, AiState.hasScreening);
    // ignore: avoid_print
    print('PASS: Trạng thái 2 (hasScreening) khi đã sàng lọc nhưng chưa có mô tả liên quan');
  });

  test('Trạng thái 3: có chunk liên quan (similarity >= ngưỡng) từ phụ huynh/giáo viên/chuyên gia', () {
    final relevantChunk = ScoredProfileChunk(
      chunk: _fakeChunk(nguon: 'phu_huynh'),
      similarity: 0.9,
    );

    final result = service.determineState(
      retrievedProfileChunks: [relevantChunk],
      hasScreeningResult: false,
    );

    expect(result.state, AiState.hasProfessionalAssessment);
    expect(result.groundingChunks, [relevantChunk]);
    // ignore: avoid_print
    print('PASS: Trạng thái 3 (hasProfessionalAssessment) khi có chunk liên quan từ nguồn hợp lệ');
  });

  test('Case biên: có chunk nhưng similarity dưới ngưỡng => KHÔNG lên Trạng thái 3, rơi về 1 hoặc 2 tuỳ hasScreeningResult', () {
    final belowThresholdChunk = ScoredProfileChunk(
      chunk: _fakeChunk(nguon: 'phu_huynh'),
      similarity: GuardrailService.relevanceThreshold - 0.01,
    );

    final resultWithoutScreening = service.determineState(
      retrievedProfileChunks: [belowThresholdChunk],
      hasScreeningResult: false,
    );
    expect(resultWithoutScreening.state, AiState.insufficientData);

    final resultWithScreening = service.determineState(
      retrievedProfileChunks: [belowThresholdChunk],
      hasScreeningResult: true,
    );
    expect(resultWithScreening.state, AiState.hasScreening);
    // ignore: avoid_print
    print('PASS: chunk dưới ngưỡng similarity không kích hoạt Trạng thái 3, rơi đúng về 1/2 tuỳ hasScreeningResult');
  });

  test('Case biên: chunk similarity đủ cao nhưng nguồn không hợp lệ (VD null) => không lên Trạng thái 3', () {
    final chunkFromUnknownSource = ScoredProfileChunk(
      chunk: _fakeChunk(nguon: null),
      similarity: 0.95,
    );

    final result = service.determineState(
      retrievedProfileChunks: [chunkFromUnknownSource],
      hasScreeningResult: true,
    );

    expect(result.state, AiState.hasScreening);
    // ignore: avoid_print
    print('PASS: chunk similarity cao nhưng nguon không hợp lệ không kích hoạt Trạng thái 3');
  });
}
