import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/remote/groq_api_client.dart';
import '../../data/remote/nvidia_api_client.dart';
import '../../data/repositories/notification_repository.dart';

/// Trạng thái kết nối của từng API đơn lẻ.
enum AiApiStatus { untested, ok, error }

/// Trạng thái gộp của hệ thống kết nối AI.
enum _CombinedStatus { initial, connected, issue }

/// State chứa trạng thái chi tiết và gộp của kết nối AI.
class AiConnectivityState {
  final AiApiStatus nvidiaStatus;
  final AiApiStatus groqStatus;
  final bool isChecking;

  const AiConnectivityState({
    this.nvidiaStatus = AiApiStatus.untested,
    this.groqStatus = AiApiStatus.untested,
    this.isChecking = false,
  });

  /// Chỉ coi là đã kết nối khi CẢ 2 API đều OK.
  bool get isConnected =>
      nvidiaStatus == AiApiStatus.ok && groqStatus == AiApiStatus.ok;

  /// Đang gặp vấn đề nếu 1 hoặc cả 2 API bị lỗi.
  bool get hasIssue =>
      nvidiaStatus == AiApiStatus.error || groqStatus == AiApiStatus.error;

  AiConnectivityState copyWith({
    AiApiStatus? nvidiaStatus,
    AiApiStatus? groqStatus,
    bool? isChecking,
  }) {
    return AiConnectivityState(
      nvidiaStatus: nvidiaStatus ?? this.nvidiaStatus,
      groqStatus: groqStatus ?? this.groqStatus,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

/// Service theo dõi và quản lý kết nối 2 API AI (NVIDIA + Groq).
/// Chạy kiểm tra nền không chặn UI, tự động thử lại khi lỗi và phát thông báo.
class AiConnectivityService {
  static AiConnectivityService? _instance;
  static AiConnectivityService get instance =>
      _instance ??= AiConnectivityService();

  /// Cho phép gán instance giả lập trong test.
  static void setInstanceForTest(AiConnectivityService service) {
    _instance = service;
  }

  /// Reset instance cho test.
  static void resetForTest() {
    _instance?.dispose();
    _instance = null;
  }

  final NvidiaApiClient _nvidiaClient;
  final GroqApiClient _groqClient;
  final NotificationRepository _notificationRepository;
  final Duration _retryInterval;

  Timer? _retryTimer;
  _CombinedStatus _lastCombinedStatus = _CombinedStatus.initial;

  final ValueNotifier<AiConnectivityState> stateNotifier;

  AiConnectivityService({
    NvidiaApiClient? nvidiaClient,
    GroqApiClient? groqClient,
    NotificationRepository? notificationRepository,
    Duration checkTimeout = const Duration(seconds: 8),
    this._retryInterval = const Duration(seconds: 30),
    http.Client? httpClient,
  }) : _nvidiaClient =
           nvidiaClient ??
           NvidiaApiClient(client: httpClient, timeout: checkTimeout),
       _groqClient =
           groqClient ?? GroqApiClient(client: httpClient, timeout: checkTimeout),
       _notificationRepository =
           notificationRepository ?? NotificationRepository(),
       stateNotifier = ValueNotifier(const AiConnectivityState());

  /// Trạng thái hiện tại
  AiConnectivityState get state => stateNotifier.value;
  bool get isConnected => state.isConnected;
  bool get hasIssue => state.hasIssue;
  bool get isChecking => state.isChecking;

  /// Hủy timer khi không dùng nữa
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Kích hoạt kiểm tra ban đầu (gọi lúc mở app trong nền, KHÔNG chặn splash).
  Future<void> checkInitialConnectivity() async {
    await checkConnectivity(forceCheckAll: true);
  }

  /// Kiểm tra kết nối AI.
  /// [forceCheckAll]: Nếu true, kiểm tra cả 2 API; nếu false, chỉ kiểm tra các API đang lỗi.
  Future<void> checkConnectivity({bool forceCheckAll = false}) async {
    if (state.isChecking) return;

    stateNotifier.value = state.copyWith(isChecking: true);

    final currentNvidia = state.nvidiaStatus;
    final currentGroq = state.groqStatus;

    final shouldCheckNvidia =
        forceCheckAll ||
        currentNvidia != AiApiStatus.ok ||
        currentNvidia == AiApiStatus.untested;
    final shouldCheckGroq =
        forceCheckAll ||
        currentGroq != AiApiStatus.ok ||
        currentGroq == AiApiStatus.untested;

    // Chạy song song kiểm tra các API cần kiểm tra
    final nvidiaFuture = shouldCheckNvidia
        ? _testNvidia()
        : Future.value(currentNvidia);
    final groqFuture = shouldCheckGroq ? _testGroq() : Future.value(currentGroq);

    final results = await Future.wait([nvidiaFuture, groqFuture]);
    final newNvidiaStatus = results[0];
    final newGroqStatus = results[1];

    final newState = state.copyWith(
      nvidiaStatus: newNvidiaStatus,
      groqStatus: newGroqStatus,
      isChecking: false,
    );

    stateNotifier.value = newState;

    await _handleStateTransition(newState);
  }

  Future<AiApiStatus> _testNvidia() async {
    try {
      await _nvidiaClient.embed('ping');
      return AiApiStatus.ok;
    } catch (_) {
      return AiApiStatus.error;
    }
  }

  Future<AiApiStatus> _testGroq() async {
    try {
      await _groqClient.generate(
        systemPrompt: 'ping',
        userQuestion: 'ping',
      );
      return AiApiStatus.ok;
    } catch (_) {
      return AiApiStatus.error;
    }
  }

  Future<void> _handleStateTransition(AiConnectivityState currentState) async {
    final currentCombined = currentState.isConnected
        ? _CombinedStatus.connected
        : (currentState.hasIssue
            ? _CombinedStatus.issue
            : _CombinedStatus.initial);

    // Kịch bản 1: Cả 2 API đều OK ngay từ đầu
    if (_lastCombinedStatus == _CombinedStatus.initial &&
        currentCombined == _CombinedStatus.connected) {
      _lastCombinedStatus = _CombinedStatus.connected;
      _stopRetryTimer();
      return;
    }

    // Kịch bản 2: Chuyển sang trạng thái Lỗi (từ initial hoặc connected -> issue)
    if (_lastCombinedStatus != _CombinedStatus.issue &&
        currentCombined == _CombinedStatus.issue) {
      _lastCombinedStatus = _CombinedStatus.issue;
      try {
        await _notificationRepository.add(
          title: 'Kết nối AI',
          content: 'Kết nối AI đang gặp vấn đề.',
          type: 'ai_connectivity',
        );
      } catch (e) {
        debugPrint('Lỗi khi ghi thông báo kết nối AI: $e');
      }
      _startRetryTimer();
      return;
    }

    // Kịch bản 3: Phục hồi kết nối thành công (từ issue -> connected)
    if (_lastCombinedStatus == _CombinedStatus.issue &&
        currentCombined == _CombinedStatus.connected) {
      _lastCombinedStatus = _CombinedStatus.connected;
      try {
        await _notificationRepository.add(
          title: 'Kết nối AI',
          content: 'Đã có thể kết nối AI.',
          type: 'ai_connectivity',
        );
      } catch (e) {
        debugPrint('Lỗi khi ghi thông báo kết nối AI: $e');
      }
      _stopRetryTimer();
      return;
    }

    // Kịch bản 4: Vẫn đang lỗi (issue -> issue) -> Không ghi thêm thông báo trùng lặp
    if (currentCombined == _CombinedStatus.issue) {
      _startRetryTimer();
    }
  }

  void _startRetryTimer() {
    if (_retryTimer != null && _retryTimer!.isActive) return;
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      checkConnectivity(forceCheckAll: false);
    });
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
