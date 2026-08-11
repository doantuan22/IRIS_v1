import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/child.dart';
import 'video_review_page.dart';

const Duration _maxRecordingDuration = Duration(minutes: 3);

/// Bước 3/4 — Quay video: preview camera thật + nút quay/dừng + đồng hồ
/// đang quay, tự dừng khi chạm giới hạn thời lượng. Mọi lỗi camera/ghi file
/// đều hiện rõ ràng, không crash — dữ liệu (hồ sơ, tình huống đã chọn) vẫn
/// giữ nguyên để người dùng có thể quay lại thử lại.
class VideoRecordingCapturePage extends StatefulWidget {
  final Child child;
  final String situation;

  const VideoRecordingCapturePage({super.key, required this.child, required this.situation});

  @override
  State<VideoRecordingCapturePage> createState() => _VideoRecordingCapturePageState();
}

class _VideoRecordingCapturePageState extends State<VideoRecordingCapturePage> {
  CameraController? _controller;
  String? _errorMessage;
  bool _isRecording = false;
  bool _isSaving = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Không tìm thấy camera nào trên thiết bị.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.medium, enableAudio: true);
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Không mở được camera (có thể do quyền camera/micro bị từ chối): $e');
      }
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || _isRecording) return;
    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= _maxRecordingDuration) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không bắt đầu quay được: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isSaving = true;
    });
    try {
      final tempFile = await controller.stopVideoRecording();
      final savedPath = await _saveToLocalFile(tempFile);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoReviewPage(
            child: widget.child,
            situation: widget.situation,
            filePath: savedPath,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi dừng quay / lưu file video: $e')),
        );
      }
    }
  }

  Future<String> _saveToLocalFile(XFile tempFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final videosDir = Directory(p.join(directory.path, 'videos'));
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    final targetPath = p.join(videosDir.path, '${const Uuid().v4()}.mp4');
    await File(tempFile.path).copy(targetPath);
    return targetPath;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đang quay — ${widget.situation}')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: CameraPreview(controller)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_formatDuration(_elapsed), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isSaving ? null : (_isRecording ? _stopRecording : _startRecording),
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                label: Text(_isSaving ? 'Đang lưu...' : (_isRecording ? 'Dừng quay' : 'Bắt đầu quay')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
