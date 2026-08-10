/// Model chung cho một chunk văn bản kèm embedding, dùng khi thực hiện
/// vector search trên `profile_chunks` hoặc `expert_knowledge_chunks`.
class AiChunk {
  final String id;
  final String content;
  final List<double> embedding;
  final String? linhVuc;
  final String? contentType;

  const AiChunk({
    required this.id,
    required this.content,
    required this.embedding,
    this.linhVuc,
    this.contentType,
  });
}
