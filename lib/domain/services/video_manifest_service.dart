import 'dart:convert';
import 'package:flutter/services.dart';

/// Nạp và cache `assets/reference/video_manifest.json` — file manifest do
/// tool dev `tools/video_manager_tool.py` sinh ra khi người biên soạn gắn
/// video mẫu minh hoạ cho từng entry `so_sanh` cụ thể (khoá theo `id` chunk
/// trong `expert_knowledge_chunks`, KHÔNG phải theo nhóm lĩnh vực/phân
/// loại/tuổi). Không phải mọi `id` đều có video — phần lớn không có.
class VideoManifestService {
  static const String assetPath = 'assets/reference/video_manifest.json';

  /// id chunk -> đường dẫn asset video (VD "assets/videos/nhan_thuc/xxx.mp4").
  static Map<String, String>? _cachedPaths;

  /// Nạp từ asset bundle (mặc định dùng trong ứng dụng) — chỉ đọc file 1
  /// lần, các lần gọi sau trả thẳng từ cache. An toàn nếu file chưa tồn tại
  /// (VD dải tuổi chưa gắn video nào) — coi như không có video nào, KHÔNG
  /// ném lỗi.
  static Future<Map<String, String>> loadVideoPaths({AssetBundle? bundle}) async {
    if (_cachedPaths != null) {
      return _cachedPaths!;
    }
    final effectiveBundle = bundle ?? rootBundle;
    try {
      final jsonString = await effectiveBundle.loadString(assetPath);
      _cachedPaths = parseJson(jsonString);
    } catch (_) {
      // Asset chưa tồn tại (chưa gắn video nào) hoặc JSON hỏng — coi như
      // không có video nào, không chặn màn "So sánh" hiển thị nội dung.
      _cachedPaths = {};
    }
    return _cachedPaths!;
  }

  /// Parse từ chuỗi JSON (tiện lợi cho unit test độc lập không cần Flutter
  /// engine) — đúng schema `{"videos": {"<id>": {"file_path": ..., ...}}}`.
  static Map<String, String> parseJson(String jsonString) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    final videos = decoded['videos'] as Map<String, dynamic>? ?? {};
    return videos.map(
      (id, info) => MapEntry(id, (info as Map<String, dynamic>)['file_path'] as String),
    );
  }

  /// Tra cứu đồng bộ (không async) — chỉ trả kết quả đúng SAU KHI đã gọi
  /// [loadVideoPaths] ít nhất 1 lần (thường ở `initState`/hàm tải dữ liệu
  /// đầu trang, trước khi build danh sách entry). Trả `null` nếu chưa nạp
  /// hoặc entry đó không có video.
  static String? getVideoPathForId(String id) => _cachedPaths?[id];

  /// Xoá cache (dùng trong test).
  static void clearCache() {
    _cachedPaths = null;
  }
}
