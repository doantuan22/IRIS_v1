# ADR 0002 — Hoãn chuyển đổi cách lưu trữ video (`assets/videos/`)

## Bối cảnh
`assets/videos/` hiện chiếm ~898MB, bundle trực tiếp trong git và trong APK
qua khai báo asset của Flutter (`pubspec.yaml`). Repo `.git` hiện đã nặng
~2GB, phần lớn từ lịch sử của các video này.

Khi đánh giá chuẩn hóa repo, đã cân nhắc 3 phương án:
1. Giữ nguyên trong git (không đổi gì).
2. Chuyển sang Git LFS.
3. Tách ra khỏi git, tải qua CDN/object storage lúc build/runtime.

## Quyết định
Chọn **Phương án 1 — giữ nguyên**, không chuyển Git LFS, không chuyển CDN,
không xóa video thật ở thời điểm này.

## Lý do
- Cả 3 phương án đều có đánh đổi phụ thuộc trực tiếp vào [[0001]] (cấu trúc
  đa nền tảng) — quyết định lưu trữ video hợp lý nhất phụ thuộc việc có web
  app thật hay không, và web app đó có cần hiển thị cùng bộ video hay
  không.
- Phương án 2 (Git LFS) không giải quyết được vấn đề dung lượng lịch sử
  `.git` đã có — muốn giảm dung lượng lịch sử cũ bắt buộc phải viết lại
  lịch sử git (`git filter-repo` hoặc tương đương), một thao tác 1 chiều,
  rủi ro cao, nằm ngoài phạm vi cho phép tự quyết định.
- Phương án 3 (CDN) là thay đổi kiến trúc tải asset, ảnh hưởng trực tiếp
  tính năng `comparison_video/` đang hoạt động ổn định, đòi hỏi hạ tầng
  storage/CDN thật chưa tồn tại, và cần thiết kế lại cơ chế cache để không
  mất tính chất "local-first" của app hiện tại.
- Ở quy mô hiện tại (1 app Flutter, chưa có web), Phương án 1 không gây vấn
  đề vận hành thực tế nào ngoài tốc độ clone/CI — chấp nhận được cho giai
  đoạn chuẩn hóa này.

## Điều kiện revisit
Xem lại quyết định này khi **bắt đầu code web info** (nền tảng dự kiến cần
hiển thị video tương tự app mobile) — đây là thời điểm Phương án 3 gần như
trở thành bắt buộc (web không thể bundle 898MB video vào bundle JS). Khi
đó cần đánh giá lại đồng thời:
- Có nên xử lý dung lượng lịch sử `.git` cũ hay chấp nhận giữ nguyên và chỉ
  chuyển asset MỚI sang lưu trữ khác?
- Chọn nhà cung cấp CDN/object storage nào, chi phí vận hành.
