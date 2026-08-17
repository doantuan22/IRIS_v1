import 'package:flutter/material.dart';

import '../../../core/theme/iris_theme.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../data/repositories/profile_chunk_repository.dart';
import '../../../data/repositories/screening_repository.dart';
import '../../../domain/models/child.dart';
import '../../../domain/services/expert_knowledge_seed_service.dart';

/// Màn debug riêng cho 1 trẻ — chỉ vào được qua icon debug (guard
/// `kDebugMode`) trên `ProfileDetailPage`, không hiện trong luồng chính cho
/// người dùng thường. Gộp lại đúng 3 hành động debug trước đây từng nằm lẫn
/// trong `ProfileDetailPage`.
class ChildDebugPage extends StatefulWidget {
  final Child child;

  const ChildDebugPage({super.key, required this.child});

  @override
  State<ChildDebugPage> createState() => _ChildDebugPageState();
}

class _ChildDebugPageState extends State<ChildDebugPage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _profileChunkRepository = ProfileChunkRepository(AppDatabase.instance);
  bool _ingestingExpertData = false;

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
                      .map(
                        (s) =>
                            'id: ${s.id}\ntool_name: ${s.toolName}\nscore: ${s.score}\nresult_summary: ${s.resultSummary}\nperformed_at: ${s.performedAt}\n',
                      )
                      .join('\n---\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDebugAssessmentData() async {
    final assessments = await _assessmentRepository.getForChild(
      widget.child.id,
    );
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Xoá sạch + nạp lại dữ liệu "So sánh" (content_type='so_sanh') từ file
  /// seed đã tính sẵn embedding (`expert_knowledge_seed.json`) — KHÔNG gọi
  /// API, KHÔNG sinh id mới (giữ nguyên `id` gốc, khớp đúng `video_manifest.json`).
  ///
  /// Bình thường KHÔNG CẦN bấm nút này — `AppDatabase` đã tự seed dữ liệu
  /// này ngay khi mở app lần đầu (xem `ExpertKnowledgeSeedService.seedIfEmpty`,
  /// gọi từ `onOpen`). Nút này chỉ dùng khi cần NẠP LẠI THỦ CÔNG (VD: vừa
  /// chạy `scripts/generate_expert_knowledge_seed.dart` để cập nhật nội dung
  /// mới, muốn đồng bộ ngay mà không gỡ cài đặt app). Idempotent — bấm nhiều
  /// lần liên tiếp luôn ra đúng 532 dòng, không nhân bản.
  Future<void> _resetAndReseedExpertData() async {
    if (_ingestingExpertData) return;

    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset & nạp lại dữ liệu tham khảo'),
          content: const Text(
            'Sẽ xoá sạch toàn bộ dữ liệu "So sánh" hiện có trong '
            'expert_knowledge_chunks rồi nạp lại từ file seed mới nhất '
            '(assets/reference/expert_knowledge_seed.json). Tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset & nạp lại'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _ingestingExpertData = true);
    try {
      final db = await AppDatabase.instance.database;
      final total = await ExpertKnowledgeSeedService.resetAndReseed(db);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã nạp lại $total dòng dữ liệu "So sánh".')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi nạp lại: $e')));
      }
    } finally {
      if (mounted) setState(() => _ingestingExpertData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug — ${widget.child.name}')),
      body: ListView(
        padding: IrisSpacing.page,
        children: [
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
          TextButton.icon(
            onPressed: _ingestingExpertData ? null : _resetAndReseedExpertData,
            icon: _ingestingExpertData
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: const Text('Debug: Reset & nạp lại dữ liệu tham khảo'),
          ),
        ],
      ),
    );
  }
}
