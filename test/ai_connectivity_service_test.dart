import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/remote/groq_api_client.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:iris_app/data/repositories/notification_repository.dart';
import 'package:iris_app/domain/services/ai_connectivity_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    AiConnectivityService.resetForTest();
  });

  tearDown(() async {
    AiConnectivityService.resetForTest();
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  http.Client createSuccessNvidiaMock() => MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'embedding': [0.1, 0.2, 0.3],
              },
            ],
          }),
          200,
        );
      });

  http.Client createSuccessGroqMock() => MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'pong'},
              },
            ],
          }),
          200,
        );
      });

  http.Client createErrorMock() => MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

  test('Kịch bản 1: Cả 2 API đều OK ngay từ đầu -> isConnected=true, không ghi thông báo lỗi', () async {
    final notificationRepo = NotificationRepository(AppDatabase.instance);

    final service = AiConnectivityService(
      nvidiaClient: NvidiaApiClient(client: createSuccessNvidiaMock()),
      groqClient: GroqApiClient(client: createSuccessGroqMock()),
      notificationRepository: notificationRepo,
      retryInterval: const Duration(seconds: 1),
    );

    expect(service.isConnected, isFalse); // Chưa test

    await service.checkInitialConnectivity();

    expect(service.isConnected, isTrue);
    expect(service.hasIssue, isFalse);
    expect(service.state.nvidiaStatus, equals(AiApiStatus.ok));
    expect(service.state.groqStatus, equals(AiApiStatus.ok));

    // Không có thông báo nào bị ghi
    final notifications = await notificationRepo.getAll();
    expect(notifications, isEmpty);
  });

  test('Kịch bản 2 & 3: 1 API lỗi ban đầu -> ghi thông báo lỗi; retry vẫn lỗi -> không spam thông báo trùng lặp', () async {
    final notificationRepo = NotificationRepository(AppDatabase.instance);

    final service = AiConnectivityService(
      nvidiaClient: NvidiaApiClient(client: createSuccessNvidiaMock()),
      groqClient: GroqApiClient(client: createErrorMock()), // Groq lỗi
      notificationRepository: notificationRepo,
      retryInterval: const Duration(seconds: 1),
    );

    await service.checkInitialConnectivity();

    expect(service.isConnected, isFalse);
    expect(service.hasIssue, isTrue);
    expect(service.state.nvidiaStatus, equals(AiApiStatus.ok));
    expect(service.state.groqStatus, equals(AiApiStatus.error));

    // Phải ghi đúng 1 thông báo
    var notifications = await notificationRepo.getAll();
    expect(notifications.length, equals(1));
    expect(notifications.first.content, equals('Kết nối AI đang gặp vấn đề.'));

    // Retry lần 2 khi Groq vẫn lỗi
    await service.checkConnectivity(forceCheckAll: false);

    expect(service.isConnected, isFalse);
    expect(service.hasIssue, isTrue);

    // Vẫn chỉ có 1 thông báo, không bị nhân bản spam
    notifications = await notificationRepo.getAll();
    expect(notifications.length, equals(1));
  });

  test('Kịch bản 4: Phục hồi kết nối thành công -> ghi thông báo "Đã có thể kết nối AI."', () async {
    final notificationRepo = NotificationRepository(AppDatabase.instance);
    var groqShouldFail = true;

    final dynamicGroqMock = MockClient((request) async {
      if (groqShouldFail) {
        return http.Response('Service Unavailable', 503);
      }
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'pong'},
            },
          ],
        }),
        200,
      );
    });

    final service = AiConnectivityService(
      nvidiaClient: NvidiaApiClient(client: createSuccessNvidiaMock()),
      groqClient: GroqApiClient(client: dynamicGroqMock),
      notificationRepository: notificationRepo,
      retryInterval: const Duration(seconds: 1),
    );

    // Lần 1: Lỗi
    await service.checkInitialConnectivity();
    expect(service.hasIssue, isTrue);
    var notifications = await notificationRepo.getAll();
    expect(notifications.length, equals(1));
    expect(notifications.first.content, equals('Kết nối AI đang gặp vấn đề.'));

    // Lần 2: Mạng phục hồi
    groqShouldFail = false;
    await service.checkConnectivity(forceCheckAll: false);

    expect(service.isConnected, isTrue);
    expect(service.hasIssue, isFalse);

    notifications = await notificationRepo.getAll();
    expect(notifications.length, equals(2));
    expect(notifications.first.content, equals('Đã có thể kết nối AI.'));
  });

  test('Kịch bản 5: Chỉ retry các API bị lỗi khi forceCheckAll=false', () async {
    final notificationRepo = NotificationRepository(AppDatabase.instance);
    var nvidiaCallCount = 0;
    var groqCallCount = 0;

    final nvidiaMock = MockClient((request) async {
      nvidiaCallCount++;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'embedding': [0.1],
            },
          ],
        }),
        200,
      );
    });

    final groqMock = MockClient((request) async {
      groqCallCount++;
      return http.Response('Error', 500);
    });

    final service = AiConnectivityService(
      nvidiaClient: NvidiaApiClient(client: nvidiaMock),
      groqClient: GroqApiClient(client: groqMock),
      notificationRepository: notificationRepo,
      retryInterval: const Duration(seconds: 1),
    );

    // Lần 1: Cả 2 đều được gọi
    await service.checkInitialConnectivity();
    expect(nvidiaCallCount, equals(1));
    expect(groqCallCount, equals(1));
    expect(service.state.nvidiaStatus, equals(AiApiStatus.ok));
    expect(service.state.groqStatus, equals(AiApiStatus.error));

    // Lần 2: Retry (forceCheckAll=false) -> CHỈ Groq được gọi lại, Nvidia không gọi lại
    await service.checkConnectivity(forceCheckAll: false);
    expect(nvidiaCallCount, equals(1)); // Không tăng
    expect(groqCallCount, equals(2)); // Tăng lên 2
  });
}
