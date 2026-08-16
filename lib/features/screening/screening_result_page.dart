import 'package:flutter/material.dart';

import '../../core/constants/domains.dart';
import '../../core/theme/iris_theme.dart';
import '../../data/local/database.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/screening.dart';
import '../../domain/models/screening_domain_score.dart';
import '../../domain/services/screening_scoring_service.dart';
import 'assessment_summary_page.dart';

const String _defaultDisclaimerText =
    'Đây là bản sàng lọc/thử nghiệm để rà soát mức độ biểu hiện và định hướng hỗ trợ. '
    'Không dùng tổng điểm hoặc các mức mô tả để kết luận/chẩn đoán rối loạn phổ tự kỷ hay thay thế đánh giá chuyên môn.';

class _ScreeningResultDbData {
  final Child child;
  final Screening screening;
  final List<ScreeningDomainScore> domainScores;

  const _ScreeningResultDbData({
    required this.child,
    required this.screening,
    required this.domainScores,
  });
}

/// Màn hình kết quả sàng lọc 50 câu 7 lĩnh vực.
/// Hỗ trợ cả 2 chế độ:
/// 1. Vừa hoàn thành bài làm: nhận `scoreResult` trực tiếp trong bộ nhớ.
/// 2. Xem lại từ Lịch sử: nhận `screeningId` và tự truy vấn độc lập từ SQLite.
class ScreeningResultPage extends StatefulWidget {
  final Child? child;
  final String? screeningId;
  final String? score;
  final String? resultSummary;
  final ScreeningScoreResult? scoreResult;
  final bool isOnboarding;

  const ScreeningResultPage({
    super.key,
    this.child,
    this.screeningId,
    this.score,
    this.resultSummary,
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
    final screening = await _screeningRepository.getById(screeningId);
    if (screening == null) return null;

    Child? child = widget.child;
    if (child == null || child.id != screening.childId) {
      child = await _childRepository.getById(screening.childId);
    }
    child ??= Child(
      id: screening.childId,
      name: 'Trẻ',
      createdAt: screening.createdAt,
    );

    final domainScores = await _screeningRepository.getDomainScores(
      screeningId,
    );

    return _ScreeningResultDbData(
      child: child,
      screening: screening,
      domainScores: domainScores,
    );
  }

  Color _levelColor(String levelText) {
    if (levelText.contains('Mức 1')) return IrisColors.success;
    if (levelText.contains('Mức 2')) return IrisColors.warning;
    if (levelText.contains('Mức 3')) return IrisColors.danger;
    return IrisColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scoreResult != null) {
      return _buildContent(
        childName: widget.child?.name ?? 'Trẻ',
        scoreText: widget.score ?? '0%',
        resultSummaryText: widget.resultSummary ?? 'Mức 1 - Ít biểu hiện',
        mucMoTaYNghia: widget.scoreResult!.mucMoTaYNghia,
        disclaimer: widget.scoreResult!.luuYKhongChanDoan.isNotEmpty
            ? widget.scoreResult!.luuYKhongChanDoan
            : _defaultDisclaimerText,
        breakdownWidget: _buildDomainBreakdownFromMemory(
          widget.scoreResult!.domainScores,
        ),
        effectiveChild: widget.child ??
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
          scoreText: data.screening.score ?? 'Chưa đủ dữ liệu',
          resultSummaryText:
              data.screening.resultSummary ?? 'Kết quả sàng lọc',
          mucMoTaYNghia: null,
          disclaimer: _defaultDisclaimerText,
          breakdownWidget: _buildDomainBreakdownFromDb(data.domainScores),
          effectiveChild: data.child,
        );
      },
    );
  }

  Widget _buildContent({
    required String childName,
    required String scoreText,
    required String resultSummaryText,
    required String? mucMoTaYNghia,
    required String disclaimer,
    required Widget breakdownWidget,
    required Child effectiveChild,
  }) {
    final levelColor = _levelColor(resultSummaryText);

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

            // Card mức tổng quan
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
                      scoreText,
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
                        resultSummaryText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: levelColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (mucMoTaYNghia != null && mucMoTaYNghia.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        mucMoTaYNghia,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề Breakdown 7 lĩnh vực
            Text(
              'Điểm theo 7 lĩnh vực',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Danh sách breakdown 7 lĩnh vực
            breakdownWidget,

            const SizedBox(height: 20),

            // Lưu ý không chẩn đoán NGUYÊN VĂN
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
                          disclaimer,
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

            // Nút tiếp tục
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

  Widget _buildDomainBreakdownFromMemory(
    List<DomainScoreCalculation> domainScores,
  ) {
    return Column(
      children: domainScores.map((d) {
        final domainColor = IrisDomainStyle.colorOf(d.linhVuc);
        final pct = d.diemPhanTram;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IrisDomainStyle.iconOf(d.linhVuc),
                      color: domainColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.tenHienThi,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      pct != null
                          ? '${pct.round()}%'
                          : 'Chưa đủ dữ liệu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pct != null
                            ? domainColor
                            : Theme.of(context).hintColor,
                        fontStyle: pct == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (pct != null) ...[
                  LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: IrisColors.neutralSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(domainColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.soCauHopLe}/${d.soCauThietKe} câu hợp lệ • Điểm thô: ${d.diemTho}/${d.soCauHopLe * 2}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Chưa đủ dữ liệu cho lĩnh vực này (toàn bộ câu trả lời N/A)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDomainBreakdownFromDb(
    List<ScreeningDomainScore> domainScores,
  ) {
    return Column(
      children: domainScores.map((d) {
        final domainColor = IrisDomainStyle.colorOf(d.linhVuc);
        final domainName = domains
            .firstWhere(
              (dom) => dom.code == d.linhVuc,
              orElse: () => Domain(code: d.linhVuc, label: d.linhVuc),
            )
            .label;
        final pct = d.diemPhanTram;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IrisDomainStyle.iconOf(d.linhVuc),
                      color: domainColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        domainName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      pct != null
                          ? '${pct.round()}%'
                          : 'Chưa đủ dữ liệu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pct != null
                            ? domainColor
                            : Theme.of(context).hintColor,
                        fontStyle: pct == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (pct != null) ...[
                  LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: IrisColors.neutralSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(domainColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.soCauHopLe}/${d.soCauThietKe} câu hợp lệ • Điểm thô: ${d.diemTho}/${d.soCauHopLe * 2}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Chưa đủ dữ liệu cho lĩnh vực này (toàn bộ câu trả lời N/A)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
