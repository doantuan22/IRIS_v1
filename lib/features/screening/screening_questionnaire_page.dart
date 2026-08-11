import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import 'screening_result_page.dart';

/// Bộ câu hỏi sàng lọc MOCK (demo) — 6 câu có/không, chưa phải bộ công cụ
/// sàng lọc chuẩn thật (VD M-CHAT-R). Dùng để minh hoạ luồng chức năng.
const List<String> _mockQuestions = [
  'Trẻ có tránh giao tiếp bằng mắt khi được gọi tên không?',
  'Trẻ có ít khi chỉ tay vào đồ vật để chia sẻ sự thích thú không?',
  'Trẻ có lặp đi lặp lại một số hành động hoặc từ ngữ không?',
  'Trẻ có phản ứng bất thường với âm thanh (quá nhạy hoặc không phản ứng) không?',
  'Trẻ có khó thích nghi khi thay đổi thói quen hàng ngày không?',
  'Trẻ có ít chơi giả vờ (VD: giả vờ nấu ăn, chăm búp bê) so với bạn cùng tuổi không?',
];

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

  bool get _allAnswered => _answers.length == _mockQuestions.length;

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời tất cả câu hỏi')),
      );
      return;
    }

    setState(() => _saving = true);
    final flaggedCount = _answers.values.where((answeredYes) => answeredYes).length;
    final total = _mockQuestions.length;
    final resultSummary =
        'Có $flaggedCount/$total câu hỏi ghi nhận dấu hiệu cần chú ý. '
        'Đây là kết quả sàng lọc tham khảo bằng bộ câu hỏi demo, không phải kết luận chẩn đoán.';

    final screening = await _screeningRepository.save(
      childId: widget.child.id,
      toolName: 'Bộ câu hỏi sàng lọc mock (demo) — chưa phải bộ công cụ chuẩn',
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
    return Scaffold(
      appBar: AppBar(title: Text('Sàng lọc — ${widget.child.name}')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockQuestions.length + 1,
        itemBuilder: (context, index) {
          if (index == _mockQuestions.length) {
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

          final question = _mockQuestions[index];
          final answer = _answers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1}. $question'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: answer == true
                              ? OutlinedButton.styleFrom(backgroundColor: Colors.orange.withValues(alpha: 0.2))
                              : null,
                          onPressed: () => setState(() => _answers[index] = true),
                          child: const Text('Có'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          key: ValueKey('answer_no_$index'),
                          style: answer == false
                              ? OutlinedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.2))
                              : null,
                          onPressed: () => setState(() => _answers[index] = false),
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
