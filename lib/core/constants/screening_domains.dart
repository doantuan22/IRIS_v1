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

/// Nhãn hiển thị cho 4 mức điểm (0-3) trong bài sàng lọc — index trùng
/// đúng giá trị điểm lưu ở cột `screening_answers.diem` (index 0 -> điểm
/// 0, ... index 3 -> điểm 3). CHỈ dùng cho hiển thị UI — KHÔNG liên quan
/// tới cách map lựa chọn sang giá trị điểm lưu trữ (giữ nguyên 0/1/2/3).
const List<String> screeningAnswerOptionLabels = [
  'Chưa làm được',
  'Làm được khi có hỗ trợ',
  'Làm được nhưng chưa ổn định',
  'Làm được độc lập và thường xuyên',
];

/// Nhãn hiển thị cho lựa chọn N/A (không tính điểm, `la_na = 1`).
const String screeningAnswerOptionLabelNa = 'Chưa quan sát được';

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

/// Tìm mức tuổi phù hợp với [ageMonths] — LUÔN trả về đúng 1 trong 4 mức,
/// KHÔNG BAO GIỜ trả `null`/lỗi. Trẻ ngoài dải 24-71 tháng được KẸP về mức
/// gần nhất thay vì bị chặn không làm được bài nào:
/// - `ageMonths < 24` (kể cả 0 tháng) -> kẹp về `'2_tuoi'` (mức thấp nhất).
/// - `ageMonths > 71` -> kẹp về `'5_tuoi'` (mức cao nhất).
/// - Trong dải 24-71 -> map đúng theo `monthsMin`/`monthsMax` từng mức.
///
/// Đây là hàm DUY NHẤT xác định mức tuổi làm bài từ số tháng tuổi — mọi
/// nơi cần map tuổi -> mức (UI làm bài, service...) phải gọi hàm này,
/// không tự viết lại logic map ở nơi khác.
ScreeningAgeTierRange resolveScreeningAgeTier(int ageMonths) {
  if (ageMonths < screeningAgeTierRanges.first.monthsMin) {
    return screeningAgeTierRanges.first;
  }
  if (ageMonths > screeningAgeTierRanges.last.monthsMax) {
    return screeningAgeTierRanges.last;
  }
  for (final range in screeningAgeTierRanges) {
    if (ageMonths >= range.monthsMin && ageMonths <= range.monthsMax) {
      return range;
    }
  }
  // Không thể tới đây nếu screeningAgeTierRanges là dải liên tục đầy đủ
  // 24-71 tháng như hiện tại — fallback an toàn về mức thấp nhất.
  return screeningAgeTierRanges.first;
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
