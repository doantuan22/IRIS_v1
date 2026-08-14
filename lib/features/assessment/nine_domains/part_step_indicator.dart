import 'package:flutter/material.dart';

/// Chỉ báo "Phần x/5" dùng chung cho 5 màn tổng quan thuộc chuỗi Bước 6
/// (đánh giá chi tiết 1 lĩnh vực) — không áp dụng cho các màn "chi tiết"
/// drill-down (VD `ComparisonDetailPage`, `ExpertDetailPage`...) vì các màn
/// đó không nằm trong chuỗi điều hướng tuần tự 1→2→3→4→5.
class PartStepIndicator extends StatelessWidget {
  final int step;

  const PartStepIndicator({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Phần $step/5',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}
