import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/core/constants/api_config.dart';
import 'package:iris_app/core/constants/domains.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:iris_app/data/repositories/ai_conversation_repository.dart';
import 'package:iris_app/data/repositories/ai_repository.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/overview_repository.dart';
import 'package:iris_app/data/repositories/overview_summary_repository.dart';
import 'package:iris_app/data/repositories/profile_chunk_repository.dart';
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

  group(
    'End-to-End Real Cloud AI Verification (NVIDIA & Groq)',
    skip: !ApiConfig.hasAiConfig ? 'Bỏ qua khi chạy flutter test mặc định không truyền --dart-define' : null,
    () {
    test('Xác nhận API keys đã được nạp thành công từ dart_define.json', () {
      expect(ApiConfig.hasNvidiaApiKey, isTrue, reason: 'NVIDIA_API_KEY không được để trống');
      expect(ApiConfig.hasGroqApiKey, isTrue, reason: 'GROQ_API_KEY không được để trống');
      expect(ApiConfig.hasAiConfig, isTrue, reason: 'Toàn bộ cấu hình AI phải sẵn sàng');
      // ignore: avoid_print
      print('=== [PASS] API keys đã được nạp qua compile-time constant thành công ===');
    });

    test('a. Gọi NVIDIA NIM Embedding THẬT -> Vector float thật được lưu vào profile_chunks', () async {
      final nvidiaClient = NvidiaApiClient();
      final sampleText = 'Bé 3 tuổi rất thích xếp các khối gỗ theo hàng thẳng và lặp đi lặp lại';

      // 1. Gọi trực tiếp API NVIDIA NIM
      final embedding = await nvidiaClient.embed(sampleText);
      expect(embedding, isNotEmpty);
      expect(embedding.length, greaterThan(100)); // nv-embedqa-e5-v5 trả về vector 1024 chiều

      // 2. Lưu vào profile_chunks
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Test Real AI',
        ageYears: 3,
      );

      final chunkRepo = ProfileChunkRepository(AppDatabase.instance);
      final createdChunk = await chunkRepo.add(
        childId: child.id,
        content: sampleText,
        linhVuc: 'ngon_ngu',
        embedding: embedding,
      );

      // 3. Đọc lại từ database thật để verify
      final chunks = await chunkRepo.getForChild(child.id);
      expect(chunks.length, 1);
      expect(chunks.first.id, createdChunk.id);
      expect(chunks.first.embedding.length, embedding.length);
      expect(chunks.first.embedding.first, isA<double>());

      // ignore: avoid_print
      print('=== [EVIDENCE A: NVIDIA NIM EMBEDDING THẬT] ===');
      // ignore: avoid_print
      print('Nội dung: "$sampleText"');
      // ignore: avoid_print
      print('Vector length: ${embedding.length} chiều');
      // ignore: avoid_print
      print('Sample 5 float values đầu tiên: ${embedding.take(5).toList()}');
      // ignore: avoid_print
      print('Đã lưu thành công vào SQLite bảng profile_chunks với id: ${createdChunk.id}');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('b. Gọi Groq Generation THẬT -> Hỏi đáp AI trả lời tiếng Việt chuẩn UTF-8', () async {
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Test Chat Real',
        ageYears: 3,
      );

      // Thêm mô tả mẫu vào assessment
      await AssessmentRepository(AppDatabase.instance).save(
        childId: child.id,
        linhVuc: 'ngon_ngu',
        content: 'Bé chưa nói được từ đơn nào, chỉ ê a khi muốn lấy đồ chơi.',
        nguon: 'phu_huynh',
      );

      // Gọi AiRepository với Groq API thật
      final aiRepo = AiRepository(db: AppDatabase.instance);
      final question = 'Bé 3 tuổi chưa nói được từ đơn thì phụ huynh nên làm gì để hỗ trợ bé?';

      final conversation = await aiRepo.ask(child: child, question: question);

      expect(conversation.answer, isNotEmpty);
      expect(conversation.answer.length, greaterThan(30));
      // Kiểm tra câu trả lời có chứa các ký tự tiếng Việt có dấu chuẩn UTF-8
      expect(
        conversation.answer.contains(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]', caseSensitive: false)),
        isTrue,
        reason: 'Câu trả lời tiếng Việt phải đúng encoding UTF-8',
      );

      final savedConversations = await AiConversationRepository(AppDatabase.instance).getForChild(child.id);
      expect(savedConversations, isNotEmpty);

      // ignore: avoid_print
      print('=== [EVIDENCE B: GROQ GENERATION THẬT - HỎI ĐÁP AI] ===');
      // ignore: avoid_print
      print('Câu hỏi: "$question"');
      // ignore: avoid_print
      print('Trạng thái Guardrail: ${conversation.state}');
      // ignore: avoid_print
      print('Câu trả lời từ Groq LLM:');
      // ignore: avoid_print
      print(conversation.answer);
      // ignore: avoid_print
      print('Đã lưu vào SQLite bảng ai_conversations với id: ${savedConversations.first.id}');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('c. Chân dung toàn cảnh 7 lĩnh vực THẬT -> Gắn nhãn AI + Tính Tier + Groq sinh mô tả tổng hợp', () async {
      final child = await ChildRepository(AppDatabase.instance).create(
        name: 'Bé Test Chân Dung Real',
        ageYears: 3,
      );

      // Thêm dữ liệu tham khảo so sánh chuẩn cho các lĩnh vực
      final expertRepo = ExpertKnowledgeRepository(AppDatabase.instance);
      final nvidiaClient = NvidiaApiClient();
      final sampleRefEmbedding = await nvidiaClient.embed('Trẻ phát triển các biểu hiện theo độ tuổi');

      for (final domain in domains) {
        await expertRepo.add(
          content: 'Trẻ 3 tuổi có các biểu hiện phát triển bình thường trong lĩnh vực ${domain.label}.',
          contentType: 'so_sanh',
          phanLoai: 'binh_thuong',
          linhVuc: domain.code,
          doTuoiThangMin: 24,
          doTuoiThangMax: 48,
          embedding: sampleRefEmbedding,
        );
        await expertRepo.add(
          content: 'Trẻ có dấu hiệu khác biệt đáng kể hoặc cần hỗ trợ đặc biệt trong lĩnh vực ${domain.label}.',
          contentType: 'so_sanh',
          phanLoai: 'roi_loan_pho_tu_ky',
          linhVuc: domain.code,
          doTuoiThangMin: 24,
          doTuoiThangMax: 48,
          embedding: sampleRefEmbedding,
        );
      }

      // Nhập mô tả thật cho cả 7 lĩnh vực
      final descriptions = {
        'nhan_thuc': 'Bé nhận biết được các đồ vật quen thuộc và làm theo một số chỉ dẫn đơn giản của bố mẹ.',
        'cam_xuc': 'Bé biết cười khi vui và thể hiện cảm xúc phù hợp với hoàn cảnh hàng ngày.',
        'giac_quan': 'Bé phản ứng bình thường với âm thanh và ánh sáng, không có dấu hiệu nhạy cảm quá mức.',
        'quan_he_xa_hoi': 'Bé thích chơi cùng bạn bè và tương tác mắt tốt với người quen.',
        'ngon_ngu': 'Bé nói được câu ngắn 3-4 từ rõ ràng và hiểu lời người lớn nói.',
        'sinh_hoc': 'Bé ăn ngủ ngon, cân nặng và chiều cao phát triển bình thường theo chuẩn y tế.',
        'sinh_hoat_ca_nhan': 'Bé tự xúc ăn được và biết gọi người lớn khi muốn đi vệ sinh.',
      };

      final assessmentRepo = AssessmentRepository(AppDatabase.instance);
      for (final domain in domains) {
        final content = descriptions[domain.code] ?? 'Bé có biểu hiện bình thường trong lĩnh vực này.';
        await assessmentRepo.save(
          childId: child.id,
          linhVuc: domain.code,
          content: content,
          nguon: 'phu_huynh',
        );
      }

      // 1. Gắn nhãn AI cho cả 7 lĩnh vực với Real Groq AI
      final overviewRepo = OverviewRepository(db: AppDatabase.instance);
      final labels = await overviewRepo.labelAllDomains(child);

      expect(labels.length, 7);

      // 2. Chạy tính toán Chân dung toàn cảnh (Tính Tier + Groq sinh mô tả tổng hợp)
      final result = await overviewRepo.computeAndSaveOverview(child);

      expect(result.status, OverviewComputationStatus.computed);
      expect(result.summary, isNotNull);
      expect(result.summary!.tier, isNotEmpty);

      // 3. Verify mô tả tổng hợp AI
      final summaryRepo = OverviewSummaryRepository(AppDatabase.instance);
      final latestSummary = await summaryRepo.getLatestForChild(child.id);
      expect(latestSummary, isNotNull);
      expect(latestSummary!.moTaTongHop, isNotNull);
      expect(latestSummary.moTaTongHop!, isNotEmpty);

      // ignore: avoid_print
      print('=== [EVIDENCE C: CHÂN DUNG TOÀN CẢNH 7 LĨNH VỰC THẬT] ===');
      // ignore: avoid_print
      print('Tier tính toán được: ${latestSummary.tier}');
      // ignore: avoid_print
      print('Danh sách 7 nhãn được AI phân loại:');
      for (final label in labels) {
        // ignore: avoid_print
        print(' - Lĩnh vực ${label.linhVuc}: nhãn "${label.nhan}" (${label.lyDoNganGon ?? ""})');
      }
      // ignore: avoid_print
      print('Mô tả tổng hợp Chân dung toàn cảnh do Groq AI sinh:');
      // ignore: avoid_print
      print(latestSummary.moTaTongHop);
      // ignore: avoid_print
      print('=== HOÀN TẤT XÁC THỰC TOÀN DIỆN VỚI REAL CLOUD AI ===');
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
