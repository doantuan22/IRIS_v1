import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/history_log_repository.dart';
import 'package:iris_app/data/repositories/video_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test VideoRepository + HistoryLogRepository (Giai đoạn 5 — Quay video).
/// Chạy trên desktop qua sqflite_common_ffi, không cần thiết bị/emulator.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    appDatabase = AppDatabase.instance;
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('VideoRepository: lưu video mới mặc định status pending khi truyền vào, đọc lại đúng theo trẻ', () async {
    final childRepo = ChildRepository(appDatabase);
    final videoRepo = VideoRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé An', ageYears: 3);
    final video = await videoRepo.save(
      childId: child.id,
      filePath: '/data/videos/abc.mp4',
      situation: 'Trẻ chơi cùng người khác',
      status: 'pending',
    );

    expect(video.status, 'pending');

    final list = await videoRepo.getForChild(child.id);
    expect(list.length, 1);
    expect(list.first.situation, 'Trẻ chơi cùng người khác');
    expect(list.first.filePath, '/data/videos/abc.mp4');
    // ignore: avoid_print
    print('PASS: VideoRepository.save + getForChild lưu và đọc đúng dữ liệu video');
  });

  test('VideoRepository: getForChild chỉ trả video của đúng trẻ, không lẫn trẻ khác', () async {
    final childRepo = ChildRepository(appDatabase);
    final videoRepo = VideoRepository(appDatabase);

    final childA = await childRepo.create(name: 'Bé A', ageYears: 3);
    final childB = await childRepo.create(name: 'Bé B', ageYears: 4);

    await videoRepo.save(childId: childA.id, filePath: '/a1.mp4', situation: 'Tình huống A1', status: 'pending');
    await videoRepo.save(childId: childB.id, filePath: '/b1.mp4', situation: 'Tình huống B1', status: 'pending');

    final listA = await videoRepo.getForChild(childA.id);
    final listB = await videoRepo.getForChild(childB.id);

    expect(listA.length, 1);
    expect(listA.first.situation, 'Tình huống A1');
    expect(listB.length, 1);
    expect(listB.first.situation, 'Tình huống B1');
    // ignore: avoid_print
    print('PASS: VideoRepository.getForChild lọc đúng theo child_id, không lẫn giữa các trẻ');
  });

  test('VideoRepository: updateStatus cập nhật status + expert_note (mô phỏng chuyên gia phản hồi)', () async {
    final childRepo = ChildRepository(appDatabase);
    final videoRepo = VideoRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé Chi', ageYears: 3);
    final video = await videoRepo.save(
      childId: child.id,
      filePath: '/data/videos/xyz.mp4',
      situation: 'Phản ứng khi được gọi tên',
      status: 'pending',
    );

    await videoRepo.updateStatus(video.id, 'reviewed', expertNote: 'Nhận xét mẫu của chuyên gia');

    final list = await videoRepo.getForChild(child.id);
    expect(list.length, 1);
    expect(list.first.status, 'reviewed');
    expect(list.first.expertNote, 'Nhận xét mẫu của chuyên gia');
    // ignore: avoid_print
    print('PASS: VideoRepository.updateStatus cập nhật đúng status + expert_note');
  });

  test('VideoRepository: delete xoá đúng bản ghi', () async {
    final childRepo = ChildRepository(appDatabase);
    final videoRepo = VideoRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé Dương', ageYears: 3);
    final video = await videoRepo.save(childId: child.id, filePath: '/d1.mp4', status: 'pending');

    await videoRepo.delete(video.id);

    final list = await videoRepo.getForChild(child.id);
    expect(list, isEmpty);
    // ignore: avoid_print
    print('PASS: VideoRepository.delete xoá đúng video khỏi bảng videos');
  });

  test('HistoryLogRepository: add + getForChild ghi và đọc đúng event video, sắp xếp mới nhất trước', () async {
    final childRepo = ChildRepository(appDatabase);
    final historyRepo = HistoryLogRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé Em', ageYears: 3);

    await historyRepo.add(
      childId: child.id,
      eventType: 'video',
      description: 'Quay video tình huống: Chia sẻ đồ chơi',
      eventDate: DateTime(2026, 1, 1),
    );
    await historyRepo.add(
      childId: child.id,
      eventType: 'video',
      description: 'Quay video tình huống: Giúp đỡ người khác',
      eventDate: DateTime(2026, 1, 2),
    );

    final list = await historyRepo.getForChild(child.id);
    expect(list.length, 2);
    expect(list.first.description, contains('Giúp đỡ người khác'));
    expect(list.every((log) => log.eventType == 'video'), true);
    // ignore: avoid_print
    print('PASS: HistoryLogRepository.add + getForChild ghi nhận đúng sự kiện video, sắp xếp mới nhất trước');
  });
}
