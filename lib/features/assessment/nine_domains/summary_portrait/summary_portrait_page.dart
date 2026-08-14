import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/expert_knowledge_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/expert_knowledge_chunk.dart';
import '../part_step_indicator.dart';
import '../saved_result_page.dart';
import 'summary_detail_page.dart';

/// Phần 5/5 (cuối cùng) — "Chân dung biểu hiện": đọc `expert_knowledge_chunks`
/// (content_type='chan_dung') đúng theo lĩnh vực + độ tuổi trẻ. Bố cục gốc
/// là sơ đồ mindmap toả tròn — đã CHỦ ĐỘNG đơn giản hoá thành danh sách +
/// lưới thẻ màu phân loại (xem [SummaryDetailPage]) để ưu tiên đúng chức
/// năng, giữ nguyên ý nghĩa phân loại nội dung.
///
/// Vì các Phần 2-5 đều dùng `pushReplacement` nối tiếp nhau, ngăn xếp hiện
/// tại chỉ có đúng 1 route (trang này) nằm trên `DomainListPage`. Nút
/// "Hoàn tất" giờ `pushReplacement` sang `SavedResultPage` (Bước 7) thay vì
/// `pop()` thẳng — vẫn giữ đúng bất biến "chỉ 1 route trên DomainListPage",
/// nên `SavedResultPage` chỉ cần 1 lần `pop()` để quay đúng về danh sách 9
/// lĩnh vực.
class SummaryPortraitPage extends StatefulWidget {
  final Child child;
  final String linhVuc;
  final String linhVucLabel;

  const SummaryPortraitPage({
    super.key,
    required this.child,
    required this.linhVuc,
    required this.linhVucLabel,
  });

  @override
  State<SummaryPortraitPage> createState() => _SummaryPortraitPageState();
}

class _SummaryPortraitPageState extends State<SummaryPortraitPage> {
  final _expertKnowledgeRepository = ExpertKnowledgeRepository(AppDatabase.instance);
  late Future<List<ExpertKnowledgeChunk>> _chunksFuture;

  @override
  void initState() {
    super.initState();
    _chunksFuture = _load();
  }

  Future<List<ExpertKnowledgeChunk>> _load() {
    return _expertKnowledgeRepository.query(
      linhVuc: widget.linhVuc,
      ageInMonths: childAgeInMonths(widget.child),
      contentType: 'chan_dung',
    );
  }

  void _openDetail(List<ExpertKnowledgeChunk> chunks) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SummaryDetailPage(
          child: widget.child,
          linhVucLabel: widget.linhVucLabel,
          chunks: chunks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.linhVucLabel} — Chân dung biểu hiện')),
      body: FutureBuilder<List<ExpertKnowledgeChunk>>(
        future: _chunksFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được dữ liệu chân dung: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chunks = snapshot.data!;
          final diemManh = chunks.where((c) => c.phanLoai == 'diem_manh').toList();
          final khacBiet = chunks.where((c) => c.phanLoai == 'khac_biet').toList();
          final canHoTro = chunks.where((c) => c.phanLoai == 'can_ho_tro').toList();
          final mucDoBieuHienList = chunks.where((c) => c.phanLoai == 'muc_do_bieu_hien').toList();
          final mucDoBieuHien = mucDoBieuHienList.isEmpty ? null : mucDoBieuHienList.first;
          final hasGridData = diemManh.isNotEmpty || khacBiet.isNotEmpty || canHoTro.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PartStepIndicator(step: 5),
              Text(
                'Chân dung biểu hiện (${formatAgeLabel(widget.child)})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!hasGridData && mucDoBieuHien == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Chưa có dữ liệu chân dung cho lĩnh vực này ở độ tuổi hiện tại.',
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                // Đúng thứ tự đã chốt: Điểm nổi bật → Khác biệt so với trẻ
                // cùng tuổi → Mức độ biểu hiện → nút xem chi tiết.
                _PortraitSection(
                  title: 'Điểm nổi bật',
                  icon: Icons.star_outline,
                  color: Colors.green,
                  items: diemManh,
                ),
                if (diemManh.isNotEmpty) const SizedBox(height: 20),
                _PortraitSection(
                  title: 'Khác biệt so với trẻ cùng tuổi',
                  icon: Icons.compare_arrows_outlined,
                  color: Colors.orange,
                  items: khacBiet,
                ),
                if (khacBiet.isNotEmpty) const SizedBox(height: 20),
                if (mucDoBieuHien != null) ...[
                  Text('Mức độ biểu hiện', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Icon(Icons.speed_outlined, size: 18),
                    label: Text(mucDoBieuHien.content),
                  ),
                  const SizedBox(height: 20),
                ],
                if (hasGridData)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openDetail(chunks),
                      icon: const Icon(Icons.grid_view_outlined),
                      label: const Text('Xem chân dung chi tiết'),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SavedResultPage(
                      child: widget.child,
                      linhVuc: widget.linhVuc,
                      linhVucLabel: widget.linhVucLabel,
                    ),
                  ),
                ),
                child: const Text('Hoàn tất — Về danh sách lĩnh vực'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PortraitSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<ExpertKnowledgeChunk> items;

  const _PortraitSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(c.content)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
