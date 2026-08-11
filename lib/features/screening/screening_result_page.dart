import 'package:flutter/material.dart';

import '../../domain/models/child.dart';

/// Kết quả sàng lọc — luôn hiển thị rõ đây KHÔNG phải kết luận chẩn đoán.
class ScreeningResultPage extends StatelessWidget {
  final Child child;
  final String score;
  final String resultSummary;

  const ScreeningResultPage({
    super.key,
    required this.child,
    required this.score,
    required this.resultSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả sàng lọc')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kết quả cho ${child.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm: $score', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(resultSummary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đây là kết quả sàng lọc, không phải kết luận chẩn đoán.',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                // Ngăn xếp hiện tại: ...ProfileDetail, Intro, [Questionnaire đã bị
                // thay bằng] Result — pop 2 lần để quay thẳng về ProfileDetail.
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pop();
              },
              child: const Text('Quay lại hồ sơ trẻ'),
            ),
          ],
        ),
      ),
    );
  }
}
