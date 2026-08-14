import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris_app/core/constants/nine_domains.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/remote/groq_api_client.dart';
import 'package:iris_app/data/remote/nvidia_api_client.dart';
import 'package:iris_app/data/repositories/assessment_repository.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/domain_overview_label_repository.dart';
import 'package:iris_app/data/repositories/expert_knowledge_repository.dart';
import 'package:iris_app/data/repositories/history_log_repository.dart';
import 'package:iris_app/data/repositories/overview_repository.dart';
import 'package:iris_app/data/repositories/overview_summary_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _fixedEmbedding = [1.0, 0.0, 0.0];

http.Client _nvidiaMockClient() => MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {'embedding': _fixedEmbedding, 'index': 0},
          ],
        }),
        200,
      );
    });

/// MockClient Groq — trả nhãn khác nhau THEO LĨNH VỰC, tra theo tên lĩnh vực
/// xuất hiện trong system prompt (`buildDomainOverviewLabelPrompt` luôn
/// chèn `lĩnh vực "$linhVucLabel"`). Ghi lại toàn bộ request đã nhận để có
/// thể assert KHÔNG gọi AI cho lĩnh vực chưa có mô tả.
class _PerDomainGroqMock {
  final Map<String, String> labelByDomainCode;
  final List<http.Request> requests = [];

  _PerDomainGroqMock(this.labelByDomainCode);

  http.Client get client => MockClient((request) async {
        requests.add(request);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final systemPrompt = (body['messages'] as List<dynamic>)[0]['content'] as String;
        final domain = nineDomains.firstWhere((d) => systemPrompt.contains('lĩnh vực "${d.label}"'));
        final nhan = labelByDomainCode[domain.code]!;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': jsonEncode({'nhan': nhan, 'ly_do_ngan_gon': 'Lý do mock cho ${domain.label}'}),
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
}

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

  test('labelDomain: chưa có mô tả => nhãn cứng chua_du_du_lieu, KHÔNG gọi Groq/NVIDIA', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Chưa Mô Tả', ageYears: 3);
    final groqMock = _PerDomainGroqMock(const {});
    var nvidiaCallCount = 0;
    final nvidiaClient = MockClient((request) async {
      nvidiaCallCount++;
      return http.Response(jsonEncode({'data': []}), 200);
    });

    final overviewRepository = OverviewRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: nvidiaClient),
      groqApiClient: GroqApiClient(client: groqMock.client),
    );

    final label = await overviewRepository.labelDomain(child, 'ngon_ngu', 'Ngôn ngữ');

    expect(label.nhan, 'chua_du_du_lieu');
    expect(label.lyDoNganGon, isNull);
    expect(nvidiaCallCount, 0);
    expect(groqMock.requests, isEmpty);

