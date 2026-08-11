import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';
import '../expert_input/expert_input_page.dart';

/// Phần 3/5 — Chia sẻ từ phụ huynh (content_type = 'chia_se_phu_huynh'):
/// tên gọi/góc nhìn trình bày nội dung tham khảo tĩnh, không phải tính năng
/// đăng bài của phụ huynh thật.
///
/// Giai đoạn 3: chỉ khung UI placeholder — chưa đọc dữ liệu thật từ
/// `expert_knowledge_chunks` (để dành lúc ingest dữ liệu tham khảo thật).
class ParentInputPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$linhVucLabel — Chia sẻ từ phụ huynh')),
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
                  builder: (_) => ExpertInputPage(
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
