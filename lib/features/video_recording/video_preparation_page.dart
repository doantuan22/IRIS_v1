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

/// Bước 1/3 — Màn tips tĩnh chuẩn bị trước khi quay video quan sát trẻ.
class VideoPreparationPage extends StatelessWidget {
  final Child child;

  const VideoPreparationPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuẩn bị quay video')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lưu ý quan trọng khi quay video cho bé ${child.name}:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _tips
                    .map(
                      (tip) => ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.teal),
                        title: Text(tip),
                      ),
                    )
                    .toList(),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => VideoRecordingCapturePage(child: child),
                ),
              ),
              icon: const Icon(Icons.videocam),
              label: const Text('Bắt đầu quay'),
            ),
          ],
        ),
      ),
    );
  }
}
