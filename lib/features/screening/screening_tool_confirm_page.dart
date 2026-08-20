import 'package:flutter/material.dart';

import '../../core/theme/iris_assets.dart';
import '../../domain/models/child.dart';
import 'screening_questionnaire_page.dart';

/// Bước 3 — Màn xác nhận công cụ sàng lọc, đứng giữa
/// `ScreeningIntroPage` (hỏi "Có muốn sàng lọc?") và
/// `ScreeningQuestionnairePage` (bảng câu hỏi thật). Chỉ hiển thị thông
/// tin tĩnh, KHÔNG tự chọn mức tuổi ở đây — việc chọn đúng bộ 20 câu theo
/// tuổi trẻ diễn ra ở `ScreeningQuestionnairePage` (qua
/// `resolveScreeningAgeTier`) ngay khi màn đó mở lên.
class ScreeningToolConfirmPage extends StatelessWidget {
  final Child child;

  /// `true` khi vào từ luồng tạo hồ sơ mới (onboarding) — chỉ truyền tiếp
  /// cho `ScreeningQuestionnairePage` để quyết định điều hướng sau khi có
  /// kết quả, không ảnh hưởng nội dung màn này.
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
                      'Bộ câu hỏi sàng lọc 20 câu (5 lĩnh vực)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gồm 20 câu hỏi quan sát biểu hiện qua 5 lĩnh vực phát triển '
                      '(Ngôn ngữ-giao tiếp, Nhận thức-giải quyết vấn đề, Vận động, '
                      'Xã hội-cảm xúc, Tự lập), chọn đúng bộ theo độ tuổi trẻ (2-5 tuổi). '
                      'Mỗi câu có 4 mức lựa chọn (0-3) và N/A.',
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
