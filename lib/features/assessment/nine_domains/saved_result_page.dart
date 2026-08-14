import 'package:flutter/material.dart';

import '../../../data/local/database.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../data/repositories/expert_knowledge_repository.dart';
import '../../../domain/models/child.dart';
import 'description/description_page.dart';

class _SavedResultData {
  final bool hasDescription;
  final bool hasComparison;
  final bool hasParentShare;
  final bool hasDoctorNote;

  const _SavedResultData({
    required this.hasDescription,
    required this.hasComparison,
    required this.hasParentShare,
    required this.hasDoctorNote,
  });
}

/// Bước 7 — "Đã lưu kết quả": chèn giữa lúc bấm "Hoàn tất" ở Phần 5/5 (Chân
/// dung biểu hiện) và lúc quay về `DomainListPage`. Checklist "Nội dung đã
/// được lưu" đối chiếu đúng dữ liệu thật (assessments + expert_knowledge_chunks)
/// — KHÔNG đánh dấu ✓ giả cho mục không có dữ liệu.
class SavedResultPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const SavedResultPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<SavedResultPage> createState() => _SavedResultPageState();
}

class _SavedResultPageState extends State<SavedResultPage> {
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _expertKnowledgeRepository = ExpertKnowledgeRepository(AppDatabase.instance);

  /// Thời điểm hoàn tất chuỗi 5 phần — dùng làm "Ngày đánh giá" hiển thị,
  /// luôn có giá trị kể cả khi Phần 1 không lưu mô tả nào (bấm "Lưu & tiếp
  /// tục" khi ô nhập trống vẫn cho qua, xem `description_page.dart`).
  final DateTime _completedAt = DateTime.now();

  late final Future<_SavedResultData> _dataFuture = _load();

  Future<_SavedResultData> _load() async {
    final assessments = await _assessmentRepository.getForChild(widget.child.id, linhVuc: widget.linhVuc);
    final hasDescription = assessments.any((a) => a.contentType == 'mo_ta');

    final ageMonths = childAgeInMonths(widget.child);
    final soSanh = await _expertKnowledgeRepository.query(
      linhVuc: widget.linhVuc,
      ageInMonths: ageMonths,
      contentType: 'so_sanh',
    );
    final chiaSe = await _expertKnowledgeRepository.query(
      linhVuc: widget.linhVuc,
      ageInMonths: ageMonths,
      contentType: 'chia_se_phu_huynh',
    );
    final bacSi = await _expertKnowledgeRepository.query(
      linhVuc: widget.linhVuc,
      ageInMonths: ageMonths,
      contentType: 'bac_si',
    );

    return _SavedResultData(
      hasDescription: hasDescription,
      hasComparison: soSanh.isNotEmpty,
      hasParentShare: chiaSe.isNotEmpty,
      hasDoctorNote: bacSi.isNotEmpty,
    );
  }

  String get _formattedCompletedAt {
    final d = _completedAt;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.linhVucLabel} — Đã lưu kết quả')),
      body: FutureBuilder<_SavedResultData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 56),
              const SizedBox(height: 8),
              const Text(
                'Lưu thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                widget.linhVucLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'Ngày đánh giá', value: _formattedCompletedAt),
                      _InfoRow(label: 'Người thực hiện', value: widget.child.nguoiDanhGia ?? 'Chưa cập nhật'),
                      const _InfoRow(label: 'Trạng thái', value: 'Đã lưu thành công'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nội dung đã được lưu', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _ChecklistRow(label: 'Mô tả của người dùng', done: data.hasDescription),
                      _ChecklistRow(label: 'Kết quả so sánh', done: data.hasComparison),
                      _ChecklistRow(label: 'Chia sẻ phụ huynh', done: data.hasParentShare),
                      _ChecklistRow(label: 'Ghi chú bác sĩ', done: data.hasDoctorNote),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kết quả sàng lọc/đánh giá chỉ mang tính tham khảo, không thay thế chẩn đoán chuyên môn.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DescriptionPage(
                      child: widget.child,
                      linhVuc: widget.linhVuc,
                      linhVucLabel: widget.linhVucLabel,
                    ),
                  ),
                ),
                child: const Text('Xem kết quả'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay về tổng quan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: Theme.of(context).hintColor))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool done;

  const _ChecklistRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.remove_circle_outline,
            color: done ? Colors.green : Theme.of(context).hintColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          if (!done)
            Text(
              'Không có dữ liệu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
            ),
        ],
      ),
    );
  }
}
