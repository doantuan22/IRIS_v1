import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/iris_theme.dart';
import '../../../data/local/database.dart';
import '../../../data/remote/nvidia_api_client.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../data/repositories/expert_knowledge_repository.dart';
import '../../../data/repositories/profile_chunk_repository.dart';
import '../../../data/repositories/screening_repository.dart';
import '../../../domain/models/child.dart';

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
  final _expertKnowledgeRepository = ExpertKnowledgeRepository(
    AppDatabase.instance,
  );
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

  /// Nạp dữ liệu tham khảo (`assets/reference/expert_content.json`) thẳng
  /// vào database THẬT của app đang chạy — thay cho
  /// `scripts/ingest_expert_data.dart` (script đó ghi vào 1 file db riêng
  /// trên máy desktop qua sqflite_common_ffi, KHÔNG phải database thật của
  /// app trên emulator/thiết bị, nên dữ liệu không tới được app thật).
  /// Chặn bấm 2 lần liên tiếp bằng [_ingestingExpertData], và hỏi xác nhận
  /// nếu đã có dữ liệu để tránh insert trùng.
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
      final allEntries = <Map<String, dynamic>>[];

      // 1. Dữ liệu tham khảo khác (expert_content.json)
      try {
        final jsonString = await rootBundle.loadString(
          'assets/reference/expert_content.json',
        );
        final list = (jsonDecode(jsonString) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        allEntries.addAll(list);
      } catch (_) {}

      // 2. Dữ liệu So sánh 15-23 tháng (so_sanh_15_23_thang.json)
      try {
        final jsonString = await rootBundle.loadString(
          'assets/reference/so_sanh_15_23_thang.json',
        );
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        final list = (map['entries'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        allEntries.addAll(list);
      } catch (_) {}

      // 3. Dữ liệu So sánh 24-47 tháng (so_sanh_24_47_thang.json)
      try {
        final jsonString = await rootBundle.loadString(
          'assets/reference/so_sanh_24_47_thang.json',
        );
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        final list = (map['entries'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        allEntries.addAll(list);
      } catch (_) {}

      final nvidiaApiClient = NvidiaApiClient();

      for (final entry in allEntries) {
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
          SnackBar(
            content: Text(
              'Nạp dữ liệu tham khảo: $success thành công, $failed lỗi.',
            ),
          ),
        );
      }
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
