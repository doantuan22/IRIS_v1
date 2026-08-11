import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/models/child.dart';

/// Test hàm quy đổi tuổi trẻ sang tháng (childAgeInMonths) — dùng để so
/// sánh với expert_knowledge_chunks.do_tuoi_thang_min/max (đơn vị tháng),
/// khác đơn vị với Child.ageYears (năm).
void main() {
  test('childAgeInMonths: có dob ~365 ngày trước → xấp xỉ 12 tháng', () {
    final dob = DateTime.now().subtract(const Duration(days: 365));
    final child = Child(
      id: '1',
      name: 'Bé Ẩn',
      dob: dob.toIso8601String(),
      createdAt: DateTime.now(),
    );

    final months = childAgeInMonths(child);
    expect(months, inInclusiveRange(11, 12));
    // ignore: avoid_print
    print('PASS: childAgeInMonths dob ~1 năm trước => $months tháng (kỳ vọng 11-12)');
  });

  test('childAgeInMonths: dob mới 1 ngày trước → 0 tháng', () {
    final dob = DateTime.now().subtract(const Duration(days: 1));
    final child = Child(
      id: '2',
      name: 'Bé Bo',
      dob: dob.toIso8601String(),
      createdAt: DateTime.now(),
    );

    expect(childAgeInMonths(child), 0);
    // ignore: avoid_print
    print('PASS: childAgeInMonths dob 1 ngày trước => 0 tháng');
  });

  test('childAgeInMonths: chỉ có ageYears → quy đổi *12', () {
    final child = Child(
      id: '3',
      name: 'Bé Cún',
      ageYears: 3,
      createdAt: DateTime.now(),
    );

    expect(childAgeInMonths(child), 36);
    // ignore: avoid_print
    print('PASS: childAgeInMonths ageYears=3 => 36 tháng');
  });

  test('childAgeInMonths: không có dob lẫn ageYears → throw', () {
    final child = Child(id: '4', name: 'Bé Không rõ tuổi', createdAt: DateTime.now());
    expect(() => childAgeInMonths(child), throwsStateError);
    // ignore: avoid_print
    print('PASS: childAgeInMonths không có dob/ageYears => throw StateError');
  });
}
