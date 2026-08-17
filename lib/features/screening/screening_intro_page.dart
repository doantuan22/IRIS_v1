import 'package:flutter/material.dart';

import '../../core/theme/iris_assets.dart';
import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
import '../../domain/models/child.dart';
import 'assessment_summary_page.dart';
import 'screening_tool_confirm_page.dart';

/// Bước 3 — Lựa chọn thực hiện bài sàng lọc: đúng 2 nhánh, không có nhánh
/// thứ 3. "Chưa muốn" là lựa chọn trung lập, KHÔNG tạo bản ghi `screenings`
/// và không mang bất kỳ hàm ý kết luận nào. Cả 2 nhánh đều dẫn tiếp vào Bước
/// 4 (tổng hợp hồ sơ & đề xuất hướng đánh giá) trước khi vào 7 lĩnh vực —
/// dùng `push` (không phải `pushReplacement`) để giữ trang này trong ngăn
/// xếp: `ProfileDetailPage._openScreening()` đang `await` chính route này,
/// nếu tự thay thế chính mình thì Future đó hoàn tất ngay khi bấm nút (thay
/// vì khi người dùng thực sự quay lại hồ sơ), khiến badge "Đã sàng lọc"
/// không được làm mới đúng lúc.
class ScreeningIntroPage extends StatelessWidget {
  final Child child;

  /// `true` khi màn này được vào ngay sau khi tạo hồ sơ trẻ (luồng
  /// onboarding từ `CreateProfilePage`) — khi đó cả 2 nhánh đều kết thúc
  /// thẳng ở `HomePage` (xoá back-stack) thay vì tiếp tục vào Bước 4 (tổng
  /// hợp hồ sơ & đề xuất hướng đánh giá) như luồng gọi từ
  /// `ProfileDetailPage._openScreening()`. Không đổi logic bài sàng lọc,
  /// chỉ đổi điểm đến điều hướng.
  final bool isOnboarding;

  const ScreeningIntroPage({
    super.key,
    required this.child,
    this.isOnboarding = false,
  });

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
            const SizedBox(height: IrisSpacing.md),
            Center(
              child: Container(
                width: 126,
                height: 126,
                margin: const EdgeInsets.symmetric(vertical: IrisSpacing.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  border: Border.all(color: IrisColors.primarySoft),
                  boxShadow: IrisShadows.soft,
                ),
                alignment: Alignment.center,
                child: const IrisAssetIcon(
                  asset: IrisAssets.featureAssessment,
                  size: 108,
                  semanticLabel: 'Minh hoạ bảng kiểm sàng lọc',
                ),
              ),
            ),
            const SizedBox(height: IrisSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScreeningToolConfirmPage(
                    child: child,
                    isOnboarding: isOnboarding,
                  ),
                ),
              ),
              child: const Text('Có'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                if (isOnboarding) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AssessmentSummaryPage(child: child),
                  ),
                );
              },
              child: const Text('Chưa muốn'),
            ),
          ],
        ),
      ),
    );
  }
}
