/// Bảng `screening_sessions` — 1 dòng/lần làm bài sàng lọc mới (4 mức
/// tuổi × 20 câu × 5 lĩnh vực), thay thế hoàn toàn bảng `screenings` cũ
/// (bộ 50 câu/7 lĩnh vực, đã xóa ở migration version 12).
///
/// `tong_diem_60` NULL khi bất kỳ lĩnh vực nào trong 5 lĩnh vực chưa đủ dữ
/// liệu (`screening_domain_results.muc_linh_vuc = 'chua_du_du_lieu'`).
/// `giai_doan` là 1 trong '1'/'2'/'3'/'chua_du_du_lieu' — tính 100% bằng
/// code thuần (`ScreeningScoringService`), không suy diễn thêm.
/// `co_canh_bao` — LỊCH SỬ: từng là cờ "mất kỹ năng đã từng có / lo ngại
/// phát triển rõ rệt" hỏi ở cuối bài làm. Màn hỏi này đã bị BỎ khỏi luồng
/// (xem `SETUP_REPORT.md`), nên cột này LUÔN nhận giá trị 0 kể từ đó — giữ
/// nguyên trong schema (không migration) để tránh đổi cấu trúc bảng không
/// cần thiết, KHÔNG còn mang ý nghĩa nghiệp vụ nào, đừng dựa vào cột này.
const String screeningSessionsTableCreate = '''
CREATE TABLE screening_sessions (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  muc_tuoi_lam_bai TEXT NOT NULL,
  tong_diem_60 REAL,
  giai_doan TEXT NOT NULL,
  co_canh_bao INTEGER NOT NULL DEFAULT 0,
  ngay_thuc_hien TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_sessions_child ON screening_sessions(child_id);
''';
