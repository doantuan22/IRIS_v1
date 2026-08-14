import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/screening_repository.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/models/child.dart';

enum _NeedLevel { insufficient, monitor, detailed }

class _NeedInfo {
  final String title;
  final String description;
  final IconData icon;

  const _NeedInfo({required this.title, required this.description, required this.icon});
}

const Map<_NeedLevel, _NeedInfo> _needInfo = {
  _NeedLevel.insufficient: _NeedInfo(
    title: 'Chưa có đủ thông tin',
    description:
        'Hồ sơ chưa có kết quả sàng lọc và chưa có mô tả cho lĩnh vực nào. '
        'Nên thực hiện sàng lọc hoặc bắt đầu mô tả biểu hiện trước khi tìm đơn vị hỗ trợ.',
    icon: Icons.info_outline,
  ),
  _NeedLevel.monitor: _NeedInfo(
    title: 'Có dấu hiệu cần theo dõi',
    description: 'Hồ sơ đã có một số dữ liệu sàng lọc/đánh giá. Nên gặp chuyên gia để được đánh giá chuyên sâu hơn.',
    icon: Icons.visibility_outlined,
  ),
  _NeedLevel.detailed: _NeedInfo(
    title: 'Đã có kết quả đánh giá đầy đủ hơn',
    description: 'Hồ sơ đã có khá đầy đủ dữ liệu đánh giá. Có thể tham khảo các dịch vụ can thiệp/hỗ trợ cụ thể dưới đây.',
    icon: Icons.fact_check_outlined,
  ),
};

class _ProviderInfo {
  final String name;
  final String description;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final IconData icon;

  const _ProviderInfo({
    required this.name,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.icon,
  });
}

/// Danh sách tĩnh, đóng gói sẵn trong app — KHÔNG phải kết nối thật tới
/// dịch vụ/API bên ngoài, đúng quyết định kiến trúc đã chốt từ đầu dự án
/// ("mô phỏng trong phạm vi 1 thiết bị"). 4 mục đầu hiện mặc định, 2 mục
/// sau hiện khi bấm "Xem thêm gợi ý phù hợp".
const List<_ProviderInfo> _providers = [
  _ProviderInfo(
    name: 'Trung tâm Can thiệp sớm Ánh Dương',
    description: 'Trung tâm can thiệp sớm — phù hợp trẻ 18 tháng - 6 tuổi',
    rating: 4.6,
    reviewCount: 128,
    distanceKm: 1.2,
    icon: Icons.child_care_outlined,
  ),
  _ProviderInfo(
    name: 'Phòng khám Nhi khoa - Phát triển An Khang',
    description: 'Phòng khám nhi / phát triển trẻ nhỏ — khám & tư vấn trẻ 0-10 tuổi',
    rating: 4.4,
    reviewCount: 96,
    distanceKm: 2.5,
    icon: Icons.local_hospital_outlined,
  ),
  _ProviderInfo(
    name: 'ThS. Nguyễn Thị Lan — Chuyên gia Tâm lý - Giáo dục',
    description: 'Chuyên gia tâm lý - giáo dục — tư vấn 1-1, trẻ 2-12 tuổi',
    rating: 4.9,
    reviewCount: 64,
    distanceKm: 3.8,
    icon: Icons.psychology_outlined,
  ),
  _ProviderInfo(
    name: 'Trường Mầm non Hoà nhập Mặt Trời Nhỏ',
    description: 'Trường mầm non hoà nhập — trẻ 2-6 tuổi',
    rating: 4.3,
    reviewCount: 41,
    distanceKm: 4.6,
    icon: Icons.school_outlined,
  ),
  _ProviderInfo(
    name: 'Trung tâm Can thiệp sớm Bình Minh',
    description: 'Trung tâm can thiệp sớm — phù hợp trẻ 2-7 tuổi',
    rating: 4.5,
    reviewCount: 87,
    distanceKm: 5.1,
    icon: Icons.child_care_outlined,
  ),
  _ProviderInfo(
    name: 'Bệnh viện Nhi Đồng — Khoa Tâm lý',
    description: 'Khoa tâm lý bệnh viện nhi — khám & đánh giá chuyên sâu',
    rating: 4.2,
    reviewCount: 210,
    distanceKm: 6.3,
    icon: Icons.local_hospital_outlined,
  ),
];

/// Bước 14 — "Kết nối chuyên gia/trung tâm": banner phân loại nhu cầu (tính
/// bằng code thuần dựa trên dữ liệu thật của trẻ, KHÔNG dùng AI) + danh sách
/// đơn vị/dịch vụ đề xuất (dữ liệu tĩnh minh hoạ, đóng gói sẵn trong app).
class ExpertConnectPage extends StatefulWidget {
  final Child child;

  const ExpertConnectPage({super.key, required this.child});

  @override
  State<ExpertConnectPage> createState() => _ExpertConnectPageState();
}

class _ExpertConnectPageState extends State<ExpertConnectPage> {
  final _screeningRepository = ScreeningRepository(AppDatabase.instance);
  final _assessmentRepository = AssessmentRepository(AppDatabase.instance);
  final _videoRepository = VideoRepository(AppDatabase.instance);

  late final Future<_NeedLevel> _needLevelFuture = _determineNeedLevel();
  bool _showMore = false;

  /// Phân loại nhu cầu bằng code thuần — đơn giản hoá có chủ đích từ 5
  /// trường hợp gốc xuống còn 3 mức, vì dữ liệu hiện có (đã sàng lọc?/số
  /// lĩnh vực đã mô tả/đã có video được chuyên gia xem hay chưa) không đủ
  /// chi tiết để phân biệt rạch ròi hơn 3 mức. Ngưỡng "≥5/9 lĩnh vực" (quá
  /// bán) cho mức "đầy đủ hơn" là lựa chọn tự chọn hợp lý, không có sẵn
  /// trong tài liệu gốc.
  Future<_NeedLevel> _determineNeedLevel() async {
    final hasScreening = await _screeningRepository.hasScreening(widget.child.id);
    final assessments = await _assessmentRepository.getForChild(widget.child.id);
    final doneDomainCount =
        assessments.where((a) => a.contentType == 'mo_ta').map((a) => a.linhVuc).toSet().length;
    final videos = await _videoRepository.getForChild(widget.child.id);
    final hasReviewedVideo = videos.any((v) => v.status == 'reviewed');

    if (!hasScreening && doneDomainCount == 0) return _NeedLevel.insufficient;
    if (doneDomainCount >= 5 || hasReviewedVideo) return _NeedLevel.detailed;
    return _NeedLevel.monitor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết nối chuyên gia/trung tâm')),
      body: FutureBuilder<_NeedLevel>(
        future: _needLevelFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = _needInfo[snapshot.data!]!;
          final visibleProviders = _showMore ? _providers : _providers.take(4).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(info.icon, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(info.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(info.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Đơn vị/dịch vụ đề xuất', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...visibleProviders.map((provider) => _ProviderCard(provider: provider)),
              if (!_showMore && _providers.length > 4)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showMore = true),
                    child: const Text('Xem thêm gợi ý phù hợp'),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Đây là danh sách minh hoạ, chưa phải dữ liệu đơn vị/chuyên gia thật.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final _ProviderInfo provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(provider.icon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(provider.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.rating} (${provider.reviewCount} đánh giá)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text('${provider.distanceKm} km', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
