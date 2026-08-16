import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Phát 1 video minh hoạ (asset đóng gói sẵn trong app — gắn qua tool dev
/// `tools/video_manager_tool.py`) cho 1 entry "So sánh" cụ thể.
///
/// Cùng kiểu giao diện (AspectRatio + VideoPlayer + nút play/pause đè lên,
/// báo lỗi bằng Text khi không phát được) như màn xem lại video người dùng
/// tự quay (`video_detail_page.dart`/`video_review_page.dart`) — khác ở chỗ
/// nguồn là `VideoPlayerController.asset()` (asset đóng gói sẵn) thay vì
/// `VideoPlayerController.file()` (file người dùng tự quay lưu trên máy),
/// nên không dùng chung được 1 constructor, phải khởi tạo riêng.
class VideoIllustrationPlayerPage extends StatefulWidget {
  final String assetPath;
  final String title;

  const VideoIllustrationPlayerPage({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  State<VideoIllustrationPlayerPage> createState() => _VideoIllustrationPlayerPageState();
}

class _VideoIllustrationPlayerPageState extends State<VideoIllustrationPlayerPage> {
  VideoPlayerController? _playerController;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      if (!mounted) return;
      setState(() => _playerController = controller);
      controller.play();
    } catch (e) {
      if (mounted) {
        setState(() => _playerError = 'Không phát được video minh hoạ: $e');
      }
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: _buildPlayer()),
    );
  }

  Widget _buildPlayer() {
    if (_playerError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_playerError!, textAlign: TextAlign.center),
      );
    }
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator();
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
