import 'dart:convert';

import '../../core/constants/domains.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/child.dart';
import '../../domain/models/domain_overview_label.dart';
import '../../domain/models/overview_summary.dart';
import '../../domain/services/overview_tier_calculator.dart';
import '../../domain/services/prompt_builder.dart';
import '../../domain/services/vector_search_service.dart';
import '../local/database.dart';
import '../remote/groq_api_client.dart';
import '../remote/nvidia_api_client.dart';
import 'assessment_repository.dart';
import 'domain_overview_label_repository.dart';
import 'expert_knowledge_repository.dart';
import 'history_log_repository.dart';
import 'overview_summary_repository.dart';
import 'profile_chunk_repository.dart';

const String _noReferenceContext = '(không có dữ liệu tham khảo phù hợp)';

/// Số chunk tham khảo tối đa lấy MỖI nhóm phân loại (`binh_thuong` /
/// `roi_loan_pho_tu_ky`) đưa vào prompt cho AI — đủ để có ngữ cảnh so sánh,
/// không làm prompt quá dài.
const int _topChunksPerGroup = 3;

/// Trạng thái kết quả `computeAndSaveOverview` — [insufficientLabels] khi
/// chưa gắn nhãn đủ 7/7 lĩnh vực (chưa gọi `labelAllDomains` hoặc gọi dở
/// dang); [insufficientData] khi ĐÃ đủ 7/7 nhãn nhưng quá nhiều lĩnh vực
/// `'chua_du_du_lieu'` (xem `overview_tier_calculator.dart`); [computed] khi
/// đã tính và lưu `overview_summaries` thành công.
enum OverviewComputationStatus { insufficientLabels, insufficientData, computed }

class OverviewComputationResult {
  final OverviewComputationStatus status;

  /// Số lĩnh vực đã có nhãn (trên tổng 7) — chỉ có ý nghĩa khi [status] =
  /// `insufficientLabels`.
  final int? soLinhVucDaGanNhan;

  /// Số lĩnh vực nhãn `'chua_du_du_lieu'` — có ý nghĩa khi [status] =
  /// `insufficientData` hoặc `computed`.
  final int? soThieu;

  final OverviewSummary? summary;

  const OverviewComputationResult._({
    required this.status,
    this.soLinhVucDaGanNhan,
    this.soThieu,
    this.summary,
  });

  factory OverviewComputationResult.insufficientLabels({required int soLinhVucDaGanNhan}) =>
      OverviewComputationResult._(
        status: OverviewComputationStatus.insufficientLabels,
        soLinhVucDaGanNhan: soLinhVucDaGanNhan,
      );

  factory OverviewComputationResult.insufficientData({required int soThieu}) =>
      OverviewComputationResult._(
        status: OverviewComputationStatus.insufficientData,
        soThieu: soThieu,
      );

  factory OverviewComputationResult.computed({required OverviewSummary summary, required int soThieu}) =>
      OverviewComputationResult._(
        status: OverviewComputationStatus.computed,
        summary: summary,
        soThieu: soThieu,
      );
}

/// Gộp pipeline "Chân dung toàn cảnh": [labelAllDomains] gắn nhãn TỪNG lĩnh
/// vực (AI hỗ trợ, xem `PromptBuilder.buildDomainOverviewLabelPrompt`) rồi
/// [computeAndSaveOverview] tổng hợp mức cuối cùng 100% BẰNG CODE
/// (`overview_tier_calculator.dart`) — 2 bước tách biệt rõ ràng đúng nguyên
/// tắc "AI không tự quyết định kết luận cuối".
class OverviewRepository {
  final AssessmentRepository _assessmentRepository;
  final ExpertKnowledgeRepository _expertKnowledgeRepository;
  final VectorSearchService _vectorSearchService;
  final NvidiaApiClient _nvidiaApiClient;
  final GroqApiClient _groqApiClient;
  final DomainOverviewLabelRepository _labelRepository;
  final OverviewSummaryRepository _summaryRepository;
  final HistoryLogRepository _historyLogRepository;
  final PromptBuilder _promptBuilder;

