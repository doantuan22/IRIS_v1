import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';

/// Bảng chi tiết so sánh (3 cột: Tiêu chí | Thường gặp | Cần quan sát) — dùng
/// lại đúng danh sách chunk đã tải ở "So sánh nhanh" (`ComparisonVideoPage`),
/// không truy vấn lại database.
class ComparisonDetailPage extends StatelessWidget {
  final Child child;
  final String linhVucLabel;
  final List<ExpertKnowledgeChunk> chunks;

  const ComparisonDetailPage({
    super.key,
    required this.child,
    required this.linhVucLabel,
    required this.chunks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$linhVucLabel — Chi tiết so sánh')),
      body: chunks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có dữ liệu so sánh cho lĩnh vực này ở độ tuổi hiện tại.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'So sánh chi tiết (${formatAgeLabel(child)})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(color: Theme.of(context).dividerColor),
                    columnWidths: const {
                      0: FixedColumnWidth(280),
                      1: FixedColumnWidth(96),
                      2: FixedColumnWidth(96),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        children: [
                          _HeaderCell('Tiêu chí'),
                          _HeaderCell('Thường gặp'),
                          _HeaderCell('Cần quan sát'),
                        ],
                      ),
                      ...chunks.map(
                        (c) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(c.content),
                            ),
                            _MarkCell(checked: c.phanLoai == 'thuong_gap'),
                            _MarkCell(checked: c.phanLoai == 'can_quan_sat'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Thông tin này chỉ giúp đối chiếu với trẻ cùng độ tuổi, không dùng để tự chẩn đoán.',
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _MarkCell extends StatelessWidget {
  final bool checked;

  const _MarkCell({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: checked ? const Icon(Icons.check, color: Colors.green) : const SizedBox.shrink(),
      ),
    );
  }
}
