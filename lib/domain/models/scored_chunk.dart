import 'expert_knowledge_chunk.dart';
import 'profile_chunk.dart';

/// Kết quả vector search trên `profile_chunks` — chunk kèm điểm cosine
/// similarity so với embedding câu hỏi.
class ScoredProfileChunk {
  final ProfileChunk chunk;
  final double similarity;

  const ScoredProfileChunk({required this.chunk, required this.similarity});
}

/// Kết quả vector search trên `expert_knowledge_chunks` — chunk kèm điểm
/// cosine similarity so với embedding câu hỏi.
class ScoredExpertChunk {
  final ExpertKnowledgeChunk chunk;
  final double similarity;

  const ScoredExpertChunk({required this.chunk, required this.similarity});
}
