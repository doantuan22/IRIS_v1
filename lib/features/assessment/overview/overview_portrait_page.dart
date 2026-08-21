import 'package:flutter/material.dart';

import '../../../core/constants/domains.dart';
import '../../../core/theme/iris_assets.dart';
import '../../../core/theme/iris_theme.dart';
import '../../../core/utils/retry_with_backoff.dart';
import '../../../core/widgets/iris_ui.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../data/repositories/domain_overview_label_repository.dart';
import '../../../data/repositories/overview_repository.dart';
import '../../../data/repositories/overview_summary_repository.dart';
import '../../../domain/models/child.dart';
import '../../../domain/models/domain_overview_label.dart';
import '../../../domain/models/overview_summary.dart';
import '../../../domain/services/ai_connectivity_service.dart';
import '../../expert_connect/expert_connect_page.dart';

const String _disclaimerText =
    'Đây là tổng hợp mang tính tham khảo dựa trên mô tả bạn cung cấp và dữ liệu tham khảo trong ứng dụng, '
    'không phải kết luận chẩn đoán y khoa.';

String _domainLabelDisplayText(String? nhan) => switch (nhan) {
  labelThuongGap => 'Thường gặp',
  labelCanTheoDoi => 'Cần theo dõi',
  labelChuaDuDuLieu => 'Chưa đủ dữ liệu',
  _ => 'Chưa có nhãn',
};

Color _domainLabelColor(BuildContext context, String? nhan) => switch (nhan) {
  labelThuongGap => IrisColors.success,
  labelCanTheoDoi => IrisColors.warning,
  _ => Theme.of(context).hintColor,
};

/// Trạng thái đã tải xong dữ liệu cần cho màn hình — tách khỏi `Future` gốc
/// để `build()` chỉ cần switch theo 1 kiểu dữ liệu duy nhất.
class _LoadedState {
  final int doneDomainCount;
  final Map<String, DomainOverviewLabel> labels;
  final OverviewSummary? summary;

  /// Văn bản "Chân dung biểu hiện" sinh theo N lĩnh vực đã có (1 <= N < 7) —
  /// CHỈ có ý nghĩa khi chưa đủ 7/7 ([isComplete] == false). `null` nghĩa là
  /// chưa gọi được AI (lỗi mạng...), không phải "chưa có lĩnh vực nào".
  /// KHÔNG lưu DB — sinh lại mỗi lần tải trang, luôn phản ánh dữ liệu mới
  /// nhất, không dùng cache kết quả cũ.
  final String? partialSummaryText;

  const _LoadedState({
    required this.doneDomainCount,
    required this.labels,
    this.summary,
    this.partialSummaryText,
  });

  bool get isComplete => doneDomainCount >= domains.length;
}

/// "Chân dung toàn cảnh" — khả dụng ngay khi trẻ có mô tả (Phần 1) cho ÍT
/// NHẤT 1 lĩnh vực, với 2 chế độ hiển thị RIÊNG BIỆT:
/// - Chưa đủ 7/7 (`_buildPartial`): CHỈ có văn bản tổng hợp theo đúng N lĩnh
///   vực đã có (`OverviewRepository.generatePartialSummaryDescription`),
///   TUYỆT ĐỐI không có mức tổng quan/tier.
/// - Đủ 7/7 (`_buildReady`): tổng hợp 7 nhãn lĩnh vực (AI hỗ trợ gắn nhãn
///   từng lĩnh vực) thành 1 trong 3 mức tổng quan, tính 100% BẰNG CODE (xem
///   `overview_tier_calculator.dart`) — AI KHÔNG được quyết định mức cuối
///   cùng.
class OverviewPortraitPage extends StatefulWidget {
  final Child child;

  const OverviewPortraitPage({super.key, required this.child});

  @override
  State<OverviewPortraitPage> createState() => _OverviewPortraitPageState();
}

class _OverviewPortraitPageState extends State<OverviewPortraitPage> {
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _labelRepository = DomainOverviewLabelRepository(AppDatabase.instance);
  final _summaryRepository = OverviewSummaryRepository(AppDatabase.instance);
  late final _overviewRepository = OverviewRepository(db: AppDatabase.instance);

  late Future<_LoadedState> _stateFuture;
  bool _computing = false;
  String? _computeError;

