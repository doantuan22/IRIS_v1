import 'dart:async';

import 'package:flutter/foundation.dart';

/// Gọi [action] tối đa [maxAttempts] lần (tính cả lần đầu), dùng exponential
/// backoff giữa các lần thử khi [action] NÉM LỖI — dùng cho các lệnh gọi có
/// thể lỗi TẠM THỜI (mạng chập chờn, giới hạn tốc độ API, lỗi 5xx, response
/// sai định dạng...). Caller tự quyết định lỗi nào đáng ném ra để kích hoạt
/// retry — [retryWithBackoff] không tự phân biệt loại lỗi, không dùng cho
/// lỗi KHÔNG nên thử lại (VD input không hợp lệ, lỗi logic nội bộ không
/// liên quan tới gọi mạng — những lỗi này nên được xử lý/ném RA NGOÀI
/// [action] thay vì để retry vô ích).
///
/// Backoff: chờ `initialDelay * 2^(số lần đã thất bại - 1)` giữa mỗi lần
/// thử, giới hạn trần [maxDelay]/lần chờ — với mặc định (initialDelay=1s,
/// maxDelay=20s, maxAttempts=10): 1s, 2s, 4s, 8s, 16s, rồi giữ nguyên 20s
/// cho 4 lần chờ còn lại. Tổng thời gian CHỜ tối đa giữa 10 lần thử (chưa
/// tính thời gian gọi [action] mỗi lần) là 1+2+4+8+16+20+20+20+20 = 111
/// giây.
///
/// Nếu tất cả [maxAttempts] lần đều thất bại, ném lại lỗi của LẦN THỬ CUỐI
/// CÙNG cho caller xử lý (VD hiển thị thông báo lỗi + nút thử lại thủ công
/// như phương án cuối cùng).
///
/// [onAttemptFailed] (tuỳ chọn) được gọi sau MỖI lần thất bại (kể cả lần
/// cuối, trước khi ném lỗi ra ngoài) — CHỈ dùng để log debug nội bộ (số lần
/// đã thử, loại lỗi), KHÔNG dùng để cập nhật UI — UI chỉ nên hiện đúng 1
/// trạng thái loading xuyên suốt cho tới khi có kết quả hoặc thất bại hẳn,
/// không nhấp nháy theo từng lần thử nội bộ.
Future<T> retryWithBackoff<T>(
  Future<T> Function() action, {
  int maxAttempts = 10,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 20),
  void Function(int attempt, Object error)? onAttemptFailed,
}) async {
  assert(maxAttempts >= 1, 'maxAttempts phải >= 1');
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await action();
    } catch (e) {
      onAttemptFailed?.call(attempt, e);
      if (attempt >= maxAttempts) rethrow;
      var delay = initialDelay * (1 << (attempt - 1));
      if (delay > maxDelay) delay = maxDelay;
      if (kDebugMode) {
        debugPrint(
          'retryWithBackoff: lần $attempt/$maxAttempts thất bại ($e), '
          'chờ ${delay.inSeconds}s rồi thử lại.',
        );
      }
      await Future.delayed(delay);
    }
  }
}
