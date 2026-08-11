import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/services/screening_question_bank.dart';
import 'screening_result_page.dart';

class ScreeningQuestionnairePage extends StatefulWidget {
  final Child child;

  const ScreeningQuestionnairePage({super.key, required this.child});

  @override
  State<ScreeningQuestionnairePage> createState() => _ScreeningQuestionnairePageState();
}

class _ScreeningQuestionnairePageState extends State<ScreeningQuestionnairePage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  final _historyLogRepository = HistoryLogRepository(AppDatabase.instance);
  final Map<int, bool> _answers = {};
  bool _saving = false;

  /// Bộ câu hỏi mock phù hợp theo tuổi trẻ (Chức năng #3 roadmap — "Xác định
  /// hướng đánh giá theo độ tuổi"), không dùng cứng 1 bộ cho mọi độ tuổi.
  late final ScreeningQuestionSet _questionSet =
      selectScreeningQuestionSet(childAgeInMonths(widget.child));

  bool get _allAnswered => _answers.length == _questionSet.questions.length;

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời tất cả câu hỏi')),
      );
      return;
    }

    setState(() => _saving = true);
    final flaggedCount = _answers.values.where((answeredYes) => answeredYes).length;
    final total = _questionSet.questions.length;
    final resultSummary =
        'Có $flaggedCount/$total câu hỏi ghi nhận dấu hiệu cần chú ý. '
        'Đây là kết quả sàng lọc tham khảo bằng bộ câu hỏi demo, không phải kết luận chẩn đoán.';

    final screening = await _screeningRepository.save(
      childId: widget.child.id,
      toolName:
          'Bộ câu hỏi sàng lọc mock (demo) — ${_questionSet.label} — chưa phải bộ công cụ chuẩn',
      score: '$flaggedCount/$total',
      resultSummary: resultSummary,
      performedAt: DateTime.now(),
    );

    // Ghi lịch sử — lỗi ở đây không được làm mất kết quả sàng lọc đã lưu ở trên.
    try {
      await _historyLogRepository.add(
        childId: widget.child.id,
        eventType: 'sang_loc',
        description: 'Thực hiện sàng lọc — điểm $flaggedCount/$total',
      );
    } catch (_) {
      // Không chặn luồng chính vì lịch sử là dữ liệu phụ trợ.
    }

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ScreeningResultPage(
          child: widget.child,
          score: screening.score ?? '$flaggedCount/$total',
          resultSummary: resultSummary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questionSet.questions;
    return Scaffold(
      appBar: AppBar(title: Text('Sàng lọc — ${widget.child.name}')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Công cụ sàng lọc: ${_questionSet.label}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }
          final questionIndex = index - 1;
          if (questionIndex == questions.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Hoàn thành'),
              ),
            );
          }

          final question = questions[questionIndex];
          final answer = _answers[questionIndex];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${questionIndex + 1}. $question'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: answer == true
                              ? OutlinedButton.styleFrom(backgroundColor: Colors.orange.withValues(alpha: 0.2))
                              : null,
                          onPressed: () => setState(() => _answers[questionIndex] = true),
                          child: const Text('Có'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          key: ValueKey('answer_no_$questionIndex'),
                          style: answer == false
                              ? OutlinedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.2))
                              : null,
                          onPressed: () => setState(() => _answers[questionIndex] = false),
                          child: const Text('Không'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
