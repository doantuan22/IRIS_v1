# ADR 0003 — Hoãn rename thư mục `nine_domains/`

## Bối cảnh
`lib/features/assessment/nine_domains/` (gồm `comparison_video/` và
`description/`) vẫn mang tên "nine_domains" dù dự án đã chuyển từ 9 lĩnh
vực xuống 7 lĩnh vực từ trước (đã loại bỏ "Hành vi" và gộp "Ứng xử" vào
"Quan hệ xã hội" — xem `lib/core/constants/domains.dart`). Đã xác nhận
không còn logic 9-lĩnh-vực nào bên trong thư mục này — chỉ tên thư mục lỗi
thời, code hoạt động đúng cho 7 lĩnh vực hiện tại.

## Quyết định
**Hoãn** việc rename thư mục này sang tên phản ánh đúng hiện trạng (ví dụ
`domain_content/`). Chưa thực thi trong đợt chuẩn hóa này.

## Lý do
- Đây là vấn đề đặt tên (naming), không ảnh hưởng chức năng hay đúng/sai
  của code — không khẩn cấp.
- Rename đúng cách đòi hỏi `git mv` + rà soát/sửa toàn bộ `import` tham
  chiếu tới đường dẫn cũ trong `lib/`, rồi `flutter analyze` + build thử
  để xác nhận không sót import nào — nên làm như 1 tác vụ riêng, tách biệt
  khỏi các thay đổi chuẩn hóa khác trong đợt này, để dễ review/rollback
  độc lập nếu có vấn đề.

## Điều kiện revisit
Thực hiện ở 1 tác vụ riêng, kế hoạch gợi ý:
1. `git mv lib/features/assessment/nine_domains lib/features/assessment/<tên_mới>`.
2. Rà soát + sửa toàn bộ `import '...nine_domains...'` trong `lib/`.
3. `flutter analyze` xác nhận 0 lỗi import.
4. Build thử Android debug xác nhận không vỡ.

Nên làm sớm trước khi có thêm người/AI coding tool khác tham gia sửa vùng
code này, để tránh conflict giữa rename và các thay đổi tính năng song
song — nhưng không có deadline cụ thể ràng buộc.