  OverviewRepository({
    required AppDatabase db,
    AssessmentRepository? assessmentRepository,
    ExpertKnowledgeRepository? expertKnowledgeRepository,
    VectorSearchService? vectorSearchService,
    NvidiaApiClient? nvidiaApiClient,
    GroqApiClient? groqApiClient,
    DomainOverviewLabelRepository? labelRepository,
    OverviewSummaryRepository? summaryRepository,
    HistoryLogRepository? historyLogRepository,
    PromptBuilder? promptBuilder,
  })  : _assessmentRepository = assessmentRepository ?? AssessmentRepository(db),
        _expertKnowledgeRepository = expertKnowledgeRepository ?? ExpertKnowledgeRepository(db),
        _vectorSearchService = vectorSearchService ??
            VectorSearchService(ProfileChunkRepository(db), ExpertKnowledgeRepository(db)),
        _nvidiaApiClient = nvidiaApiClient ?? NvidiaApiClient(),
        _groqApiClient = groqApiClient ?? GroqApiClient(),
        _labelRepository = labelRepository ?? DomainOverviewLabelRepository(db),
        _summaryRepository = summaryRepository ?? OverviewSummaryRepository(db),
        _historyLogRepository = historyLogRepository ?? HistoryLogRepository(db),
        _promptBuilder = promptBuilder ?? PromptBuilder();

  /// Gắn nhãn cho ĐỦ 7/7 lĩnh vực của [child], theo đúng thứ tự
  /// `domains`. Gọi tuần tự (không song song) để không vượt rate limit
  /// Groq/NVIDIA — dữ liệu ở quy mô demo (7 lần gọi) nên không cần tối ưu
  /// song song.
  Future<List<DomainOverviewLabel>> labelAllDomains(Child child) async {
    final results = <DomainOverviewLabel>[];
    for (final domain in domains) {
      results.add(await labelDomain(child, domain.code, domain.label));
    }
    return results;
  }

  /// Gắn nhãn 1 lĩnh vực — mục 2 trong yêu cầu:
  /// - Chưa có mô tả (`assessments` content_type='mo_ta' rỗng) → nhãn cứng
  ///   [labelChuaDuDuLieu], KHÔNG gọi AI.
  /// - Đã có mô tả → vector search `expert_knowledge_chunks` content_type=
  ///   'so_sanh' theo đúng lĩnh vực + độ tuổi, tách theo `phan_loai`, gọi
  ///   Groq với prompt ép JSON thuần, parse + validate (fallback
  ///   [labelChuaDuDuLieu] nếu sai định dạng — KHÔNG crash), rồi lưu.
  Future<DomainOverviewLabel> labelDomain(Child child, String linhVuc, String linhVucLabel) async {
    final assessments = await _assessmentRepository.getForChild(child.id, linhVuc: linhVuc);
    final descriptions = assessments.where((a) => a.contentType == 'mo_ta').toList();

    if (descriptions.isEmpty) {
      return _labelRepository.save(childId: child.id, linhVuc: linhVuc, nhan: labelChuaDuDuLieu);
    }

    final moTaText = descriptions.map((a) => '- ${a.content}').join('\n');

    String nhan;
    String? lyDoNganGon;
    try {
      final queryEmbedding = await _nvidiaApiClient.embed(moTaText);
      final ageMonths = childAgeInMonths(child);

      final chunks = await _expertKnowledgeRepository.query(
        linhVuc: linhVuc,
        ageInMonths: ageMonths,
        contentType: 'so_sanh',
      );
      final scored = chunks
          .map((c) => (chunk: c, similarity: _vectorSearchService.cosineSimilarity(c.embedding, queryEmbedding)))
          .toList()
        ..sort((a, b) => b.similarity.compareTo(a.similarity));

      final binhThuongChunks =
          scored.where((s) => s.chunk.phanLoai == 'binh_thuong').take(_topChunksPerGroup).toList();
      final roiLoanChunks = scored
          .where((s) => s.chunk.phanLoai == 'roi_loan_pho_tu_ky')
          .take(_topChunksPerGroup)
          .toList();

      final binhThuongContext = binhThuongChunks.isEmpty
          ? _noReferenceContext
          : binhThuongChunks.map((s) => '- ${s.chunk.content}').join('\n');
      final roiLoanContext = roiLoanChunks.isEmpty
          ? _noReferenceContext
          : roiLoanChunks.map((s) => '- ${s.chunk.content}').join('\n');

      final systemPrompt = _promptBuilder.buildDomainOverviewLabelPrompt(
        linhVucLabel: linhVucLabel,
        moTaText: moTaText,
        binhThuongContext: binhThuongContext,
        roiLoanContext: roiLoanContext,
      );

      final rawResponse = await _groqApiClient.generate(
        systemPrompt: systemPrompt,
        userQuestion: 'Hãy trả lời đúng định dạng JSON duy nhất theo yêu cầu ở trên.',
      );

      final parsed = _parseLabelResponse(rawResponse);
      nhan = parsed.nhan;
      lyDoNganGon = parsed.lyDoNganGon;
    } catch (e) {
      // Lỗi gọi API (mạng, timeout, HTTP lỗi...) — KHÔNG được crash luồng
      // tổng hợp, fallback về 'chua_du_du_lieu' giống trường hợp AI trả sai
      // định dạng.
      // ignore: avoid_print
      print('Lỗi khi gắn nhãn lĩnh vực "$linhVuc" cho trẻ ${child.id}, fallback "$labelChuaDuDuLieu": $e');
      nhan = labelChuaDuDuLieu;
      lyDoNganGon = 'Không gắn nhãn được do lỗi hệ thống, cần thử lại.';
    }

    return _labelRepository.save(
      childId: child.id,
      linhVuc: linhVuc,
      nhan: nhan,
      lyDoNganGon: lyDoNganGon,
    );
  }

