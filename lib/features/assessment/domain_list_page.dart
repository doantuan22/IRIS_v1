import 'package:flutter/material.dart';

import '../../core/constants/domains.dart';
import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
import '../../data/local/database.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/models/child.dart';
import 'domain_hub_page.dart';
import 'overview/overview_portrait_page.dart';

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
    return all
        .where((a) => a.contentType == 'mo_ta')
        .map((a) => a.linhVuc)
        .toSet();
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
                padding: const EdgeInsets.fromLTRB(
                  IrisSpacing.md,
                  IrisSpacing.md,
                  IrisSpacing.md,
                  IrisSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiến độ: $doneCount/$total lĩnh vực'),
                    const SizedBox(height: IrisSpacing.xs),
                    LinearProgressIndicator(
                      value: total == 0 ? 0 : doneCount / total,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  IrisSpacing.md,
                  0,
                  IrisSpacing.md,
                  IrisSpacing.xs,
                ),
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
                          const Icon(
                            Icons.celebration_rounded,
                            color: IrisColors.success,
                          ),
                          const SizedBox(width: IrisSpacing.xs),
                          const Expanded(
                            child: Text(
                              'Bạn đã hoàn thành đánh giá cả 7 lĩnh vực!',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OverviewPortraitPage(child: widget.child),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Xem Chân dung toàn cảnh'),
                      ),
                    ],
                    const SizedBox(height: IrisSpacing.xs),
                    Text(
                      'Bạn không cần hoàn thành tất cả 7 lĩnh vực trong cùng một phiên. '
                      'Hãy đánh giá theo nhịp độ phù hợp của bạn và bé.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: IrisSpacing.page,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: IrisSpacing.sm,
                    crossAxisSpacing: IrisSpacing.sm,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: domains.length,
                  itemBuilder: (context, index) {
                    final domain = domains[index];
                    final hasDescription = domainsWithDescription.contains(
                      domain.code,
                    );
                    final accent = IrisDomainStyle.colorOf(domain.code);
                    return Card(
                      color: IrisDomainStyle.softColorOf(domain.code),
                      child: InkWell(
                        borderRadius: IrisRadii.cardBorder,
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
                          padding: const EdgeInsets.all(IrisSpacing.sm),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IrisDomainIcon(
                                domainCode: domain.code,
                                completed: hasDescription,
                              ),
                              const SizedBox(height: IrisSpacing.xs),
                              Text(
                                domain.label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: IrisSpacing.xxs),
                              IrisStatusBadge(
                                label: hasDescription
                                    ? 'Đã có mô tả'
                                    : 'Chưa có mô tả',
                                color: hasDescription
                                    ? IrisColors.success
                                    : accent,
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

  const _NextDomainCard({
    required this.child,
    required this.domain,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: IrisSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IrisIconChip(
                  icon: Icons.lightbulb_rounded,
                  color: IrisDomainStyle.colorOf(domain.code),
                ),
                const SizedBox(width: IrisSpacing.sm),
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
