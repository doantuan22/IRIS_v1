import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../data/local/database.dart';
import '../../../data/remote/nvidia_api_client.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../data/repositories/expert_knowledge_repository.dart';
import '../../../data/repositories/profile_chunk_repository.dart';
import '../../../data/repositories/screening_repository.dart';
import '../../../domain/models/child.dart';
import '../../ai_chat/ai_chat_page.dart';
import '../../assessment/domain_list_page.dart';
import '../../expert_connect/expert_connect_page.dart';
import '../../history/history_page.dart';
import '../../screening/screening_intro_page.dart';
import '../../video_recording/video_list_page.dart';

/// Trang chi tiết hồ sơ trẻ — điểm vào các chức năng sàng lọc, đánh giá,
/// lịch sử, hỏi đáp AI, quay video cho một trẻ cụ thể.
class ProfileDetailPage extends StatefulWidget {
  final Child child;

  const ProfileDetailPage({super.key, required this.child});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _profileChunkRepository = ProfileChunkRepository(AppDatabase.instance);
  final _expertKnowledgeRepository = ExpertKnowledgeRepository(AppDatabase.instance);
  late Future<bool> _hasScreeningFuture;
  bool _ingestingExpertData = false;

  @override
  void initState() {
    super.initState();
    _reloadScreeningStatus();
  }

  void _reloadScreeningStatus() {
    setState(() {
      _hasScreeningFuture = _screeningRepository.hasScreening(widget.child.id);
    });
  }

  Future<void> _openScreening() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScreeningIntroPage(child: widget.child)),
    );
    _reloadScreeningStatus();
  }

  Future<void> _showDebugRawData() async {
    final screenings = await _screeningRepository.getForChild(widget.child.id);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug — dữ liệu sàng lọc thô'),
        content: SingleChildScrollView(
          child: Text(
            screenings.isEmpty
                ? '(chưa có bản ghi screenings nào cho trẻ này)'
                : screenings
                    .map((s) =>
                        'id: ${s.id}\ntool_name: ${s.toolName}\nscore: ${s.score}\nresult_summary: ${s.resultSummary}\nperformed_at: ${s.performedAt}\n')
                    .join('\n---\n'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _showDebugAssessmentData() async {
    final assessments = await _assessmentRepository.getForChild(widget.child.id);
    final chunks = await _profileChunkRepository.getForChild(widget.child.id);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug — dữ liệu đánh giá thô'),
        content: SingleChildScrollView(
          child: Text(
            'assessments (${assessments.length}):\n'
            '${assessments.isEmpty ? '(rỗng)' : assessments.map((a) => 'id: ${a.id}\nlinh_vuc: ${a.linhVuc}\ncontent_type: ${a.contentType}\ncontent: ${a.content}\nnguon: ${a.nguon}\n').join('\n---\n')}'
            '\n\nprofile_chunks (${chunks.length}):\n'
            '${chunks.isEmpty ? '(rỗng)' : chunks.map((c) => 'id: ${c.id}\nlinh_vuc: ${c.linhVuc}\ncontent: ${c.content}\nembedding.length: ${c.embedding.length}\n').join('\n---\n')}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  /// Nạp dữ liệu tham khảo (`assets/reference/expert_content.json`) thẳng
  /// vào database THẬT của app đang chạy — thay cho
  /// `scripts/ingest_expert_data.dart` (script đó ghi vào 1 file db riêng
  /// trên máy desktop qua sqflite_common_ffi, KHÔNG phải database thật của
  /// app trên emulator/thiết bị, nên dữ liệu không tới được app thật).
  /// Chỉ hiện trong debug mode, chặn bấm 2 lần liên tiếp bằng
  /// [_ingestingExpertData], và hỏi xác nhận nếu đã có dữ liệu để tránh
  /// insert trùng.
  Future<void> _ingestExpertData() async {
    if (_ingestingExpertData) return;

    final existing = await _expertKnowledgeRepository.getAll();
    if (existing.isNotEmpty && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đã có dữ liệu tham khảo'),
          content: Text(
            'Đã có ${existing.length} chunk trong expert_knowledge_chunks. '
            'Nạp lại sẽ tạo thêm bản ghi trùng nội dung. Vẫn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Vẫn nạp'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _ingestingExpertData = true);
    var success = 0;
    var failed = 0;
    try {
      final jsonString = await rootBundle.loadString('assets/reference/expert_content.json');
      final entries = (jsonDecode(jsonString) as List<dynamic>).cast<Map<String, dynamic>>();
      final nvidiaApiClient = NvidiaApiClient();

      for (final entry in entries) {
        try {
          final content = entry['content'] as String;
          final embedding = await nvidiaApiClient.embed(content);
          await _expertKnowledgeRepository.add(
            content: content,
            contentType: entry['content_type'] as String,
            phanLoai: entry['phan_loai'] as String?,
            nhomTre: entry['nhom_tre'] as String?,
            boiCanh: entry['boi_canh'] as String?,
            linhVuc: entry['linh_vuc'] as String?,
            doTuoiThangMin: entry['do_tuoi_thang_min'] as int?,
            doTuoiThangMax: entry['do_tuoi_thang_max'] as int?,
            nguonTaiLieu: entry['nguon_tai_lieu'] as String?,
            embedding: embedding,
          );
          success++;
        } catch (_) {
          failed++;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _ingestingExpertData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nạp dữ liệu tham khảo: $success thành công, $failed lỗi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Scaffold(
      appBar: AppBar(title: Text(child.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${formatAgeLabel(child)} • ${child.gender ?? "chưa rõ giới tính"}'),
                  const SizedBox(height: 4),
                  Text('Người đánh giá: ${child.nguoiDanhGia ?? "Chưa cập nhật"}'),
                  const SizedBox(height: 4),
                  Text('Vai trò: ${child.vaiTro ?? "Chưa cập nhật"}'),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: _hasScreeningFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final hasScreening = snapshot.data!;
                      return Chip(
                        label: Text(hasScreening ? 'Đã sàng lọc' : 'Chưa sàng lọc'),
                        backgroundColor: hasScreening
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openScreening,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Sàng lọc'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DomainListPage(child: child)),
            ),
            icon: const Icon(Icons.checklist_outlined),
            label: const Text('Đánh giá 9 lĩnh vực'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistoryPage(child: child)),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Lịch sử'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AiChatPage(child: child)),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Hỏi đáp AI'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoListPage(child: child)),
            ),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Quay video tình huống'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExpertConnectPage(child: child)),
            ),
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Kết nối chuyên gia/trung tâm'),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _showDebugRawData,
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Debug: xem dữ liệu sàng lọc thô'),
          ),
          TextButton.icon(
            onPressed: _showDebugAssessmentData,
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Debug: xem dữ liệu đánh giá thô'),
          ),
          if (!kIsWeb && kDebugMode)
            TextButton.icon(
              onPressed: _ingestingExpertData ? null : _ingestExpertData,
              icon: _ingestingExpertData
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Debug: Nạp dữ liệu tham khảo'),
            ),
        ],
      ),
    );
  }
}
