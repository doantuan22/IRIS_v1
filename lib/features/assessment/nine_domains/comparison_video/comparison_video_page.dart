import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/expert_knowledge_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';
import '../parent_input/parent_input_page.dart';
import '../part_step_indicator.dart';
import 'comparison_detail_page.dart';

/// Phần 2/5 — "So sánh nhanh": đọc `expert_knowledge_chunks`
/// (content_type='so_sanh') đúng theo lĩnh vực + độ tuổi trẻ (qua
/// `childAgeInMonths()`), tách thành 2 khối theo `phan_loai`
/// ('thuong_gap'/'can_quan_sat'). "Xem chi tiết so sánh" mở
/// [ComparisonDetailPage] dùng lại đúng danh sách đã tải, không query lại.
class ComparisonVideoPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const ComparisonVideoPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<ComparisonVideoPage> createState() => _ComparisonVideoPageState();
}

class _ComparisonVideoPageState extends State<ComparisonVideoPage> {
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
      contentType: 'so_sanh',
    );
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ParentInputPage(
          child: widget.child,
          linhVuc: widget.linhVuc,
          linhVucLabel: widget.linhVucLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.linhVucLabel} — So sánh nhanh')),
      body: FutureBuilder<List<ExpertKnowledgeChunk>>(
        future: _chunksFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được dữ liệu so sánh: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chunks = snapshot.data!;
          final thuongGap = chunks.where((c) => c.phanLoai == 'thuong_gap').toList();
          final canQuanSat = chunks.where((c) => c.phanLoai == 'can_quan_sat').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PartStepIndicator(step: 2),
              Text(
                'So sánh nhanh (${formatAgeLabel(widget.child)})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (chunks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Chưa có dữ liệu so sánh cho lĩnh vực này ở độ tuổi hiện tại.',
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                _ComparisonSection(
                  title: 'Biểu hiện thường gặp',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  items: thuongGap,
                ),
                const SizedBox(height: 20),
                _ComparisonSection(
                  title: 'Cần quan sát thêm',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  items: canQuanSat,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ComparisonDetailPage(
                          child: widget.child,
                          linhVucLabel: widget.linhVucLabel,
                          chunks: chunks,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Xem chi tiết so sánh'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Thông tin này chỉ mang tính tham khảo.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor),
              ),
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

class _ComparisonSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<ExpertKnowledgeChunk> items;

  const _ComparisonSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(c.content)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
