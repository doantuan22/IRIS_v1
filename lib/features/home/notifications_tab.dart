import 'package:flutter/material.dart';

import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
import '../../data/local/database.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/app_notification.dart';

/// Tab "Thông báo" — hiển thị danh sách thông báo hệ thống và trạng thái kết nối AI.
class NotificationsTab extends StatefulWidget {
  final NotificationRepository? notificationRepository;

  const NotificationsTab({super.key, this.notificationRepository});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late final NotificationRepository _repository =
      widget.notificationRepository ??
      NotificationRepository(AppDatabase.instance);
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _notificationsFuture = _repository.getAll();
    });
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/$year';
  }

  IconData _getIconForNotification(AppNotification item) {
    if (item.type == 'ai_connectivity') {
      if (item.content.contains('vấn đề') || item.content.contains('lỗi')) {
        return Icons.cloud_off_outlined;
      }
      return Icons.cloud_done_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getIconColor(BuildContext context, AppNotification item) {
    if (item.type == 'ai_connectivity') {
      if (item.content.contains('vấn đề') || item.content.contains('lỗi')) {
        return IrisColors.warning;
      }
      return IrisColors.success;
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _reload,
          ),
        ],
      ),
      body: Stack(
        children: [
          const IrisPageBackdrop(),
          FutureBuilder<List<AppNotification>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(IrisSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: IrisColors.danger,
                          size: 40,
                        ),
                        const SizedBox(height: IrisSpacing.sm),
                        Text(
                          'Không tải được thông báo: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: IrisSpacing.md),
                        OutlinedButton(
                          onPressed: _reload,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(IrisSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 56,
                          color: IrisColors.neutral,
                        ),
                        SizedBox(height: IrisSpacing.md),
                        Text(
                          'Chưa có thông báo nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: IrisColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.separated(
                  padding: IrisSpacing.page,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: IrisSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Card(
                      child: Padding(
                        padding: IrisSpacing.card,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(IrisSpacing.sm),
                              decoration: BoxDecoration(
                                color: _getIconColor(
                                  context,
                                  item,
                                ).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForNotification(item),
                                color: _getIconColor(context, item),
                                size: IrisSizes.iconMedium,
                              ),
                            ),
                            const SizedBox(width: IrisSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        _formatDateTime(item.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: IrisSpacing.xs),
                                  Text(
                                    item.content,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
