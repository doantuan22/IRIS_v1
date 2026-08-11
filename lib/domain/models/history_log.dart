/// Model 1 mốc trong lịch sử tổng hợp, ánh xạ tới bảng `history_logs`.
/// [eventType]: 'sang_loc' / 'danh_gia' / 'video' / 'ho_so'.
class HistoryLog {
  final String id;
  final String childId;
  final String eventType;
  final String? description;
  final DateTime eventDate;

  const HistoryLog({
    required this.id,
    required this.childId,
    required this.eventType,
    this.description,
    required this.eventDate,
  });
}
