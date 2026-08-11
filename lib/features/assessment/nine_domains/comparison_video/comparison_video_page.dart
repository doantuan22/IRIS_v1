import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';
import '../parent_input/parent_input_page.dart';

/// Phần 2/5 — So sánh với trẻ cùng tuổi + video mẫu tham khảo
/// (content_type = 'so_sanh', nội dung tĩnh biên soạn sẵn).
///
/// Giai đoạn 3: chỉ khung UI placeholder — chưa đọc dữ liệu thật từ
/// `expert_knowledge_chunks` (để dành lúc ingest dữ liệu tham khảo thật).
class ComparisonVideoPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$linhVucLabel — So sánh với trẻ cùng tuổi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: Center(child: Text('Nội dung tham khảo đang được cập nhật')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ParentInputPage(
                    child: child,
                    linhVuc: linhVuc,
                    linhVucLabel: linhVucLabel,
                  ),
                ),
              ),
              child: const Text('Tiếp theo'),
            ),
          ],
        ),
      ),
    );
  }
}
