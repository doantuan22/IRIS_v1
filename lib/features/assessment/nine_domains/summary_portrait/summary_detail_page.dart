import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';

/// "Chân dung biểu hiện" chi tiết — lưới thẻ màu phân loại
/// (diem_manh/khac_biet/can_ho_tro), dùng lại đúng danh sách chunk đã tải ở
/// màn tổng quan (`SummaryPortraitPage`), không truy vấn lại.
///
/// Đơn giản hoá CHỦ ĐỘNG từ bố cục mindmap toả tròn gốc thành lưới thẻ —
/// giữ nguyên thông tin + ý nghĩa phân loại (màu viền/nhãn theo nhóm), khác
/// biệt ở cách trình bày trực quan.
class SummaryDetailPage extends StatelessWidget {
  final Child child;
  final String linhVucLabel;
  final List<ExpertKnowledgeChunk> chunks;

  const SummaryDetailPage({
    super.key,
    required this.child,
    required this.linhVucLabel,
    required this.chunks,
  });

  static const _diemManhColor = Colors.green;
  static const _khacBietColor = Colors.orange;
  static const _canHoTroColor = Colors.blue;

  static const _labels = {
    'diem_manh': 'Điểm mạnh',
    'khac_biet': 'Khác biệt',
    'can_ho_tro': 'Cần hỗ trợ',
  };

  Color _colorFor(String? phanLoai) => switch (phanLoai) {
        'diem_manh' => _diemManhColor,
        'khac_biet' => _khacBietColor,
        'can_ho_tro' => _canHoTroColor,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final cardItems = chunks.where((c) => _labels.containsKey(c.phanLoai)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('$linhVucLabel — Chân dung biểu hiện')),
      body: cardItems.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có dữ liệu chân dung cho lĩnh vực này ở độ tuổi hiện tại.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Chân dung biểu hiện (${formatAgeLabel(child)})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng hợp từ nhiều nguồn thông tin, giúp hình dung rõ hơn đặc điểm phát triển '
                  'của bé trong bối cảnh cụ thể.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: cardItems.length,
                  itemBuilder: (context, index) {
                    final chunk = cardItems[index];
                    final color = _colorFor(chunk.phanLoai);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: color.withValues(alpha: 0.06),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _labels[chunk.phanLoai] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              chunk.content,
                              overflow: TextOverflow.fade,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Chú thích màu', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _LegendRow(color: _diemManhColor, label: 'Xanh lá — Điểm mạnh của bé'),
                      SizedBox(height: 4),
                      _LegendRow(color: _khacBietColor, label: 'Cam — Khác biệt so với trẻ cùng tuổi'),
                      SizedBox(height: 4),
                      _LegendRow(color: _canHoTroColor, label: 'Xanh dương — Điểm cần hỗ trợ thêm'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}
