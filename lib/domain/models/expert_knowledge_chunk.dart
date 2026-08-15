/// Model chunk dữ liệu tham khảo, ánh xạ tới bảng `expert_knowledge_chunks`.
/// Nội dung tĩnh do nhóm phát triển biên soạn/thu thập sẵn, dùng chung cho
/// mọi trẻ, gồm 3 loại: so_sanh / chia_se_phu_huynh / bac_si.
///
/// [doTuoiThangMin]/[doTuoiThangMax] tính theo THÁNG tuổi (khớp mốc các
/// công cụ sàng lọc thực tế) — KHÔNG cùng đơn vị với `Child.ageYears` (năm).
/// Dùng `childAgeInMonths()` để quy đổi trước khi so sánh.
///
/// [phanLoai] chỉ có ý nghĩa khi [contentType] = `'so_sanh'`:
/// `'thuong_gap'` / `'can_quan_sat'` / `null` (chưa phân loại).
///
/// [nhomTre]/[boiCanh] chỉ có ý nghĩa khi [contentType] =
/// `'chia_se_phu_huynh'`: [nhomTre] là `'binh_thuong'` / `'asd'` / `null`;
/// [boiCanh] là `'o_nha'` / `'o_truong'` / `'noi_cong_cong'` / `null`.
class ExpertKnowledgeChunk {
  final String id;
  final String content;
  final String contentType;
  final String? phanLoai;
  final String? nhomTre;
  final String? boiCanh;
  final String? linhVuc;
  final int? doTuoiThangMin;
  final int? doTuoiThangMax;
  final String? nguonTaiLieu;
  final List<double> embedding;

  const ExpertKnowledgeChunk({
    required this.id,
    required this.content,
    required this.contentType,
    this.phanLoai,
    this.nhomTre,
    this.boiCanh,
    this.linhVuc,
    this.doTuoiThangMin,
    this.doTuoiThangMax,
    this.nguonTaiLieu,
    required this.embedding,
  });
}
