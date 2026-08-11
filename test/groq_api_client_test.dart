import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris_app/core/constants/api_config.dart';
import 'package:iris_app/data/remote/groq_api_client.dart';

/// Test GroqApiClient bằng MockClient — không gọi API thật (chưa có API key
/// thật trong môi trường này). Kiểm chứng đúng request format và parse
/// response.
void main() {
  test('generate() gọi đúng endpoint, header, body messages[system,user] và parse đúng response', () async {
    late http.Request capturedRequest;
    final mockClient = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'Câu trả lời mẫu từ Groq'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = GroqApiClient(client: mockClient);
    final result = await client.generate(
      systemPrompt: 'Bạn là IRIS...',
      userQuestion: 'Con tôi 2 tuổi chưa biết nói nhiều từ có sao không?',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.toString(), ApiConfig.groqGenerationEndpoint);
    expect(capturedRequest.headers['Authorization'], 'Bearer ${ApiConfig.groqApiKey}');
    expect(capturedRequest.headers['Content-Type'], contains('application/json'));

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['model'], ApiConfig.groqModelFast);
    final messages = body['messages'] as List<dynamic>;
    expect(messages.length, 2);
    expect(messages[0], {'role': 'system', 'content': 'Bạn là IRIS...'});
    expect(messages[1], {'role': 'user', 'content': 'Con tôi 2 tuổi chưa biết nói nhiều từ có sao không?'});

    expect(result, 'Câu trả lời mẫu từ Groq');
    // ignore: avoid_print
    print('PASS: GroqApiClient.generate() gọi đúng endpoint/header/body và parse đúng response');
  });

  test('generate() ném GroqApiException khi API trả mã lỗi HTTP', () async {
    final mockClient = MockClient((request) async => http.Response('unauthorized', 401));
    final client = GroqApiClient(client: mockClient);

    expect(
      () => client.generate(systemPrompt: 'x', userQuestion: 'y'),
      throwsA(isA<GroqApiException>()),
    );
    // ignore: avoid_print
    print('PASS: GroqApiClient.generate() ném GroqApiException khi HTTP 401');
  });

  test('generate() ném GroqApiException khi response thiếu choices', () async {
    final mockClient = MockClient(
      (request) async => http.Response(jsonEncode({'choices': <dynamic>[]}), 200),
    );
    final client = GroqApiClient(client: mockClient);

    expect(
      () => client.generate(systemPrompt: 'x', userQuestion: 'y'),
      throwsA(isA<GroqApiException>()),
    );
    // ignore: avoid_print
    print('PASS: GroqApiClient.generate() ném GroqApiException khi response rỗng/sai định dạng');
  });

  test('generate() ném GroqApiException rõ ràng khi quá thời gian chờ (timeout)', () async {
    final mockClient = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return http.Response(jsonEncode({'choices': <dynamic>[]}), 200);
    });
    final client = GroqApiClient(client: mockClient, timeout: const Duration(milliseconds: 20));

    await expectLater(
      client.generate(systemPrompt: 'x', userQuestion: 'y'),
      throwsA(isA<GroqApiException>().having(
        (e) => e.message,
        'message',
        contains('Hết thời gian chờ'),
      )),
    );
    // ignore: avoid_print
    print('PASS: GroqApiClient.generate() ném GroqApiException rõ ràng khi timeout, không treo vô hạn');
  });
}
