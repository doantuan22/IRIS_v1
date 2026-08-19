# Setup Report — Dọn Dẹp Repo IRIS_v1

Ghi nhận thực tế những gì đã xóa/sửa trong đợt dọn dẹp repo, đối chiếu với
`AUDIT_DON_DEP_REPO.md` (audit đầy đủ, đã được duyệt từng mục trước khi
thực thi).

Thời điểm: 2026-08-19.

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
