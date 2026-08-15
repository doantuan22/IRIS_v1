import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';

/// Sinh câu trả lời có thể mất nhiều thời gian hơn embedding (model lớn hơn,
/// câu trả lời dài hơn) — 30 giây đủ dư trước khi coi là treo.
const Duration _groqTimeout = Duration(seconds: 30);

/// Lỗi khi gọi Groq API — HTTP lỗi, response sai định dạng, hoặc thiếu nội
/// dung câu trả lời.
class GroqApiException implements Exception {
  final String message;

  GroqApiException(this.message);

  @override
  String toString() => 'GroqApiException: $message';
}

/// Client gọi Groq API để sinh câu trả lời dựa trên system prompt đã build
/// theo đúng trạng thái guardrail (1/2/3). Chưa streaming ở giai đoạn này —
/// ưu tiên đúng chức năng trước, streaming để dành lúc làm đẹp UI.
class GroqApiClient {
  final http.Client _client;
  final Duration _timeout;
  final bool _isCustomClient;

  /// [timeout] cho phép ghi đè trong test (mặc định 30 giây khi dùng thật).
  GroqApiClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? _groqTimeout,
      _isCustomClient = client != null;

  Future<String> generate({
    required String systemPrompt,
    required String userQuestion,
  }) async {
    if (!_isCustomClient && !ApiConfig.hasGroqApiKey) {
      throw GroqApiException(
        'Chưa cấu hình GROQ_API_KEY. Vui lòng cấu hình API key khi chạy hoặc build app.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.groqGenerationEndpoint),
            headers: {
              'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'model': ApiConfig.groqModelFast,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userQuestion},
              ],
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw GroqApiException(
        'Hết thời gian chờ khi gọi Groq API (quá ${_timeout.inSeconds} giây)',
      );
    } catch (e) {
      throw GroqApiException('Không gọi được Groq API: $e');
    }

    if (response.statusCode != 200) {
      throw GroqApiException(
        'Groq API trả về mã lỗi ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw GroqApiException('Không parse được response Groq API: $e');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw GroqApiException('Groq API không trả về choices nào');
    }

    final firstChoice = choices.first;
    final message = firstChoice is Map<String, dynamic>
        ? firstChoice['message']
        : null;
    if (message is! Map<String, dynamic> || message['content'] is! String) {
      throw GroqApiException('Groq API trả về định dạng message không hợp lệ');
    }

    return message['content'] as String;
  }
}
