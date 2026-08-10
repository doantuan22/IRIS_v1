import '../../core/constants/api_config.dart';

/// Client gọi Groq API để sinh câu trả lời (streaming) dựa trên system
/// prompt đã build theo đúng trạng thái guardrail (1/2/3).
class GroqApiClient {
  Stream<String> generate({
    required String systemPrompt,
    required String userQuestion,
  }) async* {
    throw UnimplementedError('TODO: gọi ${ApiConfig.groqGenerationEndpoint} và stream câu trả lời');
  }
}
