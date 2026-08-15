import 'package:flutter/material.dart';

import '../../../../core/theme/iris_theme.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';

/// "Giải thích chuyên môn" — hiện đủ 3 nhóm `phan_loai` của
/// `content_type='bac_si'` (Mốc phát triển / Dấu hiệu cần lưu ý / Giải
/// thích chuyên môn), dùng lại đúng danh sách chunk đã tải ở "Thông tin từ
/// bác sĩ" (`ExpertInputPage`), không truy vấn lại. [initialSection] (nếu
/// có) khớp giá trị `phan_loai` — trang tự cuộn tới đúng nhóm sau khi build
/// xong, phục vụ 3 mục điều hướng ở màn tổng quan.
class ExpertDetailPage extends StatefulWidget {
  final Child child;
  final String linhVucLabel;
  final List<ExpertKnowledgeChunk> chunks;
  final String? initialSection;

  const ExpertDetailPage({
    super.key,
    required this.child,
    required this.linhVucLabel,
    required this.chunks,
    this.initialSection,
  });

  @override
  State<ExpertDetailPage> createState() => _ExpertDetailPageState();
}

class _ExpertDetailPageState extends State<ExpertDetailPage> {
  final _mocPhatTrienKey = GlobalKey();
  final _dauHieuLuuYKey = GlobalKey();
  final _giaiThichKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final section = widget.initialSection;
    if (section != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSection(section),
      );
    }
  }

  void _scrollToSection(String section) {
    final key = switch (section) {
      'moc_phat_trien' => _mocPhatTrienKey,
      'dau_hieu_luu_y' => _dauHieuLuuYKey,
      'giai_thich' => _giaiThichKey,
      _ => null,
    };
    final sectionContext = key?.currentContext;
    if (sectionContext != null) {
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chunks = widget.chunks;
    final mocPhatTrien = chunks
        .where((c) => c.phanLoai == 'moc_phat_trien')
        .toList();
    final dauHieuLuuY = chunks
        .where((c) => c.phanLoai == 'dau_hieu_luu_y')
        .toList();
    final giaiThich = chunks.where((c) => c.phanLoai == 'giai_thich').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.linhVucLabel} — Giải thích chuyên môn'),
      ),
      body: chunks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có dữ liệu từ bác sĩ cho lĩnh vực này ở độ tuổi hiện tại.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Giải thích chuyên môn (${formatAgeLabel(widget.child)})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (mocPhatTrien.isNotEmpty) ...[
                  _ExpertSection(
                    key: _mocPhatTrienKey,
                    title: 'Mốc phát triển',
                    items: mocPhatTrien,
                  ),
                  const SizedBox(height: 20),
                ],
                if (dauHieuLuuY.isNotEmpty) ...[
                  _ExpertSection(
                    key: _dauHieuLuuYKey,
                    title: 'Dấu hiệu cần lưu ý',
                    items: dauHieuLuuY,
                  ),
                  const SizedBox(height: 20),
                ],
                if (giaiThich.isNotEmpty) ...[
                  _ExpertSection(
                    key: _giaiThichKey,
                    title: 'Giải thích chuyên môn',
                    items: giaiThich,
                  ),
                  const SizedBox(height: 20),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: IrisRadii.inputBorder,
                  ),
                  child: const Text(
                    'Thông tin mang tính tham khảo, không thay thế khám và đánh giá chuyên sâu.',
                  ),
                ),
              ],
            ),
    );
  }
}

class _ExpertSection extends StatelessWidget {
  final String title;
  final List<ExpertKnowledgeChunk> items;

  const _ExpertSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map(
          (c) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.content),
                  if (c.nguonTaiLieu != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '— ${c.nguonTaiLieu}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
