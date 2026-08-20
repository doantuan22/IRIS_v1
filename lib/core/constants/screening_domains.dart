/// 1 trong 5 lĩnh vực của bộ sàng lọc mới (4 mức tuổi × 20 câu). [code] khớp
/// giá trị `linh_vuc` lưu trong `screening_answers`/`screening_domain_results`.
///
/// ĐỘC LẬP HOÀN TOÀN với 7 lĩnh vực trong `domains.dart` (dùng cho phần
/// Đánh giá chi tiết) — không cố ép 2 bộ khớp nhau.
class ScreeningDomain {
  final String code;
  final String label;

  const ScreeningDomain({required this.code, required this.label});
}

/// Đúng thứ tự 5 lĩnh vực sàng lọc: Ngôn ngữ-giao tiếp, Nhận thức-giải
/// quyết vấn đề, Vận động (gồm 2 nhóm con: thô + tinh), Xã hội-cảm xúc,
/// Tự lập.
const List<ScreeningDomain> screeningDomains = [
  ScreeningDomain(code: 'ngon_ngu_giao_tiep', label: 'Ngôn ngữ - Giao tiếp'),
  ScreeningDomain(
    code: 'nhan_thuc_giai_quyet_van_de',
    label: 'Nhận thức - Giải quyết vấn đề',
  ),
  ScreeningDomain(code: 'van_dong', label: 'Vận động'),
  ScreeningDomain(code: 'xa_hoi_cam_xuc', label: 'Xã hội - Cảm xúc'),
  ScreeningDomain(code: 'tu_lap', label: 'Tự lập'),
];

/// 2 nhóm con của lĩnh vực `van_dong` — CHỈ áp dụng cho lĩnh vực này, các
/// lĩnh vực khác không có `nhom_van_dong` (NULL).
const String nhomVanDongTho = 'tho';
const String nhomVanDongTinh = 'tinh';

/// 4 mức tuổi làm bài sàng lọc — khớp giá trị `muc_tuoi_lam_bai` lưu trong
/// `screening_sessions`/`screening_answers`.
const List<String> screeningAgeTiers = ['2_tuoi', '3_tuoi', '4_tuoi', '5_tuoi'];

/// Dải tháng tuổi LIÊN TỤC cho từng mức — GIẢ ĐỊNH LÀM VIỆC, CẦN CHUYÊN GIA
/// XÁC NHẬN LẠI trước khi dùng chính thức (chưa phải thang đo đã kiểm định).
/// [monthsMin]/[monthsMax] dùng để tự động chọn đúng bộ câu hỏi theo tuổi
/// trẻ (`childAgeInMonths()`); [representativeMonths] dùng khi người dùng
/// chọn TRỰC TIẾP 1 mức tuổi (không có ngày sinh) — quy đổi thành `dob` gần
/// đúng qua `dobFromAgeInMonths()`.
class ScreeningAgeTierRange {
  final String tier;
  final int monthsMin;
  final int monthsMax;
  final int representativeMonths;

  const ScreeningAgeTierRange({
    required this.tier,
    required this.monthsMin,
    required this.monthsMax,
    required this.representativeMonths,
  });
}

const List<ScreeningAgeTierRange> screeningAgeTierRanges = [
  ScreeningAgeTierRange(
    tier: '2_tuoi',
    monthsMin: 24,
    monthsMax: 35,
    representativeMonths: 29,
  ),
  ScreeningAgeTierRange(
    tier: '3_tuoi',
    monthsMin: 36,
    monthsMax: 47,
    representativeMonths: 41,
  ),
  ScreeningAgeTierRange(
    tier: '4_tuoi',
    monthsMin: 48,
    monthsMax: 59,
    representativeMonths: 53,
  ),
  ScreeningAgeTierRange(
    tier: '5_tuoi',
    monthsMin: 60,
    monthsMax: 71,
    representativeMonths: 65,
  ),
];

/// Tìm mức tuổi phù hợp với [ageMonths] — trả `null` nếu ngoài mọi dải
/// (dưới 24 tháng hoặc trên 71 tháng), gọi nơi dùng phải tự xử lý rõ ràng
/// trường hợp `null` (KHÔNG mặc định chọn liều 1 mức nào).
ScreeningAgeTierRange? screeningAgeTierForMonths(int ageMonths) {
  for (final range in screeningAgeTierRanges) {
    if (ageMonths >= range.monthsMin && ageMonths <= range.monthsMax) {
      return range;
    }
  }
  return null;
}

/// Nhãn hiển thị cho 1 mức tuổi, VD '2_tuoi' -> '2 tuổi'.
String screeningAgeTierLabel(String tier) {
  switch (tier) {
    case '2_tuoi':
      return '2 tuổi';
    case '3_tuoi':
      return '3 tuổi';
    case '4_tuoi':
      return '4 tuổi';
    case '5_tuoi':
      return '5 tuổi';
    default:
      return tier;
  }
}
