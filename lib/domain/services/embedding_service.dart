import '../../data/remote/nvidia_api_client.dart';

/// Service bọc NvidiaApiClient — tính embedding cho câu hỏi người dùng và
/// cho các chunk trước khi lưu vào `profile_chunks` / `expert_knowledge_chunks`.
class EmbeddingService {
  final NvidiaApiClient _client;

  EmbeddingService(this._client);

  Future<List<double>> embedText(String text) => _client.embed(text);
}
