import '../models/scored_chunk.dart';

/// Guardrail (hàm Dart thuần) — xác định Trạng thái 1/2/3 cho hỏi đáp AI
/// dựa trên kết quả retrieval. Trạng thái được xác định bằng code, KHÔNG
/// giao cho LLM tự quyết định.
///
/// 1 — [insufficientData]: không có chunk profile liên quan + chưa có sàng lọc.
/// 2 — [hasScreening]: có kết quả sàng lọc nhưng không có mô tả liên quan
///     trực tiếp câu hỏi.
/// 3 — [hasProfessionalAssessment]: có mô tả/nhận xét liên quan trực tiếp từ
///     phụ huynh/giáo viên/chuyên gia.
enum AiState { insufficientData, hasScreening, hasProfessionalAssessment }

class GuardrailService {
  /// Ngưỡng độ tương đồng Cosine để xác định chunk mô tả hồ sơ có liên quan
  /// trực tiếp tới câu hỏi hay không.
  ///
  /// Căn cứ số liệu calibration thực tế với model NVIDIA NIM nv-embedqa-e5-v5:
  /// - Nhóm 1 (Ngoài domain): 0.5265 - 0.6661 (outlier Giá xăng dầu: 0.7386).
  /// - Nhóm 2 (Về trẻ ngoài mô tả): 0.6375 - 0.7108.
  /// - Nhóm 3 (Liên quan mờ nhạt): 0.6448 - 0.6650.
  /// - Nhóm 4 (Liên quan trực tiếp): 0.6485 - 0.7358.
  ///
  /// Quyết định: Chọn ngưỡng 0.72 theo nguyên tắc ưu tiên AN TOÀN, loại bỏ
  /// toàn bộ Nhóm 2 và Nhóm 3, giữ lại 5/7 câu hỏi liên quan trực tiếp
  /// cụ thể (đều >= 0.726). Các câu hỏi khái quát (0.64 - 0.66) được chuyển về
  /// Trạng thái 1 để đảm bảo an toàn tuyệt đối.
  /// Đối với outlier "Giá xăng dầu" (0.7386), đã có thêm lớp lọc từ khóa
  /// [_childKeywords] phòng hộ (defense-in-depth) để chặn đứng câu hỏi ngoài domain.
  static const double relevanceThreshold = 0.72;

  /// Danh sách từ khóa cơ bản về trẻ em và các khía cạnh phát triển
  static final List<String> _childKeywords = [
    'bé',
    'con',
    'trẻ',
    'cháu',
    'em bé',
    'con tôi',
    'bé nhà',
    'phát triển',
    'tự kỷ',
    'chậm nói',
    'ngôn ngữ',
    'nói',
    'vận động',
    'hành vi',
    'cảm xúc',
    'giác quan',
    'giao tiếp',
    'nhận thức',
    'sinh hoạt',
    'ngủ',
    'ăn',
    'tai',
    'mắt',
    'khóc',
    'sợ',
    'xúc',
    'nhón gót',
    'chậm',
    'mẹ',
    'bố',
    'phụ huynh',
    'cha mẹ',
  ];

  /// Kiểm tra nhanh câu hỏi có thuộc domain trẻ em / phát triển không (so khớp nguyên từ)
  static bool isChildDevelopmentQuery(String query) {
    final lower = query.toLowerCase();
    // Tách các từ độc lập theo ranh giới ký tự tiếng Việt
    final words = lower
        .split(
          RegExp(
            r'[^a-z0-9àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệđìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ]',
          ),
        )
        .where((w) => w.isNotEmpty)
        .toSet();

    for (final kw in _childKeywords) {
      if (kw.contains(' ')) {
        // Cụm từ ghép (VD: "phát triển", "ngôn ngữ", "giác quan", "giao tiếp")
        if (lower.contains(kw)) return true;
      } else {
        // Từ đơn (VD: "bé", "con", "trẻ", "nói", "ăn", "ngủ", "tai", "mắt")
        if (words.contains(kw)) return true;
      }
    }
    return false;
  }

  ({AiState state, List<ScoredProfileChunk> groundingChunks}) determineState({
    required List<ScoredProfileChunk> retrievedProfileChunks,
    required bool hasScreeningResult,
    String? userQuestion,
  }) {
    // Lớp lọc phụ (Defense in Depth): Nếu câu hỏi hoàn toàn không chứa từ khóa
    // nào về trẻ em/phát triển, lập tức chuyển về Trạng thái 1 để chặn đứng các
    // outlier có điểm cosine tương đồng nền cao do đặc thù dense embedding.
    if (userQuestion != null && !isChildDevelopmentQuery(userQuestion)) {
      return (
        state: AiState.insufficientData,
        groundingChunks: <ScoredProfileChunk>[],
      );
    }

    final relevant = retrievedProfileChunks
        .where((c) => c.similarity >= relevanceThreshold)
        .toList();
    final hasRelevantDescription = relevant.any(
      (c) => ['phu_huynh', 'giao_vien', 'chuyen_gia'].contains(c.chunk.nguon),
    );
    if (hasRelevantDescription) {
      return (
        state: AiState.hasProfessionalAssessment,
        groundingChunks: relevant,
      );
    }
    if (hasScreeningResult) {
      return (
        state: AiState.hasScreening,
        groundingChunks: <ScoredProfileChunk>[],
      );
    }
    return (
      state: AiState.insufficientData,
      groundingChunks: <ScoredProfileChunk>[],
    );
  }
}
