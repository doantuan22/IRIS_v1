import 'package:flutter/material.dart';

import '../../core/constants/domains.dart';
import '../../core/theme/iris_theme.dart';
import '../../data/local/database.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/services/screening_loader_service.dart';
import '../../domain/services/screening_scoring_service.dart';
import 'screening_result_page.dart';

/// Màn hình làm bài sàng lọc — Mô hình 1 câu hỏi / 1 màn hình.
/// Mỗi thời điểm CHỈ hiển thị đúng 1 câu hỏi, có thanh tiến độ "Câu X/50",
/// 4 lựa chọn (0, 1, 2, N/A), tự động chuyển câu sau khi chọn và cho phép quay lại.
class ScreeningQuestionnairePage extends StatefulWidget {
  final Child child;
  final bool isOnboarding;
  final ScreeningQuestionnaireData? questionnaireData; // Cho phép inject trong test
  final ScreeningRepository? screeningRepository;
  final HistoryLogRepository? historyLogRepository;

  const ScreeningQuestionnairePage({
    super.key,
    required this.child,
    this.isOnboarding = false,
    this.questionnaireData,
    this.screeningRepository,
    this.historyLogRepository,
  });

  @override
  State<ScreeningQuestionnairePage> createState() =>
      _ScreeningQuestionnairePageState();
}

