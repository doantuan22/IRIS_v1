import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/video.dart';
import 'video_detail_page.dart';
import 'video_situation_page.dart';

/// Mục 6 (Phụ lục 1) — Danh sách video quay tình huống của 1 trẻ: tình
/// huống, ngày quay, trạng thái. Bấm vào mở lại video + nhận xét.
class VideoListPage extends StatefulWidget {
  final Child child;

  const VideoListPage({super.key, required this.child});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final _videoRepository = VideoRepository(AppDatabase.instance);
  late Future<List<Video>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _videosFuture = _videoRepository.getForChild(widget.child.id);
    });
  }

  String _statusLabel(String status) => switch (status) {
        'reviewed' => '🟢 Đã có nhận xét',
        'pending' => '🟡 Đang chờ chuyên gia',
        _ => 'Chưa gửi',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video tình huống — ${widget.child.name}')),
      body: FutureBuilder<List<Video>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snapshot.data!;
          if (videos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có video nào. Bấm "+" để quay video mới.'),
              ),
            );
          }
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return ListTile(
                title: Text(video.situation ?? '(không rõ tình huống)'),
                subtitle: Text(
                  '${video.recordedAt.day}/${video.recordedAt.month}/${video.recordedAt.year} • ${_statusLabel(video.status)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VideoDetailPage(video: video)),
                  );
                  _reload();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => VideoSituationPage(child: widget.child)),
          );
          _reload();
        },
        tooltip: 'Quay video mới',
        child: const Icon(Icons.videocam),
      ),
    );
  }
}
