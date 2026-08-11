import 'package:flutter/material.dart';

import '../../domain/models/child.dart';
import 'assessment_summary_page.dart';
import 'screening_questionnaire_page.dart';

/// Bước 3 — Lựa chọn thực hiện bài sàng lọc: đúng 2 nhánh, không có nhánh
/// thứ 3. "Chưa muốn" là lựa chọn trung lập, KHÔNG tạo bản ghi `screenings`
/// và không mang bất kỳ hàm ý kết luận nào. Cả 2 nhánh đều dẫn tiếp vào Bước
/// 4 (tổng hợp hồ sơ & đề xuất hướng đánh giá) trước khi vào 9 lĩnh vực —
/// dùng `push` (không phải `pushReplacement`) để giữ trang này trong ngăn
/// xếp: `ProfileDetailPage._openScreening()` đang `await` chính route này,
/// nếu tự thay thế chính mình thì Future đó hoàn tất ngay khi bấm nút (thay
/// vì khi người dùng thực sự quay lại hồ sơ), khiến badge "Đã sàng lọc"
/// không được làm mới đúng lúc.
class ScreeningIntroPage extends StatelessWidget {
  final Child child;

  const ScreeningIntroPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sàng lọc')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bạn có muốn thực hiện bài sàng lọc cho ${child.name} ngay bây giờ không?',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Đây là bước không bắt buộc — bạn có thể quay lại làm sau bất cứ lúc nào.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ScreeningQuestionnairePage(child: child)),
              ),
              child: const Text('Có'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AssessmentSummaryPage(child: child)),
              ),
              child: const Text('Chưa muốn'),
            ),
          ],
        ),
      ),
    );
  }
}
