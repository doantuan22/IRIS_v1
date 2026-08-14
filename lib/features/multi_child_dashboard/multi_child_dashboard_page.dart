import 'package:flutter/material.dart';

import '../../core/constants/nine_domains.dart';
import '../../data/local/database.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/services/active_child_service.dart';
import '../child_profile/create_profile/create_profile_page.dart';
import '../child_profile/profile_detail/profile_detail_page.dart';
import '../history/history_page.dart';

enum _ProgressFilter { all, notStarted, inProgress, done }

class _ChildSummary {
  final Child child;
  final int doneDomainCount;
  final DateTime? lastUpdated;

  const _ChildSummary({required this.child, required this.doneDomainCount, required this.lastUpdated});
}

/// Phụ lục 1 — Tổng quan quản lý nhiều trẻ, dành cho phụ huynh nhiều con /
/// giáo viên / trung tâm. Mô phỏng/đơn giản hoá trong phạm vi 1 thiết bị cho
/// bản demo: 1 người dùng local xem nhiều hồ sơ trẻ trên cùng 1 thiết bị,
/// không phải multi-user/đăng nhập/đồng bộ nhiều máy thật.
class MultiChildDashboardPage extends StatefulWidget {
  const MultiChildDashboardPage({super.key});

  @override
  State<MultiChildDashboardPage> createState() => _MultiChildDashboardPageState();
}

class _MultiChildDashboardPageState extends State<MultiChildDashboardPage> {
  final _childRepository = ChildRepository(AppDatabase.instance);
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _historyLogRepository = HistoryLogRepository(AppDatabase.instance);
  final _activeChildService = ActiveChildService();

  late Future<List<_ChildSummary>> _summariesFuture;
  late Future<String?> _activeChildIdFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _ProgressFilter _filter = _ProgressFilter.all;

