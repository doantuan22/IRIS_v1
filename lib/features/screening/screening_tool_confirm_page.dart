import 'package:flutter/material.dart';

import '../../core/theme/iris_assets.dart';
import '../../domain/models/child.dart';
import 'screening_questionnaire_page.dart';

/// Bước 3 — Màn xác nhận công cụ sàng lọc sẽ dùng trước khi vào bảng câu hỏi thật.
class ScreeningToolConfirmPage extends StatelessWidget {
  final Child child;
  final bool isOnboarding;

  const ScreeningToolConfirmPage({
    super.key,
    required this.child,
    this.isOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Image.asset(
                IrisAssets.screeningChecklistIllustration,
                width: 132,
                height: 132,
                fit: BoxFit.contain,
                semanticLabel: 'Minh hoạ bảng kiểm sàng lọc',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bộ câu hỏi sàng lọc 50 câu (7 lĩnh vực)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gồm 50 câu hỏi quan sát biểu hiện hành vi qua 7 lĩnh vực cốt lõi. '
                      'Mỗi câu có 4 mức lựa chọn (Không/Hiếm khi, Thỉnh thoảng, Thường xuyên, N/A) '
                      'áp dụng cho trẻ ở mọi lứa tuổi.',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScreeningQuestionnairePage(
                    child: child,
                    isOnboarding: isOnboarding,
                  ),
                ),
              ),
              child: const Text('Bắt đầu'),
            ),
          ],
        ),
      ),
    );
  }
}
