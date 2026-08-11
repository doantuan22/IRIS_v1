import 'package:flutter/material.dart';

import '../../../../domain/models/child.dart';

/// Phần 5/5 — Chân dung biểu hiện (content_type = 'chan_dung'): tổng hợp
/// nội dung tham khảo tĩnh cho lĩnh vực này.
///
/// Giai đoạn 3: chỉ khung UI placeholder — chưa đọc dữ liệu thật từ
/// `expert_knowledge_chunks` (để dành lúc ingest dữ liệu tham khảo thật).
/// Nút cuối khép lại luồng, quay về danh sách 9 lĩnh vực — vì các bước 2-5
/// đều dùng `pushReplacement` nối tiếp nhau, ngăn xếp hiện tại chỉ có đúng
/// 1 route (trang này) nằm trên DomainListPage, nên 1 lần `pop()` là đủ.
class SummaryPortraitPage extends StatelessWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const SummaryPortraitPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$linhVucLabel — Chân dung biểu hiện')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: Center(child: Text('Nội dung tham khảo đang được cập nhật')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hoàn tất — Về danh sách lĩnh vực'),
            ),
          ],
        ),
      ),
    );
  }
}
