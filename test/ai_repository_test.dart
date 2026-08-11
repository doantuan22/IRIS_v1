import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/remote/groq_api_client.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:iris_app/data/repositories/ai_conversation_repository.dart';
import 'package:iris_app/data/repositories/ai_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/profile_chunk_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:iris_app/domain/services/guardrail_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _fixedQueryEmbedding = [1.0, 0.0, 0.0];

/// MockClient trả cố định embedding (không gọi NVIDIA thật).
http.Client _nvidiaMockClient() => MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {'embedding': _fixedQueryEmbedding, 'index': 0},
          ],
        }),
        200,
      );
    });

/// MockClient Groq — ghi lại system prompt đã nhận được để assert, trả về
/// 1 câu trả lời cố định (không gọi Groq thật).
class _CapturingGroqMock {
  http.Request? lastRequest;

  http.Client get client => MockClient((request) async {
        lastRequest = request;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Câu trả lời mẫu (mock)'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
}

/// Test tích hợp AiRepository — xác nhận đúng pipeline: embed (NVIDIA giả)
/// → vector search local thật (sqflite ffi) → guardrail → đúng prompt →
/// Groq (giả) → lưu ai_conversations. Không gọi API AI thật.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('Trạng thái 1: chưa có mô tả liên quan + chưa sàng lọc', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé A', ageYears: 3);
    final groqMock = _CapturingGroqMock();

    final aiRepository = AiRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: _nvidiaMockClient()),
      groqApiClient: GroqApiClient(client: groqMock.client),
    );

    final result = await aiRepository.ask(child: child, question: 'Con tôi có chậm nói không?');

    expect(result.state, AiState.insufficientData);
    final systemPrompt = (jsonDecode(groqMock.lastRequest!.body) as Map<String, dynamic>)['messages'][0]['content'];
    expect(systemPrompt, contains('Chưa đủ dữ liệu để đưa ra nhận định'));

    final conversations = await AiConversationRepository(AppDatabase.instance).getForChild(child.id);
    expect(conversations.length, 1);
    expect(conversations.first.state, 1);
    // ignore: avoid_print
    print('PASS: Trạng thái 1 — đúng state, đúng prompt, đã lưu ai_conversations state=1');
  });

  test('Trạng thái 2: đã có sàng lọc nhưng chưa có mô tả liên quan', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé B', ageYears: 3);
    await ScreeningRepository(AppDatabase.instance).save(
      childId: child.id,
      toolName: 'Mock tool',
      score: '2/6',
      resultSummary: 'Kết quả tham khảo',
      performedAt: DateTime.now(),
    );
    final groqMock = _CapturingGroqMock();

    final aiRepository = AiRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: _nvidiaMockClient()),
      groqApiClient: GroqApiClient(client: groqMock.client),
    );

    final result = await aiRepository.ask(child: child, question: 'Con tôi có chậm nói không?');

    expect(result.state, AiState.hasScreening);
    final systemPrompt = (jsonDecode(groqMock.lastRequest!.body) as Map<String, dynamic>)['messages'][0]['content'];
    expect(systemPrompt, contains('KẾT QUẢ SÀNG LỌC'));

    final conversations = await AiConversationRepository(AppDatabase.instance).getForChild(child.id);
    expect(conversations.single.state, 2);
    // ignore: avoid_print
    print('PASS: Trạng thái 2 — đúng state, đúng prompt, đã lưu ai_conversations state=2');
  });

  test('Trạng thái 3: có mô tả liên quan trực tiếp từ phụ huynh', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé C', ageYears: 3);

    // Embedding TRÙNG với query embedding => similarity = 1.0 >= ngưỡng 0.75.
    await ProfileChunkRepository(AppDatabase.instance).add(
      childId: child.id,
      content: 'Bé nói được câu 2-3 từ, hay lặp lại lời người lớn',
      linhVuc: 'ngon_ngu',
      nguon: 'phu_huynh',
      embedding: _fixedQueryEmbedding,
    );
    await ExpertKnowledgeRepository(AppDatabase.instance).add(
      content: 'Mốc ngôn ngữ tham khảo 24-48 tháng',
      contentType: 'so_sanh',
      linhVuc: 'ngon_ngu',
      doTuoiThangMin: 24,
      doTuoiThangMax: 48,
      embedding: const [0.9, 0.1, 0.0],
    );

    final groqMock = _CapturingGroqMock();
    final aiRepository = AiRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: _nvidiaMockClient()),
      groqApiClient: GroqApiClient(client: groqMock.client),
    );

    final result = await aiRepository.ask(child: child, question: 'Con tôi nói chuyện thế có bình thường không?');

    expect(result.state, AiState.hasProfessionalAssessment);
    final systemPrompt = (jsonDecode(groqMock.lastRequest!.body) as Map<String, dynamic>)['messages'][0]['content'] as String;
    expect(systemPrompt, contains('DỮ LIỆU HỒ SƠ TRẺ LIÊN QUAN ĐẾN CÂU HỎI:'));
    expect(systemPrompt, contains('Bé nói được câu 2-3 từ'));
    expect(systemPrompt, contains('Mốc ngôn ngữ tham khảo 24-48 tháng'));

    final conversations = await AiConversationRepository(AppDatabase.instance).getForChild(child.id);
    expect(conversations.single.state, 3);
    // ignore: avoid_print
    print('PASS: Trạng thái 3 — đúng state, prompt chứa đúng profileContext + expertContext, đã lưu state=3');
  });

  test('Trạng thái 3 nhưng không có expert chunk phù hợp độ tuổi => dùng câu mặc định', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé D', ageYears: 3);

    await ProfileChunkRepository(AppDatabase.instance).add(
      childId: child.id,
      content: 'Ghi chú case-specific từ chuyên gia sau khi xem video',
      nguon: 'chuyen_gia',
      embedding: _fixedQueryEmbedding,
    );
    // Không thêm expert_knowledge_chunks nào phù hợp độ tuổi 36 tháng của Bé D.

    final groqMock = _CapturingGroqMock();
    final aiRepository = AiRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: _nvidiaMockClient()),
      groqApiClient: GroqApiClient(client: groqMock.client),
    );

    await aiRepository.ask(child: child, question: 'Biểu hiện này có cần lo lắng không?');

    final systemPrompt = (jsonDecode(groqMock.lastRequest!.body) as Map<String, dynamic>)['messages'][0]['content'] as String;
    expect(systemPrompt, contains('Không có tài liệu tham khảo chuyên môn phù hợp.'));
    // ignore: avoid_print
    print('PASS: Trạng thái 3 không có expert chunk phù hợp => đúng câu mặc định trong prompt');
  });
}
