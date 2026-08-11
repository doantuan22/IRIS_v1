import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/local/database.dart';
import '../../data/repositories/history_log_repository.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/models/child.dart';
import 'video_situation_page.dart';

/// Bước 4/4 — Phát lại video vừa quay, gửi cho chuyên gia (tạo bản ghi
/// `videos` + `history_logs`, mô phỏng trong phạm vi 1 thiết bị — không có
/// kênh upload thật ra ngoài máy).
class VideoReviewPage extends StatefulWidget {
  final Child child;
  final String situation;
  final String filePath;

  const VideoReviewPage({
    super.key,
    required this.child,
    required this.situation,
    required this.filePath,
  });

  @override
  State<VideoReviewPage> createState() => _VideoReviewPageState();
}

class _VideoReviewPageState extends State<VideoReviewPage> {
  final _videoRepository = VideoRepository(AppDatabase.instance);
  final _historyLogRepository = HistoryLogRepository(AppDatabase.instance);

  VideoPlayerController? _playerController;
  String? _playerError;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final controller = VideoPlayerController.file(File(widget.filePath));
      await controller.initialize();
      if (!mounted) return;
      setState(() => _playerController = controller);
    } catch (e) {
      if (mounted) setState(() => _playerError = 'Không phát lại được video: $e');
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _sendToExpert() async {
    if (_sending || _sent) return;
    setState(() => _sending = true);
    try {
      // Bước 1 — luôn tạo bản ghi videos trước, giữ nguyên file đã quay dù
      // bước ghi history_logs bên dưới có lỗi.
      await _videoRepository.save(
        childId: widget.child.id,
        filePath: widget.filePath,
        situation: widget.situation,
        status: 'pending',
      );
      try {
        await _historyLogRepository.add(
          childId: widget.child.id,
          eventType: 'video',
          description: 'Quay video tình huống: ${widget.situation}',
        );
      } catch (_) {
        // Không để lỗi ghi lịch sử làm mất video đã gửi thành công.
      }
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi video cho chuyên gia (mô phỏng trong phạm vi thiết bị).')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không gửi được video: $e')),
        );
      }
    }
  }

  void _recordAnother() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VideoSituationPage(child: widget.child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xem lại & gửi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tình huống: ${widget.situation}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(child: _buildPlayer()),
            const SizedBox(height: 16),
            if (_sent) ...[
              const Text(
                'Đã gửi. Bạn có thể quay thêm tình huống khác hoặc quay lại hồ sơ.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _recordAnother,
                child: const Text('Quay thêm tình huống khác'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Xong, quay lại hồ sơ'),
              ),
            ] else
              FilledButton.icon(
                onPressed: _sending ? null : _sendToExpert,
                icon: _sending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Đang gửi...' : 'Gửi cho chuyên gia'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_playerError != null) {
      return Center(child: Text(_playerError!, textAlign: TextAlign.center));
    }
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        IconButton(
          iconSize: 48,
          icon: Icon(controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
          onPressed: () => setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          }),
        ),
      ],
    );
  }
}
