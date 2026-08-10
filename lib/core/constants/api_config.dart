/// Cấu hình endpoint + model cho NVIDIA (embedding) và Groq (generation).
/// API key KHÔNG hardcode — truyền vào lúc build/run qua --dart-define, VD:
///   flutter run --dart-define=NVIDIA_API_KEY=xxx --dart-define=GROQ_API_KEY=yyy
class ApiConfig {
  ApiConfig._();

  // NVIDIA NIM — embedding
  static const String nvidiaEmbeddingEndpoint =
      'https://integrate.api.nvidia.com/v1/embeddings';
  static const String nvidiaEmbeddingModel = 'nvidia/nv-embedqa-e5-v5';
  static const String nvidiaApiKey = String.fromEnvironment('NVIDIA_API_KEY');

  // Groq — sinh câu trả lời
  static const String groqGenerationEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModelFast = 'openai/gpt-oss-20b';
  static const String groqModelQuality = 'openai/gpt-oss-120b';
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
}
