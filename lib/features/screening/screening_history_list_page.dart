import 'package:flutter/material.dart';

import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
import '../../data/local/database.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/screening_session.dart';
import '../../domain/services/active_child_service.dart';
import '../../domain/services/screening_scoring_service.dart';
import 'screening_result_page.dart';

class _ScreeningHistoryData {
  final Child? child;
  final List<ScreeningSession> screenings;

  const _ScreeningHistoryData({required this.child, required this.screenings});
}

/// Màn hình "Lịch sử sàng lọc" — hiển thị danh sách các lần làm bài sàng lọc
/// của ĐÚNG trẻ đang hoạt động (active child), đọc tươi từ ActiveChildService.
class ScreeningHistoryListPage extends StatefulWidget {
  final ActiveChildService? activeChildService;
  final ChildRepository? childRepository;
  final ScreeningRepository? screeningRepository;

  const ScreeningHistoryListPage({
    super.key,
    this.activeChildService,
    this.childRepository,
    this.screeningRepository,
  });

  @override
  State<ScreeningHistoryListPage> createState() =>
      _ScreeningHistoryListPageState();
}

class _ScreeningHistoryListPageState extends State<ScreeningHistoryListPage> {
  late final ActiveChildService _activeChildService =
      widget.activeChildService ?? ActiveChildService();
  late final ChildRepository _childRepository =
      widget.childRepository ?? ChildRepository(AppDatabase.instance);
  late final ScreeningRepository _screeningRepository =
      widget.screeningRepository ?? ScreeningRepository(AppDatabase.instance);

  late Future<_ScreeningHistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ScreeningHistoryListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reload();
  }

  void _reload() {
    setState(() {
      _historyFuture = _loadData();
    });
  }

  Future<_ScreeningHistoryData> _loadData() async {
    // Luôn đọc active_child_id tươi ngay lúc mở màn hình
    final activeChildId = await _activeChildService.getActiveChildId();
    if (activeChildId == null) {
      return const _ScreeningHistoryData(child: null, screenings: []);
    }

    final child = await _childRepository.getById(activeChildId);
    if (child == null) {
      return const _ScreeningHistoryData(child: null, screenings: []);
    }

    // Lọc trực tiếp bằng WHERE child_id = ? trong SQL
    final screenings = await _screeningRepository.getSessionsByChildId(
      activeChildId,
    );

    return _ScreeningHistoryData(child: child, screenings: screenings);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa ghi nhận ngày';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year lúc $hour:$minute';
  }

  Color _levelColor(String giaiDoan) {
    switch (giaiDoan) {
      case giaiDoan1:
        return IrisColors.success;
      case giaiDoan2:
        return IrisColors.warning;
      case giaiDoan3:
        return IrisColors.danger;
      default:
        return IrisColors.primary;
    }
  }

  String _giaiDoanLabel(String giaiDoan) {
    switch (giaiDoan) {
      case giaiDoan1:
        return 'Giai đoạn 1';
      case giaiDoan2:
        return 'Giai đoạn 2';
      case giaiDoan3:
        return 'Giai đoạn 3';
      default:
        return 'Chưa đủ dữ liệu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ScreeningHistoryData>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lịch sử sàng lọc')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lịch sử sàng lọc')),
            body: Center(
              child: Padding(
                padding: IrisSpacing.page,
                child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
              ),
            ),
          );
        }

        final data = snapshot.data;
        final child = data?.child;
        final screenings = data?.screenings ?? [];

        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lịch sử sàng lọc')),
            body: const Center(
              child: Padding(
                padding: IrisSpacing.page,
                child: Text('Chưa có hồ sơ trẻ nào được chọn.'),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text('Lịch sử sàng lọc — ${child.name}')),
          body: screenings.isEmpty
              ? _buildEmptyState(child)
              : _buildHistoryList(child, screenings),
        );
      },
    );
  }

  Widget _buildEmptyState(Child child) {
    return Center(
      child: Padding(
        padding: IrisSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const IrisIconChip(
              icon: Icons.history_rounded,
              color: IrisColors.primary,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử sàng lọc cho ${child.name}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Trẻ chưa thực hiện bài sàng lọc nào. '
              'Bạn có thể bắt đầu sàng lọc từ Trang chủ.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(Child child, List<ScreeningSession> screenings) {
    return ListView.separated(
      padding: IrisSpacing.page,
      itemCount: screenings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final screening = screenings[index];
        final levelColor = _levelColor(screening.giaiDoan);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: IrisRadii.cardBorder,
            side: BorderSide(
              color: levelColor.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: InkWell(
            borderRadius: IrisRadii.cardBorder,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScreeningResultPage(
                    screeningId: screening.id,
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: levelColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _giaiDoanLabel(screening.giaiDoan),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (screening.tongDiem60 != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor.withValues(alpha: 0.15),
                                  borderRadius: IrisRadii.pillBorder,
                                ),
                                child: Text(
                                  '${screening.tongDiem60!.toStringAsFixed(1)}/60',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: levelColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ngày thực hiện: ${_formatDateTime(screening.ngayThucHien)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: IrisColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
