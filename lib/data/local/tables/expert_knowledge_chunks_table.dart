/// Bảng `expert_knowledge_chunks` — nội dung tham khảo dùng chung cho mọi trẻ
/// (tĩnh, do nhóm phát triển biên soạn/thu thập sẵn), gồm 4 loại nội dung:
/// so_sanh / chia_se_phu_huynh / bac_si / chan_dung. Hai loại sau chỉ khác
/// nhau về văn phong trình bày, không phải nội dung do phụ huynh/bác sĩ thật
/// đăng trực tiếp.
const String expertKnowledgeChunksTableCreate = '''
CREATE TABLE expert_knowledge_chunks (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  content_type TEXT NOT NULL,
  linh_vuc TEXT,
  do_tuoi_thang_min INTEGER,
  do_tuoi_thang_max INTEGER,
  nguon_tai_lieu TEXT,
  embedding BLOB NOT NULL
);
''';
