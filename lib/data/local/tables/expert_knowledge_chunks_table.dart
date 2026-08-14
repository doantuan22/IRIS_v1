/// Bảng `expert_knowledge_chunks` — nội dung tham khảo dùng chung cho mọi trẻ
/// (tĩnh, do nhóm phát triển biên soạn/thu thập sẵn), gồm 4 loại nội dung:
/// so_sanh / chia_se_phu_huynh / bac_si / chan_dung. Hai loại sau chỉ khác
/// nhau về văn phong trình bày, không phải nội dung do phụ huynh/bác sĩ thật
/// đăng trực tiếp.
///
/// `phan_loai` (thêm ở version 3, xem `onUpgrade` trong `database.dart`) —
/// CHỈ áp dụng cho `content_type='so_sanh'`: `'thuong_gap'` (biểu hiện
/// thường gặp ở độ tuổi) hoặc `'can_quan_sat'` (cần quan sát thêm); `NULL`
/// cho mọi loại nội dung khác hoặc entry `so_sanh` chưa phân loại.
///
/// `nhom_tre`/`boi_canh` (thêm ở version 4) — CHỈ áp dụng cho
/// `content_type='chia_se_phu_huynh'`: `nhom_tre` là `'binh_thuong'` /
/// `'asd'` / `NULL`; `boi_canh` là `'o_nha'` / `'o_truong'` /
/// `'noi_cong_cong'` / `NULL`. `NULL` cho mọi loại nội dung khác.
const String expertKnowledgeChunksTableCreate = '''
CREATE TABLE expert_knowledge_chunks (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  content_type TEXT NOT NULL,
  phan_loai TEXT,
  nhom_tre TEXT,
  boi_canh TEXT,
  linh_vuc TEXT,
  do_tuoi_thang_min INTEGER,
  do_tuoi_thang_max INTEGER,
  nguon_tai_lieu TEXT,
  embedding BLOB NOT NULL
);
''';
