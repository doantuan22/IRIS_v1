import 'package:flutter/material.dart';

import '../../core/constants/screening_domains.dart';
import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
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
/// Sau câu cuối, tính điểm và chuyển thẳng sang màn kết quả.
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
    ScreeningTierQuestionnaire tier,
    ScreeningQuestion question,
    ScreeningRawAnswer value,
  ) {
    if (_isSubmitting || _isAdvancing) return;

    final questions = tier.cauHoi;
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
      // Đã là câu cuối cùng — tính điểm và lưu kết quả ngay, không còn màn
      // trung gian nào nữa.
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        _finishAndSave(tier);
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

  /// Điểm nối luồng chính sau câu hỏi cuối: chấm điểm (thuần
  /// [ScreeningScoringService], không I/O) → lưu toàn bộ vào DB trong 1
  /// transaction ([ScreeningRepository.saveScreeningSession]) → ghi log lịch
  /// sử (lỗi ghi log bị nuốt có chủ đích, không được làm hỏng kết quả sàng
  /// lọc đã lưu) → điều hướng sang [ScreeningResultPage], truyền thẳng
  /// [result] đã tính (màn kết quả không cần tính lại, chỉ đọc DB lại nếu
  /// được mở từ nơi khác — xem `ScreeningResultPage._loadFromDb`).
  Future<void> _finishAndSave(ScreeningTierQuestionnaire tier) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = ScreeningScoringService.calculateScore(
        answers: _answers,
        questions: tier.cauHoi,
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
        // Màn hỏi "cờ cảnh báo" đã bị bỏ khỏi luồng làm bài (theo yêu cầu
        // tinh chỉnh UI) — cột co_canh_bao trong schema vẫn giữ nguyên
        // (không migration) nhưng từ nay luôn ghi false/0.
        coCanhBao: false,
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
        // resolveScreeningAgeTier LUÔN trả về 1 mức hợp lệ (kẹp về mức gần
        // nhất nếu ngoài dải 24-71 tháng) — không còn nhánh "ngoài phạm vi".
        final ageTier = resolveScreeningAgeTier(ageMonths);

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
                              child: IrisParagraph(
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
                            title: screeningAnswerOptionLabels[0],
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 0,
                            selectedColor: IrisColors.danger,
                            onTap: () => _selectAnswer(tier, currentQuestion, (
                              diem: 0,
                              laNa: false,
                            )),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: screeningAnswerOptionLabels[1],
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 1,
                            selectedColor: IrisColors.warning,
                            onTap: () => _selectAnswer(tier, currentQuestion, (
                              diem: 1,
                              laNa: false,
                            )),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: screeningAnswerOptionLabels[2],
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 2,
                            selectedColor: IrisColors.primary,
                            onTap: () => _selectAnswer(tier, currentQuestion, (
                              diem: 2,
                              laNa: false,
                            )),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: screeningAnswerOptionLabels[3],
                            isSelected:
                                selectedAnswer != null &&
                                !selectedAnswer.laNa &&
                                selectedAnswer.diem == 3,
                            selectedColor: IrisColors.success,
                            onTap: () => _selectAnswer(tier, currentQuestion, (
                              diem: 3,
                              laNa: false,
                            )),
                          ),
                          const SizedBox(height: 10),
                          _AnswerOptionTile(
                            title: screeningAnswerOptionLabelNa,
                            isSelected:
                                selectedAnswer != null && selectedAnswer.laNa,
                            selectedColor: IrisColors.neutral,
                            onTap: () => _selectAnswer(tier, currentQuestion, (
                              diem: null,
                              laNa: true,
                            )),
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
