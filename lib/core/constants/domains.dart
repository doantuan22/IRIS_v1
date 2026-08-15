/// 1 trong 7 lĩnh vực đánh giá. [code] khớp giá trị
/// `linh_vuc` lưu trong `assessments`/`profile_chunks`/`expert_knowledge_chunks`
/// và tên thư mục trong `assets/videos/`.
class Domain {
  final String code;
  final String label;

  const Domain({required this.code, required this.label});
}

/// Đúng thứ tự 7 lĩnh vực đánh giá:
/// Nhận thức, Cảm xúc, Giác quan, Quan hệ xã hội (gộp ý nghĩa Ứng xử),
/// Ngôn ngữ, Sinh học, Sinh hoạt cá nhân.
/// (Đã loại bỏ "Hành vi" và gộp "Ứng xử" vào "Quan hệ xã hội").
const List<Domain> domains = [
  Domain(code: 'nhan_thuc', label: 'Nhận thức'),
  Domain(code: 'cam_xuc', label: 'Cảm xúc'),
  Domain(code: 'giac_quan', label: 'Giác quan'),
  Domain(code: 'quan_he_xa_hoi', label: 'Quan hệ xã hội'),
  Domain(code: 'ngon_ngu', label: 'Ngôn ngữ'),
  Domain(code: 'sinh_hoc', label: 'Sinh học'),
  Domain(code: 'sinh_hoat_ca_nhan', label: 'Sinh hoạt cá nhân'),
];
