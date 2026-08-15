import 'package:flutter/material.dart';

import '../../core/theme/iris_theme.dart';
import '../../domain/models/child.dart';
import 'assessment_summary_page.dart';

/// Kết quả sàng lọc — luôn hiển thị rõ đây KHÔNG phải kết luận chẩn đoán.
class ScreeningResultPage extends StatelessWidget {
  final Child child;
  final String score;
  final String resultSummary;

  /// `true` khi bài sàng lọc này thực hiện trong luồng onboarding ngay sau
  /// khi tạo hồ sơ — khi đó nút "Tiếp tục" dẫn thẳng về `HomePage` (xoá
  /// back-stack) thay vì vào Bước 4 (`AssessmentSummaryPage`) như luồng gọi
  /// từ `ProfileDetailPage._openScreening()`.
  final bool isOnboarding;

  const ScreeningResultPage({
    super.key,
    required this.child,
    required this.score,
    required this.resultSummary,
    this.isOnboarding = false,
  });

  /// Tách "x/y" từ [score] để tính tỉ lệ cho vòng tròn điểm — chỉ phục vụ
  /// hiển thị, không đổi cách tính điểm sàng lọc (vẫn từ `resultSummary`
  /// truyền vào nguyên văn).
  double get _ratio {
    final parts = score.split('/');
    if (parts.length != 2) return 0;
    final flagged = int.tryParse(parts[0]);
    final total = int.tryParse(parts[1]);
    if (flagged == null || total == null || total == 0) return 0;
    return flagged / total;
  }

  /// Nhãn mô tả trung tính, tái dùng đúng cụm từ "dấu hiệu cần chú ý" đã
  /// dùng trong `resultSummary` (screening_questionnaire_page.dart) — tránh
  /// tự đặt ra nhãn mức độ nguy cơ/chẩn đoán mới không có trong logic đã có.
  String get _levelLabel {
    if (_ratio <= 0) return 'Không ghi nhận dấu hiệu cần chú ý';
    if (_ratio < 0.5) return 'Một vài dấu hiệu cần chú ý';
    return 'Nhiều dấu hiệu cần chú ý';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả sàng lọc')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IrisSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kết quả cho ${child.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: _ratio,
                        strokeWidth: 14,
                        color: _ratio < 0.5
                            ? IrisColors.primary
                            : IrisColors.warning,
                        backgroundColor: IrisColors.neutralSoft,
                      ),
                    ),
                    Text(
                      score,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _levelLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Card(
              color: IrisColors.warningSoft,
              child: Padding(
                padding: IrisSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điểm: $score',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                if (isOnboarding) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => AssessmentSummaryPage(child: child),
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
}