  bool _generatingDescription = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _stateFuture = _load();
    });
  }

  Future<_LoadedState> _load() async {
    final assessments = await _assessmentRepository.getForChild(
      widget.child.id,
    );
    final doneDomains = assessments
        .where((a) => a.contentType == 'mo_ta')
        .map((a) => a.linhVuc)
        .toSet();

    if (doneDomains.isEmpty) {
      return _LoadedState(doneDomainCount: 0, labels: const {});
    }

    if (doneDomains.length < domains.length) {
      // Đường dẫn ĐỘC LẬP với luồng 7/7 bên dưới — xem
      // `OverviewRepository.generatePartialSummaryDescription`: KHÔNG gắn
      // nhãn, KHÔNG tính tier, KHÔNG lưu DB, chỉ sinh văn bản theo đúng N
      // lĩnh vực đã có mô tả. Hàm này KHÔNG BAO GIỜ ném lỗi (tự bắt lỗi nội
      // bộ, trả `null` khi thất bại) nên với nhánh N<7, `null` LUÔN LUÔN có
      // nghĩa "gọi AI thất bại" (không có trường hợp "null hợp lệ" nào
      // khác) — an toàn để coi `null` là tín hiệu retry.
      String? partialSummary;
      try {
        partialSummary = await retryWithBackoff<String>(
          () async {
            final result = await _overviewRepository
                .generatePartialSummaryDescription(widget.child);
            if (result == null) {
              throw Exception(
                'AI chưa trả về được mô tả tổng hợp (Chân dung từng phần)',
              );
            }
            return result;
          },
          onAttemptFailed: (attempt, error) => debugPrint(
            '[ChanDungToanCanh][N<7] Lần thử $attempt thất bại: $error',
          ),
        );
      } catch (_) {
        // Hết tối đa số lần thử tự động — giữ `null`, UI (`_buildPartial`)
        // hiện thông báo + nút "Tổng hợp lại" làm phương án cuối, không
        // khác gì hành vi trước khi có cơ chế tự động thử lại.
        partialSummary = null;
      }
      return _LoadedState(
        doneDomainCount: doneDomains.length,
        labels: const {},
        partialSummaryText: partialSummary,
      );
    }

    final hasSummaryAlready =
        await _summaryRepository.getLatestForChild(widget.child.id) != null;
    if (!hasSummaryAlready) {
      // Lần đầu vào màn khi đã đủ 7/7 nhưng CHƯA từng tổng hợp — tự động
      // gắn nhãn + tính tier ngay, không đợi bấm nút. Nút "Tính toán lại"
      // (`_compute`) chỉ còn dùng để CHỦ ĐỘNG làm mới sau khi đã có sẵn kết
      // quả (VD sau khi sửa mô tả) — 2 việc khác nhau, không gộp chung.
      //
      // Bắt lỗi ở đây (giống nhánh N<7) thay vì để ném ra ngoài `_load()`
      // — nếu để lộ ra `snapshot.hasError`, UI sẽ hiện nguyên văn
      // `e.toString()` (rò rỉ chi tiết kỹ thuật ra người dùng cuối). Hết
      // 10 lần vẫn thất bại thì bỏ qua, để `_fetchReadyState` đọc lại thấy
      // `summary == null` — UI (`_buildReady`) đã có sẵn thông báo rõ ràng
      // + nút "Thử lại" (gọi `_compute()`, cũng tự động thử lại 10 lần).
      try {
        await _computeOverviewWithRetry();
      } catch (e) {
        debugPrint(
          '[ChanDungToanCanh][N=7] Hết số lần thử tự động, vẫn lỗi: $e',
        );
      }
    }
    return _fetchReadyState(doneDomains.length);
  }

  /// Gắn nhãn 7/7 lĩnh vực + tính tier ĐÚNG 1 LẦN — dùng làm [action] cho
  /// [retryWithBackoff]. Ném lỗi khi kết quả CHƯA đáng tin (để kích hoạt
  /// thử lại), phân biệt 2 trường hợp `insufficientData`:
  /// - Có ít nhất 1 lĩnh vực gắn nhãn `chua_du_du_lieu` với đúng lý do
  ///   [domainOverviewLabelSystemErrorReason] (LỖI HỆ THỐNG khi gọi AI —
  ///   mạng, timeout, rate limit...) → TẠM THỜI, NÊN thử lại.
  /// - Ngược lại (AI thật sự đánh giá thiếu dữ liệu tham khảo phù hợp cho
  ///   đủ số lĩnh vực) → kết quả ỔN ĐỊNH, thử lại cũng ra như vậy, KHÔNG
  ///   ném lỗi (tránh chờ vô ích tới hết 10 lần cho 1 kết quả sẽ không đổi).
  Future<void> _computeOverviewOnce() async {
    final labels = await _overviewRepository.labelAllDomains(widget.child);
    final result = await _overviewRepository.computeAndSaveOverview(
      widget.child,
    );
    if (result.status == OverviewComputationStatus.computed) return;

    final hasSystemErrorFallback = labels.any(
      (l) => l.lyDoNganGon == domainOverviewLabelSystemErrorReason,
    );
    if (hasSystemErrorFallback) {
      throw Exception(
        'Một số lĩnh vực gắn nhãn thất bại do lỗi hệ thống tạm thời '
        '(status=${result.status})',
      );
    }
    // insufficientData nhưng KHÔNG do lỗi hệ thống — kết quả hợp lệ, không
    // retry, để `_fetchReadyState` đọc lại và UI hiện đúng trạng thái này.
  }

  /// [retryWithBackoff] bọc quanh [_computeOverviewOnce] — dùng chung cho
  /// cả lần tự động đầu tiên (`_load()`) và lần bấm "Tính toán lại"/
  /// "Thử lại" thủ công (`_compute()`), đảm bảo CẢ 2 đường vào đều có cùng
  /// cơ chế thử lại tối đa 10 lần, không phải chỉ thử 1 lần khi bấm nút.
  Future<void> _computeOverviewWithRetry() {
    return retryWithBackoff<void>(
      _computeOverviewOnce,
      onAttemptFailed: (attempt, error) => debugPrint(
        '[ChanDungToanCanh][N=7] Lần thử $attempt thất bại: $error',
      ),
    );
  }

  /// Đọc lại nhãn + kết quả tổng hợp MỚI NHẤT từ DB — dùng CHUNG cho cả
  /// `_load()` (sau khi tự động tính lần đầu) và `_compute()` (sau khi
  /// người dùng chủ động bấm "Tính toán lại"/"Thử lại"), KHÔNG tự ý gọi
  /// AI ở đây — tách biệt bước "đọc" khỏi bước "tính" để `_compute()`
  /// không vô tình kích hoạt tính lại LẦN 2 qua `_load()`.
  Future<_LoadedState> _fetchReadyState(int doneDomainCount) async {
    final labels = await _labelRepository.getLatestForChild(widget.child.id);
    final summary = await _summaryRepository.getLatestForChild(widget.child.id);
    return _LoadedState(
      doneDomainCount: doneDomainCount,
      labels: labels,
      summary: summary,
    );
  }

  Future<void> _compute() async {
    if (_computing) return;

    if (!AiConnectivityService.instance.isConnected) {
      setState(
        () => _computeError =
            'AI đang chưa kết nối được, xin vui lòng thử lại sau.',
      );
      return;
    }

    setState(() {
      _computing = true;
      _computeError = null;
    });
    try {
      await _computeOverviewWithRetry();
      if (!mounted) return;
      // Đọc lại trực tiếp qua `_fetchReadyState` (KHÔNG gọi `_reload()` ->
      // `_load()`) — nếu đi qua `_load()`, hàm đó sẽ thấy vẫn có thể chưa
      // có summary (VD do insufficientData) và tự động tính lại LẦN NỮA,
      // gọi trùng AI 2 lần cho đúng 1 lần bấm nút.
      final newState = await _fetchReadyState(domains.length);
      if (!mounted) return;
      // LƯU Ý: PHẢI dùng block `{ }`, KHÔNG dùng arrow `() => x = y` — với
      // arrow, thân hàm là biểu thức gán `_stateFuture = Future.value(...)`,
      // mà giá trị của 1 biểu thức gán chính là vế phải, tức closure này sẽ
      // TRẢ VỀ `Future<_LoadedState>` thay vì `void`. `setState()` của
      // Flutter kiểm tra runtime nếu callback trả về `Future` sẽ ném lỗi
      // "setState() callback argument returned a Future" — đúng lỗi đã gặp.
      setState(() {
        _stateFuture = Future.value(newState);
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[ChanDungToanCanh][N=7] _compute() thất bại hẳn: $e');
      // Không hiện nguyên văn `$e` ra UI — sau khi đã tự động thử lại tối
      // đa (xem `retryWithBackoff`), chi tiết kỹ thuật/loại lỗi CHỈ log nội
      // bộ, người dùng chỉ cần biết đã thử và chưa thành công.
      setState(
        () => _computeError =
            'Chưa thể tổng hợp Chân dung toàn cảnh lúc này. Vui lòng thử lại sau.',
      );
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }

  Future<void> _retryDescription(OverviewSummary summary) async {
    if (_generatingDescription) return;

    if (!AiConnectivityService.instance.isConnected) {
      setState(
        () => _computeError =
            'AI đang chưa kết nối được, xin vui lòng thử lại sau.',
      );
      return;
    }

    setState(() => _generatingDescription = true);
    try {
      final updated = await _overviewRepository
          .generateAndSaveSummaryDescription(widget.child, summary);
      if (updated != null && mounted) {
        _reload();
      }
    } finally {
      if (mounted) setState(() => _generatingDescription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chân dung toàn cảnh — ${widget.child.name}')),
      body: FutureBuilder<_LoadedState>(
        future: _stateFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: IrisColors.danger,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được dữ liệu: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang phân tích dữ liệu bằng AI. Quá trình này thường '
                      'mất vài giây, nhưng có thể lâu hơn một chút nếu mạng '
                      'chậm — xin vui lòng đợi.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final state = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ValueListenableBuilder<AiConnectivityState>(
                valueListenable: AiConnectivityService.instance.stateNotifier,
                builder: (context, connectivityState, _) {
                  if (!connectivityState.isConnected &&
                      connectivityState.hasIssue) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: IrisSpacing.md,
                        vertical: IrisSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: IrisColors.dangerSoft,
                        borderRadius: IrisRadii.cardBorder,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: IrisColors.danger),
                          const SizedBox(width: IrisSpacing.sm),
                          Expanded(
                            child: Text(
                              'AI đang chưa kết nối được, xin vui lòng thử lại sau.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (state.doneDomainCount == 0)
                _buildIncomplete(state.doneDomainCount)
              else if (!state.isComplete)
                _buildPartial(state)
              else
                _buildReady(state),
              if (_computeError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _computeError!,
                  style: const TextStyle(color: IrisColors.danger),
                ),
              ],
              const SizedBox(height: 24),
              // Dòng cảnh báo LUÔN hiển thị, bất kể trạng thái ở trên —
              // KHÔNG được ẩn trong bất kỳ nhánh nào.
              _buildDisclaimer(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIncomplete(int doneCount) {
    final total = domains.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ mô tả: $doneCount/$total lĩnh vực',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: total == 0 ? 0 : doneCount / total),
        const SizedBox(height: 16),
        const IrisParagraph(
          'Cần hoàn thành mô tả biểu hiện (Phần 1) cho ít nhất 1 lĩnh vực trước khi xem '
          'Chân dung toàn cảnh.',
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Quay lại tiếp tục mô tả'),
        ),
      ],
    );
  }

  /// Nhánh hiển thị khi trẻ đã có mô tả cho ÍT NHẤT 1 nhưng CHƯA ĐỦ 7 lĩnh
  /// vực — CHỈ hiển thị văn bản tổng hợp theo đúng N lĩnh vực đã có, TUYỆT
  /// ĐỐI KHÔNG hiển thị bất kỳ card/nhãn/màu "Mức tổng quan" nào (tier chỉ
  /// tính và hiện khi đủ 7/7, xem `_buildReady`).
  Widget _buildPartial(_LoadedState state) {
    final total = domains.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chân dung dựa trên ${state.doneDomainCount}/$total lĩnh vực đã đánh giá — '
          'mức độ tổng quan sẽ hiển thị sau khi hoàn thành đủ 7 lĩnh vực.',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        if (state.partialSummaryText != null &&
            state.partialSummaryText!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IrisSparkle(
                        size: IrisSizes.iconChip,
                        color: IrisColors.primary,
                      ),
                      const SizedBox(width: IrisSpacing.xs),
                      Text(
                        'Chân dung biểu hiện',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  IrisParagraph(
                    state.partialSummaryText!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa thể tạo mô tả tổng hợp bằng AI.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _reload, child: const Text('Tổng hợp lại')),
      ],
    );
  }

  Widget _buildReady(_LoadedState state) {
    if (state.summary == null) {
      // Tới được đây nghĩa là hệ thống ĐÃ TỰ ĐỘNG thử tổng hợp khi vào màn
      // (xem `_load()`) nhưng chưa ra kết quả — thường do một số lĩnh vực
      // chưa gắn nhãn được vì lỗi tạm thời khi gọi AI (VD giới hạn tốc độ
      // Groq), KHÔNG PHẢI vì chưa từng thử. Nút bên dưới là THỬ LẠI, không
      // phải lần đầu tổng hợp.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IrisParagraph(
            'Chưa thể tính mức tổng quan lúc này — hệ thống đã thử tự động '
            'nhưng một số lĩnh vực chưa gắn nhãn được, thường do lỗi tạm '
            'thời khi gọi AI (VD mạng chậm hoặc giới hạn tốc độ). Bấm nút '
            'bên dưới để thử lại.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _computing ? null : _compute,
            child: _computing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Thử lại'),
          ),
        ],
      );
    }

    final summary = state.summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IrisAssetIcon(asset: IrisAssets.iconOverview),
                    const SizedBox(width: IrisSpacing.sm),
                    Text(
                      'Mức tổng quan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tierDisplayLabel(summary.tier),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.soLinhVucCanTheoDoi}/${domains.length} lĩnh vực cần theo dõi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (summary.moTaTongHop != null && summary.moTaTongHop!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IrisSparkle(
                        size: IrisSizes.iconChip,
                        color: IrisColors.primary,
                      ),
                      const SizedBox(width: IrisSpacing.xs),
                      Text(
                        'Chân dung biểu hiện',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  IrisParagraph(
                    summary.moTaTongHop!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chưa thể tạo mô tả tổng hợp bằng AI.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _generatingDescription
                          ? null
                          : () => _retryDescription(summary),
                      icon: _generatingDescription
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Tạo mô tả tổng hợp'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Chi tiết theo lĩnh vực',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: domains.map((domain) {
              final label = state.labels[domain.code];
              return ListTile(
                leading: IrisDomainIcon(domainCode: domain.code),
                title: Text(domain.label),
                subtitle: label?.lyDoNganGon != null
                    ? Text(label!.lyDoNganGon!)
                    : null,
                trailing: Text(
                  _domainLabelDisplayText(label?.nhan),
                  style: TextStyle(
                    color: _domainLabelColor(context, label?.nhan),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _computing ? null : _compute,
          child: _computing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tính toán lại'),
        ),
        const SizedBox(height: 12),
        _ExpertConnectBanner(tier: summary.tier, child: widget.child),
      ],
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: IrisRadii.inputBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: IrisParagraph(
              _disclaimerText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Giọng điệu banner mời liên hệ trung tâm thay đổi theo mức tổng quan,
/// nhưng LUÔN hiển thị ở cả 3 mức — trước đây chỉ hiện ở [tierChuyenMonSom].
const Map<String, String> _expertConnectBannerText = {
  tierThuongGap:
      'Bé đang trong giới hạn thường gặp. Nếu muốn yên tâm hơn, bạn vẫn có '
      'thể tham khảo thêm ý kiến từ chuyên gia/trung tâm.',
  tierCanTheoDoi:
      'Một số lĩnh vực có điểm cần theo dõi. Bạn nên cân nhắc liên hệ '
      'chuyên gia/trung tâm để được đánh giá sâu hơn.',
  tierChuyenMonSom:
      'Nên tìm đánh giá chuyên môn sớm. Hãy liên hệ chuyên gia/trung tâm '
      'dưới đây để được hỗ trợ kịp thời.',
};

class _ExpertConnectBanner extends StatelessWidget {
  final String tier;
  final Child child;

  const _ExpertConnectBanner({required this.tier, required this.child});

  @override
  Widget build(BuildContext context) {
    final text =
        _expertConnectBannerText[tier] ??
        _expertConnectBannerText[tierCanTheoDoi]!;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IrisParagraph(text, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpertConnectPage(child: child),
                ),
              ),
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Kết nối chuyên gia/trung tâm'),
            ),
          ],
        ),
      ),
    );
  }
}
