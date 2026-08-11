/// 1 trong 9 lĩnh vực đánh giá (Bước 4-6 roadmap). [code] khớp giá trị
/// `linh_vuc` lưu trong `assessments`/`profile_chunks`/`expert_knowledge_chunks`
/// và tên thư mục trong `assets/videos/`.
class NineDomain {
  final String code;
  final String label;

  const NineDomain({required this.code, required this.label});
}

/// Đúng thứ tự liệt kê trong roadmap mục 1: "Hành vi, Nhận thức, Cảm xúc,
/// Giác quan, Quan hệ xã hội, Ngôn ngữ, Ứng xử, Sinh học, Sinh hoạt cá nhân".
const List<NineDomain> nineDomains = [
  NineDomain(code: 'hanh_vi', label: 'Hành vi'),
  NineDomain(code: 'nhan_thuc', label: 'Nhận thức'),
  NineDomain(code: 'cam_xuc', label: 'Cảm xúc'),
  NineDomain(code: 'giac_quan', label: 'Giác quan'),
  NineDomain(code: 'quan_he_xa_hoi', label: 'Quan hệ xã hội'),
  NineDomain(code: 'ngon_ngu', label: 'Ngôn ngữ'),
  NineDomain(code: 'ung_xu', label: 'Ứng xử'),
  NineDomain(code: 'sinh_hoc', label: 'Sinh học'),
  NineDomain(code: 'sinh_hoat_ca_nhan', label: 'Sinh hoạt cá nhân'),
];
