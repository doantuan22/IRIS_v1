import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/profile_chunk_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test nền tảng dữ liệu Giai đoạn 1 — không đụng tới UI, không gọi API
/// NVIDIA/Groq. Chạy trên desktop qua sqflite_common_ffi (không cần
/// thiết bị/emulator Android).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;

  setUp(() {
    // AppDatabase.instance là singleton — ghi đè đường dẫn sang in-memory
    // (":memory:") để mỗi test chạy trên 1 database sạch, không cần
    // path_provider (vốn cần platform channel thật, không có trong Dart VM
    // test).
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    appDatabase = AppDatabase.instance;
  });

  tearDown(() async {
    final db = await appDatabase.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  test('ChildRepository: tạo và đọc hồ sơ trẻ', () async {
    final repo = ChildRepository(appDatabase);

    final child = await repo.create(name: 'Bé An', ageYears: 3, gender: 'nam');
    final all = await repo.getAll();
    final byId = await repo.getById(child.id);

    expect(all.length, 1);
    expect(byId?.name, 'Bé An');
    // ignore: avoid_print
    print('PASS: ChildRepository tạo + đọc hồ sơ trẻ');
  });

  test('ChildRepository: tạo hồ sơ có "Người đánh giá" + "Vai trò" đọc lại đúng, không điền thì null',
      () async {
    final repo = ChildRepository(appDatabase);

    final withRole = await repo.create(
      name: 'Bé Có Vai Trò',
      ageYears: 4,
      nguoiDanhGia: 'Cô Lan',
      vaiTro: 'Giáo viên',
    );
    final withoutRole = await repo.create(name: 'Bé Không Vai Trò', ageYears: 4);

    final readWithRole = await repo.getById(withRole.id);
    final readWithoutRole = await repo.getById(withoutRole.id);

    expect(readWithRole?.nguoiDanhGia, 'Cô Lan');
    expect(readWithRole?.vaiTro, 'Giáo viên');
    expect(readWithoutRole?.nguoiDanhGia, isNull);
    expect(readWithoutRole?.vaiTro, isNull);
    // ignore: avoid_print
    print('PASS: ChildRepository lưu + đọc đúng "nguoi_danh_gia"/"vai_tro", null khi không điền');
  });

  test('ScreeningRepository: hasScreening phản ánh đúng có/chưa sàng lọc', () async {
    final childRepo = ChildRepository(appDatabase);
    final screeningRepo = ScreeningRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé Bình', ageYears: 2);

    final before = await screeningRepo.hasScreening(child.id);
    expect(before, false);

    await screeningRepo.save(
      childId: child.id,
      toolName: 'M-CHAT-R',
      score: '3',
      resultSummary: 'Kết quả sàng lọc tham khảo, không phải chẩn đoán',
      performedAt: DateTime.now(),
    );

    final after = await screeningRepo.hasScreening(child.id);
    expect(after, true);
    // ignore: avoid_print
    print('PASS: ScreeningRepository.hasScreening() = false trước, true sau khi thêm');
  });

  test('AssessmentRepository: thêm mô tả biểu hiện theo lĩnh vực', () async {
    final childRepo = ChildRepository(appDatabase);
    final assessmentRepo = AssessmentRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé Chi', ageYears: 3);
    await assessmentRepo.save(
      childId: child.id,
      linhVuc: 'ngon_ngu',
      content: 'Bé nói được câu 2-3 từ, hay lặp lại lời người lớn',
      nguon: 'phu_huynh',
    );

    final list = await assessmentRepo.getForChild(child.id, linhVuc: 'ngon_ngu');
    expect(list.length, 1);
    expect(list.first.contentType, 'mo_ta');
    // ignore: avoid_print
    print('PASS: AssessmentRepository thêm + đọc mô tả biểu hiện');
  });

  test('ProfileChunkRepository: encode/decode BLOB embedding không sai lệch', () async {
    final childRepo = ChildRepository(appDatabase);
    final chunkRepo = ProfileChunkRepository(appDatabase);

    final child = await childRepo.create(name: 'Bé Dương', ageYears: 3);
    final fakeEmbedding = List<double>.generate(768, (i) => i.toDouble());

    await chunkRepo.add(
      childId: child.id,
      content: 'Bé thích chơi xếp hình một mình',
      linhVuc: 'nhan_thuc',
      embedding: fakeEmbedding,
    );

    final rows = await chunkRepo.getForChild(child.id);
    expect(rows.length, 1);
    expect(rows.first.embedding.length, fakeEmbedding.length);
    for (var i = 0; i < fakeEmbedding.length; i++) {
      expect(rows.first.embedding[i], closeTo(fakeEmbedding[i], 1e-6));
    }
    // ignore: avoid_print
    print('PASS: ProfileChunkRepository encode/decode embedding 768 chiều khớp giá trị gốc');
  });

  test('ExpertKnowledgeRepository: query theo lĩnh vực + độ tuổi lọc đúng', () async {
    final expertRepo = ExpertKnowledgeRepository(appDatabase);

    await expertRepo.add(
      content: 'Tham khảo ngôn ngữ 24-36 tháng',
      contentType: 'so_sanh',
      linhVuc: 'ngon_ngu',
      doTuoiThangMin: 24,
      doTuoiThangMax: 36,
      embedding: [0.1, 0.2, 0.3],
    );
    await expertRepo.add(
      content: 'Tham khảo ngôn ngữ 36-48 tháng',
      contentType: 'so_sanh',
      linhVuc: 'ngon_ngu',
      doTuoiThangMin: 36,
      doTuoiThangMax: 48,
      embedding: [0.4, 0.5, 0.6],
    );
    await expertRepo.add(
      content: 'Tham khảo nhận thức 24-36 tháng',
      contentType: 'so_sanh',
      linhVuc: 'nhan_thuc',
      doTuoiThangMin: 24,
      doTuoiThangMax: 36,
      embedding: [0.7, 0.8, 0.9],
    );

    final result = await expertRepo.query(linhVuc: 'ngon_ngu', ageInMonths: 30);
    expect(result.length, 1);
    expect(result.first.content, contains('24-36'));

    final resultOverlap = await expertRepo.query(linhVuc: 'ngon_ngu', ageInMonths: 36);
    expect(resultOverlap.length, 2);

    // ignore: avoid_print
    print('PASS: ExpertKnowledgeRepository.query lọc đúng theo linh_vuc + độ tuổi');
  });

  test('ExpertKnowledgeRepository: lưu + đọc đúng "phan_loai" cho content_type="so_sanh"', () async {
    final expertRepo = ExpertKnowledgeRepository(appDatabase);

    await expertRepo.add(
      content: 'Biểu hiện thường gặp mẫu',
      contentType: 'so_sanh',
      phanLoai: 'thuong_gap',
      linhVuc: 'quan_he_xa_hoi',
      doTuoiThangMin: 48,
      doTuoiThangMax: 71,
      embedding: [0.1, 0.2],
    );
    await expertRepo.add(
      content: 'Cần quan sát thêm mẫu',
      contentType: 'so_sanh',
      phanLoai: 'can_quan_sat',
      linhVuc: 'quan_he_xa_hoi',
      doTuoiThangMin: 48,
      doTuoiThangMax: 71,
      embedding: [0.3, 0.4],
    );

    final result = await expertRepo.query(linhVuc: 'quan_he_xa_hoi', ageInMonths: 60, contentType: 'so_sanh');
    expect(result.length, 2);
    expect(result.firstWhere((c) => c.content.contains('thường gặp')).phanLoai, 'thuong_gap');
    expect(result.firstWhere((c) => c.content.contains('quan sát thêm')).phanLoai, 'can_quan_sat');
    // ignore: avoid_print
    print('PASS: ExpertKnowledgeRepository lưu + đọc đúng phan_loai cho so_sanh');
  });
}
