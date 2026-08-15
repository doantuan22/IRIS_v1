import '../models/domain_overview_label.dart';
import '../models/overview_summary.dart';

/// Ngưỡng số lĩnh vực nhãn `'can_theo_doi'` (0 đến [nguongThuongGap], bao
/// gồm) để xếp trẻ vào tier [tierThuongGap] ("Trong giới hạn thường gặp").
/// NGƯỠNG TẠM do dự án tự đặt cho mục đích demo — KHÔNG phải thang đo lâm
/// sàng đã được kiểm định, cần thay bằng ngưỡng có cơ sở chuyên môn trước
/// khi dùng thật.
/// Giá trị giữ nguyên từ thiết kế 9 lĩnh vực, nay tính trên nền 7 lĩnh vực
/// nên tỷ lệ đạt mức 'chuyên môn sớm' khắt khe hơn trước (yêu cầu 6-7/7
/// thay vì 6-9/9) - quyết định có chủ đích, không phải sai sót.
const int nguongThuongGap = 2;

/// Ngưỡng trên của số lĩnh vực nhãn `'can_theo_doi'` để còn xếp vào tier
/// [tierCanTheoDoi] ("Có điểm cần theo dõi") — khoảng
/// (`nguongThuongGap`, `nguongCanTheoDoi`]. Vượt ngưỡng này xếp vào tier
/// [tierChuyenMonSom]. NGƯỠNG TẠM do dự án tự đặt, không phải thang đo lâm
/// sàng đã kiểm định.
/// Giá trị giữ nguyên từ thiết kế 9 lĩnh vực, nay tính trên nền 7 lĩnh vực
/// nên tỷ lệ đạt mức 'chuyên môn sớm' khắt khe hơn trước (yêu cầu 6-7/7
/// thay vì 6-9/9) - quyết định có chủ đích, không phải sai sót.
const int nguongCanTheoDoi = 5;

/// Số lĩnh vực nhãn `'chua_du_du_lieu'` TỐI THIỂU để coi là "chưa đủ dữ liệu
/// để tổng hợp". Khi `so_thieu >= nguongThieuDuLieuToiThieu`, KHÔNG tính
/// tier, không lưu `overview_summaries`. NGƯỠNG TẠM do dự án tự đặt, không
/// phải thang đo lâm sàng đã kiểm định.
/// Giá trị giữ nguyên từ thiết kế 9 lĩnh vực, nay tính trên nền 7 lĩnh vực
/// nên tỷ lệ đạt mức 'chuyên môn sớm' khắt khe hơn trước (yêu cầu 6-7/7
/// thay vì 6-9/9) - quyết định có chủ đích, không phải sai sót.
const int nguongThieuDuLieuToiThieu = 4;

enum OverviewTierStatus { insufficientData, computed }

/// Kết quả tính tier — [status] = `insufficientData` khi `so_thieu` vượt
/// [nguongThieuDuLieuToiThieu] (không đủ dữ liệu để tổng hợp, [tier] là
/// `null`); `computed` khi đã tính được [tier].
class OverviewTierResult {
  final OverviewTierStatus status;
  final String? tier;
  final int soCanTheoDoi;
  final int soThieu;

  const OverviewTierResult._({
    required this.status,
    this.tier,
    required this.soCanTheoDoi,
    required this.soThieu,
  });

  factory OverviewTierResult.insufficientData({
    required int soCanTheoDoi,
    required int soThieu,
  }) =>
      OverviewTierResult._(
        status: OverviewTierStatus.insufficientData,
        soCanTheoDoi: soCanTheoDoi,
        soThieu: soThieu,
      );

  factory OverviewTierResult.computed({
    required String tier,
    required int soCanTheoDoi,
    required int soThieu,
  }) =>
      OverviewTierResult._(
        status: OverviewTierStatus.computed,
        tier: tier,
        soCanTheoDoi: soCanTheoDoi,
        soThieu: soThieu,
      );

  bool get isInsufficientData => status == OverviewTierStatus.insufficientData;
}

/// Tính mức tổng quan cuối cùng ("Chân dung toàn cảnh") — 100% CODE THUẦN,
/// KHÔNG gọi AI, không phụ thuộc I/O — nhận vào đúng danh sách [labels] (mỗi
/// phần tử là 1 trong 3 giá trị `'thuong_gap'`/`'can_theo_doi'`/
/// `'chua_du_du_lieu'`, thường là 7 nhãn — 1 nhãn/lĩnh vực) rồi đếm + so
/// ngưỡng, không suy diễn gì thêm ngoài phép đếm. Toàn bộ hằng số ngưỡng
/// khai báo ở đầu file, có thể trace/debug độc lập với LLM.
OverviewTierResult calculateOverviewTier(List<String> labels) {
  final soThieu = labels.where((l) => l == labelChuaDuDuLieu).length;
  final soCanTheoDoi = labels.where((l) => l == labelCanTheoDoi).length;

  if (soThieu >= nguongThieuDuLieuToiThieu) {
    return OverviewTierResult.insufficientData(soCanTheoDoi: soCanTheoDoi, soThieu: soThieu);
  }

  final String tier;
  if (soCanTheoDoi <= nguongThuongGap) {
    tier = tierThuongGap;
  } else if (soCanTheoDoi <= nguongCanTheoDoi) {
    tier = tierCanTheoDoi;
  } else {
    tier = tierChuyenMonSom;
  }
  return OverviewTierResult.computed(tier: tier, soCanTheoDoi: soCanTheoDoi, soThieu: soThieu);
}
