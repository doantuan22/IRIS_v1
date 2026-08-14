import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/services/active_child_service.dart';
import '../ai_chat/ai_chat_page.dart';
import '../assessment/domain_list_page.dart';
import '../child_profile/create_profile/create_profile_page.dart';
import '../expert_connect/expert_connect_page.dart';
import '../history/history_page.dart';
import '../multi_child_dashboard/multi_child_dashboard_page.dart';
import '../screening/screening_intro_page.dart';
import '../video_recording/video_situation_page.dart';

/// Trang chủ — điểm vào chính của app, xoay quanh khái niệm "1 hồ sơ trẻ
/// đang hoạt động" (active child, lưu bền vững qua `ActiveChildService`).
/// 4 tab dưới cùng: Trang chủ/Hỏi đáp/Thông báo/Tài khoản — tất cả đều thao
/// tác trực tiếp trên hồ sơ đang hoạt động, không cần chọn lại mỗi lần.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _activeChildService = ActiveChildService();
  final _childRepository = ChildRepository(AppDatabase.instance);

  int _tabIndex = 0;
  late Future<Child?> _activeChildFuture;

  /// Chặn `addPostFrameCallback` gọi lặp `push` nhiều lần trong lúc route đó
  /// đang mở (mỗi lần `build()` chạy lại khi chưa có active child đều muốn
  /// điều hướng, nhưng chỉ được đẩy route 1 lần).
  bool _redirectingNoActiveChild = false;

  @override
  void initState() {
    super.initState();
    _reloadActiveChild();
  }

  void _reloadActiveChild() {
    setState(() {
      _activeChildFuture = _loadActiveChild();
    });
  }

  Future<Child?> _loadActiveChild() async {
    final id = await _activeChildService.getActiveChildId();
    if (id == null) return null;
    final child = await _childRepository.getById(id);
    if (child == null) {
      // active_child_id cũ trỏ tới hồ sơ đã bị xoá — dọn lại để lần sau
      // không phải tra cứu lại vô ích.
      await _activeChildService.clearActiveChildId();
      return null;
    }
    return child;
  }

  /// Chưa có active child — có thể vì app thật sự chưa có hồ sơ nào, hoặc vì
  /// `active_child_id` bị mất/trỏ tới hồ sơ đã xoá trong khi vẫn còn hồ sơ
  /// khác (VD dữ liệu `shared_preferences` chưa kịp ghi xuống đĩa nếu app bị
  /// tắt đột ngột — phát hiện được khi verify tay đợt này). Phân biệt 2
  /// trường hợp bằng cách kiểm tra còn hồ sơ nào trong DB không: còn thì đưa
  /// qua màn chọn hồ sơ (`MultiChildDashboardPage`) thay vì bắt tạo hồ sơ
  /// mới không cần thiết; không còn hồ sơ nào mới thật sự điều hướng vào tạo
  /// hồ sơ.
  Future<void> _redirectWhenNoActiveChild() async {
    if (_redirectingNoActiveChild) return;
    _redirectingNoActiveChild = true;
    final existing = await _childRepository.getAll();
    if (!mounted) return;
    final destination = existing.isEmpty
        ? const CreateProfilePage()
        : const MultiChildDashboardPage();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
    _redirectingNoActiveChild = false;
    _reloadActiveChild();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Child?>(
      future: _activeChildFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final activeChild = snapshot.data;
        if (activeChild == null) {
          // Chưa có active child — điều hướng thẳng vào tạo hồ sơ (nếu thật
          // sự chưa có hồ sơ nào) hoặc màn chọn hồ sơ (nếu còn hồ sơ khác),
          // thay vì hiện Trang chủ rỗng. Xem `_redirectWhenNoActiveChild()`.
          WidgetsBinding.instance.addPostFrameCallback((_) => _redirectWhenNoActiveChild());
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final tabs = [
          _HomeTabContent(child: activeChild),
          AiChatPage(child: activeChild),
          const _NotificationsPlaceholderTab(),
          _AccountTab(child: activeChild, onChanged: _reloadActiveChild),
        ];

        return Scaffold(
          body: IndexedStack(index: _tabIndex, children: tabs),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => setState(() => _tabIndex = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Hỏi đáp'),
              NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Thông báo'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tài khoản'),
            ],
          ),
        );
      },
    );
  }
}