class _ScreeningQuestionnairePageState
    extends State<ScreeningQuestionnairePage> {
  late final ScreeningRepository _screeningRepository =
      widget.screeningRepository ?? ScreeningRepository(AppDatabase.instance);
  late final HistoryLogRepository _historyLogRepository =
      widget.historyLogRepository ?? HistoryLogRepository(AppDatabase.instance);

  late Future<ScreeningQuestionnaireData> _questionnaireFuture;
  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // cau_hoi_id -> '0'|'1'|'2'|'N/A'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.questionnaireData != null) {
      _questionnaireFuture = Future.value(widget.questionnaireData);
    } else {
      _questionnaireFuture = ScreeningLoaderService.loadQuestionnaire();
    }
  }

  void _selectAnswer(
    ScreeningQuestionnaireData data,
    ScreeningQuestion question,
    String value,
  ) {
    if (_isSubmitting) return;

    setState(() {
      _answers[question.id] = value;
    });

    if (_currentIndex < data.cauHoi.length - 1) {
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
        });
      });
    } else {
      // Đã là câu cuối cùng (câu 50)
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        _finishAndSave(data);
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0 && !_isSubmitting) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _nextQuestion(int totalQuestions) {
    if (_currentIndex < totalQuestions - 1 && !_isSubmitting) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  Future<void> _finishAndSave(ScreeningQuestionnaireData data) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = ScreeningScoringService.calculateScore(
        answers: _answers,
        questionnaire: data,
      );

      final scoreStr = result.diemToanBaiPhanTram != null
          ? '${result.diemToanBaiPhanTram!.round()}%'
          : 'Chưa đủ dữ liệu';

      final responsesList = data.cauHoi.map((q) {
        return (
          cauHoiId: q.id,
          linhVuc: q.linhVuc,
          giaTri: _answers[q.id] ?? 'N/A',
        );
      }).toList();

      final domainScoresList = result.domainScores.map((d) {
        return (
          linhVuc: d.linhVuc,
          soCauThietKe: d.soCauThietKe,
          soCauHopLe: d.soCauHopLe,
          diemTho: d.diemTho,
          diemPhanTram: d.diemPhanTram,
        );
      }).toList();

      final screening = await _screeningRepository.saveScreeningSession(
        childId: widget.child.id,
        toolName: data.meta.boCauHoiId,
        score: scoreStr,
        resultSummary: result.mucMoTaTen,
        performedAt: DateTime.now(),
        responses: responsesList,
        domainScores: domainScoresList,
      );

      try {
        await _historyLogRepository.add(
          childId: widget.child.id,
          eventType: 'sang_loc',
          description:
              'Thực hiện sàng lọc 50 câu — kết quả: $scoreStr (${result.mucMoTaTen})',
        );
      } catch (_) {
        // Không để lỗi ghi lịch sử làm ảnh hưởng kết quả sàng lọc
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScreeningResultPage(
            child: widget.child,
            screeningId: screening.id,
            score: scoreStr,
            resultSummary: result.mucMoTaTen,
            scoreResult: result,
            isOnboarding: widget.isOnboarding,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu kết quả sàng lọc: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScreeningQuestionnaireData>(
      future: _questionnaireFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sàng lọc')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Không tải được bộ câu hỏi: ${snapshot.error}'),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        final questions = data.cauHoi;
        final totalQuestions = questions.length;

        if (totalQuestions == 0) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sàng lọc')),
            body: const Center(child: Text('Bộ câu hỏi rỗng.')),
          );
        }

        final currentQuestion = questions[_currentIndex];
        final selectedAnswer = _answers[currentQuestion.id];
        final domainColor = IrisDomainStyle.colorOf(currentQuestion.linhVuc);
        final domainName = domains
            .firstWhere(
              (d) => d.code == currentQuestion.linhVuc,
              orElse: () => Domain(
                code: currentQuestion.linhVuc,
                label: currentQuestion.linhVuc,
              ),
            )
            .label;

        return Scaffold(
          appBar: AppBar(
            title: Text('Sàng lọc — ${widget.child.name}'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / totalQuestions,
                backgroundColor: IrisColors.neutralSoft,
                valueColor: AlwaysStoppedAnimation<Color>(domainColor),
              ),
            ),
          ),
          body: _isSubmitting
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang tính điểm và lưu kết quả...'),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: IrisSpacing.page,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hàng thông tin tiến độ & lĩnh vực
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: domainColor.withValues(alpha: 0.15),
                                borderRadius: IrisRadii.pillBorder,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    IrisDomainStyle.iconOf(
                                      currentQuestion.linhVuc,
                                    ),
                                    size: 16,
                                    color: domainColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    domainName,
                                    style: TextStyle(
                                      color: domainColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentQuestion.tieuLinhVuc.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentQuestion.tieuLinhVuc,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              'Câu ${_currentIndex + 1}/$totalQuestions',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: IrisColors.primaryDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card câu hỏi chính
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: IrisRadii.cardBorder,
                            side: BorderSide(
                              color: domainColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentQuestion.noiDung,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        height: 1.45,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (currentQuestion.goiYQuanSat.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: IrisColors.neutralSoft,
                                      borderRadius: IrisRadii.inputBorder,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.lightbulb_outline,
                                          size: 18,
                                          color: IrisColors.warning,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Gợi ý: ${currentQuestion.goiYQuanSat}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4 Lựa chọn trả lời
                        _AnswerOptionTile(
                          value: '0',
                          title: '0 — Không / Hiếm khi',
                          subtitle: 'Biểu hiện không xuất hiện hoặc rất ít',
                          isSelected: selectedAnswer == '0',
                          selectedColor: IrisColors.success,
                          onTap: () =>
                              _selectAnswer(data, currentQuestion, '0'),
                        ),
                        const SizedBox(height: 10),
                        _AnswerOptionTile(
                          value: '1',
                          title: '1 — Thỉnh thoảng / Không ổn định',
                          subtitle:
                              'Biểu hiện có xuất hiện nhưng không ổn định',
                          isSelected: selectedAnswer == '1',
                          selectedColor: IrisColors.warning,
                          onTap: () =>
                              _selectAnswer(data, currentQuestion, '1'),
                        ),
                        const SizedBox(height: 10),
                        _AnswerOptionTile(
                          value: '2',
                          title: '2 — Thường xuyên / Rõ rệt',
                          subtitle:
                              'Lặp lại nhiều tình huống hoặc ảnh hưởng rõ rệt',
                          isSelected: selectedAnswer == '2',
                          selectedColor: IrisColors.danger,
                          onTap: () =>
                              _selectAnswer(data, currentQuestion, '2'),
                        ),
                        const SizedBox(height: 10),
                        _AnswerOptionTile(
                          value: 'N/A',
                          title: 'N/A — Không tính điểm',
                          subtitle:
                              'Chưa phù hợp độ tuổi hoặc chưa có cơ hội quan sát',
                          isSelected: selectedAnswer == 'N/A',
                          selectedColor: IrisColors.neutral,
                          onTap: () =>
                              _selectAnswer(data, currentQuestion, 'N/A'),
                        ),
                        const SizedBox(height: 24),

                        // Nút điều hướng quay lại / tiếp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed:
                                  _currentIndex > 0 ? _previousQuestion : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Quay lại câu trước'),
                            ),
                            if (selectedAnswer != null &&
                                _currentIndex < totalQuestions - 1)
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    _nextQuestion(totalQuestions),
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Tiếp theo'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _AnswerOptionTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? selectedColor.withValues(alpha: 0.12)
          : IrisColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: IrisRadii.cardBorder,
        side: BorderSide(
          color: isSelected ? selectedColor : IrisColors.divider,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: IrisRadii.cardBorder,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? selectedColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? selectedColor : IrisColors.divider,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? IrisColors.primaryDark
                            : IrisColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
