/// Bảng `domain_overview_labels` (thêm ở version 5, xem `onUpgrade` trong
/// `database.dart`) — nhãn tổng quan CHO TỪNG LĨNH VỰC trong 7 lĩnh vực của
/// 1 trẻ, dùng để tổng hợp "Chân dung toàn cảnh". Mỗi lần gắn nhãn ghi 1
/// dòng MỚI (lịch sử theo thời gian qua `computed_at`), không UPDATE đè —
/// nhãn "hiện hành" của 1 (child_id, linh_vuc) là dòng có `computed_at` mới
/// nhất.
///
/// `nhan` do AI hỗ trợ gắn (xem `OverviewRepository`) nhưng CHỈ được 1 trong
/// 3 giá trị: `'thuong_gap'` / `'can_theo_doi'` / `'chua_du_du_lieu'` — AI
/// KHÔNG được tự quyết định mức tổng quan cuối cùng, chỉ gắn nhãn từng lĩnh
/// vực; mức cuối cùng tính ở `overview_tier_calculator.dart` (100% code).
///
/// `ly_do_ngan_gon` là lời giải thích ngắn do AI sinh ra kèm nhãn, hiển thị
/// được cho người dùng — có thể `NULL` khi nhãn là `'chua_du_du_lieu'` do
/// code gán cứng (không gọi AI, xem `OverviewRepository.labelDomain`).
const String domainOverviewLabelsTableCreate = '''
CREATE TABLE domain_overview_labels (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  linh_vuc TEXT NOT NULL,
  nhan TEXT NOT NULL,
  ly_do_ngan_gon TEXT,
  computed_at TEXT NOT NULL
);

CREATE INDEX idx_domain_overview_labels_child ON domain_overview_labels(child_id, linh_vuc, computed_at);
''';
