import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';

/// "Kinh nghiệm theo tình huống" — tab theo `boi_canh`
/// ('o_nha'/'o_truong'/'noi_cong_cong'), dùng lại đúng danh sách chunk đã
/// tải ở "Góc nhìn từ phụ huynh" (`ParentInputPage`), không truy vấn lại.
class ParentContextPage extends StatelessWidget {
  final Child child;
  final String linhVucLabel;
  final List<ExpertKnowledgeChunk> chunks;

  const ParentContextPage({
    super.key,
    required this.child,
    required this.linhVucLabel,
    required this.chunks,
  });

  static const _contexts = [
    (code: 'o_nha', label: 'Ở nhà'),
    (code: 'o_truong', label: 'Ở trường'),
    (code: 'noi_cong_cong', label: 'Nơi công cộng'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _contexts.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$linhVucLabel — Kinh nghiệm theo tình huống'),
          bottom: TabBar(
            tabs: _contexts.map((c) => Tab(text: c.label)).toList(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kinh nghiệm theo tình huống (${formatAgeLabel(child)})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng hợp góc nhìn thực tế phụ huynh chia sẻ theo từng bối cảnh khác nhau, '
                    'giúp hình dung biểu hiện của trẻ trong đời sống hằng ngày.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _contexts
                    .map(
                      (c) => _ContextList(
                        items: chunks
                            .where((chunk) => chunk.boiCanh == c.code)
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextList extends StatelessWidget {
  final List<ExpertKnowledgeChunk> items;

  const _ContextList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có chia sẻ nào cho bối cảnh này ở lĩnh vực + độ tuổi hiện tại.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final chunk = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chunk.content),
                if (chunk.nguonTaiLieu != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '— ${chunk.nguonTaiLieu}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
