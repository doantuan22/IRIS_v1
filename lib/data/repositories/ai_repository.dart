import '../../domain/models/child.dart';
import '../../domain/services/guardrail_service.dart';
import '../../domain/services/prompt_builder.dart';
import '../../domain/services/vector_search_service.dart';
import '../local/database.dart';
import '../remote/groq_api_client.dart';
import '../remote/nvidia_api_client.dart';
import 'ai_conversation_repository.dart';
import 'expert_knowledge_repository.dart';
import 'profile_chunk_repository.dart';
import 'screening_repository.dart';

/// Câu trả lời AI kèm trạng thái guardrail đã dùng để build prompt — UI dùng
/// [state] để hiện chú thích, không dùng để quyết định logic gì thêm.
class AiAnswer {
  final String answer;
  final AiState state;

  const AiAnswer({required this.answer, required this.state});
}

int _stateToInt(AiState state) => switch (state) {
  AiState.insufficientData => 1,
  AiState.hasScreening => 2,
  AiState.hasProfessionalAssessment => 3,
};

const String _noExpertContext =
    'Không có tài liệu tham khảo chuyên môn phù hợp.';

/// Gộp toàn bộ pipeline hỏi đáp AI: embed câu hỏi → vector search local
/// trên `profile_chunks` + `expert_knowledge_chunks` → guardrail xác định
/// trạng thái 1/2/3 → build system prompt → gọi Groq → lưu `ai_conversations`.
class AiRepository {
  final NvidiaApiClient _nvidiaApiClient;
  final VectorSearchService _vectorSearchService;
  final ScreeningRepository _screeningRepository;
  final GuardrailService _guardrailService;
  final PromptBuilder _promptBuilder;
  final GroqApiClient _groqApiClient;
  final AiConversationRepository _aiConversationRepository;

  AiRepository({
    required AppDatabase db,
    NvidiaApiClient? nvidiaApiClient,
    VectorSearchService? vectorSearchService,
    GuardrailService? guardrailService,
    PromptBuilder? promptBuilder,
    GroqApiClient? groqApiClient,
  }) : _nvidiaApiClient = nvidiaApiClient ?? NvidiaApiClient(),
       _vectorSearchService =
           vectorSearchService ??
           VectorSearchService(
             ProfileChunkRepository(db),
             ExpertKnowledgeRepository(db),
           ),
       _screeningRepository = ScreeningRepository(db),
       _guardrailService = guardrailService ?? GuardrailService(),
       _promptBuilder = promptBuilder ?? PromptBuilder(),
       _groqApiClient = groqApiClient ?? GroqApiClient(),
       _aiConversationRepository = AiConversationRepository(db);

  /// [child] cần đủ (không chỉ id) vì Trạng thái 3 cần `childAgeInMonths()`
  /// để lọc `expert_knowledge_chunks` theo đúng độ tuổi.
  Future<AiAnswer> ask({required Child child, required String question}) async {
    final queryEmbedding = await _nvidiaApiClient.embed(question);

    final profileChunks = await _vectorSearchService.searchProfileChunks(
      child.id,
      queryEmbedding,
    );
    final hasScreeningResult = await _screeningRepository.hasScreening(
      child.id,
    );

    final guardrailResult = _guardrailService.determineState(
      retrievedProfileChunks: profileChunks,
      hasScreeningResult: hasScreeningResult,
      userQuestion: question,
    );

    final String systemPrompt;
    switch (guardrailResult.state) {
      case AiState.insufficientData:
        systemPrompt = _promptBuilder.buildState1Prompt();
      case AiState.hasScreening:
        systemPrompt = _promptBuilder.buildState2Prompt();
      case AiState.hasProfessionalAssessment:
        final ageMonths = childAgeInMonths(child);
        final expertChunks = await _vectorSearchService.searchExpertChunks(
          ageMonths,
          queryEmbedding,
        );
        final profileContext = guardrailResult.groundingChunks
            .map((c) => '- ${c.chunk.content}')
            .join('\n');
        final expertContext = expertChunks.isEmpty
            ? _noExpertContext
            : expertChunks.map((c) => '- ${c.chunk.content}').join('\n');
        systemPrompt = _promptBuilder.buildState3Prompt(
          profileContext: profileContext,
          expertContext: expertContext,
        );
    }

    final rawAnswer = await _groqApiClient.generate(
      systemPrompt: systemPrompt,
      userQuestion: question,
    );

    final cleanAnswer = sanitizeAiAnswer(rawAnswer);

    await _aiConversationRepository.save(
      childId: child.id,
      question: question,
      answer: cleanAnswer,
      state: _stateToInt(guardrailResult.state),
    );

    return AiAnswer(answer: cleanAnswer, state: guardrailResult.state);
  }

  /// Làm sạch ký tự Markdown thô (**, *, -, #, bảng biểu...) để đảm bảo
  /// câu trả lời hiển thị dưới dạng văn xuôi tự nhiên, sạch đẹp trên UI.
  static String sanitizeAiAnswer(String raw) {
    var text = raw;

    // 1. Gỡ bỏ bullet points markdown (- , * , + , • ) và đánh số ở đầu dòng
    text = text.replaceAll(RegExp(r'^\s*[-*+•]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 2. Gỡ bỏ headers markdown: #, ##, ### ở đầu dòng
    text = text.replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '');

    // 3. Gỡ bỏ markdown bold/italic: **text**, *text*, __text__, _text_
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');

    // 4. Gỡ bỏ blockquote markdown: > ở đầu dòng
    text = text.replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '');

    // 5. Gỡ bỏ bảng markdown (|---|) và chuyển hàng thành văn xuôi
    final lines = text.split('\n');
    final cleanLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('|') && trimmed.contains('---')) continue;
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        final cells = trimmed
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        if (cells.isNotEmpty) {
          cleanLines.add(cells.join(': '));
        }
      } else {
        cleanLines.add(line);
      }
    }
    text = cleanLines.join('\n');

    // 6. Gỡ bỏ nhiều dòng trống liên tiếp
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }
}
