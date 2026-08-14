/// Giá trị `tier` hợp lệ duy nhất cho `OverviewSummary.tier` — đúng 3 mức đã
/// chốt, tính 100% BẰNG CODE (`overview_tier_calculator.dart`), KHÔNG do AI
/// quyết định. Tên hiển thị cho người dùng (KHÔNG dùng "bình thường/nghi
/// ngờ/nguy hiểm" ở bất kỳ đâu):
///   [tierThuongGap]    → "Trong giới hạn thường gặp"
///   [tierCanTheoDoi]   → "Có điểm cần theo dõi"
///   [tierChuyenMonSom] → "Nên tìm đánh giá chuyên môn sớm"
const String tierThuongGap = 'thuong_gap';
const String tierCanTheoDoi = 'can_theo_doi';
const String tierChuyenMonSom = 'chuyen_mon_som';

/// Tên hiển thị cho người dùng, đúng 3 tên đã chốt — dùng hàm này ở MỌI nơi
/// hiển thị [tier], không tự viết lại chuỗi.
String tierDisplayLabel(String tier) => switch (tier) {
      tierThuongGap => 'Trong giới hạn thường gặp',
      tierCanTheoDoi => 'Có điểm cần theo dõi',
      tierChuyenMonSom => 'Nên tìm đánh giá chuyên môn sớm',
      _ => tier,
    };

/// Model kết quả tổng hợp "Chân dung toàn cảnh", ánh xạ tới bảng
/// `overview_summaries`. Mỗi lần tổng hợp thành công tạo 1 dòng MỚI — bản
/// ghi lịch sử tại thời điểm [computedAt] (xem
/// `OverviewSummaryRepository.getLatestForChild`).
class OverviewSummary {
  final String id;
  final String childId;
  final String tier;
  final int soLinhVucCanTheoDoi;
  final int soLinhVucThieuDuLieu;
  final DateTime computedAt;

  const OverviewSummary({
    required this.id,
    required this.childId,
    required this.tier,
    required this.soLinhVucCanTheoDoi,
    required this.soLinhVucThieuDuLieu,
    required this.computedAt,
  });
}
