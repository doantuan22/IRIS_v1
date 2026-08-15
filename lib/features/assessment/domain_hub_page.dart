import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/remote/nvidia_api_client.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/child.dart';
import 'nine_domains/comparison_video/comparison_video_page.dart';
import 'nine_domains/description/description_page.dart';
import 'nine_domains/expert_input/expert_input_page.dart';
import 'nine_domains/parent_input/parent_input_page.dart';

/// Định nghĩa ngắn 1-2 câu cho mỗi lĩnh vực, hiển thị ở đầu màn Hub lĩnh vực.
const Map<String, String> _domainIntroText = {
  'nhan_thuc': 'Khả năng của trẻ trong việc hiểu, ghi nhớ, suy luận và giải quyết vấn đề phù hợp với độ tuổi.',
  'cam_xuc': 'Cách trẻ nhận biết, thể hiện và điều tiết cảm xúc của bản thân.',
  'giac_quan': 'Cách trẻ tiếp nhận và phản ứng với các kích thích giác quan (âm thanh, ánh sáng, xúc giác...).',
  'quan_he_xa_hoi':
      'Khả năng của trẻ trong việc tương tác, giao tiếp, ứng xử, tuân thủ quy tắc và thích nghi với các tình huống xã hội.',
  'ngon_ngu': 'Khả năng hiểu và sử dụng ngôn ngữ để giao tiếp với người xung quanh.',
  'sinh_hoc': 'Các yếu tố phát triển thể chất và sinh học liên quan đến sự phát triển chung của trẻ.',
  'sinh_hoat_ca_nhan': 'Khả năng tự thực hiện các hoạt động sinh hoạt cá nhân hàng ngày phù hợp với độ tuổi.',
};

/// Màn hình Hub trung tâm của 1 lĩnh vực đánh giá.
/// Cho phép người dùng tự do lựa chọn 1 trong 4 phần theo bất kỳ thứ tự nào:
/// 1. Mô tả biểu hiện (Phần quan trọng nhất — dữ liệu thật của trẻ)
/// 2. So sánh với trẻ cùng độ tuổi (Dữ liệu tham khảo bổ trợ)
/// 3. Chia sẻ từ phụ huynh (Dữ liệu tham khảo bổ trợ)
/// 4. Thông tin từ bác sĩ (Dữ liệu tham khảo bổ trợ)
///
/// Hoàn toàn không ràng buộc thứ tự, không khoá phần nào, dùng `push` để vào
/// từng phần và nút Back quay lại đúng Hub này.
class DomainHubPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;
  final NvidiaApiClient? nvidiaApiClient;

  const DomainHubPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
    this.nvidiaApiClient,
  });

  @override
  State<DomainHubPage> createState() => _DomainHubPageState();
}

class _DomainHubPageState extends State<DomainHubPage> {
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  late Future<List<Assessment>> _descriptionsFuture;

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
  Widget build(BuildContext context) {
    final intro = _domainIntroText[widget.linhVuc] ?? 'Đánh giá các biểu hiện phát triển của trẻ trong lĩnh vực này.';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.linhVucLabel} — ${widget.child.name}'),
      ),
      body: FutureBuilder<List<Assessment>>(
        future: _descriptionsFuture,
        builder: (context, snapshot) {
          final descriptions = snapshot.data ?? const [];
          final hasDescription = descriptions.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Khái niệm lĩnh vực',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        intro,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Các phần đánh giá & tham khảo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Bạn có thể vào bất kỳ phần nào trước để tham khảo hoặc ghi nhận biểu hiện.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),

              // 1. Thẻ Mô tả biểu hiện (Nhấn mạnh trực quan: Quan trọng / Dữ liệu chính)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DescriptionPage(
                          child: widget.child,
                          linhVuc: widget.linhVuc,
                          linhVucLabel: widget.linhVucLabel,
                          nvidiaApiClient: widget.nvidiaApiClient,
                        ),
                      ),
                    );
                    _reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit_note_outlined,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Mô tả biểu hiện của trẻ',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Quan trọng',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasDescription
                                        ? 'Đã có ${descriptions.length} ghi nhận biểu hiện'
                                        : 'Chưa có ghi nhận nào',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: hasDescription ? Colors.green : Theme.of(context).hintColor,
                                          fontWeight: hasDescription ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ghi nhận những gì bạn quan sát được hàng ngày về bé. Đây là dữ liệu thực tế duy nhất dùng để đánh giá và tổng hợp chân dung của trẻ.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Thẻ So sánh với trẻ cùng độ tuổi
              _HubNavigationCard(
                icon: Icons.compare_arrows_outlined,
                title: 'So sánh với trẻ cùng độ tuổi',
                subtitle: 'Xem các biểu hiện thường gặp và những điểm cần quan sát thêm ở độ tuổi này.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ComparisonVideoPage(
                      child: widget.child,
                      linhVuc: widget.linhVuc,
                      linhVucLabel: widget.linhVucLabel,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Thẻ Chia sẻ từ phụ huynh
              _HubNavigationCard(
                icon: Icons.groups_outlined,
                title: 'Chia sẻ từ phụ huynh',
                subtitle: 'Tham khảo góc nhìn và kinh nghiệm thực tế từ các phụ huynh khác trong các tình huống hàng ngày.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ParentInputPage(
                      child: widget.child,
                      linhVuc: widget.linhVuc,
                      linhVucLabel: widget.linhVucLabel,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Thẻ Thông tin từ bác sĩ
              _HubNavigationCard(
                icon: Icons.medical_services_outlined,
                title: 'Thông tin từ bác sĩ',
                subtitle: 'Tra cứu mốc phát triển y khoa, các dấu hiệu cần lưu ý và giải thích chuyên môn.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExpertInputPage(
                      child: widget.child,
                      linhVuc: widget.linhVuc,
                      linhVucLabel: widget.linhVucLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
}

class _HubNavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubNavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
