/// Model hồ sơ trẻ, ánh xạ tới bảng `children`.
class Child {
  final String id;
  final String name;
  final String? dob;
  final int? ageYears;
  final String? gender;
  final String status;
  final DateTime createdAt;

  const Child({
    required this.id,
    required this.name,
    this.dob,
    this.ageYears,
    this.gender,
    this.status = 'active',
    required this.createdAt,
  });
}

/// Quy đổi tuổi trẻ sang THÁNG — dùng khi so sánh với
/// `expert_knowledge_chunks.do_tuoi_thang_min/max` (đơn vị tháng), khác đơn
/// vị với `Child.ageYears` (năm). Ưu tiên `dob` nếu có (tính chính xác số
/// tháng đã trôi qua đến hiện tại); nếu chỉ có `ageYears` thì quy đổi đơn
/// giản `ageYears * 12`.
int childAgeInMonths(Child child) {
  if (child.dob != null) {
    final dob = DateTime.parse(child.dob!);
    final now = DateTime.now();
    var months = (now.year - dob.year) * 12 + (now.month - dob.month);
    if (now.day < dob.day) {
      months -= 1;
    }
    return months < 0 ? 0 : months;
  }
  if (child.ageYears != null) {
    return child.ageYears! * 12;
  }
  throw StateError('Child ${child.id} không có dob lẫn ageYears để tính tuổi theo tháng');
}

/// Nhãn tuổi hiển thị trên UI, VD "3 tuổi 2 tháng" / "8 tháng tuổi".
String formatAgeLabel(Child child) {
  final months = childAgeInMonths(child);
  final years = months ~/ 12;
  final remainderMonths = months % 12;
  if (years <= 0) return '$remainderMonths tháng tuổi';
  if (remainderMonths == 0) return '$years tuổi';
  return '$years tuổi $remainderMonths tháng';
}
