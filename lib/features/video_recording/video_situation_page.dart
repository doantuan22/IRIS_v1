import 'package:flutter/material.dart';

import '../../domain/models/child.dart';
import 'video_preparation_page.dart';

/// Bước 1/4 — Chọn tình huống quan sát trẻ. Danh sách gợi ý + tuỳ chọn tự
/// nhập tình huống khác.
const List<String> _suggestedSituations = [
  'Trẻ chơi cùng người khác',
  'Phản ứng khi được gọi tên',
  'Thực hiện yêu cầu đơn giản',
  'Chia sẻ đồ chơi',
  'Giúp đỡ người khác',
  'Tự chăm sóc bản thân',
];

class VideoSituationPage extends StatefulWidget {
  final Child child;

  const VideoSituationPage({super.key, required this.child});

  @override
  State<VideoSituationPage> createState() => _VideoSituationPageState();
}

class _VideoSituationPageState extends State<VideoSituationPage> {
  final _customSituationController = TextEditingController();

  @override
  void dispose() {
    _customSituationController.dispose();
    super.dispose();
  }

  void _selectSituation(String situation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPreparationPage(child: widget.child, situation: situation),
      ),
    );
  }

  void _selectCustomSituation() {
    final text = _customSituationController.text.trim();
    if (text.isEmpty) return;
    _selectSituation(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quay video — ${widget.child.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Chọn tình huống muốn quan sát', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._suggestedSituations.map(
            (situation) => Card(
              child: ListTile(
                title: Text(situation),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectSituation(situation),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hoặc tự nhập tình huống khác', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _customSituationController,
            decoration: const InputDecoration(
              labelText: 'Tình huống khác',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _selectCustomSituation,
            child: const Text('Dùng tình huống này'),
          ),
        ],
      ),
    );
  }
}
