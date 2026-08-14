/// Bảng `overview_summaries` (thêm ở version 5, xem `onUpgrade` trong
/// `database.dart`) — kết quả tổng hợp mức "Chân dung toàn cảnh" cuối cùng
/// của 1 trẻ, tính 100% BẰNG CODE (`overview_tier_calculator.dart`) từ 9
/// nhãn mới nhất trong `domain_overview_labels`, KHÔNG do AI tự quyết định.
/// Mỗi lần tổng hợp thành công ghi 1 dòng MỚI (lịch sử), không UPDATE đè —
/// kết quả "hiện hành" là dòng có `computed_at` mới nhất.
///
/// `tier` CHỈ được 1 trong 3 giá trị: `'thuong_gap'` / `'can_theo_doi'` /
/// `'chuyen_mon_som'` — tương ứng đúng 3 tên hiển thị đã chốt: "Trong giới
/// hạn thường gặp" / "Có điểm cần theo dõi" / "Nên tìm đánh giá chuyên môn
/// sớm". Không có dòng nào được ghi khi chưa đủ dữ liệu để tổng hợp (xem
/// `OverviewRepository.computeAndSaveOverview`).
const String overviewSummariesTableCreate = '''
CREATE TABLE overview_summaries (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  tier TEXT NOT NULL,
  so_linh_vuc_can_theo_doi INTEGER NOT NULL,
  so_linh_vuc_thieu_du_lieu INTEGER NOT NULL,
  computed_at TEXT NOT NULL
);

CREATE INDEX idx_overview_summaries_child ON overview_summaries(child_id, computed_at);
''';
