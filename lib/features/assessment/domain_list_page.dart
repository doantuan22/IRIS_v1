import 'package:flutter/material.dart';

import '../../core/constants/domains.dart';
import '../../data/local/database.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/models/child.dart';
import 'domain_hub_page.dart';
import 'overview/overview_portrait_page.dart';

/// Icon minh hoạ cho từng lĩnh vực — chỉ phục vụ hiển thị (Material icon có
/// sẵn), không ảnh hưởng logic/schema.
const Map<String, IconData> _domainIcons = {
  'nhan_thuc': Icons.psychology_outlined,
  'cam_xuc': Icons.mood_outlined,
  'giac_quan': Icons.visibility_outlined,
  'quan_he_xa_hoi': Icons.groups_outlined,
  'ngon_ngu': Icons.record_voice_over_outlined,
  'sinh_hoc': Icons.favorite_outline,
  'sinh_hoat_ca_nhan': Icons.self_improvement_outlined,
};

/// Bước 5 — Danh sách 7 lĩnh vực đánh giá. Mỗi item hiện trạng thái đơn
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
      appBar: AppBar(title: Text('Đánh giá 7 lĩnh vực — ${widget.child.name}')),
      body: FutureBuilder<Set<String>>(
        future: _domainsWithDescriptionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final domainsWithDescription = snapshot.data!;
          final doneCount = domainsWithDescription.length;
          final total = domains.length;
          // Bước 8 — gợi ý lĩnh vực nên làm tiếp theo. Kiến trúc hiện tại
          // chỉ theo dõi 1 trạng thái nhị phân mỗi lĩnh vực (đã có mô tả
          // Phần 1 hay chưa — dùng chung với badge "Đã có mô tả"/"Chưa có
          // mô tả" trên từng thẻ), không có khái niệm "đang dở" tách biệt.
          // Vì vậy gợi ý = lĩnh vực CHƯA có mô tả đầu tiên theo đúng thứ tự
          // 7 lĩnh vực — logic đơn giản nhất khớp đúng dữ liệu đang có.
          Domain? nextDomain;
          for (final domain in domains) {
            if (!domainsWithDescription.contains(domain.code)) {
              nextDomain = domain;
              break;
            }
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiến độ: $doneCount/$total lĩnh vực'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: total == 0 ? 0 : doneCount / total),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nextDomain != null)
                      _NextDomainCard(
                        child: widget.child,
                        domain: nextDomain,
                        onContinue: _reload,
                      )
                    else ...[
                      Row(
                        children: [
                          const Icon(Icons.celebration_outlined, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Bạn đã hoàn thành đánh giá cả 7 lĩnh vực!')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OverviewPortraitPage(child: widget.child)),
                        ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Xem Chân dung toàn cảnh'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Bạn không cần hoàn thành tất cả 7 lĩnh vực trong cùng một phiên. '
                      'Hãy đánh giá theo nhịp độ phù hợp của bạn và bé.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: domains.length,
                  itemBuilder: (context, index) {
                    final domain = domains[index];
                    final hasDescription = domainsWithDescription.contains(domain.code);
                    return Card(
                      child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DomainHubPage(
                                child: widget.child,
                                linhVuc: domain.code,
                                linhVucLabel: domain.label,
                              ),
                            ),
                          );
                          _reload();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _domainIcons[domain.code] ?? Icons.circle_outlined,
                                size: 36,
                                color: hasDescription ? Colors.green : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                domain.label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasDescription ? 'Đã có mô tả' : 'Chưa có mô tả',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bước 8 — card gợi ý lĩnh vực nên làm tiếp theo, tách thành widget riêng
/// (thay vì viết trực tiếp trong `build()`) để [domain] là non-nullable, nhờ
/// đó `onPressed` không cần `nextDomain!` (biến local ngoài closure không
/// được promote non-null bên trong closure `async`).
class _NextDomainCard extends StatelessWidget {
  final Child child;
  final Domain domain;
  final VoidCallback onContinue;

  const _NextDomainCard({required this.child, required this.domain, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gợi ý: tiếp tục lĩnh vực "${domain.label}"',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DomainHubPage(
                        child: child,
                        linhVuc: domain.code,
                        linhVucLabel: domain.label,
                      ),
                    ),
                  );
                  onContinue();
                },
                child: const Text('Tiếp tục ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
