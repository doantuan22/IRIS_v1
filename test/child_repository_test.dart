import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/ai_conversation_repository.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/history_log_repository.dart';
import 'package:iris_app/data/repositories/profile_chunk_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:iris_app/data/repositories/video_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test ChildRepository (Dashboard nhiều trẻ — Phụ lục 1): trọng tâm là
/// `delete()` vì `PRAGMA foreign_keys = ON` (bật trong AppDatabase) chặn xoá
/// `children` nếu còn dòng tham chiếu ở bảng khác — không bảng nào khai báo
/// `ON DELETE CASCADE` trong schema, nên đây là rủi ro crash cao nhất.
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

  test('archive/unarchive cập nhật đúng status, getAll(includeArchived:false) ẩn hồ sơ đã lưu trữ',
      () async {
    final childRepo = ChildRepository(AppDatabase.instance);
    final child = await childRepo.create(name: 'Bé Archive Test', ageYears: 4);

    expect((await childRepo.getAll()).map((c) => c.id), contains(child.id));

    await childRepo.archive(child.id);
    expect((await childRepo.getAll()).map((c) => c.id), isNot(contains(child.id)));
    expect((await childRepo.getAll(includeArchived: true)).map((c) => c.id), contains(child.id));
    final archived = await childRepo.getById(child.id);
    expect(archived!.status, 'archived');

    await childRepo.unarchive(child.id);
    expect((await childRepo.getAll()).map((c) => c.id), contains(child.id));
    final restored = await childRepo.getById(child.id);
    expect(restored!.status, 'active');
    // ignore: avoid_print
    print('PASS: archive() ẩn khỏi getAll() mặc định, unarchive() khôi phục lại đúng status');
  });

  test(
      'delete() xoá đúng toàn bộ dữ liệu liên quan ở 6 bảng con và xoá được children — '
      'không lỗi ràng buộc khoá ngoại dù PRAGMA foreign_keys=ON', () async {
    final childRepo = ChildRepository(AppDatabase.instance);
    final screeningRepo = ScreeningRepository(AppDatabase.instance);
    final assessmentRepo = AssessmentRepository(AppDatabase.instance);
    final historyLogRepo = HistoryLogRepository(AppDatabase.instance);
    final profileChunkRepo = ProfileChunkRepository(AppDatabase.instance);
    final videoRepo = VideoRepository(AppDatabase.instance);
    final aiConversationRepo = AiConversationRepository(AppDatabase.instance);

    final child = await childRepo.create(name: 'Bé Delete Test', ageYears: 5);

    // Tạo dữ liệu liên quan ở đủ 6 bảng con tham chiếu child_id.
    await screeningRepo.save(childId: child.id, toolName: 'mock', score: '1/6');
    await assessmentRepo.save(childId: child.id, linhVuc: 'ngon_ngu', content: 'mô tả test');
    await historyLogRepo.add(childId: child.id, eventType: 'sang_loc', description: 'test');
    await profileChunkRepo.add(childId: child.id, content: 'chunk test', embedding: [0.1, 0.2, 0.3]);
    await videoRepo.save(childId: child.id, filePath: '/fake/path.mp4', situation: 'test');
    await aiConversationRepo.save(
      childId: child.id,
      question: 'câu hỏi test',
      answer: 'câu trả lời test',
      state: 1,
    );

    // Xác nhận dữ liệu đã thực sự tồn tại trước khi xoá.
    expect(await screeningRepo.getForChild(child.id), isNotEmpty);
    expect(await assessmentRepo.getForChild(child.id), isNotEmpty);
    expect(await historyLogRepo.getForChild(child.id), isNotEmpty);
    expect(await profileChunkRepo.getForChild(child.id), isNotEmpty);
    expect(await videoRepo.getForChild(child.id), isNotEmpty);
    expect(await aiConversationRepo.getForChild(child.id), isNotEmpty);

    // Đây là bước rủi ro nhất — không được ném lỗi ràng buộc khoá ngoại.
    await childRepo.delete(child.id);

    expect(await childRepo.getById(child.id), isNull);
    expect(await screeningRepo.getForChild(child.id), isEmpty);
    expect(await assessmentRepo.getForChild(child.id), isEmpty);
    expect(await historyLogRepo.getForChild(child.id), isEmpty);
    expect(await profileChunkRepo.getForChild(child.id), isEmpty);
    expect(await videoRepo.getForChild(child.id), isEmpty);
    expect(await aiConversationRepo.getForChild(child.id), isEmpty);
    // ignore: avoid_print
    print('PASS: delete() xoá sạch dữ liệu ở 6 bảng con + bảng children, không lỗi khoá ngoại');
  });

  test(
      'delete() xoá cả file .mp4 vật lý của mọi video thuộc trẻ đó — không để lại dữ liệu mồ côi trên đĩa',
      () async {
    final childRepo = ChildRepository(AppDatabase.instance);
    final videoRepo = VideoRepository(AppDatabase.instance);

    final tempDir = await Directory.systemTemp.createTemp('iris_child_delete_test_');
    final videoFileA = File('${tempDir.path}/a.mp4');
    final videoFileB = File('${tempDir.path}/b.mp4');
    await videoFileA.writeAsBytes([1]);
    await videoFileB.writeAsBytes([2]);

    try {
      final child = await childRepo.create(name: 'Bé Nhiều Video', ageYears: 4);
      await videoRepo.save(childId: child.id, filePath: videoFileA.path, situation: 'Tình huống 1');
      await videoRepo.save(childId: child.id, filePath: videoFileB.path, situation: 'Tình huống 2');

      expect(await videoFileA.exists(), isTrue);
      expect(await videoFileB.exists(), isTrue);

      await childRepo.delete(child.id);

      expect(await childRepo.getById(child.id), isNull);
      expect(await videoRepo.getForChild(child.id), isEmpty);
      expect(await videoFileA.exists(), isFalse);
      expect(await videoFileB.exists(), isFalse);
      // ignore: avoid_print
      print('PASS: ChildRepository.delete() xoá sạch file .mp4 vật lý của mọi video thuộc trẻ đã xoá');
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('delete() không ảnh hưởng dữ liệu của trẻ khác', () async {
    final childRepo = ChildRepository(AppDatabase.instance);
    final assessmentRepo = AssessmentRepository(AppDatabase.instance);

    final childA = await childRepo.create(name: 'Bé A', ageYears: 3);
    final childB = await childRepo.create(name: 'Bé B', ageYears: 4);
    await assessmentRepo.save(childId: childA.id, linhVuc: 'hanh_vi', content: 'mô tả A');
    await assessmentRepo.save(childId: childB.id, linhVuc: 'hanh_vi', content: 'mô tả B');

    await childRepo.delete(childA.id);

    expect(await childRepo.getById(childA.id), isNull);
    expect(await childRepo.getById(childB.id), isNotNull);
    expect(await assessmentRepo.getForChild(childB.id), isNotEmpty);
    // ignore: avoid_print
    print('PASS: xoá 1 trẻ không ảnh hưởng dữ liệu assessments của trẻ khác');
  });
}
