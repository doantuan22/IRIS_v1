import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý "hồ sơ trẻ đang hoạt động" (active child) — lưu bền vững qua các
/// lần mở app bằng `shared_preferences` (chỉ 1 giá trị đơn giản là id trẻ,
/// không cần bảng SQLite riêng). App mặc định luôn thao tác trên đúng 1 trẻ
/// tại một thời điểm; đổi/xoá hồ sơ đang hoạt động thực hiện qua tab
/// "Tài khoản".
class ActiveChildService {
  static const _activeChildIdKey = 'active_child_id';

  Future<String?> getActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeChildIdKey);
  }

  Future<void> setActiveChildId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeChildIdKey, id);
  }

  Future<void> clearActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeChildIdKey);
  }
}