  /// Tổng hợp mức cuối cùng — mục 3 trong yêu cầu: 100% CODE THUẦN
  /// (`calculateOverviewTier`), KHÔNG gọi AI ở bước này. Chỉ đọc nhãn MỚI
  /// NHẤT của mỗi lĩnh vực đã lưu sẵn trong `domain_overview_labels` (không
  /// tự gắn nhãn ở đây — gọi [labelAllDomains] trước).
  Future<OverviewComputationResult> computeAndSaveOverview(Child child) async {
    final latest = await _labelRepository.getLatestForChild(child.id);

    final orderedLabels = <DomainOverviewLabel>[];
    for (final domain in domains) {
      final label = latest[domain.code];
      if (label == null) {
        return OverviewComputationResult.insufficientLabels(soLinhVucDaGanNhan: latest.length);
      }
      orderedLabels.add(label);
    }

    final tierResult = calculateOverviewTier(orderedLabels.map((l) => l.nhan).toList());
    if (tierResult.isInsufficientData) {
      return OverviewComputationResult.insufficientData(soThieu: tierResult.soThieu);
    }

    // Sinh đoạn văn xuôi mô tả tổng hợp (Groq) — nếu lỗi (mạng, timeout...),
    // moTaTongHop là null, KHÔNG làm mất hay chặn việc lưu tier đã tính.
    final moTaTongHop = await _generateSummaryDescription(
      child: child,
      tier: tierResult.tier!,
      labels: orderedLabels,
    );

    final summary = await _summaryRepository.save(
      childId: child.id,
      tier: tierResult.tier!,
      soLinhVucCanTheoDoi: tierResult.soCanTheoDoi,
      soLinhVucThieuDuLieu: tierResult.soThieu,
      moTaTongHop: moTaTongHop,
    );

    try {
      await _historyLogRepository.add(
        childId: child.id,
        eventType: 'tong_quan',
        description: 'Tổng hợp Chân dung toàn cảnh — mức: ${tierDisplayLabel(tierResult.tier!)}',
      );
    } catch (_) {
      // Lịch sử là dữ liệu phụ trợ — lỗi ở đây không được làm mất kết quả
      // tổng hợp đã lưu ở trên (cùng cách xử lý đã dùng ở DescriptionPage).
    }

    return OverviewComputationResult.computed(summary: summary, soThieu: tierResult.soThieu);
  }

  /// Sinh lại đoạn mô tả tổng hợp cho 1 bản ghi [summary] đã có sẵn (dùng khi thử lại
  /// riêng bước gọi AI mà không cần tính lại tier).
  Future<OverviewSummary?> generateAndSaveSummaryDescription(Child child, OverviewSummary summary) async {
    final latest = await _labelRepository.getLatestForChild(child.id);
    final orderedLabels = <DomainOverviewLabel>[];
    for (final domain in domains) {
      final label = latest[domain.code];
      if (label != null) {
        orderedLabels.add(label);
      }
    }
    final moTa = await _generateSummaryDescription(
      child: child,
      tier: summary.tier,
      labels: orderedLabels,
    );
    if (moTa != null) {
      await _summaryRepository.updateMoTaTongHop(summary.id, moTa);
      return _summaryRepository.getLatestForChild(child.id);
    }
    return null;
  }

