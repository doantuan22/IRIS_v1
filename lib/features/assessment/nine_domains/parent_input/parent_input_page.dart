import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/expert_knowledge_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';
import 'parent_context_page.dart';

/// "Góc nhìn từ phụ huynh": đọc `expert_knowledge_chunks`
/// (content_type='chia_se_phu_huynh') đúng theo lĩnh vực + độ tuổi trẻ, tách
/// theo `nhom_tre` ('binh_thuong'/'asd') thành 2 tab quote card (nội dung +
/// trích dẫn `nguon_tai_lieu`). "Xem kinh nghiệm theo tình huống" mở
/// [ParentContextPage] dùng lại đúng danh sách đã tải, không query lại.
///
/// Tên gọi/góc nhìn trình bày nội dung tham khảo tĩnh, không phải tính năng
/// đăng bài của phụ huynh thật.
class ParentInputPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const ParentInputPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<ParentInputPage> createState() => _ParentInputPageState();
}

class _ParentInputPageState extends State<ParentInputPage> {
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
      contentType: 'chia_se_phu_huynh',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.linhVucLabel} — Góc nhìn từ phụ huynh')),
      body: FutureBuilder<List<ExpertKnowledgeChunk>>(
        future: _chunksFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được dữ liệu chia sẻ: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chunks = snapshot.data!;
          final binhThuong = chunks.where((c) => c.nhomTre == 'binh_thuong').toList();
          final asd = chunks.where((c) => c.nhomTre == 'asd').toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Góc nhìn từ phụ huynh (${formatAgeLabel(widget.child)})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Phụ huynh trẻ phát triển bình thường'),
                    Tab(text: 'Phụ huynh trẻ ASD'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _QuoteList(items: binhThuong),
                      _QuoteList(items: asd),
                    ],
                  ),
                ),
                if (chunks.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ParentContextPage(
                              child: widget.child,
                              linhVucLabel: widget.linhVucLabel,
                              chunks: chunks,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Xem kinh nghiệm theo tình huống'),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuoteList extends StatelessWidget {
  final List<ExpertKnowledgeChunk> items;

  const _QuoteList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có chia sẻ nào từ nhóm phụ huynh này cho lĩnh vực + độ tuổi hiện tại.',
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${chunk.nguonTaiLieu}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor),
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
