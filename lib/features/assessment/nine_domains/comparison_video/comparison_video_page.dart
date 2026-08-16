import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/expert_knowledge_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';
import '../../../../domain/services/video_manifest_service.dart';
import 'comparison_detail_page.dart';
import 'video_illustration_player_page.dart';

/// "So sánh nhanh": đọc `expert_knowledge_chunks` (content_type='so_sanh')
/// đúng theo lĩnh vực + độ tuổi trẻ (qua `childAgeInMonths()`), tách thành 2
/// TAB theo `phan_loai` — mỗi tab gọi riêng `ExpertKnowledgeRepository.query`
/// với đúng `phanLoai` tương ứng ('binh_thuong'/'roi_loan_pho_tu_ky'), hiển
/// thị dạng danh sách (không ghép cặp theo hàng bảng). "Xem chi tiết so
/// sánh" mở [ComparisonDetailPage], màn đó tự truy vấn lại theo tab riêng.
class ComparisonVideoPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const ComparisonVideoPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<ComparisonVideoPage> createState() => _ComparisonVideoPageState();
}

class _ComparisonVideoPageState extends State<ComparisonVideoPage>
    with SingleTickerProviderStateMixin {
  final _expertKnowledgeRepository = ExpertKnowledgeRepository(
    AppDatabase.instance,
  );
  late final TabController _tabController;
  late Future<ComparisonTabData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataFuture = loadComparisonTabData(
      repository: _expertKnowledgeRepository,
      child: widget.child,
      linhVuc: widget.linhVuc,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.linhVucLabel} — So sánh nhanh'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trẻ bình thường'),
            Tab(text: 'Trẻ tự kỷ'),
          ],
        ),
      ),
      body: FutureBuilder<ComparisonTabData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được dữ liệu so sánh: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'So sánh nhanh (${formatAgeLabel(widget.child)})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ComparisonItemList(
                      items: data.binhThuong,
                      emptyText:
                          'Chưa có dữ liệu so sánh cho trẻ bình thường ở lĩnh vực này, độ tuổi hiện tại.',
                    ),
                    ComparisonItemList(
                      items: data.roiLoanPhoTuKy,
                      emptyText:
                          'Chưa có dữ liệu so sánh cho trẻ tự kỷ ở lĩnh vực này, độ tuổi hiện tại.',
                    ),
                  ],
                ),
              ),
              if (data.hasAny)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ComparisonDetailPage(
                            child: widget.child,
                            linhVuc: widget.linhVuc,
                            linhVucLabel: widget.linhVucLabel,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('Xem chi tiết so sánh'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Thông tin này chỉ mang tính tham khảo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dữ liệu 2 tab "So sánh" đã tải sẵn — tách theo `phan_loai` bằng query SQL
/// riêng cho từng tab (KHÔNG ghép entry theo `cap_doi_id`/theo hàng bảng —
/// 2 trường đó không tồn tại trong schema DB, chỉ có trong JSON nguồn lúc
/// soạn nội dung).
class ComparisonTabData {
  final List<ExpertKnowledgeChunk> binhThuong;
  final List<ExpertKnowledgeChunk> roiLoanPhoTuKy;

  const ComparisonTabData({
    required this.binhThuong,
    required this.roiLoanPhoTuKy,
  });

  bool get hasAny => binhThuong.isNotEmpty || roiLoanPhoTuKy.isNotEmpty;
}

/// Tải dữ liệu 2 tab cho [linhVuc] + độ tuổi hiện tại của [child] — dùng
/// chung cho cả "So sánh nhanh" ([ComparisonVideoPage]) và "So sánh chi
/// tiết" ([ComparisonDetailPage]).
Future<ComparisonTabData> loadComparisonTabData({
  required ExpertKnowledgeRepository repository,
  required Child child,
  required String linhVuc,
}) async {
  final ageInMonths = childAgeInMonths(child);
  final results = await Future.wait([
    repository.query(
      linhVuc: linhVuc,
      ageInMonths: ageInMonths,
      contentType: 'so_sanh',
      phanLoai: 'binh_thuong',
    ),
    repository.query(
      linhVuc: linhVuc,
      ageInMonths: ageInMonths,
      contentType: 'so_sanh',
      phanLoai: 'roi_loan_pho_tu_ky',
    ),
    // Nạp cùng lúc — VideoManifestService cache lại nên các lần gọi sau
    // (màn "Chi tiết so sánh" mở tiếp theo) không đọc lại file.
    VideoManifestService.loadVideoPaths(),
  ]);
  return ComparisonTabData(
    binhThuong: results[0] as List<ExpertKnowledgeChunk>,
    roiLoanPhoTuKy: results[1] as List<ExpertKnowledgeChunk>,
  );
}

/// Danh sách entry của 1 tab — mỗi dòng = 1 entry riêng biệt, KHÔNG dùng
/// bảng 2/3 cột ghép cặp. Hiện thông báo trống riêng cho tab khi rỗng.
class ComparisonItemList extends StatelessWidget {
  final List<ExpertKnowledgeChunk> items;
  final String emptyText;

  const ComparisonItemList({
    super.key,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = items[index];
        final videoPath = VideoManifestService.getVideoPathForId(item.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.content),
            if (videoPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoIllustrationPlayerPage(
                          assetPath: videoPath,
                          title: 'Video minh hoạ',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Xem video minh hoạ'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
