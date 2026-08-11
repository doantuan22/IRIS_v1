import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/remote/nvidia_api_client.dart';
import '../../../../data/repositories/assessment_repository.dart';
import '../../../../data/repositories/history_log_repository.dart';
import '../../../../data/repositories/profile_chunk_repository.dart';
import '../../../../domain/models/assessment.dart';
import '../../../../domain/models/child.dart';
import '../comparison_video/comparison_video_page.dart';

/// Phần 1/5 của mỗi lĩnh vực — Mô tả biểu hiện: dữ liệu riêng của trẻ do
/// người dùng nhập, lưu vào bảng `assessments` (content_type='mo_ta') và
/// đồng thời embed để lưu vào `profile_chunks` phục vụ RAG.
class DescriptionPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const DescriptionPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _profileChunkRepository = ProfileChunkRepository(AppDatabase.instance);
  final _historyLogRepository = HistoryLogRepository(AppDatabase.instance);
  final _nvidiaApiClient = NvidiaApiClient();
  final _contentController = TextEditingController();

  late Future<List<Assessment>> _descriptionsFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _descriptionsFuture = _loadDescriptions();
    });
  }

  Future<List<Assessment>> _loadDescriptions() async {
    final all = await _assessmentRepository.getForChild(widget.child.id, linhVuc: widget.linhVuc);
    return all.where((a) => a.contentType == 'mo_ta').toList();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _saving = true);

    // Bước 1 — luôn lưu mô tả trước, không phụ thuộc vào bước gọi API AI.
    await _assessmentRepository.save(
      childId: widget.child.id,
      linhVuc: widget.linhVuc,
      content: content,
      nguon: 'phu_huynh',
    );
    _contentController.clear();
    _reload();

    // Ghi lịch sử — lỗi ở đây không được làm mất mô tả đã lưu ở trên.
    try {
      await _historyLogRepository.add(
        childId: widget.child.id,
        eventType: 'danh_gia',
        description: 'Đánh giá ${widget.linhVucLabel} — đã nhập mô tả biểu hiện',
      );
    } catch (_) {
      // Không chặn luồng chính vì lịch sử là dữ liệu phụ trợ.
    }

    // Bước 2-3 — embed + lưu profile_chunks. Lỗi ở đây KHÔNG được làm mất
    // mô tả đã lưu ở bước 1, chỉ báo cho người dùng biết để thử lại sau.
    String snackBarMessage = 'Đã lưu mô tả và xử lý xong cho AI.';
    try {
      final embedding = await _nvidiaApiClient.embed(content);
      await _profileChunkRepository.add(
        childId: widget.child.id,
        content: content,
        linhVuc: widget.linhVuc,
        nguon: 'phu_huynh',
        embedding: embedding,
      );
    } catch (_) {
      snackBarMessage = 'Đã lưu mô tả, nhưng chưa xử lý được cho AI (thử lại sau).';
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarMessage)));
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ComparisonVideoPage(
          child: widget.child,
          linhVuc: widget.linhVuc,
          linhVucLabel: widget.linhVucLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.linhVucLabel} — Mô tả biểu hiện')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả biểu hiện quan sát được',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
          const SizedBox(height: 24),
          Text('Mô tả đã lưu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<Assessment>>(
            future: _descriptionsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final descriptions = snapshot.data!;
              if (descriptions.isEmpty) {
                return const Text('Chưa có mô tả nào cho lĩnh vực này.');
              }
              return Column(
                children: descriptions
                    .map((a) => Card(
                          child: ListTile(
                            title: Text(a.content),
                            subtitle: Text(a.createdAt.toString()),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _goNext,
            child: const Text('Tiếp theo'),
          ),
        ],
      ),
    );
  }
}
