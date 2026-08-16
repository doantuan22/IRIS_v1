import 'package:flutter/material.dart';

import '../../../../core/theme/iris_theme.dart';
import '../../../../data/local/database.dart';
import '../../../../data/repositories/expert_knowledge_repository.dart';
import '../../../../domain/models/child.dart';
import 'comparison_video_page.dart';

/// "So sánh chi tiết": tự truy vấn lại `expert_knowledge_chunks`
/// (content_type='so_sanh') theo đúng [linhVuc] + độ tuổi trẻ, tách 2 TAB
/// theo `phan_loai` giống [ComparisonVideoPage] — KHÔNG dùng bảng "Tiêu chí
/// | Thường gặp | Cần quan sát" ghép cặp theo hàng như thiết kế cũ.
class ComparisonDetailPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const ComparisonDetailPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<ComparisonDetailPage> createState() => _ComparisonDetailPageState();
}

class _ComparisonDetailPageState extends State<ComparisonDetailPage>
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
        title: Text('${widget.linhVucLabel} — Chi tiết so sánh'),
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
                  'So sánh chi tiết (${formatAgeLabel(widget.child)})',
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: IrisRadii.inputBorder,
                  ),
                  child: const Text(
                    'Thông tin này chỉ giúp đối chiếu với trẻ cùng độ tuổi, không dùng để tự chẩn đoán.',
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
