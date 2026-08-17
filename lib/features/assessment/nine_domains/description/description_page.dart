import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/remote/nvidia_api_client.dart';
import '../../../../data/repositories/assessment_repository.dart';
import '../../../../data/repositories/history_log_repository.dart';
import '../../../../data/repositories/profile_chunk_repository.dart';
import '../../../../domain/models/assessment.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/services/ai_connectivity_service.dart';

/// Định nghĩa ngắn 1-2 câu cho mỗi lĩnh vực, hiện ở đầu Mô tả biểu
/// hiện để người dùng hiểu đang mô tả về khía cạnh nào.
const Map<String, String> _domainIntroTextTemp = {
  'nhan_thuc':
      'Khả năng của trẻ trong việc hiểu, ghi nhớ, suy luận và giải quyết vấn đề phù hợp với độ tuổi.',
  'cam_xuc': 'Cách trẻ nhận biết, thể hiện và điều tiết cảm xúc của bản thân.',
  'giac_quan':
      'Cách trẻ tiếp nhận và phản ứng với các kích thích giác quan (âm thanh, ánh sáng, xúc giác...).',
  'quan_he_xa_hoi':
      'Khả năng của trẻ trong việc tương tác, giao tiếp, ứng xử, tuân thủ quy tắc và thích nghi với các tình huống xã hội.',
  'ngon_ngu':
      'Khả năng hiểu và sử dụng ngôn ngữ để giao tiếp với người xung quanh.',
  'sinh_hoc':
      'Các yếu tố phát triển thể chất và sinh học liên quan đến sự phát triển chung của trẻ.',
  'sinh_hoat_ca_nhan':
      'Khả năng tự thực hiện các hoạt động sinh hoạt cá nhân hàng ngày phù hợp với độ tuổi.',
};

/// Mô tả biểu hiện: dữ liệu riêng của trẻ do người dùng nhập, lưu vào bảng
/// `assessments` (content_type='mo_ta') và đồng thời embed để lưu vào
/// `profile_chunks` phục vụ RAG.
class DescriptionPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;
  final NvidiaApiClient? nvidiaApiClient;

  const DescriptionPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
    this.nvidiaApiClient,
  });

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _profileChunkRepository = ProfileChunkRepository(AppDatabase.instance);
  final _historyLogRepository = HistoryLogRepository(AppDatabase.instance);
  late final _nvidiaApiClient = widget.nvidiaApiClient ?? NvidiaApiClient();
  final _contentController = TextEditingController();

  late Future<List<Assessment>> _descriptionsFuture;
  bool _saving = false;
  bool _retrying = false;

  /// Mô tả vừa lưu thành công nhưng bước embed cho AI bị lỗi — giữ lại nội
  /// dung để hiện nút "Thử lại xử lý cho AI" ngay tại chỗ, không bắt người
  /// dùng nhập lại. `null` = không có gì đang chờ thử lại.
  String? _pendingEmbedContent;

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
    final all = await _assessmentRepository.getForChild(
      widget.child.id,
      linhVuc: widget.linhVuc,
    );
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
        description:
            'Đánh giá ${widget.linhVucLabel} — đã nhập mô tả biểu hiện',
      );
    } catch (_) {
      // Không chặn luồng chính vì lịch sử là dữ liệu phụ trợ.
    }

    // Bước 2-3 — embed + lưu profile_chunks. Lỗi ở đây KHÔNG được làm mất
    // mô tả đã lưu ở bước 1, chỉ báo cho người dùng biết để thử lại sau.
    final embedSucceeded = await _embedAndSaveChunk(content);
    final snackBarMessage = embedSucceeded
        ? 'Đã lưu mô tả và xử lý xong cho AI.'
        : 'Đã lưu mô tả, nhưng chưa xử lý được cho AI (thử lại sau).';

    if (!mounted) return;
    setState(() {
      _saving = false;
      _pendingEmbedContent = embedSucceeded ? null : content;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackBarMessage)));
  }

  /// Gọi NVIDIA embed + lưu `profile_chunks` cho [content]. Trả `true` nếu
  /// thành công. Dùng chung cho lần lưu đầu (`_save`) và nút "Thử lại xử lý
  /// cho AI" (`_retryEmbedding`) — không tạo bản ghi `assessments` mới, chỉ
  /// cập nhật chunk RAG.
  Future<bool> _embedAndSaveChunk(String content) async {
    if (!AiConnectivityService.instance.isConnected) {
      return false;
    }
    try {
      final embedding = await _nvidiaApiClient.embed(content);
      await _profileChunkRepository.add(
        childId: widget.child.id,
        content: content,
        linhVuc: widget.linhVuc,
        nguon: 'phu_huynh',
        embedding: embedding,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _retryEmbedding() async {
    final content = _pendingEmbedContent;
    if (content == null || _retrying) return;

    setState(() => _retrying = true);
    final succeeded = await _embedAndSaveChunk(content);

    if (!mounted) return;
    setState(() {
      _retrying = false;
      if (succeeded) _pendingEmbedContent = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Đã xử lý xong cho AI.'
              : 'Vẫn chưa xử lý được cho AI, thử lại sau.',
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
          Text(
            _domainIntroTextTemp[widget.linhVuc] ??
                'Mô tả biểu hiện của trẻ trong lĩnh vực này.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn quan sát thấy bé có biểu hiện gì trong ${widget.linhVucLabel}?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mô tả biểu hiện quan sát được',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              // Ghi âm chưa có chức năng thật — icon chỉ đúng vị trí thiết
              // kế, cố ý vô hiệu hoá (`onPressed: null`) để không giả vờ đã
              // hoạt động.
              suffixIcon: const IconButton(
                icon: Icon(Icons.mic_none_outlined),
                onPressed: null,
                tooltip: 'Ghi âm (chưa khả dụng)',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_contentController.text.length} ký tự',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghi nhận đơn giản',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bạn không cần kiến thức chuyên môn. Chỉ cần mô tả những gì bạn thấy trong cuộc sống hàng ngày.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Lưu mô tả'),
          ),
          if (_pendingEmbedContent != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _retrying ? null : _retryEmbedding,
              child: _retrying
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thử lại xử lý cho AI'),
            ),
          ],
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
                    .map(
                      (a) => Card(
                        child: ListTile(
                          title: Text(a.content),
                          subtitle: Text(a.createdAt.toString()),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
