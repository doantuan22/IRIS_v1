/// Model chunk dữ liệu tham khảo, ánh xạ tới bảng `expert_knowledge_chunks`.
/// Nội dung tĩnh do nhóm phát triển biên soạn/thu thập sẵn, dùng chung cho
/// mọi trẻ, gồm 4 loại: so_sanh / chia_se_phu_huynh / bac_si / chan_dung.
///
/// [doTuoiThangMin]/[doTuoiThangMax] tính theo THÁNG tuổi (khớp mốc các
/// công cụ sàng lọc thực tế) — KHÔNG cùng đơn vị với `Child.ageYears` (năm).
/// Dùng `childAgeInMonths()` để quy đổi trước khi so sánh.
class ExpertKnowledgeChunk {
  final String id;
  final String content;
  final String contentType;
  final String? linhVuc;
  final int? doTuoiThangMin;
  final int? doTuoiThangMax;
  final String? nguonTaiLieu;
  final List<double> embedding;

  const ExpertKnowledgeChunk({
    required this.id,
    required this.content,
    required this.contentType,
    this.linhVuc,
    this.doTuoiThangMin,
    this.doTuoiThangMax,
    this.nguonTaiLieu,
    required this.embedding,
  });
}