    // Đọc lại trực tiếp từ database thật (không chỉ tin giá trị trả về).
    final repoLabels = await DomainOverviewLabelRepository(AppDatabase.instance).getLatestForChild(child.id);
    expect(repoLabels['ngon_ngu']?.nhan, 'chua_du_du_lieu');
    // ignore: avoid_print
    print('PASS: lĩnh vực chưa có mô tả nhận nhãn cứng chua_du_du_lieu, không gọi AI');
  });

  test('labelDomain: AI trả JSON sai định dạng => fallback chua_du_du_lieu, không crash', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Lỗi Format', ageYears: 3);
    await AssessmentRepository(AppDatabase.instance).save(
      childId: child.id,
      linhVuc: 'cam_xuc',
      content: 'Bé hay khóc khi lạ chỗ',
      nguon: 'phu_huynh',
    );

    final brokenGroqClient = MockClient((request) async => http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Đây không phải JSON hợp lệ, xin lỗi.'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ));

    final overviewRepository = OverviewRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: _nvidiaMockClient()),
      groqApiClient: GroqApiClient(client: brokenGroqClient),
    );

    final label = await overviewRepository.labelDomain(child, 'cam_xuc', 'Cảm xúc');

    expect(label.nhan, 'chua_du_du_lieu');
    expect(label.lyDoNganGon, isNotNull);
    // ignore: avoid_print
    print('PASS: AI trả JSON sai định dạng => fallback chua_du_du_lieu, không ném lỗi ra ngoài');
  });

  test('computeAndSaveOverview: chưa đủ nhãn 9/9 => insufficientLabels, KHÔNG lưu overview_summaries', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Thiếu Nhãn', ageYears: 3);
    await DomainOverviewLabelRepository(AppDatabase.instance).save(
      childId: child.id,
      linhVuc: 'ngon_ngu',
      nhan: 'thuong_gap',
    );

    final overviewRepository = OverviewRepository(db: AppDatabase.instance);
    final result = await overviewRepository.computeAndSaveOverview(child);

    expect(result.status, OverviewComputationStatus.insufficientLabels);
    expect(result.soLinhVucDaGanNhan, 1);

    final summaries = await OverviewSummaryRepository(AppDatabase.instance).getLatestForChild(child.id);
    expect(summaries, isNull);
    // ignore: avoid_print
    print('PASS: chưa đủ nhãn 9/9 => insufficientLabels, không lưu overview_summaries');
  });

  test(
      'computeAndSaveOverview: đủ 9/9 nhãn nhưng >=4 thiếu dữ liệu => insufficientData, '
      'KHÔNG lưu overview_summaries', () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Thiếu Dữ Liệu', ageYears: 3);
    final labelRepo = DomainOverviewLabelRepository(AppDatabase.instance);
    for (var i = 0; i < nineDomains.length; i++) {
      await labelRepo.save(
        childId: child.id,
        linhVuc: nineDomains[i].code,
        nhan: i < 4 ? 'chua_du_du_lieu' : 'thuong_gap',
      );
    }

    final overviewRepository = OverviewRepository(db: AppDatabase.instance);
    final result = await overviewRepository.computeAndSaveOverview(child);

    expect(result.status, OverviewComputationStatus.insufficientData);
    expect(result.soThieu, 4);

    final summaries = await OverviewSummaryRepository(AppDatabase.instance).getLatestForChild(child.id);
    expect(summaries, isNull);
    // ignore: avoid_print
    print('PASS: đủ 9/9 nhãn nhưng >=4 thiếu dữ liệu => insufficientData, không lưu overview_summaries');
  });

  test(
      'Luồng đầy đủ: 9 mô tả thật -> labelAllDomains (AI giả) -> computeAndSaveOverview (code thuần) '
      '-> đọc lại domain_overview_labels + overview_summaries + history_logs TRỰC TIẾP từ database thật',
      () async {
    final child = await ChildRepository(AppDatabase.instance).create(name: 'Bé Đủ 9 Lĩnh Vực', ageYears: 4);
    final assessmentRepository = AssessmentRepository(AppDatabase.instance);

    for (final domain in nineDomains) {
      await assessmentRepository.save(
        childId: child.id,
        linhVuc: domain.code,
        content: 'Mô tả mẫu cho lĩnh vực ${domain.label}',
        nguon: 'phu_huynh',
      );
    }

    // 4 lĩnh vực đầu 'can_theo_doi' (>2, <=5 => tier can_theo_doi), 5 lĩnh
    // vực còn lại 'thuong_gap', 0 thiếu dữ liệu.
    final labelPlan = <String, String>{};
    for (var i = 0; i < nineDomains.length; i++) {
      labelPlan[nineDomains[i].code] = i < 4 ? 'can_theo_doi' : 'thuong_gap';
    }
    final groqMock = _PerDomainGroqMock(labelPlan);

    // Dữ liệu tham khảo placeholder/mẫu có sẵn trong repo (đã seed từ trước
    // ở việc khác) — ở đây thêm 1 chunk tối thiểu để đúng luồng vector
    // search có dữ liệu (không bắt buộc, luồng vẫn chạy đúng nếu rỗng).
    await ExpertKnowledgeRepository(AppDatabase.instance).add(
      content: '[Placeholder] Biểu hiện thường gặp mẫu cho hành vi',
      contentType: 'so_sanh',
      phanLoai: 'binh_thuong',
      linhVuc: 'hanh_vi',
      doTuoiThangMin: 36,
      doTuoiThangMax: 47,
      embedding: _fixedEmbedding,
    );

    final overviewRepository = OverviewRepository(
      db: AppDatabase.instance,
      nvidiaApiClient: NvidiaApiClient(client: _nvidiaMockClient()),
      groqApiClient: GroqApiClient(client: groqMock.client),
    );

    final labels = await overviewRepository.labelAllDomains(child);
    expect(labels.length, 9);
    expect(groqMock.requests.length, 9);

    final result = await overviewRepository.computeAndSaveOverview(child);
    expect(result.status, OverviewComputationStatus.computed);
    expect(result.summary!.tier, 'can_theo_doi');
    expect(result.summary!.soLinhVucCanTheoDoi, 4);
    expect(result.summary!.soLinhVucThieuDuLieu, 0);

    // Xác nhận bằng cách ĐỌC LẠI TRỰC TIẾP từ database thật, không chỉ tin
    // giá trị trả về từ hàm.
    final rawDb = await AppDatabase.instance.database;

    final labelRows = await rawDb.query('domain_overview_labels', where: 'child_id = ?', whereArgs: [child.id]);
    expect(labelRows.length, 9);
    final canTheoDoiRows = labelRows.where((r) => r['nhan'] == 'can_theo_doi').length;
    final thuongGapRows = labelRows.where((r) => r['nhan'] == 'thuong_gap').length;
    expect(canTheoDoiRows, 4);
    expect(thuongGapRows, 5);

    final summaryRows = await rawDb.query('overview_summaries', where: 'child_id = ?', whereArgs: [child.id]);
    expect(summaryRows.length, 1);
    expect(summaryRows.single['tier'], 'can_theo_doi');
    expect(summaryRows.single['so_linh_vuc_can_theo_doi'], 4);
    expect(summaryRows.single['so_linh_vuc_thieu_du_lieu'], 0);

    final historyLogs = await HistoryLogRepository(AppDatabase.instance).getForChild(child.id);
    final tongQuanLogs = historyLogs.where((l) => l.eventType == 'tong_quan').toList();
    expect(tongQuanLogs.length, 1);
    expect(tongQuanLogs.single.description, contains('Có điểm cần theo dõi'));

    // ignore: avoid_print
    print(
      'PASS: luồng đầy đủ 9 lĩnh vực — đọc lại từ database thật xác nhận đúng '
      '9 domain_overview_labels (4 can_theo_doi + 5 thuong_gap), 1 overview_summaries '
      '(tier=can_theo_doi), 1 history_logs (tong_quan)',
    );
  });
}
