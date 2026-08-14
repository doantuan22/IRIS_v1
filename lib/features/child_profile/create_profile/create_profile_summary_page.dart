import 'package:flutter/material.dart';

import '../../../domain/models/child.dart';
import '../profile_detail/profile_detail_page.dart';

/// Màn tóm tắt hiện ngay sau khi tạo hồ sơ trẻ thành công (Bước 2) — thay vì
/// quay thẳng về danh sách/trang chủ, cho người dùng xác nhận lại thông tin
/// vừa nhập trước khi vào chi tiết hồ sơ.
class CreateProfileSummaryPage extends StatelessWidget {
  final Child child;

  const CreateProfileSummaryPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đã tạo hồ sơ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
            const SizedBox(height: 8),
            const Text(
              'Tạo hồ sơ thành công!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(label: 'Tên trẻ', value: child.name),
                    _SummaryRow(label: 'Mã hồ sơ', value: child.id),
                    _SummaryRow(label: 'Ngày sinh', value: child.dob ?? 'Chưa cập nhật'),
                    _SummaryRow(label: 'Độ tuổi', value: formatAgeLabel(child)),
                    _SummaryRow(label: 'Giới tính', value: child.gender ?? 'Chưa cập nhật'),
                    _SummaryRow(label: 'Người đánh giá', value: child.nguoiDanhGia ?? 'Chưa cập nhật'),
                    _SummaryRow(label: 'Vai trò', value: child.vaiTro ?? 'Chưa cập nhật'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileDetailPage(child: child)),
              ),
              child: const Text('Xem hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
