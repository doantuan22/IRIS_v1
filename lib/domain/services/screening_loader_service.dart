import 'dart:convert';
import 'package:flutter/services.dart';

import 'screening_scoring_service.dart';

/// Service nạp và parse bộ câu hỏi sàng lọc mới (4 mức tuổi × 20 câu × 5
/// lĩnh vực) từ asset JSON. Dữ liệu form câu hỏi tĩnh — KHÔNG cần
/// embedding/vector search (khác `expert_knowledge_chunks`).
class ScreeningLoaderService {
  /// Dữ liệu thật — chuyển đổi từ
  /// `Bo_cau_hoi_sang_loc_phat_trien_tre_em_2-5_tuoi_ban_chinh_sua.docx`
  /// (nội dung câu hỏi + cấu trúc lĩnh vực) theo thang điểm 0-3 mô tả
  /// trong `Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx`.
  static const String assetPath = 'assets/reference/screening_questions.json';

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
