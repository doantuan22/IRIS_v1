/// Nhãn hợp lệ duy nhất cho `DomainOverviewLabel.nhan` — AI CHỈ được chọn 1
/// trong 3 giá trị này (xem `OverviewRepository.labelDomain`); giá trị nào
/// khác đều bị coi là sai định dạng và fallback về [labelChuaDuDuLieu].
const String labelThuongGap = 'thuong_gap';
const String labelCanTheoDoi = 'can_theo_doi';
const String labelChuaDuDuLieu = 'chua_du_du_lieu';

const Set<String> validDomainOverviewLabels = {
  labelThuongGap,
  labelCanTheoDoi,
  labelChuaDuDuLieu,
};

/// Giá trị CỐ ĐỊNH của [DomainOverviewLabel.lyDoNganGon] khi
/// `OverviewRepository.labelDomain` fallback về [labelChuaDuDuLieu] do LỖI
/// HỆ THỐNG (mạng, timeout, rate limit, parse response lỗi...) — PHÂN BIỆT
/// với trường hợp AI thật sự đánh giá "chưa đủ dữ liệu tham khảo" (khi đó
/// `lyDoNganGon` là văn bản AI tự sinh, khác chuỗi này) hoặc trẻ chưa có mô
/// tả cho lĩnh vực (`lyDoNganGon` = `null`). Dùng để nhận diện lỗi TẠM THỜI
/// đáng thử lại tự động — xem `OverviewPortraitPage`.
const String domainOverviewLabelSystemErrorReason =
    'Không gắn nhãn được do lỗi hệ thống, cần thử lại.';

/// Model nhãn tổng quan của 1 lĩnh vực, ánh xạ tới bảng
/// `domain_overview_labels`. Mỗi lần gắn nhãn tạo 1 dòng MỚI — bản ghi này
/// là 1 dòng lịch sử tại thời điểm [computedAt], không phải trạng thái duy
/// nhất hiện hành (xem `DomainOverviewLabelRepository.getLatestForChild`).
class DomainOverviewLabel {
  final String id;
  final String childId;
  final String linhVuc;
  final String nhan;
  final String? lyDoNganGon;
  final DateTime computedAt;

  const DomainOverviewLabel({
    required this.id,
    required this.childId,
    required this.linhVuc,
    required this.nhan,
    this.lyDoNganGon,
    required this.computedAt,
  });
}
