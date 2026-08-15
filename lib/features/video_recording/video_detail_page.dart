import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/local/database.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/models/video.dart';

/// 2-3 mẫu nhận xét cố định, xoay vòng theo id video — mô phỏng phản hồi
/// chuyên gia trong phạm vi thiết bị (không có kênh gửi/nhận thật). Mỗi
/// mẫu chạm đủ tinh thần Bước 13: nhận xét chuyên môn, điểm cần theo dõi,
/// lĩnh vực cần đánh giá thêm, khuyến nghị bước tiếp theo.
const List<String> _expertNoteTemplates = [
  'Qua video, bé thể hiện khả năng tương tác phù hợp với tình huống được quan sát. '
      'Một điểm cần tiếp tục theo dõi: thời gian duy trì giao tiếp mắt. '
      'Gợi ý: quan sát thêm ở lĩnh vực Quan hệ xã hội trong 2-3 tuần tới.',
  'Video cho thấy bé phản ứng tương đối tự nhiên với tình huống. '
      'Cần lưu ý thêm về khả năng thực hiện yêu cầu nhiều bước liên tiếp. '
      'Khuyến nghị: quay thêm 1 video tình huống tương tự sau 2 tuần để so sánh tiến triển, '
      'đồng thời bổ sung mô tả biểu hiện ở lĩnh vực Ngôn ngữ.',
  'Nhận xét sơ bộ: biểu hiện của bé trong video nằm trong phạm vi phát triển thường gặp ở độ tuổi này, '
      'tuy nhiên nên tiếp tục quan sát thêm ở lĩnh vực Cảm xúc và Hành vi. '
      'Nếu có điều kiện, nên đưa trẻ đến gặp chuyên gia để được đánh giá trực tiếp, đầy đủ hơn.',
];

/// Xem lại 1 video đã quay + trạng thái/nhận xét chuyên gia. Có nút debug
/// (chỉ hiện ở debug mode) mô phỏng chuyên gia phản hồi cho video đang chờ.
class VideoDetailPage extends StatefulWidget {
  final Video video;

  const VideoDetailPage({super.key, required this.video});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  final _videoRepository = VideoRepository(AppDatabase.instance);

  VideoPlayerController? _playerController;
  String? _playerError;
  late Video _video;
  bool _simulating = false;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final controller = VideoPlayerController.file(File(_video.filePath));
      await controller.initialize();
      if (!mounted) return;
      setState(() => _playerController = controller);
    } catch (e) {
      if (mounted) {
        setState(() => _playerError = 'Không phát lại được video: $e');
      }
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _deleteVideo() async {
    final hasNote = _video.expertNote != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá video?'),
        content: Text(
          hasNote
              ? 'Video và nhận xét chuyên gia đi kèm sẽ bị xoá vĩnh viễn, không thể khôi phục.'
              : 'Video này sẽ bị xoá vĩnh viễn, không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _videoRepository.delete(_video.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không xoá được video: $e')));
      }
    }
  }

  Future<void> _simulateExpertReview() async {
    if (_simulating) return;
    setState(() => _simulating = true);
    try {
      final note =
          _expertNoteTemplates[_video.id.hashCode.abs() %
              _expertNoteTemplates.length];
      await _videoRepository.updateStatus(
        _video.id,
        'reviewed',
        expertNote: note,
      );
      if (!mounted) return;
      setState(() {
        _video = Video(
          id: _video.id,
          childId: _video.childId,
          situation: _video.situation,
          filePath: _video.filePath,
          status: 'reviewed',
          expertNote: note,
          recordedAt: _video.recordedAt,
        );
        _simulating = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _simulating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không mô phỏng được phản hồi: $e')),
        );
      }
    }
  }

  String _statusLabel(String status) => switch (status) {
    'reviewed' => '🟢 Đã có nhận xét',
    'pending' => '🟡 Đang chờ chuyên gia',
    _ => 'Chưa gửi',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _video.situation != null && _video.situation!.trim().isNotEmpty
              ? _video.situation!
              : 'Chi tiết video',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoá video',
            onPressed: _deleteVideo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlayer(),
          const SizedBox(height: 16),
          if (_video.situation != null &&
              _video.situation!.trim().isNotEmpty) ...[
            Text(
              'Tình huống: ${_video.situation}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Trạng thái: ${_statusLabel(_video.status)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ngày quay: ${_video.recordedAt.day}/${_video.recordedAt.month}/${_video.recordedAt.year}',
          ),
          const SizedBox(height: 16),
          if (_video.expertNote != null) ...[
            Text(
              'Nhận xét chuyên gia',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_video.expertNote!),
          ],
          if (!kIsWeb && kDebugMode && _video.status != 'reviewed') ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _simulating ? null : _simulateExpertReview,
              icon: _simulating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bug_report_outlined),
              label: const Text('Debug: Mô phỏng chuyên gia phản hồi'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_playerError != null) {
      return Text(_playerError!, textAlign: TextAlign.center);
    }
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        IconButton(
          iconSize: 48,
          icon: Icon(
            controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
          ),
          onPressed: () => setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          }),
        ),
      ],
    );
  }
}
