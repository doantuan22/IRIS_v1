import 'dart:convert';
import 'package:flutter/services.dart';

import 'screening_scoring_service.dart';

/// Service nạp và parse bộ câu hỏi sàng lọc 50 câu 7 lĩnh vực từ asset JSON.
class ScreeningLoaderService {
  static const String assetPath = 'assets/data/sang_loc_50_cau_7_linh_vuc.json';

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
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return ScreeningQuestionnaireData.fromJson(decoded);
  }

  /// Xoá cache (dùng trong test).
  static void clearCache() {
    _cachedData = null;
  }
}
