import 'package:flutter/material.dart';

import '../../core/theme/iris_theme.dart';
import '../../data/local/database.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/video.dart';
import 'video_detail_page.dart';
import 'video_preparation_page.dart';

/// Danh sách video quay quan sát của 1 trẻ: ngày quay, trạng thái, và tình huống (nếu có ở video cũ).
/// Bấm vào mở lại video + nhận xét chuyên gia.
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
      appBar: AppBar(title: Text('Video quan sát — ${widget.child.name}')),
      body: FutureBuilder<List<Video>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: IrisColors.danger,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được danh sách video: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
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
              final hasSituation =
                  video.situation != null && video.situation!.trim().isNotEmpty;
              final dateStr =
                  '${video.recordedAt.day}/${video.recordedAt.month}/${video.recordedAt.year}';

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.videocam_outlined),
                ),
                title: Text(
                  hasSituation ? video.situation! : 'Video ngày $dateStr',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  hasSituation
                      ? '$dateStr • ${_statusLabel(video.status)}'
                      : _statusLabel(video.status),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoDetailPage(video: video),
                    ),
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
            MaterialPageRoute(
              builder: (_) => VideoPreparationPage(child: widget.child),
            ),
          );
          _reload();
        },
        tooltip: 'Quay video mới',
        child: const Icon(Icons.videocam),
      ),
    );
  }
}
