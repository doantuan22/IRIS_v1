import 'package:flutter/material.dart';

import '../../domain/models/child.dart';
import '../../domain/services/screening_question_bank.dart';
import 'screening_questionnaire_page.dart';

/// Bước 3 — màn xác nhận công cụ sàng lọc sẽ dùng, hiện sau khi chọn "Có"
/// và trước khi vào bảng câu hỏi thật — không tự động nhảy thẳng vào câu
/// hỏi ngay khi chọn "Có".
class ScreeningToolConfirmPage extends StatelessWidget {
  final Child child;

  const ScreeningToolConfirmPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ageMonths = childAgeInMonths(child);
    final questionSet = selectScreeningQuestionSet(ageMonths);
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận công cụ sàng lọc')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Công cụ sàng lọc sẽ dùng cho ${child.name} (${formatAgeLabel(child)}):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Công cụ sẽ sử dụng: ${questionSet.label}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Gồm ${questionSet.questions.length} câu hỏi có/không, chọn tự động theo độ tuổi hiện tại của trẻ.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ScreeningQuestionnairePage(child: child)),
              ),
              child: const Text('Bắt đầu'),
            ),
          ],
        ),
      ),
    );
  }
}
