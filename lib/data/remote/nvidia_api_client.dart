import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';

/// Embedding là request nhỏ (1 câu văn ngắn) — 15 giây đủ dư cho request
/// bình thường, chặn treo vô hạn khi mạng chập chờn.
const Duration _nvidiaTimeout = Duration(seconds: 15);

/// Lỗi khi gọi NVIDIA embedding API — HTTP lỗi, response sai định dạng,
/// hoặc thiếu dữ liệu embedding.
class NvidiaApiException implements Exception {
  final String message;

  NvidiaApiException(this.message);

  @override
  String toString() => 'NvidiaApiException: $message';
}

/// Client gọi NVIDIA NIM API để embed văn bản (câu hỏi, chunk hồ sơ/tham
/// khảo) thành vector, dùng cho vector search local.
class NvidiaApiClient {
  final http.Client _client;
  final Duration _timeout;
  final bool _isCustomClient;

  /// [timeout] cho phép ghi đè trong test (mặc định 15 giây khi dùng thật).
  NvidiaApiClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? _nvidiaTimeout,
      _isCustomClient = client != null;

  Future<List<double>> embed(String text) async {
    if (!_isCustomClient && !ApiConfig.hasNvidiaApiKey) {
      throw NvidiaApiException(
        'Chưa cấu hình NVIDIA_API_KEY. Vui lòng cấu hình API key khi chạy hoặc build app.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.nvidiaEmbeddingEndpoint),
            headers: {
              'Authorization': 'Bearer ${ApiConfig.nvidiaApiKey}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'input': [text],
              'model': ApiConfig.nvidiaEmbeddingModel,
              'input_type': 'query',
              'encoding_format': 'float',
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw NvidiaApiException(
        'Hết thời gian chờ khi gọi NVIDIA embedding API (quá ${_timeout.inSeconds} giây)',
      );
    } catch (e) {
      throw NvidiaApiException('Không gọi được NVIDIA embedding API: $e');
    }

    if (response.statusCode != 200) {
      throw NvidiaApiException(
        'NVIDIA embedding API trả về mã lỗi ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw NvidiaApiException(
        'Không parse được response NVIDIA embedding API: $e',
      );
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw NvidiaApiException(
        'NVIDIA embedding API không trả về dữ liệu embedding',
      );
    }

    final firstEntry = data.first;
    if (firstEntry is! Map<String, dynamic> ||
        firstEntry['embedding'] is! List) {
      throw NvidiaApiException(
        'NVIDIA embedding API trả về định dạng embedding không hợp lệ',
      );
    }

    return (firstEntry['embedding'] as List)
        .map((value) => (value as num).toDouble())
        .toList();
  }
}
