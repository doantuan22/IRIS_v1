/// Bảng `screening_domain_results` — điểm tổng hợp theo TỪNG lĩnh vực (5
/// lĩnh vực: `ngon_ngu_giao_tiep`/`nhan_thuc_giai_quyet_van_de`/`van_dong`/
/// `xa_hoi_cam_xuc`/`tu_lap`) của 1 lần làm bài sàng lọc mới, thay thế
/// bảng `screening_domain_scores` cũ (đã xóa ở migration version 12).
///
/// `diem_quy_doi_12` NULL khi `so_cau_tra_loi < 3` (lĩnh vực có ≥2/4 câu
/// N/A) — quy tắc: đủ dữ liệu khi ≥3/4 câu có điểm 0-3. Công thức quy đổi
/// (chỉ áp dụng khi đủ dữ liệu):
/// `diem_quy_doi_12 = diem_tho / (3 * so_cau_tra_loi) * 12`, làm tròn 1
/// chữ số thập phân — xem `ScreeningScoringService`.
const String screeningDomainResultsTableCreate = '''
CREATE TABLE screening_domain_results (
  id TEXT PRIMARY KEY,
  screening_id TEXT NOT NULL REFERENCES screening_sessions(id),
  child_id TEXT NOT NULL REFERENCES children(id),
  linh_vuc TEXT NOT NULL,
  diem_tho INTEGER NOT NULL,
  so_cau_tra_loi INTEGER NOT NULL,
  so_cau_na INTEGER NOT NULL,
  diem_quy_doi_12 REAL,
  muc_linh_vuc TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_domain_results_screening ON screening_domain_results(screening_id);
''';
