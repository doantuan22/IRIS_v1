import 'package:flutter/material.dart';

import '../../core/constants/nine_domains.dart';
import '../../data/local/database.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/models/child.dart';
import 'nine_domains/description/description_page.dart';

/// Bước 5 — Danh sách 9 lĩnh vực đánh giá. Mỗi item hiện trạng thái đơn
/// giản dựa trên việc đã có bản ghi `assessments` (content_type='mo_ta')
/// cho lĩnh vực đó hay chưa.
class DomainListPage extends StatefulWidget {
  final Child child;

  const DomainListPage({super.key, required this.child});

  @override
  State<DomainListPage> createState() => _DomainListPageState();
}

class _DomainListPageState extends State<DomainListPage> {
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  late Future<Set<String>> _domainsWithDescriptionFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _domainsWithDescriptionFuture = _loadDomainsWithDescription();
    });
  }

  Future<Set<String>> _loadDomainsWithDescription() async {
    final all = await _assessmentRepository.getForChild(widget.child.id);
    return all.where((a) => a.contentType == 'mo_ta').map((a) => a.linhVuc).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đánh giá 9 lĩnh vực — ${widget.child.name}')),
      body: FutureBuilder<Set<String>>(
        future: _domainsWithDescriptionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final domainsWithDescription = snapshot.data!;
          return ListView.builder(
            itemCount: nineDomains.length,
            itemBuilder: (context, index) {
              final domain = nineDomains[index];
              final hasDescription = domainsWithDescription.contains(domain.code);
              return ListTile(
                title: Text(domain.label),
                subtitle: Text(hasDescription ? 'Đã có mô tả' : 'Chưa có mô tả'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DescriptionPage(
                        child: widget.child,
                        linhVuc: domain.code,
                        linhVucLabel: domain.label,
                      ),
                    ),
                  );
                  _reload();
                },
              );
            },
          );
        },
      ),
    );
  }
}
