# ADR 0001 — Giữ nguyên cấu trúc single-app tại gốc repo

## Bối cảnh
Dự án IRIS hiện là 1 app Flutter duy nhất tại gốc repo (`lib/`, `android/`,
`ios/`). Dự án sẽ chuyển hướng thương mại, dự kiến có thêm backend service
và 2 web app (web admin, web info) trong tương lai — nhưng thời điểm bắt
đầu code các nền tảng này chưa xác định, mới chỉ biết trước sẽ có.

Khi đánh giá chuẩn hóa repo (xem `DE_XUAT_CHUAN_HOA_REPO.md`), đã cân nhắc
3 phương án cho cấu trúc thư mục gốc:
1. Giữ nguyên single-app tại gốc.
2. Multi-repo — mỗi nền tảng 1 repo GitHub riêng.
3. Chuẩn bị khung monorepo ngay (chuyển `lib/` vào `apps/mobile/`, tạo sẵn
   `packages/` cho code dùng chung).

## Quyết định
Chọn **Phương án 1 — giữ nguyên cấu trúc single-app tại gốc**. Không di
chuyển `lib/` vào `apps/mobile/`, không tạo `packages/`, không tách
multi-repo ở thời điểm này.

## Lý do
- Chưa bắt đầu code backend/web thật — tái cấu trúc bây giờ là tái cấu
  trúc "đón đầu" cho yêu cầu chưa cụ thể, rủi ro làm sai hướng khi yêu cầu
  thật xuất hiện.
- Phương án 3 (khung monorepo) là thay đổi rủi ro cao nhất trong 3 phương
  án: đụng toàn bộ đường dẫn import trong `lib/`, cấu hình Android/iOS
  (Gradle, Podfile trỏ đường dẫn tương đối), IDE run configuration,
  `--dart-define-from-file` path — khối lượng thay đổi lớn không tương xứng
  với lợi ích khi chưa có nền tảng thứ 2 thật để dùng chung code.
- Phương án 2 (multi-repo) là quyết định khó đổi ý sau khi đã tách — nên
  chờ tới khi biết rõ ranh giới thật giữa các nền tảng (code nào dùng
  chung, code nào riêng) trước khi chọn.
- Giữ nguyên cấu trúc hiện tại có rủi ro thực thi bằng 0, không ảnh hưởng
  tốc độ phát triển tính năng hiện tại.

## Điều kiện revisit
Xem lại quyết định này khi **bắt đầu code nền tảng thứ 2 thật sự** (backend
service hoặc 1 trong 2 web app). Tại thời điểm đó, cần trả lời trước:
- Có bao nhiêu code (model, hằng số domain, logic validate...) cần dùng
  chung giữa Flutter app và nền tảng mới?
- Team/người phụ trách từng nền tảng có tách biệt hoàn toàn không?

Câu trả lời cho 2 câu hỏi trên quyết định nên chọn Phương án 2 hay 3 lúc
đó, thay vì đoán trước bây giờ.
