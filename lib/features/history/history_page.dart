import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/history_log.dart';

/// Lịch sử tổng hợp toàn bộ mốc thời gian của 1 trẻ: sàng lọc, đánh giá,
/// video — nhóm theo ngày, mới nhất trước (Bước 9 luồng chi tiết gốc).
class HistoryPage extends StatefulWidget {
  final Child child;

  const HistoryPage({super.key, required this.child});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _historyLogRepository = HistoryLogRepository(AppDatabase.instance);
  late Future<List<HistoryLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _logsFuture = _historyLogRepository.getForChild(widget.child.id);
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  IconData _iconFor(String eventType) => switch (eventType) {
        'sang_loc' => Icons.fact_check_outlined,
        'danh_gia' => Icons.checklist_outlined,
        'video' => Icons.videocam_outlined,
        'ho_so' => Icons.person_outline,
        'tong_quan' => Icons.auto_awesome_outlined,
        _ => Icons.event_note_outlined,
      };

  String _labelFor(String eventType) => switch (eventType) {
        'sang_loc' => 'Sàng lọc',
        'danh_gia' => 'Đánh giá',
        'video' => 'Video',
        'ho_so' => 'Hồ sơ',
        'tong_quan' => 'Chân dung toàn cảnh',
        _ => eventType,
      };

  /// Nhóm các log theo ngày (yyyy-MM-dd), giữ nguyên thứ tự mới nhất trước
  /// vì [HistoryLogRepository.getForChild] đã sắp xếp `event_date DESC`.
  List<MapEntry<DateTime, List<HistoryLog>>> _groupByDay(List<HistoryLog> logs) {
    final groups = <DateTime, List<HistoryLog>>{};
    for (final log in logs) {
      final day = DateTime(log.eventDate.year, log.eventDate.month, log.eventDate.day);
      groups.putIfAbsent(day, () => []).add(log);
    }
    final entries = groups.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch sử — ${widget.child.name}')),
      body: FutureBuilder<List<HistoryLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text('Không tải được lịch sử: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có sự kiện nào trong lịch sử của trẻ này.\n'
                  'Sàng lọc, đánh giá lĩnh vực, hoặc quay video sẽ hiện tại đây.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final groups = _groupByDay(logs);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(group.key),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: group.value
                            .map(
                              (log) => ListTile(
                                leading: Icon(_iconFor(log.eventType)),
                                title: Text(log.description ?? _labelFor(log.eventType)),
                                subtitle: Text('${_labelFor(log.eventType)} • ${_formatTime(log.eventDate)}'),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