  @override
  void initState() {
    super.initState();
    _reload();
    _activeChildIdFuture = _activeChildService.getActiveChildId();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  /// Bấm vào 1 dòng hồ sơ (khác menu ⋮) → chọn làm hồ sơ đang hoạt động,
  /// quay thẳng về Trang chủ. Dùng `popUntil((route) => route.isFirst)` vì
  /// `HomePage` luôn là route gốc duy nhất của app (kể cả khi màn này được
  /// mở từ nhiều tầng điều hướng khác nhau — tab "Tài khoản" hoặc icon dashboard
  /// ở `ChildListPage`), nên luôn quay đúng về Trang chủ bất kể mở từ đâu.
  Future<void> _selectAsActive(Child child) async {
    await _activeChildService.setActiveChildId(child.id);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _summariesFuture = _loadSummaries();
    });
  }

  Future<List<_ChildSummary>> _loadSummaries() async {
    final children = await _childRepository.getAll(includeArchived: true);
    final result = <_ChildSummary>[];
    for (final child in children) {
      final assessments = await _assessmentRepository.getForChild(child.id);
      final doneDomains =
          assessments.where((a) => a.contentType == 'mo_ta').map((a) => a.linhVuc).toSet();
      final logs = await _historyLogRepository.getForChild(child.id);
      result.add(_ChildSummary(
        child: child,
        doneDomainCount: doneDomains.length,
        lastUpdated: logs.isNotEmpty ? logs.first.eventDate : null,
      ));
    }
    return result;
  }

  /// Trạng thái đánh giá — quy tắc đơn giản hoá có chủ đích (đúng tinh thần
  /// "có thể đơn giản hoá" của roadmap cho mục Phụ lục 1), không cố khớp
  /// 100% ví dụ minh hoạ trong tài liệu gốc: 0/9 → "Chưa đánh giá", 9/9 →
  /// "Đã đánh giá", còn lại → "Đang đánh giá".
  String _statusLabel(int doneCount) {
    final total = nineDomains.length;
    if (doneCount == 0) return 'Chưa đánh giá';
    if (doneCount == total) return 'Đã đánh giá';
    return 'Đang đánh giá';
  }

  bool _matchesFilter(_ChildSummary s) {
    final total = nineDomains.length;
    switch (_filter) {
      case _ProgressFilter.all:
        return true;
      case _ProgressFilter.notStarted:
        return s.doneDomainCount == 0;
      case _ProgressFilter.inProgress:
        return s.doneDomainCount > 0 && s.doneDomainCount < total;
      case _ProgressFilter.done:
        return s.doneDomainCount == total;
    }
  }

  List<_ChildSummary> _applySearchAndFilter(List<_ChildSummary> list) {
    return list
        .where((s) => _searchQuery.isEmpty || s.child.name.toLowerCase().contains(_searchQuery))
        .where(_matchesFilter)
        .toList();
  }

  Future<bool?> _confirm(String title, String content) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xác nhận')),
          ],
        ),
      );

  Future<void> _handleMenuAction(String action, Child child) async {
    switch (action) {
      case 'view':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileDetailPage(child: child)),
        );
        _reload();
      case 'history':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HistoryPage(child: child)),
        );
      case 'archive':
        final confirmed = await _confirm(
          'Lưu trữ hồ sơ',
          'Lưu trữ hồ sơ "${child.name}"? Hồ sơ sẽ ẩn khỏi danh sách "Đang quản lý", có thể khôi phục lại sau ở tab "Đã lưu trữ".',
        );
        if (confirmed == true) {
          await _childRepository.archive(child.id);
          _reload();
        }
      case 'unarchive':
        final confirmed = await _confirm(
          'Khôi phục hồ sơ',
          'Khôi phục hồ sơ "${child.name}" về danh sách "Đang quản lý"?',
        );
        if (confirmed == true) {
          await _childRepository.unarchive(child.id);
          _reload();
        }
      case 'delete':
        final confirmed = await _confirm(
          'Xoá hồ sơ',
          'Xoá vĩnh viễn hồ sơ "${child.name}"? Toàn bộ dữ liệu liên quan (sàng lọc, mô tả đánh giá, lịch sử, video, hội thoại AI) sẽ bị xoá và KHÔNG thể khôi phục.',
        );
        if (confirmed == true) {
          await _childRepository.delete(child.id);
          _reload();
        }
    }
  }

  Future<void> _openCreateProfile() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateProfilePage()),
    );
    if (created == true) _reload();
  }

  String _formatLastUpdated(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatTile(String label, int value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildTile(_ChildSummary s, String? activeChildId) {
    final child = s.child;
    final total = nineDomains.length;
    final isActive = child.id == activeChildId;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(child.name.isNotEmpty ? child.name[0] : '?')),
        title: Row(
          children: [
            Flexible(child: Text(child.name)),
            if (isActive) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 2),
              Text('Đang dùng', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.green)),
            ],
          ],
        ),
        subtitle: Text(
          '${formatAgeLabel(child)} • ${s.doneDomainCount}/$total lĩnh vực • '
          '${_statusLabel(s.doneDomainCount)}\nCập nhật gần nhất: ${_formatLastUpdated(s.lastUpdated)}',
        ),
        isThreeLine: true,
        onTap: () => _selectAsActive(child),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, child),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Xem hồ sơ')),
            const PopupMenuItem(value: 'history', child: Text('Lịch sử đánh giá')),
            if (child.status == 'active')
              const PopupMenuItem(value: 'archive', child: Text('Lưu trữ hồ sơ'))
            else
              const PopupMenuItem(value: 'unarchive', child: Text('Khôi phục hồ sơ')),
            const PopupMenuItem(value: 'delete', child: Text('Xoá hồ sơ')),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_ChildSummary> summaries, String emptyMessage, String? activeChildId) {
    final filtered = _applySearchAndFilter(summaries);
    if (filtered.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyMessage)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildChildTile(filtered[index], activeChildId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý nhiều trẻ'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Đang quản lý'), Tab(text: 'Đã lưu trữ')],
          ),
        ),
        body: FutureBuilder<List<_ChildSummary>>(
          future: _summariesFuture,
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
                      Text('Không tải được dữ liệu tổng quan: ${snapshot.error}', textAlign: TextAlign.center),
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
            final all = snapshot.data!;
            final active = all.where((s) => s.child.status == 'active').toList();
            final archived = all.where((s) => s.child.status == 'archived').toList();
            final total = active.length;
            final doneCount = active.where((s) => s.doneDomainCount == nineDomains.length).length;
            final inProgressCount = active
                .where((s) => s.doneDomainCount > 0 && s.doneDomainCount < nineDomains.length)
                .length;
            final notStartedCount = active.where((s) => s.doneDomainCount == 0).length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatTile('Tổng số trẻ', total),
                      const SizedBox(width: 8),
                      _buildStatTile('Đã đánh giá', doneCount),
                      const SizedBox(width: 8),
                      _buildStatTile('Đang đánh giá', inProgressCount),
                      const SizedBox(width: 8),
                      _buildStatTile('Chưa đánh giá', notStartedCount),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Tìm theo tên trẻ',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<_ProgressFilter>(
                        value: _filter,
                        onChanged: (value) => setState(() => _filter = value ?? _ProgressFilter.all),
                        items: const [
                          DropdownMenuItem(value: _ProgressFilter.all, child: Text('Tất cả')),
                          DropdownMenuItem(
                              value: _ProgressFilter.notStarted, child: Text('Chưa đánh giá')),
                          DropdownMenuItem(
                              value: _ProgressFilter.inProgress, child: Text('Đang đánh giá')),
                          DropdownMenuItem(value: _ProgressFilter.done, child: Text('Đã đánh giá')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<String?>(
                    future: _activeChildIdFuture,
                    builder: (context, activeSnapshot) {
                      final activeChildId = activeSnapshot.data;
                      return TabBarView(
                        children: [
                          _buildList(active, 'Chưa có hồ sơ trẻ nào đang quản lý. Bấm "+" để thêm trẻ.', activeChildId),
                          _buildList(archived, 'Chưa có hồ sơ nào được lưu trữ.', activeChildId),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreateProfile,
          tooltip: 'Thêm trẻ',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