  String _formatDomainsSummaryText(
    List<DomainOverviewLabel> labels,
    List<Assessment> assessments,
  ) {
    final buffer = StringBuffer();
    for (final domain in domains) {
      final label = labels.firstWhere(
        (l) => l.linhVuc == domain.code,
        orElse: () => DomainOverviewLabel(
          id: '',
          childId: '',
          linhVuc: domain.code,
          nhan: labelChuaDuDuLieu,
          computedAt: DateTime.now(),
        ),
      );
      final domainAssessments = assessments
          .where((a) => a.linhVuc == domain.code && a.contentType == 'mo_ta')
          .toList();
      buffer.writeln('### Lĩnh vực: ${domain.label}');
      buffer.writeln(
        '- Đánh giá tổng quan lĩnh vực: ${label.nhan == labelThuongGap ? "Thường gặp" : label.nhan == labelCanTheoDoi ? "Cần theo dõi" : "Chưa đủ dữ liệu"}${label.lyDoNganGon != null ? " (${label.lyDoNganGon})" : ""}',
      );
      if (domainAssessments.isEmpty) {
        buffer.writeln('- Mô tả người dùng: (chưa có)');
      } else {
        buffer.writeln('- Mô tả người dùng:');
        for (final a in domainAssessments) {
          buffer.writeln('  + ${a.content}');
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  Future<String?> _generateSummaryDescription({
    required Child child,
    required String tier,
    required List<DomainOverviewLabel> labels,
  }) async {
    try {
      final assessments = await _assessmentRepository.getForChild(child.id);
      final domainsSummaryText = _formatDomainsSummaryText(labels, assessments);
      final systemPrompt = _promptBuilder.buildOverviewPortraitSummaryPrompt(
        childName: child.name,
        childAgeLabel: formatAgeLabel(child),
        tierLabel: tierDisplayLabel(tier),
        domainsSummaryText: domainsSummaryText,
      );

      final response = await _groqApiClient.generate(
        systemPrompt: systemPrompt,
        userQuestion: 'Hãy viết đoạn văn xuôi tổng hợp bức tranh chân dung biểu hiện của trẻ theo đúng các nguyên tắc trên.',
      );
      final trimmed = response.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi khi sinh mô tả tổng hợp cho trẻ ${child.id}: $e');
      return null;
    }
  }

  /// Parse phản hồi JSON từ Groq — model đôi khi kèm text thừa quanh JSON
  /// dù đã được yêu cầu chỉ trả JSON thuần, nên lấy đoạn từ `{` đầu tiên đến
  /// `}` cuối cùng thay vì `jsonDecode` toàn bộ chuỗi. Bất kỳ lỗi nào (thiếu
  /// JSON hợp lệ, thiếu field, giá trị "nhan" không nằm trong 3 giá trị hợp
  /// lệ) đều fallback về [labelChuaDuDuLieu] — KHÔNG ném lỗi ra ngoài.
  ({String nhan, String? lyDoNganGon}) _parseLabelResponse(String raw) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1 || end < start) {
        throw const FormatException('Không tìm thấy JSON object trong phản hồi');
      }
      final decoded = jsonDecode(raw.substring(start, end + 1));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi không phải JSON object');
      }
      final nhan = decoded['nhan'];
      if (nhan is! String || !validDomainOverviewLabels.contains(nhan)) {
        throw FormatException('Giá trị "nhan" không hợp lệ: $nhan');
      }
      final lyDo = decoded['ly_do_ngan_gon'];
      return (nhan: nhan, lyDoNganGon: lyDo is String ? lyDo : null);
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi parse phản hồi gắn nhãn từ AI, fallback "$labelChuaDuDuLieu": $e — raw: $raw');
      return (
        nhan: labelChuaDuDuLieu,
        lyDoNganGon: 'Không xác định được nhãn từ phản hồi AI (sai định dạng).',
      );
    }
  }
}
