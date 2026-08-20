import 'package:flutter/material.dart';

import '../../core/constants/domains.dart';
import '../../core/constants/screening_domains.dart';
import '../../data/local/database.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../domain/models/child.dart';
import '../../domain/models/screening_session.dart';
import '../../domain/services/screening_scoring_service.dart';
import '../assessment/domain_list_page.dart';

class _SummaryData {
  final bool hasScreening;
  final ScreeningSession? latestScreening;
  final int doneDomainCount;

  const _SummaryData({
    required this.hasScreening,
    required this.latestScreening,
    required this.doneDomainCount,
  });
}

/// Bước 4 — Tổng hợp hồ sơ & đề xuất hướng đánh giá. Hiện sau khi người dùng
/// hoàn thành HOẶC bỏ qua sàng lọc (cả 2 nhánh Bước 3), trước khi vào giao
/// diện 7 lĩnh vực (Bước 5). Toàn bộ nội dung đọc từ dữ liệu thật của trẻ,
/// đề xuất hướng đánh giá tính bằng logic Dart thuần (if/else), không gọi AI.
class AssessmentSummaryPage extends StatefulWidget {
  final Child child;

  const AssessmentSummaryPage({super.key, required this.child});

  @override
  State<AssessmentSummaryPage> createState() => _AssessmentSummaryPageState();
}

class _AssessmentSummaryPageState extends State<AssessmentSummaryPage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  late final Future<_SummaryData> _summaryFuture = _load();

  Future<_SummaryData> _load() async {
    final hasScreening = await _screeningRepository.hasScreening(
      widget.child.id,
    );
    final latestScreening = await _screeningRepository.getLatestForChild(
      widget.child.id,
    );
    final assessments = await _assessmentRepository.getForChild(
      widget.child.id,
    );
    final doneDomains = assessments
        .where((a) => a.contentType == 'mo_ta')
        .map((a) => a.linhVuc)
        .toSet();
    return _SummaryData(
      hasScreening: hasScreening,
      latestScreening: latestScreening,
      doneDomainCount: doneDomains.length,
    );
  }

  /// Logic Dart thuần — không gọi AI. Kết hợp trạng thái sàng lọc và số lĩnh vực đã có mô tả.
  String _buildSuggestion(_SummaryData data) {
    final total = domains.length;
    const toolLabel = 'bài sàng lọc (5 lĩnh vực theo độ tuổi)';

    if (!data.hasScreening && data.doneDomainCount == 0) {
      return 'Trẻ chưa thực hiện sàng lọc và chưa có mô tả biểu hiện ở lĩnh vực nào. '
          'Có thể thực hiện $toolLabel, '
          'hoặc bắt đầu ngay bằng cách mô tả biểu hiện ở lĩnh vực trẻ có quan sát rõ nhất.';
    }
    if (!data.hasScreening && data.doneDomainCount > 0) {
      return 'Đã có mô tả biểu hiện cho ${data.doneDomainCount}/$total lĩnh vực nhưng chưa sàng lọc. '
          'Có thể thực hiện thêm $toolLabel để có góc nhìn tổng quát hơn.';
    }
    if (data.hasScreening && data.doneDomainCount == 0) {
      return 'Đã có kết quả sàng lọc nhưng chưa có mô tả biểu hiện cụ thể cho lĩnh vực nào. '
          'Nên nhập mô tả biểu hiện cho từng lĩnh vực để có dữ liệu chi tiết, đặc biệt các lĩnh vực '
          'liên quan tới dấu hiệu đã ghi nhận trong sàng lọc.';
    }
    if (data.doneDomainCount < total) {
      return 'Đã sàng lọc và đánh giá ${data.doneDomainCount}/$total lĩnh vực. '
          'Nên tiếp tục mô tả biểu hiện ở các lĩnh vực còn lại để có bức tranh đầy đủ hơn.';
    }
    return 'Đã sàng lọc và có mô tả biểu hiện cho đủ $total lĩnh vực. '
        'Có thể xem lại chân dung tổng thể hoặc bổ sung mô tả mới nếu có quan sát thêm.';
  }


  void _startAssessment() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DomainListPage(child: widget.child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng hợp hồ sơ & đề xuất')),
      body: FutureBuilder<_SummaryData>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final total = domains.length;
          final screening = data.latestScreening;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Khối 1 — thông tin trẻ.
              Text(
                'Tổng hợp hồ sơ ${widget.child.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text('Độ tuổi: ${formatAgeLabel(widget.child)}'),
              const SizedBox(height: 16),
              // Khối 2 — tóm tắt sàng lọc.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sàng lọc',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(data.hasScreening ? 'Đã sàng lọc' : 'Chưa sàng lọc'),
                      if (data.hasScreening && screening != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kết quả sàng lọc gần nhất: '
                          '${screening.tongDiem60 != null ? "${screening.tongDiem60!.toStringAsFixed(1)}/60" : "(chưa đủ dữ liệu)"} — '
                          '${screeningGiaiDoanLabel(screening.giaiDoan)}',
                        ),
                        const SizedBox(height: 4),
                        Text('Mức tuổi làm bài: ${screeningAgeTierLabel(screening.mucTuoiLamBai)}'),
                        const SizedBox(height: 4),
                        Text('Ngày thực hiện: ${screening.ngayThucHien}'),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Người đánh giá: ${widget.child.nguoiDanhGia ?? "Chưa cập nhật"}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Khối 3 — số lĩnh vực đã/chưa đánh giá.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh giá 7 lĩnh vực',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đã có mô tả cho ${data.doneDomainCount}/$total lĩnh vực',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Khối 4 — đề xuất hướng đánh giá.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đề xuất hướng đánh giá',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_buildSuggestion(data)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _startAssessment,
                child: const Text('Bắt đầu đánh giá'),
              ),
            ],
          );
        },
      ),
    );
  }
}
