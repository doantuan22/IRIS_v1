import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/core/utils/retry_with_backoff.dart';

void main() {
  group('retryWithBackoff', () {
    test('thành công ngay lần đầu -> không retry, không delay', () async {
      var calls = 0;
      final result = await retryWithBackoff<int>(
        () async {
          calls++;
          return 42;
        },
        initialDelay: const Duration(milliseconds: 5),
        maxDelay: const Duration(milliseconds: 20),
      );
      expect(result, 42);
      expect(calls, 1);
    });

    test('thất bại vài lần rồi thành công -> trả kết quả, đúng số lần gọi', () async {
      var calls = 0;
      final failedAttempts = <int>[];
      final result = await retryWithBackoff<String>(
        () async {
          calls++;
          if (calls < 4) throw Exception('lỗi tạm thời lần $calls');
          return 'ok';
        },
        maxAttempts: 10,
        initialDelay: const Duration(milliseconds: 5),
        maxDelay: const Duration(milliseconds: 20),
        onAttemptFailed: (attempt, error) => failedAttempts.add(attempt),
      );
      expect(result, 'ok');
      expect(calls, 4);
      expect(failedAttempts, [1, 2, 3]);
    });

    test(
      'thất bại hết maxAttempts -> ném lại lỗi của lần cuối, gọi đúng maxAttempts lần',
      () async {
        var calls = 0;
        final failedAttempts = <int>[];
        await expectLater(
          () => retryWithBackoff<int>(
            () async {
              calls++;
              throw Exception('lỗi lần $calls');
            },
            maxAttempts: 5,
            initialDelay: const Duration(milliseconds: 2),
            maxDelay: const Duration(milliseconds: 5),
            onAttemptFailed: (attempt, error) => failedAttempts.add(attempt),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('lỗi lần 5'),
            ),
          ),
        );
        expect(calls, 5);
        expect(failedAttempts, [1, 2, 3, 4, 5]);
      },
    );

    test('maxAttempts=1 -> không retry, ném lỗi ngay sau lần đầu', () async {
      var calls = 0;
      await expectLater(
        () => retryWithBackoff<int>(
          () async {
            calls++;
            throw Exception('lỗi duy nhất');
          },
          maxAttempts: 1,
          initialDelay: const Duration(milliseconds: 2),
        ),
        throwsException,
      );
      expect(calls, 1);
    });

    test('backoff tăng dần và bị chặn ở maxDelay (đo thời gian thực tế)', () async {
      var calls = 0;
      final stopwatch = Stopwatch()..start();
      try {
        await retryWithBackoff<int>(
          () async {
            calls++;
            throw Exception('luôn lỗi');
          },
          maxAttempts: 4,
          initialDelay: const Duration(milliseconds: 20),
          maxDelay: const Duration(milliseconds: 30),
        );
      } catch (_) {
        // Chỉ quan tâm thời gian chờ, bỏ qua lỗi ném ra.
      }
      stopwatch.stop();
      // 3 khoảng chờ giữa 4 lần thử: 20ms, 30ms (chặn trần từ 40ms), 30ms
      // (chặn trần từ 80ms) = 80ms tổng tối thiểu — cho biên độ dung sai vì
      // môi trường CI có thể chậm hơn 1 chút.
      expect(calls, 4);
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(75));
    });
  });
}
