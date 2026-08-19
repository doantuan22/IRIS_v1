# Setup Report — Dọn Dẹp Repo IRIS_v1

Ghi nhận thực tế những gì đã xóa/sửa trong đợt dọn dẹp repo, đối chiếu với
`AUDIT_DON_DEP_REPO.md` (audit đầy đủ, đã được duyệt từng mục trước khi
thực thi).

Thời điểm: 2026-08-19 (đợt 1 — dọn rác ảnh/log), 2026-08-20 (đợt 2 — xóa
toàn bộ `test/`).

---

## Đợt 2 (2026-08-20) — Xóa toàn bộ thư mục `test/`

Quyết định của chủ dự án: xóa sạch toàn bộ bộ test hiện có (43 file .dart,
đã được audit kỹ ở đợt 1 và xác nhận không có file nào test tính năng chết)
để chuẩn bị viết lại từ đầu theo kiến trúc hạ tầng thương mại sắp triển khai.
Đây là quyết định phá bỏ hoàn toàn có chủ đích, không phải kết quả audit —
khác với đợt 1 (chỉ xóa rác, giữ nguyên toàn bộ test).

**Đã xóa**: toàn bộ thư mục `test/` — 43 file `.dart`.

**Đã kiểm tra, KHÔNG đụng tới** (theo đúng yêu cầu chỉ liệt kê, không tự xóa):
- `pubspec.yaml` — `dev_dependencies` giữ nguyên 100%:
  - `flutter_test` (SDK) — chỉ dùng trong `test/`, không dùng ở `lib/`.
  - `flutter_lints` — cấu hình lint chung cho `flutter analyze`, không
    riêng cho test.
  - `sqflite_common_ffi` — chỉ dùng trong `test/` (để chạy SQLite trên Dart
    VM thuần); `lib/data/local/database.dart` chỉ nhắc tên package này
    trong 1 dòng docstring, không import/dùng thật.
  - `url_launcher_platform_interface` — chỉ dùng trong `test/` (mock
    `url_launcher`), không dùng ở `lib/`.
  - → Cả 4 dependency này AN TOÀN GIỮ LẠI để dùng khi viết bộ test mới sau
    này; không có dependency nào chỉ tồn tại để phục vụ 1 tính năng đã mất
    ý nghĩa.
- CI/CD: **không tìm thấy** file nào trong `.github/workflows/` (thư mục
  `.github/` chỉ có `.github/modernize/java-upgrade/` — công cụ hỗ trợ
  nâng cấp Java, không liên quan Flutter/test). Không có script `.sh`/`.ps1`/
  `.yml` nào gọi `flutter test` trong repo.
- `analysis_options.yaml`: không có rule/exclude riêng cho `test/` — file
  chỉ include `package:flutter_lints/flutter.yaml`, áp dụng chung cho toàn
  bộ project, không cần sửa gì sau khi xóa `test/`.
- `lib/`, `assets/`, mọi file `.md`: không đụng tới.

**Kiểm tra sau khi xóa**: `flutter analyze` → **0 issues** (xác nhận
`lib/` không import ngược bất kỳ gì từ `test/`, đúng như dự đoán).

**2 commit của đợt 2**: không cần commit checkpoint riêng (working tree đã
sạch từ cuối đợt 1) — chỉ có 1 commit xóa:
`chore: xóa toàn bộ test suite cũ, chuẩn bị viết lại theo kiến trúc mới`.

---

## Đợt 1 (2026-08-19) — Dọn rác ảnh/log debug

## Đã xóa (142 file, ~21MB) — theo đúng danh sách đã duyệt

| Thư mục | Số file | Lý do |
|---|---|---|
| `.packaging_logs/` | 33 | Log cài đặt/build APK release + ảnh chụp màn hình audit thủ công, không được tham chiếu bởi bất kỳ code/docs nào |
| `.scratch_e2e/` | 19 | Ảnh chụp + dump XML từ luồng E2E thủ công (tạo hồ sơ, sàng lọc...), không tham chiếu |
| `.scratch_screens/` | 68 | Ảnh chụp màn hình rời rạc dùng đối chiếu UI trong quá trình redesign, không tham chiếu |
| `artifacts/ui_refresh/` | 22 | Ảnh chụp toàn bộ màn hình app sau đợt UI refresh, không tham chiếu |

`artifacts/video_compression_20260816.csv` và
`artifacts/video_compression_ffprobe_20260816.csv` **được giữ nguyên** —
không nằm trong danh sách đã duyệt.

## Đã sửa (1 file)

- `test/real_cloud_ai_verification_test.dart` dòng 63: đổi
  `linhVuc: 'hanh_vi'` (domain code đã gỡ khỏi 7 lĩnh vực hiện tại) thành
  `linhVuc: 'ngon_ngu'` (domain hợp lệ) — chỉ là dữ liệu mẫu trong 1 test bị
  skip mặc định (không có API key), không ảnh hưởng logic.

## KHÔNG đụng tới (theo đúng quyết định tách bạch với việc dọn rác)

- 42 file trong `test/` — toàn bộ được giữ nguyên. Không file nào bị xóa vì
  không phát hiện file nào test tính năng đã chết (xem chi tiết đối chiếu
  từng file trong `AUDIT_DON_DEP_REPO.md` mục 2).
- **14 test FAIL có sẵn từ trước** (baseline 185 PASS / 14 FAIL trên 41 file
  khi loại trừ `ai_connectivity_ui_guard_test.dart` — file có 2 test treo
  10 phút/test, bug có sẵn không liên quan tới dọn dẹp) — các fail này thuộc
  3 nhóm nguyên nhân độc lập (lệch số version schema DB trong 3 test migration,
  `google_fonts` cố tải font qua network thật trong test env, và 2-3 chỗ nội
  dung/kỳ vọng lệch nhau) — **để nguyên, không sửa trong đợt này** theo đúng
  quyết định giữ commit dọn dẹp tách bạch khỏi thay đổi tính năng/bugfix
  khác. Chi tiết đầy đủ ở `AUDIT_DON_DEP_REPO.md` mục 7b.
- `assets/videos/` (898MB) — asset thật đang dùng runtime, không xóa. 3
  phương án lưu trữ (Git LFS / giữ nguyên / tách CDN) đã nêu ở
  `AUDIT_DON_DEP_REPO.md` mục 5, chờ quyết định riêng.

## Kết quả kiểm tra sau khi xóa

- `flutter analyze`: **0 issues**.
- `flutter test` (loại trừ 2 file lý do đã nêu ở trên): kết quả đối chiếu
  với baseline trước dọn dẹp — xem `AUDIT_DON_DEP_REPO.md` mục 7 để có số
  liệu PASS/FAIL trước/sau đầy đủ.

## 2 commit git của đợt dọn dẹp

1. `1f25402` — `chore: checkpoint pending doc/test cleanup from previous session`
   (ghi nhận thay đổi tồn đọng từ phiên trước, trước khi bắt đầu audit).
2. Commit dọn dẹp (tạo ngay sau report này) — xóa 4 thư mục ảnh/log rác +
   sửa 1 dòng dữ liệu mẫu lỗi thời trong test.
