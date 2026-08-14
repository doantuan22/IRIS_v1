import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/expert_knowledge_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';
import '../part_step_indicator.dart';
import '../summary_portrait/summary_portrait_page.dart';
import 'expert_detail_page.dart';

/// Phần 4/5 — "Thông tin từ bác sĩ": đọc `expert_knowledge_chunks`
/// (content_type='bac_si') đúng theo lĩnh vực + độ tuổi trẻ. Card đầu trang
/// chỉ minh hoạ VAI TRÒ chuyên môn (không gắn danh tính bác sĩ thật). 3 mục
/// điều hướng mở [ExpertDetailPage] dùng lại đúng danh sách đã tải, cuộn
/// thẳng tới đúng nhóm `phan_loai` tương ứng.
class ExpertInputPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const ExpertInputPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<ExpertInputPage> createState() => _ExpertInputPageState();
}

class _ExpertInputPageState extends State<ExpertInputPage> {
  final _expertKnowledgeRepository = ExpertKnowledgeRepository(AppDatabase.instance);
  late Future<List<ExpertKnowledgeChunk>> _chunksFuture;

  @override
  void initState() {
    super.initState();
    _chunksFuture = _load();
  }

  Future<List<ExpertKnowledgeChunk>> _load() {
    return _expertKnowledgeRepository.query(
      linhVuc: widget.linhVuc,
      ageInMonths: childAgeInMonths(widget.child),
      contentType: 'bac_si',
    );
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SummaryPortraitPage(
          child: widget.child,
          linhVuc: widget.linhVuc,
          linhVucLabel: widget.linhVucLabel,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, List<ExpertKnowledgeChunk> chunks, String section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpertDetailPage(
          child: widget.child,
          linhVucLabel: widget.linhVucLabel,
          chunks: chunks,
          initialSection: section,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.linhVucLabel} — Thông tin từ bác sĩ')),
      body: FutureBuilder<List<ExpertKnowledgeChunk>>(
        future: _chunksFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được dữ liệu từ bác sĩ: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chunks = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PartStepIndicator(step: 4),
              Text(
                'Thông tin từ bác sĩ (${formatAgeLabel(widget.child)})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Góc nhìn chuyên khoa Tâm thần Nhi (minh hoạ)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nội dung dưới đây trình bày theo góc nhìn chuyên môn y khoa mang tính minh hoạ '
                              'cho bản demo, không phải ý kiến trực tiếp từ một bác sĩ cụ thể.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (chunks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Chưa có dữ liệu từ bác sĩ cho lĩnh vực này ở độ tuổi hiện tại.',
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                _NavTile(
                  icon: Icons.timeline_outlined,
                  title: 'Mốc phát triển',
                  subtitle: 'Biểu hiện thường gặp theo mốc phát triển của độ tuổi',
                  onTap: () => _openDetail(context, chunks, 'moc_phat_trien'),
                ),
                _NavTile(
                  icon: Icons.flag_outlined,
                  title: 'Dấu hiệu cần lưu ý',
                  subtitle: 'Những điểm nên tiếp tục quan sát hoặc trao đổi thêm',
                  onTap: () => _openDetail(context, chunks, 'dau_hieu_luu_y'),
                ),
                _NavTile(
                  icon: Icons.info_outline,
                  title: 'Giải thích chuyên môn',
                  subtitle: 'Diễn giải thêm giúp hiểu đúng bối cảnh',
                  onTap: () => _openDetail(context, chunks, 'giai_thich'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _goNext,
                child: const Text('Tiếp theo'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
