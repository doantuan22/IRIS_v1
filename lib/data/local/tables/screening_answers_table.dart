/// Bảng `screening_answers` — câu trả lời từng câu của bài sàng lọc mới
/// (4 mức tuổi × 20 câu × 5 lĩnh vực), thay thế bảng `screening_responses`
/// cũ (đã xóa ở migration version 12).
///
/// `diem` là 0-3 (NULL nếu `la_na = 1`) — khác bảng cũ (`gia_tri TEXT` ép
/// cả '0'/'1'/'2'/'N/A' vào 1 cột chuỗi), thiết kế mới tách rõ kiểu dữ
/// liệu để không phải parse chuỗi khi tính điểm.
/// `nhom_van_dong` CHỈ áp dụng khi `linh_vuc='van_dong'`: 'tho' (vận động
/// thô) hoặc 'tinh' (vận động tinh); NULL cho 4 lĩnh vực còn lại.
const String screeningAnswersTableCreate = '''
CREATE TABLE screening_answers (
  id TEXT PRIMARY KEY,
  screening_id TEXT NOT NULL REFERENCES screening_sessions(id),
  child_id TEXT NOT NULL REFERENCES children(id),
  muc_tuoi_lam_bai TEXT NOT NULL,
  cau_hoi_id TEXT NOT NULL,
  linh_vuc TEXT NOT NULL,
  nhom_van_dong TEXT,
  diem INTEGER,
  la_na INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_answers_screening ON screening_answers(screening_id);
CREATE INDEX idx_screening_answers_child ON screening_answers(child_id);
''';
