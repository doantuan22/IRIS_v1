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
