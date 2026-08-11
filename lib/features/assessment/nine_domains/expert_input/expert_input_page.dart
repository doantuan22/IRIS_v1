import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';
import '../summary_portrait/summary_portrait_page.dart';

/// Phần 4/5 — Thông tin từ bác sĩ (content_type = 'bac_si'): góc nhìn y
/// khoa của cùng nội dung tham khảo tĩnh.
///
/// Giai đoạn 3: chỉ khung UI placeholder — chưa đọc dữ liệu thật từ
/// `expert_knowledge_chunks` (để dành lúc ingest dữ liệu tham khảo thật).
class ExpertInputPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$linhVucLabel — Thông tin từ bác sĩ')),
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
                  builder: (_) => SummaryPortraitPage(
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
