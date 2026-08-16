/// Bảng `screening_domain_scores` — lưu điểm tổng hợp cho từng lĩnh vực (7 lĩnh vực)
/// của 1 bài sàng lọc.
/// `diem_phan_tram` là NULL nếu `so_cau_hop_le` = 0 (toàn bộ câu trong lĩnh vực đều N/A).
const String screeningDomainScoresTableCreate = '''
CREATE TABLE screening_domain_scores (
  id TEXT PRIMARY KEY,
  screening_id TEXT NOT NULL REFERENCES screenings(id),
  linh_vuc TEXT NOT NULL,
  so_cau_thiet_ke INTEGER NOT NULL,
  so_cau_hop_le INTEGER NOT NULL,
  diem_tho INTEGER NOT NULL,
  diem_phan_tram REAL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_domain_scores_screening ON screening_domain_scores(screening_id);
''';
