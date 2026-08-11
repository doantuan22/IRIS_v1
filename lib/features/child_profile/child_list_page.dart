import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/child_repository.dart';
import '../../domain/models/child.dart';
import '../multi_child_dashboard/multi_child_dashboard_page.dart';
import 'create_profile/create_profile_page.dart';
import 'profile_detail/profile_detail_page.dart';

/// Danh sách hồ sơ trẻ (Bước 1) — điểm vào chính của app: chọn 1 hồ sơ có
/// sẵn hoặc tạo hồ sơ mới.
class ChildListPage extends StatefulWidget {
  const ChildListPage({super.key});

  @override
  State<ChildListPage> createState() => _ChildListPageState();
}

class _ChildListPageState extends State<ChildListPage> {
  final _childRepository = ChildRepository(AppDatabase.instance);
  late Future<List<Child>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _childrenFuture = _childRepository.getAll();
    });
  }

  Future<void> _openCreateProfile() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateProfilePage()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ trẻ'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MultiChildDashboardPage()),
              );
              _reload();
            },
            tooltip: 'Quản lý nhiều trẻ',
            icon: const Icon(Icons.dashboard_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Child>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text('Không tải được danh sách hồ sơ: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }
          final children = snapshot.data ?? [];
          if (children.isEmpty) {
            return const Center(
              child: Text('Chưa có hồ sơ trẻ nào. Bấm "+" để tạo hồ sơ mới.'),
            );
          }
          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return ListTile(
                leading: CircleAvatar(child: Text(child.name.isNotEmpty ? child.name[0] : '?')),
                title: Text(child.name),
                subtitle: Text('${formatAgeLabel(child)} • ${child.gender ?? "chưa rõ giới tính"}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProfileDetailPage(child: child)),
                  );
                  _reload();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateProfile,
        tooltip: 'Tạo hồ sơ mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}
