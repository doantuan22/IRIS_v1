/// Bảng `screening_responses` — lưu chi tiết câu trả lời cho từng câu hỏi
/// trong bài sàng lọc 50 câu (khớp id trong JSON, VD "sl50_q01").
/// Giá trị: '0' / '1' / '2' / 'N/A'.
const String screeningResponsesTableCreate = '''
CREATE TABLE screening_responses (
  id TEXT PRIMARY KEY,
  screening_id TEXT NOT NULL REFERENCES screenings(id),
  cau_hoi_id TEXT NOT NULL,
  linh_vuc TEXT NOT NULL,
  gia_tri TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_responses_screening ON screening_responses(screening_id);
''';
