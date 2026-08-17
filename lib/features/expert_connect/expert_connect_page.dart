import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/iris_assets.dart';
import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
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

  const _NeedInfo({
    required this.title,
    required this.description,
    required this.icon,
  });
}

const Map<_NeedLevel, _NeedInfo> _needInfo = {
  _NeedLevel.insufficient: _NeedInfo(
    title: 'Chưa có đủ thông tin',
    description:
        'Hồ sơ chưa có kết quả sàng lọc và chưa có mô tả cho lĩnh vực nào. '
        'Nên thực hiện sàng lọc hoặc bắt đầu mô tả biểu hiện trước khi liên hệ trung tâm.',
    icon: Icons.info_outline,
  ),
  _NeedLevel.monitor: _NeedInfo(
    title: 'Có dấu hiệu cần theo dõi',
    description:
        'Hồ sơ đã có một số dữ liệu sàng lọc/đánh giá. Nên liên hệ chuyên gia để được đánh giá chuyên sâu hơn.',
    icon: Icons.visibility_outlined,
  ),
  _NeedLevel.detailed: _NeedInfo(
    title: 'Đã có kết quả đánh giá đầy đủ hơn',
    description:
        'Hồ sơ đã có khá đầy đủ dữ liệu đánh giá. Nên liên hệ trung tâm dưới đây để được tư vấn can thiệp/hỗ trợ cụ thể.',
    icon: Icons.fact_check_outlined,
  ),
};

const String _notDiagnosisDisclaimer =
    'Thông tin trung tâm dưới đây chỉ mang tính tham khảo để liên hệ, không phải chỉ định hay chẩn đoán y khoa. '
    'Quyết định thăm khám/can thiệp nên dựa trên tư vấn trực tiếp từ chuyên gia/trung tâm.';

const String _tuongMinhWebsite = 'https://tuongminhcenter.com.vn/';

/// Bước 14 — "Kết nối chuyên gia/trung tâm": banner phân loại nhu cầu (tính
/// bằng code thuần dựa trên dữ liệu thật của trẻ, KHÔNG dùng AI) + thông tin
/// liên hệ THẬT của đúng 1 trung tâm — Trung Tâm Hỗ Trợ Phát Triển Giáo Dục
/// Hòa Nhập Tường Minh (tuongminhcenter.com.vn). Dữ liệu trung tâm đã được
/// xác minh thủ công từ website chính thức, không bịa thêm chi tiết ngoài
/// những gì đã xác minh (không có giờ làm việc/giá cả trong dữ liệu nguồn
/// nên không hiển thị các trường đó).
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

  /// Phân loại nhu cầu bằng code thuần — đơn giản hoá có chủ đích từ 5
  /// trường hợp gốc xuống còn 3 mức, vì dữ liệu hiện có (đã sàng lọc?/số
  /// lĩnh vực đã mô tả/đã có video được chuyên gia xem hay chưa) không đủ
  /// chi tiết để phân biệt rạch ròi hơn 3 mức. Ngưỡng "≥5/9 lĩnh vực" (quá
  /// bán) cho mức "đầy đủ hơn" là lựa chọn tự chọn hợp lý, không có sẵn
  /// trong tài liệu gốc. Logic này được TÁI SỬ DỤNG nguyên vẹn từ bản trước
  /// — chỉ dùng để tạo thông điệp đi kèm, nơi liên hệ luôn là đúng 1 trung
  /// tâm thật bên dưới (không còn khái niệm nhiều lựa chọn để lọc).
  Future<_NeedLevel> _determineNeedLevel() async {
    final hasScreening = await _screeningRepository.hasScreening(
      widget.child.id,
    );
    final assessments = await _assessmentRepository.getForChild(
      widget.child.id,
    );
    final doneDomainCount = assessments
        .where((a) => a.contentType == 'mo_ta')
        .map((a) => a.linhVuc)
        .toSet()
        .length;
    final videos = await _videoRepository.getForChild(widget.child.id);
    final hasReviewedVideo = videos.any((v) => v.status == 'reviewed');

    if (!hasScreening && doneDomainCount == 0) return _NeedLevel.insufficient;
    if (doneDomainCount >= 5 || hasReviewedVideo) return _NeedLevel.detailed;
    return _NeedLevel.monitor;
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_tuongMinhWebsite);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở website. Vui lòng thử lại.')),
      );
    }
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
          return ListView(
            padding: IrisSpacing.page,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IrisAssetIcon(asset: IrisAssets.iconExpert),
                      const SizedBox(width: IrisSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
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
              Text(
                'Trung tâm liên hệ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _TuongMinhCenterCard(onOpenWebsite: _openWebsite),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: IrisRadii.inputBorder,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _notDiagnosisDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TuongMinhCenterCard extends StatelessWidget {
  final VoidCallback onOpenWebsite;

  const _TuongMinhCenterCard({required this.onOpenWebsite});

  static const _addresses = [
    'CS1: Số 37, đường 2, Khu đô thị Vạn Phúc, Hiệp Bình Phước, TP. Thủ Đức',
    'CS2: Số 449/41, đường Trường Chinh, P.14, Q. Tân Bình, TP.HCM',
    'CS3: Số 25, đường 44, P. Tân Phong, Q.7, TP.HCM',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: IrisSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IrisIconChip(
                  icon: Icons.school_outlined,
                  color: IrisColors.primary,
                ),
                const SizedBox(width: IrisSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trung Tâm Hỗ Trợ Phát Triển Giáo Dục Hòa Nhập Tường Minh',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trung tâm Giáo dục Tường Minh',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Thành lập 15/12/2016, chuyên can thiệp cho trẻ tự kỷ và trẻ có '
              'rối loạn phát triển khác. Đội ngũ chuyên gia và giáo dục viên '
              'nhiều kinh nghiệm trong chăm sóc và can thiệp trẻ tự kỷ.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final address in _addresses) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '0919 795 574 – 0827 377 607 – 0942 211 000',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'trungtamtuongminhthuduc@gmail.com',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenWebsite,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Truy cập website'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
