# Setup Report — Chuẩn Hóa Repo IRIS_v1 (Giai Đoạn B)

Ghi lại thực tế đã làm ở Giai đoạn B, đối chiếu với bảng quyết định đã chốt
trong `DE_XUAT_CHUAN_HOA_REPO.md` (Giai đoạn A).

Thời điểm: 2026-08-20.

> Ghi chú: đây là bản `SETUP_REPORT.md` mới — bản trước (ghi lại đợt dọn
> dẹp file rác 2026-08-19) đã bị xóa khỏi repo trước khi tác vụ này bắt
> đầu. Lịch sử đợt dọn dẹp đó vẫn còn nguyên trong git log (commit
> `8e3c2d9`, `a8702e2`).

## Đối chiếu quyết định ↔ thực thi

| # | Mục | Quyết định | Đã làm |
|---|---|---|---|
| 1 | Cấu trúc gốc | Giữ nguyên (PA1), ghi ADR | ✅ `docs/adr/0001-giu-nguyen-single-app-repo.md` |
| 2 | `docs/` | Tạo cấu trúc đầy đủ | ✅ `docs/{README.md, architecture/, adr/, reports/, api/}` |
| 3 | File chuẩn gốc | `CHANGELOG.md` + `.editorconfig`; KHÔNG `LICENSE` | ✅ 2 file đã thêm; **không** tạo `LICENSE` (chưa chốt loại) |
| 4 | Versioning | Ghi quy ước vào `docs/` | ✅ `docs/versioning.md` |
| 5 | Env/secrets | Hoãn | Không làm gì — đúng quyết định |
| 6 | CI/CD | Tạo `ci.yml`, chỉ job `analyze` | ✅ `.github/workflows/ci.yml` — không có job build APK, không bật `flutter test` |
| 7 | Lint | Thêm 4 rule cụ thể, báo cáo warning | ✅ xem số liệu bên dưới |
| 8a | Rename `nine_domains/` | Hoãn, ghi ADR | ✅ `docs/adr/0003-hoan-rename-nine-domains.md` |
| 8b | Xóa 2 `.gitkeep` thừa | Duyệt xóa | ✅ đã xóa `assets/videos/{hanh_vi,ung_xu}/` |
| 9 | Video 898MB | Giữ nguyên, ghi ADR | ✅ `docs/adr/0002-hoan-chuyen-doi-luu-tru-video.md` |

## Kết quả rule lint mới (mục 7)

Thêm vào `analysis_options.yaml`: `always_declare_return_types`,
`avoid_dynamic_calls`, `require_trailing_commas`, `prefer_single_quotes`.

`flutter analyze` sau khi thêm — **3 issues** (info level), toàn bộ đều là
`avoid_dynamic_calls`, toàn bộ đều nằm trong `scripts/` (không có trong
`lib/`):
- `scripts/ingest_so_sanh_15_23.dart:120:28`
- `scripts/ingest_so_sanh_24_47.dart:120:28`
- `scripts/ingest_so_sanh_48_60.dart:120:28`

3 rule còn lại (`always_declare_return_types`, `require_trailing_commas`,
`prefer_single_quotes`): **0 warning** — codebase hiện tại đã tuân thủ sẵn.

**Không sửa code để dọn 3 warning này** theo đúng yêu cầu — để lại cho tác
vụ riêng nếu muốn xử lý.

## File/thư mục đã thêm

```
docs/
  README.md
  adr/0001-giu-nguyen-single-app-repo.md
  adr/0002-hoan-chuyen-doi-luu-tru-video.md
  adr/0003-hoan-rename-nine-domains.md
  architecture/.gitkeep
  reports/.gitkeep
  api/.gitkeep
  versioning.md
CHANGELOG.md
.editorconfig
.github/workflows/ci.yml
```

## File/thư mục đã xóa

```
assets/videos/hanh_vi/.gitkeep
assets/videos/ung_xu/.gitkeep
```

## KHÔNG làm (đúng theo giới hạn đã chốt)

- Không tạo `LICENSE`.
- Không di chuyển `lib/` vào `apps/mobile/`, không tạo `packages/`.
- Không đổi cách lưu trữ `assets/videos/` (không LFS, không CDN, không xóa
  video thật).
- Không rename `nine_domains/`.
- Không thêm `CONTRIBUTING.md`, `CODEOWNERS`, issue/PR template.
- Không thêm dependency mới (`very_good_analysis` hay bất kỳ package nào).
- Không sửa code trong `lib/`/`scripts/` để dọn warning lint mới.
- Không bật CI thật (không kết nối secret, không tự chạy workflow).

## Kiểm tra cuối

- `flutter analyze`: 3 issues (info, đã liệt kê ở trên) — không có lỗi
  biên dịch.
- `flutter build apk --debug`: **thành công** —
  `√ Built build\app\outputs\flutter-apk\app-debug.apk` (Gradle
  `assembleDebug`, ~201.5s). Chỉ có warning vô hại từ Gradle/Android SDK
  (restricted native access, SDK XML version) — không liên quan tới thay
  đổi trong đợt chuẩn hóa này.

## 6 commit của Giai đoạn B

1. `61fb803` — checkpoint (thêm `DE_XUAT_CHUAN_HOA_REPO.md` từ Giai đoạn A).
2. `9d9be96` — `docs: tạo cấu trúc docs/ + 3 ADR + quy ước versioning`.
3. `502edac` — `chore: thêm CHANGELOG.md và .editorconfig`.
4. `ae51960` — `ci: thêm khung CI tối thiểu (flutter analyze)`.
5. `933dc41` — `chore: siết thêm 4 rule lint (...)`.
6. `913e696` — `chore: xóa 2 thư mục asset thừa (...)`.
