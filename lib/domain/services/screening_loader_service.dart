import 'dart:convert';
import 'package:flutter/services.dart';

import 'screening_scoring_service.dart';

/// Service nạp và parse bộ câu hỏi sàng lọc mới (4 mức tuổi × 20 câu × 5
/// lĩnh vực) từ asset JSON. Dữ liệu form câu hỏi tĩnh — KHÔNG cần
/// embedding/vector search (khác `expert_knowledge_chunks`).
class ScreeningLoaderService {
  /// TẠM dùng file PLACEHOLDER (dữ liệu giả, chỉ để dựng/kiểm tra khung
  /// chạy được — xem `[PLACEHOLDER]` trong nội dung file). Đợt chuyển đổi
  /// dữ liệu thật từ tài liệu Word (Prompt 2) sẽ thay bằng file
  /// `sang_loc_20_cau_4_muc_tuoi.json` (không có hậu tố `.placeholder`) và
  /// cập nhật đúng 1 dòng [assetPath] này.
  static const String assetPath =
      'assets/reference/sang_loc_20_cau_4_muc_tuoi.placeholder.json';

  static ScreeningQuestionnaireData? _cachedData;

  /// Nạp từ asset bundle (mặc định dùng trong ứng dụng).
  static Future<ScreeningQuestionnaireData> loadQuestionnaire({
    AssetBundle? bundle,
  }) async {
    if (_cachedData != null) {
      return _cachedData!;
    }
    final effectiveBundle = bundle ?? rootBundle;
    final jsonString = await effectiveBundle.loadString(assetPath);
    _cachedData = parseJson(jsonString);
    return _cachedData!;
  }

  /// Parse từ chuỗi JSON (tiện lợi cho unit test độc lập không cần Flutter engine).
  static ScreeningQuestionnaireData parseJson(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString);
    return ScreeningQuestionnaireData.fromJsonList(decoded);
  }

  /// Xoá cache (dùng trong test).
  static void clearCache() {
    _cachedData = null;
  }
}
