import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/iris_assets.dart';
import '../../../core/theme/iris_theme.dart';
import '../../../core/widgets/iris_ui.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/screening_repository.dart';
import '../../../domain/models/child.dart';
import '../../ai_chat/ai_chat_page.dart';
import '../../assessment/domain_list_page.dart';
import '../../expert_connect/expert_connect_page.dart';
import '../../history/history_page.dart';
import '../../screening/screening_intro_page.dart';
import '../../video_recording/video_list_page.dart';
import 'child_debug_page.dart';

/// Trang chi tiết hồ sơ trẻ — điểm vào các chức năng sàng lọc, đánh giá,
/// lịch sử, hỏi đáp AI, quay video cho một trẻ cụ thể.
class ProfileDetailPage extends StatefulWidget {
  final Child child;

  const ProfileDetailPage({super.key, required this.child});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  late Future<bool> _hasScreeningFuture;

  @override
  void initState() {
    super.initState();
    _reloadScreeningStatus();
  }

  void _reloadScreeningStatus() {
    setState(() {
      _hasScreeningFuture = _screeningRepository.hasScreening(widget.child.id);
    });
  }

  Future<void> _openScreening() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScreeningIntroPage(child: widget.child),
      ),
    );
    _reloadScreeningStatus();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Scaffold(
      appBar: AppBar(
        title: Text(child.name),
        // Chỉ hiện ở debug build — không lộ hành động debug cho người dùng
        // thường trong luồng chính. Xem ChildDebugPage cho 3 hành động debug
        // (trước đây từng là nút inline ngay trên màn này).
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Debug',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChildDebugPage(child: child)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: IrisSpacing.page,
        children: [
          Card(
            child: Padding(
              padding: IrisSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatAgeLabel(child)} • ${child.gender ?? "chưa rõ giới tính"}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Người đánh giá: ${child.nguoiDanhGia ?? "Chưa cập nhật"}',
                  ),
                  const SizedBox(height: 4),
                  Text('Vai trò: ${child.vaiTro ?? "Chưa cập nhật"}'),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: _hasScreeningFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final hasScreening = snapshot.data!;
                      return IrisStatusBadge(
                        label: hasScreening ? 'Đã sàng lọc' : 'Chưa sàng lọc',
                        color: hasScreening
                            ? IrisColors.success
                            : IrisColors.neutral,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openScreening,
            icon: const IrisAssetIcon(
              asset: IrisAssets.iconScreening,
              size: IrisSizes.iconMedium,
            ),
            label: const Text('Sàng lọc'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DomainListPage(child: child)),
            ),
            icon: const IrisAssetIcon(
              asset: IrisAssets.iconAssessment,
              size: IrisSizes.iconMedium,
            ),
            label: const Text('Đánh giá 7 lĩnh vực'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistoryPage(child: child)),
            ),
            icon: const IrisAssetIcon(
              asset: IrisAssets.iconHistory,
              size: IrisSizes.iconMedium,
            ),
            label: const Text('Lịch sử'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => AiChatPage(child: child))),
            icon: const IrisAssetIcon(
              asset: IrisAssets.iconAiChat,
              size: IrisSizes.iconMedium,
            ),
            label: const Text('Hỏi đáp AI'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoListPage(child: child)),
            ),
            icon: const IrisAssetIcon(
              asset: IrisAssets.iconVideo,
              size: IrisSizes.iconMedium,
            ),
            label: const Text('Video quan sát'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpertConnectPage(child: child),
              ),
            ),
            icon: const IrisAssetIcon(
              asset: IrisAssets.iconExpert,
              size: IrisSizes.iconMedium,
            ),
            label: const Text('Kết nối chuyên gia/trung tâm'),
          ),
        ],
      ),
    );
  }
}