/// Tab "Trang chủ" — thông tin trẻ đang hoạt động + lối vào nhanh các chức
/// năng chính. Nút "Sàng lọc" chỉ hiện khi CHƯA sàng lọc (ẩn hẳn, không hiện
/// dạng mờ, sau khi sàng lọc xong).
class _HomeTabContent extends StatefulWidget {
  final Child child;

  const _HomeTabContent({required this.child});

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  late Future<bool> _hasScreeningFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _HomeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget được dựng lại với `child` mới mỗi khi active child đổi (qua
    // `HomePage._reloadActiveChild()`) — luôn tải lại trạng thái sàng lọc
    // theo đúng hồ sơ hiện tại, tránh hiện nhầm dữ liệu của hồ sơ cũ.
    _reload();
  }

  void _reload() {
    setState(() {
      _hasScreeningFuture = _screeningRepository.hasScreening(widget.child.id);
    });
  }

  Future<void> _openScreening() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScreeningIntroPage(child: widget.child)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Scaffold(
      appBar: AppBar(title: const Text('IRIS')),
      body: FutureBuilder<bool>(
        future: _hasScreeningFuture,
        builder: (context, snapshot) {
          final hasScreening = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(formatAgeLabel(child)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (hasScreening == false) ...[
                FilledButton.icon(
                  onPressed: _openScreening,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Sàng lọc'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DomainListPage(child: child)),
                ),
                icon: const Icon(Icons.checklist_outlined),
                label: const Text('Đánh giá 9 lĩnh vực'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VideoSituationPage(child: child)),
                ),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Quay video tình huống'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HistoryPage(child: child)),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Lịch sử'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ExpertConnectPage(child: child)),
                ),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Kết nối chuyên gia/trung tâm'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationsPlaceholderTab extends StatelessWidget {
  const _NotificationsPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: const Center(child: Text('Chưa có nội dung')),
    );
  }
}

/// Tab "Tài khoản" — thông tin hồ sơ đang hoạt động + 3 hành động quản lý:
/// đổi hồ sơ (tái dùng `MultiChildDashboardPage` làm màn chọn), tạo hồ sơ
/// mới, xoá hồ sơ đang hoạt động.
class _AccountTab extends StatelessWidget {
  final Child child;
  final VoidCallback onChanged;

  const _AccountTab({required this.child, required this.onChanged});

  Future<void> _changeAccount(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MultiChildDashboardPage()),
    );
    onChanged();
  }

  Future<void> _createProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateProfilePage()),
    );
    onChanged();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá tài khoản'),
        content: Text(
          'Thao tác này sẽ xoá hồ sơ trẻ đang chọn: ${child.name}. '
          'Toàn bộ dữ liệu sàng lọc, đánh giá, video sẽ bị xoá vĩnh viễn.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed != true) return;

    final childRepository = ChildRepository(AppDatabase.instance);
    await childRepository.delete(child.id);

    final remaining = await childRepository.getAll();
    if (!context.mounted) return;
    if (remaining.isNotEmpty) {
      // Còn hồ sơ khác — điều hướng qua màn chọn hồ sơ để người dùng tự
      // chọn hồ sơ tiếp theo làm active (không tự ý chọn thay).
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MultiChildDashboardPage()),
      );
    } else {
      await ActiveChildService().clearActiveChildId();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateProfilePage()),
      );
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${formatAgeLabel(child)} • ${child.gender ?? "chưa rõ giới tính"}'),
                  const SizedBox(height: 4),
                  Text('Người đánh giá: ${child.nguoiDanhGia ?? "Chưa cập nhật"}'),
                  const SizedBox(height: 4),
                  Text('Vai trò: ${child.vaiTro ?? "Chưa cập nhật"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _changeAccount(context),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Đổi tài khoản'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _createProfile(context),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Tạo hồ sơ trẻ mới'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _deleteAccount(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xoá tài khoản'),
          ),
        ],
      ),
    );
  }
}
