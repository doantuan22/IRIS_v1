import 'package:flutter/material.dart';

import '../../../core/constants/domains.dart';
import '../../../core/theme/iris_assets.dart';
import '../../../core/theme/iris_theme.dart';
import '../../../core/widgets/iris_ui.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../data/repositories/domain_overview_label_repository.dart';
import '../../../data/repositories/overview_repository.dart';
import '../../../data/repositories/overview_summary_repository.dart';
import '../../../domain/models/child.dart';
import '../../../domain/models/domain_overview_label.dart';
import '../../../domain/models/overview_summary.dart';
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

  const _LoadedState({
    required this.doneDomainCount,
    required this.labels,
    this.summary,
  });

  bool get isComplete => doneDomainCount >= domains.length;
}

/// "Chân dung toàn cảnh" — tổng hợp 7 nhãn lĩnh vực (AI hỗ trợ gắn nhãn
/// từng lĩnh vực) thành 1 trong 3 mức tổng quan, tính 100% BẰNG CODE (xem
/// `overview_tier_calculator.dart`) — AI KHÔNG được quyết định mức cuối
/// cùng. Chỉ khả dụng khi trẻ đã có mô tả (Phần 1) cho ĐỦ CẢ 7 lĩnh vực.
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

    if (doneDomains.length < domains.length) {
      return _LoadedState(
        doneDomainCount: doneDomains.length,
        labels: const {},
      );
    }

    final labels = await _labelRepository.getLatestForChild(widget.child.id);
    final summary = await _summaryRepository.getLatestForChild(widget.child.id);
    return _LoadedState(
      doneDomainCount: doneDomains.length,
      labels: labels,
      summary: summary,
    );
  }

  Future<void> _compute() async {
    if (_computing) return;
    setState(() {
      _computing = true;
      _computeError = null;
    });
    try {
      await _overviewRepository.labelAllDomains(widget.child);
      await _overviewRepository.computeAndSaveOverview(widget.child);
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _computeError = 'Lỗi khi tổng hợp: $e');
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }

  Future<void> _retryDescription(OverviewSummary summary) async {
    if (_generatingDescription) return;
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
            return const Center(child: CircularProgressIndicator());
          }
          final state = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!state.isComplete)
                _buildIncomplete(state.doneDomainCount)
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
        const Text(
          'Cần hoàn thành mô tả biểu hiện (Phần 1) cho đủ cả 7 lĩnh vực trước khi tổng hợp '
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

  Widget _buildReady(_LoadedState state) {
    if (state.summary == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đã có đủ mô tả cho cả 7 lĩnh vực. Bấm nút bên dưới để tổng hợp Chân dung toàn cảnh.',
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
                : const Text('Tổng hợp Chân dung toàn cảnh'),
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
                      const IrisMascot(
                        asset: IrisAssets.mascotPointing,
                        height: IrisSizes.iconChip,
                        semanticLabel: 'Gấu IRIS chỉ dẫn',
                      ),
                      const SizedBox(width: IrisSpacing.xs),
                      Text(
                        'Chân dung biểu hiện',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
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
        if (summary.tier == tierChuyenMonSom) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpertConnectPage(child: widget.child),
              ),
            ),
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Kết nối chuyên gia/trung tâm'),
          ),
        ],
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
            child: Text(
              _disclaimerText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
