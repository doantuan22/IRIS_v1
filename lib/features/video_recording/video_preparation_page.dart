import 'package:flutter/material.dart';

import '../../domain/models/child.dart';
import 'video_recording_capture_page.dart';

const List<String> _tips = [
  'Chọn môi trường yên tĩnh, hạn chế tiếng ồn xung quanh.',
  'Đảm bảo ánh sáng tốt, tránh ngược sáng.',
  'Giữ góc quay rõ mặt trẻ trong suốt video.',
  'Thời lượng lý tưởng: 1–3 phút.',
  'Giữ máy ổn định, hạn chế rung lắc khi quay.',
];

/// Bước 2/4 — Màn tips tĩnh trước khi quay.
class VideoPreparationPage extends StatelessWidget {
  final Child child;
  final String situation;

  const VideoPreparationPage({super.key, required this.child, required this.situation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuẩn bị quay')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tình huống: $situation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _tips
                    .map(
                      (tip) => ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(tip),
                      ),
                    )
                    .toList(),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => VideoRecordingCapturePage(child: child, situation: situation),
                ),
              ),
              child: const Text('Bắt đầu quay'),
            ),
          ],
        ),
      ),
    );
  }
}
