import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/profile_chunk_repository.dart';
import 'package:iris_app/domain/services/vector_search_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late VectorSearchService service;
  late ProfileChunkRepository profileChunkRepository;
  late ExpertKnowledgeRepository expertKnowledgeRepository;

  setUp(() {
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
    profileChunkRepository = ProfileChunkRepository(AppDatabase.instance);
    expertKnowledgeRepository = ExpertKnowledgeRepository(AppDatabase.instance);
    service = VectorSearchService(profileChunkRepository, expertKnowledgeRepository);
  });

  tearDown(() async {
    final db = await AppDatabase.instance.database;
    await db.close();
    AppDatabase.resetForTest();
  });

  group('cosineSimilarity', () {
    test('vector giống hệt nhau => 1.0', () {
      expect(service.cosineSimilarity([1, 2, 3], [1, 2, 3]), closeTo(1.0, 1e-9));
    });

    test('vector trực giao => 0.0', () {
      expect(service.cosineSimilarity([1, 0], [0, 1]), closeTo(0.0, 1e-9));
    });

    test('vector ngược chiều => -1.0', () {
      expect(service.cosineSimilarity([1, 2], [-1, -2]), closeTo(-1.0, 1e-9));
    });

    test('vector 0 không chia cho 0 (trả 0 thay vì NaN)', () {
      expect(service.cosineSimilarity([0, 0], [1, 1]), 0.0);
    });

    test('vector khác chiều dài => trả 0, KHÔNG ném lỗi (dữ liệu embedding không đồng nhất)', () {
      expect(service.cosineSimilarity([1, 0, 0], [1, 0]), 0.0);
      expect(service.cosineSimilarity([1, 0], [1, 0, 0, 0]), 0.0);
      expect(service.cosineSimilarity(<double>[], [1, 0]), 0.0);
      // ignore: avoid_print
      print('PASS: cosineSimilarity xử lý có kiểm soát khi 2 vector khác chiều dài, không throw');
    });
  });

  test('searchProfileChunks: sắp xếp giảm dần theo similarity và giới hạn đúng topK', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Test', ageYears: 3);

    await profileChunkRepository.add(
      childId: child.id,
      content: 'ít liên quan',
      embedding: [0, 1],
    );
    await profileChunkRepository.add(
      childId: child.id,
      content: 'liên quan nhất',
      embedding: [1, 0],
    );
    await profileChunkRepository.add(
      childId: child.id,
      content: 'liên quan vừa',
      embedding: [0.7, 0.7],
    );

    final result = await service.searchProfileChunks(child.id, [1, 0], topK: 2);

    expect(result.length, 2);
    expect(result[0].chunk.content, 'liên quan nhất');
    expect(result[1].chunk.content, 'liên quan vừa');
    expect(result[0].similarity, greaterThan(result[1].similarity));
    // ignore: avoid_print
    print('PASS: searchProfileChunks sắp xếp đúng + giới hạn topK');
  });

  test('searchExpertChunks: lọc theo độ tuổi TRƯỚC khi tính similarity', () async {
    // Similarity cao nhất nhưng SAI độ tuổi (6-12 tháng, hỏi ở tháng 30) — phải bị loại.
    await expertKnowledgeRepository.add(
      content: 'sai độ tuổi nhưng embedding giống hệt câu hỏi',
      contentType: 'so_sanh',
      doTuoiThangMin: 6,
      doTuoiThangMax: 12,
      embedding: [1, 0],
    );
    // Đúng độ tuổi, similarity thấp hơn.
    await expertKnowledgeRepository.add(
      content: 'đúng độ tuổi',
      contentType: 'so_sanh',
      doTuoiThangMin: 24,
      doTuoiThangMax: 36,
      embedding: [0.9, 0.1],
    );

    final result = await service.searchExpertChunks(30, [1, 0]);

    expect(result.length, 1);
    expect(result.first.chunk.content, 'đúng độ tuổi');
    // ignore: avoid_print
    print('PASS: searchExpertChunks loại đúng chunk sai độ tuổi dù similarity cao hơn');
  });
}
