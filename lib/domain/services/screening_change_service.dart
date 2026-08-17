import 'package:flutter/foundation.dart';

/// Báo cho các màn hình đang giữ trạng thái biết rằng một bài sàng lọc vừa
/// được lưu, kể cả khi luồng onboarding quay thẳng về Trang chủ.
class ScreeningChangeService {
  ScreeningChangeService._();

  static final instance = ScreeningChangeService._();

  final ValueNotifier<int> _revision = ValueNotifier(0);

  void addListener(VoidCallback listener) => _revision.addListener(listener);

  void removeListener(VoidCallback listener) => _revision.removeListener(listener);

  void notifyScreeningSaved() => _revision.value++;
}
