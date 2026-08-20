import 'package:flutter/material.dart';

import '../../core/constants/screening_domains.dart';
import '../../core/theme/iris_theme.dart';
import '../../data/local/database.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/services/screening_change_service.dart';
import '../../domain/services/screening_loader_service.dart';
import '../../domain/services/screening_scoring_service.dart';
import 'screening_result_page.dart';

/// Màn hình làm bài sàng lọc mới — Mô hình 1 câu hỏi / 1 màn hình, đúng bộ
/// 20 câu của mức tuổi trẻ (xác định tự động qua `childAgeInMonths()`).
/// Sau câu cuối, hỏi thêm 1 màn "cờ cảnh báo" trước khi tính điểm và hiển
/// thị kết quả.
class ScreeningQuestionnairePage extends StatefulWidget {
  final Child child;
  final bool isOnboarding;
  final ScreeningQuestionnaireData?
  questionnaireData; // Cho phép inject trong test
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
  final Map<String, ScreeningRawAnswer> _answers = {}; // cau_hoi_id -> answer
  bool _isSubmitting = false;
  bool _isAdvancing = false;
  bool _showingWarningStep = false;

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
    List<ScreeningQuestion> questions,
    ScreeningQuestion question,
    ScreeningRawAnswer value,
  ) {
    if (_isSubmitting || _isAdvancing) return;

    setState(() {
      _answers[question.id] = value;
      _isAdvancing = true;
    });

    if (_currentIndex < questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _isAdvancing = false;
        });
      });
    } else {
      // Đã là câu cuối cùng — chuyển sang màn hỏi cờ cảnh báo.
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _isAdvancing = false;
          _showingWarningStep = true;
        });
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0 && !_isSubmitting && !_isAdvancing) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _finishAndSave(
    ScreeningTierQuestionnaire tier,
    bool coCanhBao,
  ) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = ScreeningScoringService.calculateScore(
        answers: _answers,
        questions: tier.cauHoi,
        coCanhBao: coCanhBao,
      );

      final answersList = tier.cauHoi.map((q) {
        final a = _answers[q.id];
        return (
          cauHoiId: q.id,
          linhVuc: q.linhVuc,
          nhomVanDong: q.nhomVanDong,
          diem: a?.laNa == true ? null : a?.diem,
          laNa: a?.laNa ?? true,
        );
      }).toList();

      final domainResultsList = result.domainResults.map((d) {
        return (
          linhVuc: d.linhVuc,
          diemTho: d.diemTho,
          soCauTraLoi: d.soCauTraLoi,
          soCauNa: d.soCauNa,
          diemQuyDoi12: d.diemQuyDoi12,
          mucLinhVuc: d.mucLinhVuc,
        );
      }).toList();

      final session = await _screeningRepository.saveScreeningSession(
        childId: widget.child.id,
        mucTuoiLamBai: tier.mucTuoi,
        tongDiem60: result.tongDiem60,
        giaiDoan: result.giaiDoan,
        coCanhBao: coCanhBao,
        ngayThucHien: DateTime.now(),
        answers: answersList,
        domainResults: domainResultsList,
      );
      ScreeningChangeService.instance.notifyScreeningSaved();

      try {
        await _historyLogRepository.add(
          childId: widget.child.id,
          eventType: 'sang_loc',
          description:
              'Thực hiện sàng lọc ${screeningAgeTierLabel(tier.mucTuoi)} — '
              'kết quả: ${result.giaiDoan == giaiDoanChuaDuDuLieu ? "Chưa đủ dữ liệu" : "Giai đoạn ${result.giaiDoan}"}',
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
            screeningId: session.id,
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

        final ageMonths = childAgeInMonths(widget.child);
        final ageTier = screeningAgeTierForMonths(ageMonths);
        if (ageTier == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sàng lọc')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Trẻ ${ageMonths < 24 ? "chưa đủ 24 tháng" : "đã trên 71 tháng"} '
                  '($ageMonths tháng) — bộ sàng lọc hiện tại chỉ áp dụng cho '
                  'trẻ 24-71 tháng (2-5 tuổi).',
                ),
              ),
            ),
          );
        }

        final tier = snapshot.data!.forTier(ageTier.tier);
        if (tier == null || tier.cauHoi.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sàng lọc')),
            body: Center(
              child: Text(
                'Chưa có bộ câu hỏi cho mức ${screeningAgeTierLabel(ageTier.tier)}.',
              ),
            ),
          );
        }

        if (_showingWarningStep) {
          return _WarningFlagStep(
            isSubmitting: _isSubmitting,
            onAnswer: (coCanhBao) => _finishAndSave(tier, coCanhBao),
          );
        }

        final questions = tier.cauHoi;
        final totalQuestions = questions.length;
        final currentQuestion = questions[_currentIndex];
        final selectedAnswer = _answers[currentQuestion.id];
        final domainColor = IrisDomainStyle.colorOf(currentQuestion.linhVuc);
        final domainName = screeningDomains
            .firstWhere(
              (d) => d.code == currentQuestion.linhVuc,
              orElse: () => ScreeningDomain(
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
                    child: AnimatedSwitcher(
                      duration: IrisMotion.question,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(.06, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: Column(
                        key: ValueKey(currentQuestion.id),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                child: Text(
                                  domainName,
                                  style: TextStyle(
                                    color: domainColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
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
                              child: Text(
                                currentQuestion.noiDung,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      height: 1.45,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _AnswerOptionTile(
                            title: '0 — Chưa làm được',
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 0,
                            selectedColor: IrisColors.danger,
                            onTap: () => _selectAnswer(
                              questions,
                              currentQuestion,
                              (diem: 0, laNa: false),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: '1 — Có hỗ trợ',
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 1,
                            selectedColor: IrisColors.warning,
                            onTap: () => _selectAnswer(
                              questions,
                              currentQuestion,
                              (diem: 1, laNa: false),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: '2 — Chưa ổn định',
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 2,
                            selectedColor: IrisColors.primary,
                            onTap: () => _selectAnswer(
                              questions,
                              currentQuestion,
                              (diem: 2, laNa: false),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: '3 — Độc lập & thường xuyên',
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 3,
                            selectedColor: IrisColors.success,
                            onTap: () => _selectAnswer(
                              questions,
                              currentQuestion,
                              (diem: 3, laNa: false),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: 'N/A — Không tính điểm',
                            isSelected:
                                selectedAnswer != null && selectedAnswer.laNa,
                            selectedColor: IrisColors.neutral,
                            onTap: () => _selectAnswer(
                              questions,
                              currentQuestion,
                              (diem: null, laNa: true),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_currentIndex > 0)
                            TextButton.icon(
                              onPressed: _previousQuestion,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Quay lại câu trước'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _WarningFlagStep extends StatelessWidget {
  final bool isSubmitting;
  final ValueChanged<bool> onAnswer;

  const _WarningFlagStep({required this.isSubmitting, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sàng lọc — Câu hỏi bổ sung')),
      body: isSubmitting
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
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Trẻ có biểu hiện MẤT đi kỹ năng đã từng làm được trước đó, '
                    'hoặc bạn có lo ngại RÕ RỆT về sự phát triển của trẻ '
                    'không, dù các câu trả lời ở trên như thế nào?',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Câu trả lời này độc lập với điểm số — nếu "Có", IRIS sẽ '
                    'luôn khuyến nghị tìm đánh giá chuyên môn ngay bất kể kết '
                    'quả các câu hỏi trước.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => onAnswer(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: IrisColors.danger,
                    ),
                    child: const Text('Có'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => onAnswer(false),
                    child: const Text('Không'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _AnswerOptionTile({
    required this.title,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: IrisMotion.component,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withValues(alpha: 0.12)
            : IrisColors.surface,
        borderRadius: IrisRadii.cardBorder,
        border: Border.all(
          color: isSelected ? selectedColor : IrisColors.divider,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected ? IrisShadows.soft : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: IrisRadii.cardBorder,
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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? IrisColors.primaryDark
                          : IrisColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
