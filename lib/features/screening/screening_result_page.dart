import 'package:flutter/material.dart';

import '../../core/constants/screening_domains.dart';
import '../../core/theme/iris_theme.dart';
import '../../data/local/database.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/screening_domain_result.dart';
import '../../domain/models/screening_session.dart';
import '../../domain/services/screening_scoring_service.dart';
import 'assessment_summary_page.dart';

const String _disclaimerText =
    'Đây là bản sàng lọc/thử nghiệm để rà soát mức độ biểu hiện và định hướng hỗ trợ. '
    'Các ngưỡng phân loại là đề xuất nội bộ, chưa chuẩn hóa lâm sàng — không dùng để '
    'chẩn đoán hay thay thế đánh giá chuyên môn.';

class _ScreeningResultDbData {
  final Child child;
  final ScreeningSession session;
  final List<ScreeningDomainResult> domainResults;

  const _ScreeningResultDbData({
    required this.child,
    required this.session,
    required this.domainResults,
  });
}

/// Màn hình kết quả sàng lọc mới (4 mức tuổi × 20 câu × 5 lĩnh vực).
/// Hỗ trợ cả 2 chế độ:
/// 1. Vừa hoàn thành bài làm: nhận [scoreResult] trực tiếp trong bộ nhớ.
/// 2. Xem lại từ Lịch sử: nhận [screeningId] và tự truy vấn độc lập từ SQLite.
class ScreeningResultPage extends StatefulWidget {
  final Child? child;
  final String? screeningId;
  final ScreeningScoreResult? scoreResult;
  final bool isOnboarding;

  const ScreeningResultPage({
    super.key,
    this.child,
    this.screeningId,
    this.scoreResult,
    this.isOnboarding = false,
  });

  @override
  State<ScreeningResultPage> createState() => _ScreeningResultPageState();
}

class _ScreeningResultPageState extends State<ScreeningResultPage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  final _childRepository = ChildRepository(AppDatabase.instance);

  Future<_ScreeningResultDbData?>? _dbDataFuture;

  @override
  void initState() {
    super.initState();
    if (widget.scoreResult == null && widget.screeningId != null) {
      _dbDataFuture = _loadFromDb(widget.screeningId!);
    }
  }

  Future<_ScreeningResultDbData?> _loadFromDb(String screeningId) async {
    final session = await _screeningRepository.getById(screeningId);
    if (session == null) return null;

    Child? child = widget.child;
    if (child == null || child.id != session.childId) {
      child = await _childRepository.getById(session.childId);
    }
    child ??= Child(
      id: session.childId,
      name: 'Trẻ',
      createdAt: session.createdAt,
    );

    final domainResults = await _screeningRepository.getDomainResults(
      screeningId,
    );

    return _ScreeningResultDbData(
      child: child,
      session: session,
      domainResults: domainResults,
    );
  }

  String _giaiDoanLabel(String giaiDoan) {
    switch (giaiDoan) {
      case giaiDoan1:
        return 'Giai đoạn 1';
      case giaiDoan2:
        return 'Giai đoạn 2';
      case giaiDoan3:
        return 'Giai đoạn 3';
      default:
        return 'Chưa đủ dữ liệu';
    }
  }

  Color _giaiDoanColor(String giaiDoan) {
    switch (giaiDoan) {
      case giaiDoan1:
        return IrisColors.success;
      case giaiDoan2:
        return IrisColors.warning;
      case giaiDoan3:
        return IrisColors.danger;
      default:
        return IrisColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scoreResult != null) {
      final result = widget.scoreResult!;
      return _buildContent(
        childName: widget.child?.name ?? 'Trẻ',
        giaiDoan: result.giaiDoan,
        tongDiem60: result.tongDiem60,
        breakdownWidget: _buildDomainBreakdown(
          result.domainResults.map(
            (d) => (
              linhVuc: d.linhVuc,
              diemQuyDoi12: d.diemQuyDoi12,
              mucLinhVuc: d.mucLinhVuc,
            ),
          ),
        ),
        effectiveChild:
            widget.child ??
            Child(
              id: widget.screeningId ?? '',
              name: 'Trẻ',
              createdAt: DateTime.now(),
            ),
      );
    }

    return FutureBuilder<_ScreeningResultDbData?>(
      future: _dbDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kết quả sàng lọc')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kết quả sàng lọc')),
            body: Center(
              child: Padding(
                padding: IrisSpacing.page,
                child: Text(
                  snapshot.hasError
                      ? 'Lỗi tải kết quả: ${snapshot.error}'
                      : 'Không tìm thấy dữ liệu lần sàng lọc này.',
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return _buildContent(
          childName: data.child.name,
          giaiDoan: data.session.giaiDoan,
          tongDiem60: data.session.tongDiem60,
          breakdownWidget: _buildDomainBreakdown(
            data.domainResults.map(
              (d) => (
                linhVuc: d.linhVuc,
                diemQuyDoi12: d.diemQuyDoi12,
                mucLinhVuc: d.mucLinhVuc,
              ),
            ),
          ),
          effectiveChild: data.child,
        );
      },
    );
  }

  Widget _buildContent({
    required String childName,
    required String giaiDoan,
    required double? tongDiem60,
    required Widget breakdownWidget,
    required Child effectiveChild,
  }) {
    final levelColor = _giaiDoanColor(giaiDoan);

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả sàng lọc')),
      body: SingleChildScrollView(
        padding: IrisSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kết quả sàng lọc cho $childName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: IrisRadii.cardBorder,
                side: BorderSide(
                  color: levelColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      tongDiem60 != null
                          ? '${tongDiem60.toStringAsFixed(1)}/60'
                          : '—',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.15),
                        borderRadius: IrisRadii.pillBorder,
                      ),
                      child: Text(
                        _giaiDoanLabel(giaiDoan),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: levelColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Điểm theo 5 lĩnh vực',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            breakdownWidget,

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IrisColors.warningSoft,
                borderRadius: IrisRadii.cardBorder,
                border: Border.all(
                  color: IrisColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: IrisColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lưu ý quan trọng',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: IrisColors.primaryDark,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _disclaimerText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: () {
                if (widget.isOnboarding) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  return;
                }
                if (widget.scoreResult == null &&
                    Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => AssessmentSummaryPage(
                      child: effectiveChild,
                    ),
                  ),
                );
              },
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainBreakdown(
    Iterable<({String linhVuc, double? diemQuyDoi12, String mucLinhVuc})>
    items,
  ) {
    return Column(
      children: items.map((d) {
        final domainColor = IrisDomainStyle.colorOf(d.linhVuc);
        final domainName = screeningDomains
            .firstWhere(
              (dom) => dom.code == d.linhVuc,
              orElse: () =>
                  ScreeningDomain(code: d.linhVuc, label: d.linhVuc),
            )
            .label;
        final score = d.diemQuyDoi12;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    domainName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  score != null ? '${score.toStringAsFixed(1)}/12' : 'Chưa đủ dữ liệu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: score != null ? domainColor : Theme.of(context).hintColor,
                    fontStyle: score == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
