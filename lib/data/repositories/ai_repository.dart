import '../../domain/services/embedding_service.dart';
import '../../domain/services/guardrail_service.dart';
import '../../domain/services/vector_search_service.dart';
import '../local/database.dart';
import '../remote/groq_api_client.dart';

/// Gộp toàn bộ pipeline hỏi đáp AI: embed câu hỏi → vector search local
/// trên `profile_chunks` + `expert_knowledge_chunks` → guardrail xác định
/// trạng thái 1/2/3 → build system prompt → gọi Groq → lưu `ai_conversations`.
class AiRepository {
  final AppDatabase _db;
  final EmbeddingService _embeddingService;
  final VectorSearchService _vectorSearchService;
  final GuardrailService _guardrailService;
  final GroqApiClient _groqApiClient;

  AiRepository({
    required AppDatabase db,
    required EmbeddingService embeddingService,
    required VectorSearchService vectorSearchService,
    required GuardrailService guardrailService,
    required GroqApiClient groqApiClient,
  })  : _db = db,
        _embeddingService = embeddingService,
        _vectorSearchService = vectorSearchService,
        _guardrailService = guardrailService,
        _groqApiClient = groqApiClient;

  Stream<String> ask({required String childId, required String question}) async* {
    throw UnimplementedError('TODO: implement pipeline retrieval -> guardrail -> generate theo roadmap mục 3');
  }
}
