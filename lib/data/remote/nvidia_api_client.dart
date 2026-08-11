import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';

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

  NvidiaApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<double>> embed(String text) async {
    final http.Response response;
    try {
      response = await _client.post(
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
      decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw NvidiaApiException('Không parse được response NVIDIA embedding API: $e');
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw NvidiaApiException('NVIDIA embedding API không trả về dữ liệu embedding');
    }

    final firstEntry = data.first;
    if (firstEntry is! Map<String, dynamic> || firstEntry['embedding'] is! List) {
      throw NvidiaApiException('NVIDIA embedding API trả về định dạng embedding không hợp lệ');
    }

    return (firstEntry['embedding'] as List)
        .map((value) => (value as num).toDouble())
        .toList();
  }
}
