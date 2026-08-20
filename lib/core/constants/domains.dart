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

/// Định nghĩa ngắn 1-2 câu cho mỗi lĩnh vực — dùng chung cho `DescriptionPage`
/// và `DomainHubPage` (trước đây là 2 bản sao trùng nội dung ở từng file,
/// hợp nhất về đây để tránh lệch nhau khi sửa).
const Map<String, String> domainIntroText = {
  'nhan_thuc':
      'Khả năng của trẻ trong việc hiểu, ghi nhớ, suy luận và giải quyết vấn đề phù hợp với độ tuổi.',
  'cam_xuc': 'Cách trẻ nhận biết, thể hiện và điều tiết cảm xúc của bản thân.',
  'giac_quan':
      'Cách trẻ tiếp nhận và phản ứng với các kích thích giác quan (âm thanh, ánh sáng, xúc giác...).',
  'quan_he_xa_hoi':
      'Khả năng của trẻ trong việc tương tác, giao tiếp, ứng xử, tuân thủ quy tắc và thích nghi với các tình huống xã hội.',
  'ngon_ngu':
      'Khả năng hiểu và sử dụng ngôn ngữ để giao tiếp với người xung quanh.',
  'sinh_hoc':
      'Các yếu tố phát triển thể chất và sinh học liên quan đến sự phát triển chung của trẻ.',
  'sinh_hoat_ca_nhan':
      'Khả năng tự thực hiện các hoạt động sinh hoạt cá nhân hàng ngày phù hợp với độ tuổi.',
};
