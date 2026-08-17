import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/notification_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('NotificationRepository CRUD operations work properly', () async {
    final repo = NotificationRepository(AppDatabase.instance);

    // Initial state: empty
    final initialList = await repo.getAll();
    expect(initialList, isEmpty);

    // Add 2 notifications
    final n1 = await repo.add(
      title: 'Kết nối AI',
      content: 'Kết nối AI đang gặp vấn đề.',
      type: 'ai_connectivity',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final n2 = await repo.add(
      title: 'Kết nối AI',
      content: 'Đã có thể kết nối AI.',
      type: 'ai_connectivity',
      createdAt: DateTime.now(),
    );

    expect(n1.id, isNotEmpty);
    expect(n2.id, isNotEmpty);

    // getAll returns descending by created_at (n2 first, then n1)
    final list = await repo.getAll();
    expect(list.length, equals(2));
    expect(list.first.id, equals(n2.id));
    expect(list.first.content, equals('Đã có thể kết nối AI.'));
    expect(list.first.isRead, isFalse);

    // Mark n1 as read
    await repo.markAsRead(n1.id);
    final listAfterRead = await repo.getAll();
    final updatedN1 = listAfterRead.firstWhere((x) => x.id == n1.id);
    final updatedN2 = listAfterRead.firstWhere((x) => x.id == n2.id);
    expect(updatedN1.isRead, isTrue);
    expect(updatedN2.isRead, isFalse);

    // Mark all as read
    await repo.markAllAsRead();
    final listAllRead = await repo.getAll();
    expect(listAllRead.every((x) => x.isRead), isTrue);

    // Clear all
    await repo.clearAll();
    final emptyList = await repo.getAll();
    expect(emptyList, isEmpty);
  });
}
