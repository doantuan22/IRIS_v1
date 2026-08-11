import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris_app/core/constants/api_config.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';

/// Test NvidiaApiClient bằng MockClient — không gọi API thật (chưa có API
/// key thật trong môi trường này). Kiểm chứng đúng URL, header, body request
/// và đúng cách parse response.
void main() {
  test('embed() gọi đúng endpoint, header, body và parse đúng response', () async {
    late http.Request capturedRequest;
    final mockClient = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {'embedding': [0.1, 0.2, 0.3], 'index': 0},
          ],
          'model': ApiConfig.nvidiaEmbeddingModel,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = NvidiaApiClient(client: mockClient);
    final result = await client.embed('Bé thích chơi xếp hình một mình');

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.toString(), ApiConfig.nvidiaEmbeddingEndpoint);
    expect(capturedRequest.headers['Authorization'], 'Bearer ${ApiConfig.nvidiaApiKey}');
    expect(capturedRequest.headers['Content-Type'], contains('application/json'));

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['model'], ApiConfig.nvidiaEmbeddingModel);
    expect(body['input'], ['Bé thích chơi xếp hình một mình']);
    expect(body['input_type'], 'query');

    expect(result, [0.1, 0.2, 0.3]);
    // ignore: avoid_print
    print('PASS: NvidiaApiClient.embed() gọi đúng endpoint/header/body và parse đúng response');
  });

  test('embed() ném NvidiaApiException khi API trả mã lỗi HTTP', () async {
    final mockClient = MockClient((request) async => http.Response('unauthorized', 401));
    final client = NvidiaApiClient(client: mockClient);

    expect(() => client.embed('test'), throwsA(isA<NvidiaApiException>()));
    // ignore: avoid_print
    print('PASS: NvidiaApiClient.embed() ném NvidiaApiException khi HTTP 401');
  });

  test('embed() ném NvidiaApiException khi response thiếu field embedding', () async {
    final mockClient = MockClient(
      (request) async => http.Response(jsonEncode({'data': <dynamic>[]}), 200),
    );
    final client = NvidiaApiClient(client: mockClient);

    expect(() => client.embed('test'), throwsA(isA<NvidiaApiException>()));
    // ignore: avoid_print
    print('PASS: NvidiaApiClient.embed() ném NvidiaApiException khi response rỗng/sai định dạng');
  });
}
