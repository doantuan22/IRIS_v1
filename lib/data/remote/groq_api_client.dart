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
    String? reasoningEffort,
  }) async {
    if (!_isCustomClient && !ApiConfig.hasGroqApiKey) {
      throw GroqApiException(
        'Chưa cấu hình GROQ_API_KEY. Vui lòng cấu hình API key khi chạy hoặc build app.',
      );
    }

    http.Response response;
    var attempts = 0;
    // Tăng từ 3 lên 4 (đợt điều tra độ tin cậy "Chân dung toàn cảnh") — đo
    // thật trên Groq API cho model `openai/gpt-oss-20b` cho thấy lỗi 429
    // (rate limit TPM) là nguyên nhân chính gây thất bại khi gọi nhiều lần
    // liên tiếp trong thời gian ngắn (VD gắn nhãn tuần tự 7 lĩnh vực); mỗi
    // lần 429 Groq đều trả "try again in Xs" ngắn (thường 1-9s) nên thêm 1
    // lần thử không tốn quá nhiều thời gian nhưng tăng đáng kể tỷ lệ thành
    // công cho các chuỗi gọi liên tiếp.
    const maxAttempts = 4;

    while (true) {
      attempts++;
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
                // `reasoning_effort: low` (khi được truyền) cắt đáng kể số
                // "reasoning token" model tự sinh trước câu trả lời — đo
                // thật cho thấy giảm ~40% tổng token/lần gọi so với mặc
                // định, mà KHÔNG ảnh hưởng nội dung `message.content` thật
                // sự dùng (reasoning không được đọc ở đâu trong app). Dùng
                // cho các luồng gọi nhiều lần liên tiếp (VD gắn nhãn 7 lĩnh
                // vực) để giảm nguy cơ chạm trần token/phút (TPM).
                'reasoning_effort': ?reasoningEffort,
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

      if (response.statusCode == 429 && attempts < maxAttempts) {
        var waitSeconds = 4;
        final match = RegExp(
          r'try again in (\d+(\.\d+)?)s',
        ).firstMatch(response.body);
        if (match != null) {
          final parsed = double.tryParse(match.group(1)!);
          if (parsed != null) {
            waitSeconds = parsed.ceil() + 1;
          }
        }
        await Future.delayed(Duration(seconds: waitSeconds));
        continue;
      }
      break;
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
