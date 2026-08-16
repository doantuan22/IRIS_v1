import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/models/child.dart';

/// Test hàm quy đổi tuổi trẻ sang tháng (childAgeInMonths),
/// hàm quy đổi tháng sang dob (dobFromAgeInMonths), và định dạng nhãn tuổi (formatAgeLabel).
void main() {
  group('childAgeInMonths', () {
    test('có dob ~365 ngày trước → xấp xỉ 12 tháng', () {
      final dob = DateTime.now().subtract(const Duration(days: 365));
      final child = Child(
        id: '1',
        name: 'Bé Ẩn',
        dob: dob.toIso8601String(),
        createdAt: DateTime.now(),
      );

      final months = childAgeInMonths(child);
      expect(months, inInclusiveRange(11, 12));
    });

    test('dob mới 1 ngày trước → 0 tháng', () {
      final dob = DateTime.now().subtract(const Duration(days: 1));
      final child = Child(
        id: '2',
        name: 'Bé Bo',
        dob: dob.toIso8601String(),
        createdAt: DateTime.now(),
      );

      expect(childAgeInMonths(child), 0);
    });

    test('hồ sơ cũ: chỉ có ageYears → quy đổi *12', () {
      final child = Child(
        id: '3',
        name: 'Bé Cún',
        ageYears: 3,
        createdAt: DateTime.now(),
      );

      expect(childAgeInMonths(child), 36);
    });

    test('không có dob lẫn ageYears → throw StateError', () {
      final child = Child(
        id: '4',
        name: 'Bé Không rõ tuổi',
        createdAt: DateTime.now(),
      );
      expect(() => childAgeInMonths(child), throwsStateError);
    });
  });

  group('dobFromAgeInMonths', () {
    test('input 18 tháng → round-trip childAgeInMonths ra đúng 18 tháng', () {
      final dob = dobFromAgeInMonths(18);
      final child = Child(
        id: '18m',
        name: 'Bé 18 Tháng',
        dob: dob.toIso8601String(),
        createdAt: DateTime.now(),
      );

      expect(childAgeInMonths(child), 18);
      expect(formatAgeLabel(child), '1 tuổi 6 tháng');
    });

    test('input 1 tháng → round-trip ra đúng 1 tháng', () {
      final dob = dobFromAgeInMonths(1);
      final child = Child(
        id: '1m',
        name: 'Bé 1 Tháng',
        dob: dob.toIso8601String(),
        createdAt: DateTime.now(),
      );

      expect(childAgeInMonths(child), 1);
      expect(formatAgeLabel(child), '1 tháng tuổi');
    });

    test('input 60 tháng (5 tuổi) → round-trip ra đúng 60 tháng', () {
      final dob = dobFromAgeInMonths(60);
      final child = Child(
        id: '60m',
        name: 'Bé 5 Tuổi',
        dob: dob.toIso8601String(),
        createdAt: DateTime.now(),
      );

      expect(childAgeInMonths(child), 60);
      expect(formatAgeLabel(child), '5 tuổi');
    });

    test('xử lý biên ngày cuối tháng: 31/03/2026 trừ 1 tháng → 28/02/2026 (năm không nhuận)', () {
      final fixedNow = DateTime(2026, 3, 31);
      final dob = dobFromAgeInMonths(1, fixedNow);

      expect(dob.year, 2026);
      expect(dob.month, 2);
      expect(dob.day, 28);
    });

    test('xử lý biên ngày cuối tháng: 31/03/2024 trừ 1 tháng → 29/02/2024 (năm nhuận)', () {
      final fixedNow = DateTime(2024, 3, 31);
      final dob = dobFromAgeInMonths(1, fixedNow);

      expect(dob.year, 2024);
      expect(dob.month, 2);
      expect(dob.day, 29);
    });

    test('xử lý biên ngày cuối tháng: 31/05/2026 trừ 1 tháng → 30/04/2026', () {
      final fixedNow = DateTime(2026, 5, 31);
      final dob = dobFromAgeInMonths(1, fixedNow);

      expect(dob.year, 2026);
      expect(dob.month, 4);
      expect(dob.day, 30);
    });

    test('xử lý tràn nhiều năm: 15/01/2026 trừ 25 tháng → 15/12/2023', () {
      final fixedNow = DateTime(2026, 1, 15);
      final dob = dobFromAgeInMonths(25, fixedNow);

      expect(dob.year, 2023);
      expect(dob.month, 12);
      expect(dob.day, 15);
    });

    test('input số tháng âm → ném ArgumentError', () {
      expect(() => dobFromAgeInMonths(-5), throwsArgumentError);
    });
  });

  group('formatAgeLabel', () {
    test('hồ sơ có dob: 18 tháng → "1 tuổi 6 tháng"', () {
      final dob = dobFromAgeInMonths(18);
      final child = Child(id: 'c', name: 'Test', dob: dob.toIso8601String(), createdAt: DateTime.now());
      expect(formatAgeLabel(child), '1 tuổi 6 tháng');
    });

    test('hồ sơ có dob: 24 tháng → "2 tuổi"', () {
      final dob = dobFromAgeInMonths(24);
      final child = Child(id: 'c', name: 'Test', dob: dob.toIso8601String(), createdAt: DateTime.now());
      expect(formatAgeLabel(child), '2 tuổi');
    });

    test('hồ sơ có dob: 8 tháng → "8 tháng tuổi"', () {
      final dob = dobFromAgeInMonths(8);
      final child = Child(id: 'c', name: 'Test', dob: dob.toIso8601String(), createdAt: DateTime.now());
      expect(formatAgeLabel(child), '8 tháng tuổi');
    });

    test('hồ sơ cũ (chỉ có ageYears): ageYears = 2 → "2 tuổi"', () {
      final child = Child(id: 'legacy', name: 'Bé Cũ', ageYears: 2, createdAt: DateTime.now());
      expect(formatAgeLabel(child), '2 tuổi');
    });
  });
}
