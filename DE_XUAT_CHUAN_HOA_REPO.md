# Đề Xuất Chuẩn Hóa Repo IRIS_v1 — Giai Đoạn A

> **Trạng thái: CHỈ ĐỀ XUẤT — CHƯA SỬA/XÓA/DI CHUYỂN BẤT KỲ FILE NÀO.**
> Chờ duyệt từng mục (có thể duyệt một phần) trước khi sang Giai đoạn B.

Thời điểm: 2026-08-20. Repo hiện tại: `github.com/doantuan22/IRIS_v1`, 1 nhánh
`main`, chưa có tag version nào.

Ghi chú bối cảnh trước khi vào từng mục: kể từ lần dọn dẹp trước, bạn đã tự
xóa `AUDIT_DON_DEP_REPO.md`/`SETUP_REPORT.md` (commit `a4a2f60`) — hiện repo
gốc chỉ còn đúng 1 file `.md`: `README.md`. Điều này được ghi nhận làm dữ
liệu đầu vào cho mục 2 (bạn có xu hướng muốn gốc repo tối giản).

---

## 1. Cấu trúc thư mục gốc — 3 phương án, CHƯA CHỌN

Hiện trạng: 1 app Flutter duy nhất tại gốc repo (`lib/`, `android/`, `ios/`),
không có `web/`/`windows/`/`linux/`/`macos/`. Không có `packages/`,
`apps/`, hay workspace config nào (không dùng Melos/pub workspaces).

### Phương án 1 — Giữ nguyên single-app tại gốc (KHÔNG đổi gì)
- **Mô tả**: Repo tiếp tục là 1 Flutter app tại gốc như hiện tại.
- **Ưu điểm**: Zero rủi ro, zero effort, không phá bất kỳ import/path nào,
  công cụ AI coding/IDE hiện tại tiếp tục hoạt động không cần cấu hình lại.
- **Nhược điểm**: Khi thêm backend service/web dashboard sau này, sẽ phải
  quyết định lại từ đầu (thêm repo khác hay tái cấu trúc giữa chừng — tái
  cấu trúc giữa chừng khi đã có nhiều code hơn sẽ tốn công hơn làm bây giờ).
- **Rủi ro thực thi**: Không có (không có gì để thực thi).
- **Phù hợp nếu**: Backend/web còn xa (>6 tháng), chưa chốt được sẽ cần gì,
  ưu tiên tốc độ ra sản phẩm hiện tại hơn khung sẵn cho tương lai.

### Phương án 2 — Multi-repo (mỗi nền tảng 1 repo riêng)
- **Mô tả**: `IRIS_v1` (repo này) chỉ giữ app Flutter, các nền tảng mới
  (backend, web dashboard...) mỗi cái là 1 repo GitHub riêng.
- **Ưu điểm**: Ranh giới rõ ràng, CI/CD độc lập từng repo, team/quyền truy
  cập tách biệt dễ, không có nguy cơ 1 thay đổi ở backend làm chậm/vỡ build
  Flutter.
- **Nhược điểm**: Khó chia sẻ code dùng chung (model, hằng số domain, schema
  validation...) giữa các repo — phải publish package riêng hoặc copy-paste
  (rủi ro lệch dữ liệu, đúng loại vấn đề dự án đã từng gặp với domain
  9→7). Version code dùng chung giữa nhiều repo phức tạp hơn.
- **Rủi ro thực thi**: Thấp cho repo hiện tại (không đổi gì ở đây), nhưng
  rủi ro **kiến trúc dài hạn trung bình-cao** (khó đổi ý sau khi đã tách).
- **Phù hợp nếu**: Đã chốt rõ sẽ có backend riêng, team backend/frontend
  tách biệt, ít code logic cần dùng chung giữa Flutter và backend.

### Phương án 3 — Chuẩn bị khung monorepo ngay bây giờ (di chuyển `lib/` app hiện tại vào `apps/mobile/`, tạo sẵn `packages/` rỗng cho code dùng chung)
- **Mô tả**: Tái cấu trúc thành:
  ```
  IRIS_v1/
    apps/
      mobile/          <- toàn bộ nội dung Flutter hiện tại chuyển vào đây
    packages/          <- rỗng, dành cho code dùng chung sau này (VD: domain
                          models, validation logic dùng cả cho backend)
  ```
  Dùng Melos hoặc pub workspaces (Dart/Flutter hỗ trợ workspace native từ
  Dart 3.6+) để quản lý.
- **Ưu điểm**: Sẵn khung cho multi-platform thật sự, dễ chia sẻ code
  (domain model, validation, constants), CI/CD có thể chạy chọn lọc theo
  package thay đổi.
- **Nhược điểm**: **Đây là thay đổi động tới TOÀN BỘ đường dẫn import,
  cấu hình Android/iOS (gradle, Podfile trỏ đường dẫn tương đối), CI script
  nếu có, IDE run configuration, dart_define path...** — rủi ro cao nhất
  trong 3 phương án, dễ làm vỡ build nếu sai 1 chỗ. Cần làm khi KHÔNG có
  thay đổi tính năng song song (dễ conflict).
- **Rủi ro thực thi**: **Cao** — di chuyển hàng trăm file, phải sửa lại toàn
  bộ import path tương đối, cấu hình platform-specific, launch.json,
  `--dart-define-from-file` path. Không cần viết lại lịch sử git (`git mv`
  giữ lịch sử), nhưng khối lượng thay đổi lớn, cần test build đầy đủ Android
  + iOS sau khi xong. Không phải thao tác 1 chiều (có thể revert bằng git
  revert bình thường).
- **Phù hợp nếu**: Đã chắc chắn sẽ có ít nhất 2-3 nền tảng dùng chung code
  trong vòng vài tháng tới, có đủ thời gian test kỹ sau khi tái cấu trúc.

### Khuyến nghị (chỉ là gợi ý, không tự chọn)
Với mô tả "quy mô cụ thể sẽ chốt dần" trong bối cảnh bạn cung cấp — tín hiệu
cho thấy **chưa đủ rõ ràng để đánh đổi rủi ro cao của Phương án 3 ngay bây
giờ**. Phương án 1 (giữ nguyên) + revisit lại quyết định này khi có bản đặc
tả rõ cho nền tảng thứ 2 thường là lựa chọn an toàn cho giai đoạn "chuẩn hóa
trước khi mở rộng" — nhưng đây là quyết định ảnh hưởng hướng đi dài hạn,
**hoàn toàn chờ bạn chốt**.

---

## 2. Tài liệu (`docs/`)

Hiện trạng: gốc repo chỉ còn `README.md` (10 mục, ~200 dòng, đã viết lại
gần đây). Không còn file `.md` rời nào khác ở gốc (đã tự dọn ở đợt trước).

### Đề xuất cấu trúc `docs/` (áp dụng dần khi có tài liệu mới, không hồi tố)
```
docs/
  architecture/     <- tài liệu kiến trúc hệ thống khi mở rộng đa nền tảng
                       (sơ đồ, luồng dữ liệu, quyết định RAG/embedding...)
  adr/              <- Architecture Decision Records — 1 file/quyết định lớn
                       (VD: adr/0001-chon-sqlite-local-first.md,
                       adr/0002-nguong-cosine-similarity-072.md — ghi lại
                       LÝ DO đằng sau các hằng số/ngưỡng quan trọng đã có
                       trong code, như relevanceThreshold=0.72 trong
                       guardrail_service.dart, hiện chỉ có comment trong
                       code, chưa có ADR riêng)
  reports/          <- báo cáo/audit theo thời điểm (như
                       AUDIT_DON_DEP_REPO.md, SETUP_REPORT.md từng có ở
                       gốc) — nếu muốn giữ lại loại tài liệu này cho tham
                       khảo sau, nên đặt ở đây thay vì gốc/xóa hẳn
  api/              <- (dự phòng) tài liệu API khi có backend service
```
File giữ nguyên ở gốc theo đúng chuẩn ngành: `README.md` (bắt buộc),
`LICENSE` (nếu thêm — xem mục 3), `CHANGELOG.md` (nếu thêm — xem mục 3).
KHÔNG đặt ADR/report/architecture doc ở gốc.

**Vì gốc hiện đã sạch (không còn file rời cần di chuyển)**, mục này ở Giai
đoạn B chỉ đơn giản là **tạo cấu trúc thư mục `docs/` rỗng (kèm `.gitkeep`
hoặc 1 file `docs/README.md` giải thích quy ước)** để sẵn sàng dùng dần —
không có file nào cần "di chuyển" vào lúc này.

- **Rủi ro thực thi**: Không có (chỉ tạo thư mục rỗng/1 file mô tả).
- **Ảnh hưởng build**: Không.

---

## 3. File chuẩn còn thiếu ở gốc repo

| File | Hiện có? | Đề xuất |
|---|---|---|
| `LICENSE` | Không | Cần chốt loại license trước (MIT/Apache-2.0/proprietary/chưa mở nguồn) — **đây là quyết định pháp lý/kinh doanh, không phải kỹ thuật, đề nghị bạn chọn loại trước khi tôi thêm file**. Với hướng thương mại hóa, khả năng cao sẽ là **proprietary/All rights reserved** (không phải mã nguồn mở) — nhưng cần bạn xác nhận. |
| `CHANGELOG.md` | Không (README mục 10 đang làm chức năng này không chính thức) | Thêm theo chuẩn [Keep a Changelog](https://keepachangelog.com/) — bắt đầu từ version hiện tại `1.0.0+1`, versioning ngược lại từ README mục 10 nếu muốn giữ lịch sử. Rủi ro thấp. |
| `CONTRIBUTING.md` | Không | Có ý nghĩa khi có >1 người/AI coding tool tham gia — nên viết SAU khi chốt xong cấu trúc (mục 1) và quy ước code (mục 7), tránh viết 2 lần. Đề xuất làm ở đợt chuẩn hóa TIẾP THEO, không phải đợt này. |
| `.editorconfig` | Không | Rủi ro thấp, hữu ích ngay cả khi chỉ 1 người code (đồng bộ indent/charset giữa các editor/AI tool khác nhau). Đề xuất thêm. |
| `CODEOWNERS` | Không | Chỉ có ý nghĩa thật khi có review bắt buộc trên GitHub (nhiều người/bot review). Với repo hiện 1 người, thêm bây giờ chỉ mang tính hình thức — đề xuất **hoãn tới khi có người thứ 2** thay vì thêm ngay. |
| Issue/PR template | Không | Tương tự CODEOWNERS — có giá trị khi có nhiều người report issue/mở PR. Đề xuất hoãn. |

**Rủi ro thực thi chung của mục này**: Thấp (toàn bộ là file tài liệu, không
đụng code/build). Riêng `LICENSE` cần bạn xác nhận loại trước khi tôi tạo.

---

## 4. Versioning

Hiện tại: `pubspec.yaml` → `version: 1.0.0+1` (build number 1, chưa có tag
git tương ứng). `name: iris_app`, `description: "A new Flutter project."` —
**vẫn là mô tả mặc định của `flutter create`, chưa từng chỉnh sửa**, nên
điền lại mô tả thật cho dự án (rủi ro: không có, chỉ là text).

Đề xuất quy ước Semantic Versioning (`MAJOR.MINOR.PATCH+BUILD`) cho giai
đoạn thương mại:
- **MAJOR**: đổi kiến trúc lớn không tương thích ngược (VD: đổi từ
  local-first sang có backend bắt buộc, đổi schema DB không migrate được).
- **MINOR**: thêm tính năng mới, tương thích ngược (thêm lĩnh vực đánh giá
  mới, thêm màn hình...).
- **PATCH**: sửa lỗi, không đổi tính năng.
- **`+BUILD`**: tăng mỗi lần build release (theo đúng cách Flutter dùng
  hiện tại), độc lập với MAJOR.MINOR.PATCH.
- Gắn **git tag** (`v1.0.0`) mỗi lần release để đối chiếu ngược commit ↔
  version — hiện repo chưa có tag nào.

**Rủi ro thực thi**: Không có — đây là quy ước áp dụng từ lần bump version
tiếp theo, không cần sửa gì ngay bây giờ ngoài việc thống nhất quy tắc (ghi
vào `CONTRIBUTING.md` hoặc `docs/` khi có).

---

## 5. Quản lý cấu hình môi trường & secrets

Hiện tại: `dart_define.json` (key thật, gitignored) +
`dart_define.json.example` (template, tracked), `android/key.properties`
(gitignored) + `.example` (tracked) — đây thực ra đã là thực hành đúng
chuẩn cho 1 môi trường.

Đề xuất khi cần nhiều môi trường (dev/staging/production):
```
dart_define.dev.json.example
dart_define.staging.json.example
dart_define.production.json.example
```
Mỗi file `.example` liệt kê đúng biến cần cho môi trường đó (VD: staging
dùng NVIDIA/Groq key riêng, endpoint backend riêng nếu có). File thật
(không có hậu tố `.example`) tiếp tục gitignore. Khi build, chọn đúng file
qua `--dart-define-from-file=dart_define.<env>.json`.

Nếu về sau có backend service riêng, cân nhắc thêm biến `API_BASE_URL` vào
cấu hình này thay vì hardcode trong `api_config.dart` như hiện tại (hiện
`ApiConfig` hardcode thẳng endpoint NVIDIA/Groq — hợp lý ở quy mô hiện tại
vì gọi thẳng 2 API cố định, nhưng sẽ cần đổi khi có backend riêng đứng giữa).

**Rủi ro thực thi**: Thấp — chỉ thêm file `.example` mẫu, không đổi code
hiện tại, không tạo secret thật. Chỉ thực thi thật khi dự án THỰC SỰ có
môi trường staging/production tách biệt (hiện tại chỉ có 1 môi trường, nên
mục này có thể **hoãn tới khi cần** thay vì làm trước).

---

## 6. CI/CD

**Xác nhận: repo hiện chưa có CI/CD nào.** `.github/` chỉ chứa
`.github/modernize/java-upgrade/` (công cụ hỗ trợ nâng cấp Java của 1 IDE
extension nào đó, không liên quan Flutter/test, không phải workflow do dự
án tạo). Không có file `.yml` nào trong `.github/workflows/` vì thư mục đó
chưa tồn tại. Không có script `.sh`/`.ps1` nào tự gọi `flutter test`/
`flutter build` trong repo.

Đề xuất khung tối thiểu (`.github/workflows/ci.yml`), chỉ chạy khi có PR
hoặc push vào `main`:
```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.0'   # khớp SDK constraint hiện tại
      - run: flutter pub get
      - run: flutter analyze
      # flutter test tạm bỏ qua vì test/ đã bị xóa (đợt trước), thêm lại khi
      # có bộ test mới
  build-android:
    runs-on: ubuntu-latest
    needs: analyze-and-test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --debug   # KHÔNG build release (cần keystore
                                          # thật + dart_define thật, không
                                          # nên đặt secret CI khi chưa có hạ
                                          # tầng thương mại thật)
```

- **Rủi ro thực thi**: Thấp — chỉ thêm 1 file YAML, không sửa code. Rủi ro
  duy nhất là workflow chạy sai/tốn phút CI miễn phí của GitHub Actions nếu
  cấu hình sai, nhưng dễ sửa/tắt.
- **Cần lưu ý**: `assets/videos/` 898MB → mỗi lần CI checkout sẽ tải toàn bộ
  (trừ khi xử lý theo mục 9). Nên cân nhắc mục 9 trước khi bật CI thật, nếu
  không mỗi lần chạy CI sẽ rất chậm/tốn băng thông.
- **Không tự bật CI thật** — chỉ tạo file cấu hình, việc bật/kết nối tài
  khoản GitHub Actions thật (nếu cần secret) do bạn quyết định.

---

## 7. Quy ước code / lint

Hiện tại: `analysis_options.yaml` chỉ include `package:flutter_lints/flutter.yaml`
(bộ lint mặc định khi `flutter create`, khá nhẹ) — không rule mở rộng nào.

Đối chiếu với lựa chọn phổ biến cho dự án thương mại:
- **`package:flutter_lints`** (đang dùng): mặc định, nhẹ, đủ bắt lỗi cơ
  bản, do chính team Flutter maintain.
- **`package:very_good_analysis`**: khắt khe hơn nhiều (bật thêm hàng chục
  rule như `public_member_api_docs`, giới hạn độ dài file/hàm...), phổ biến
  trong các dự án thương mại/team lớn dùng Flutter, giúp code đồng nhất khi
  nhiều người/AI coding tool cùng sửa.
- **Tự mở rộng dần từ `flutter_lints`**: bật thêm từng rule cụ thể (VD:
  `prefer_single_quotes`, `require_trailing_commas`) thay vì đổi hẳn bộ lint.

**Đây là thay đổi ảnh hưởng TOÀN BỘ `lib/` hiện có** — bật `very_good_analysis`
nguyên bộ gần như chắc chắn sẽ phát sinh hàng trăm warning mới trên code đã
viết (đặc biệt `public_member_api_docs` — đòi hỏi docstring cho mọi API
public, codebase hiện dùng comment tiếng Việt không theo format đó).

- **Rủi ro thực thi**: **Trung bình** nếu đổi bộ lint (sẽ hiện nhiều warning
  cần dọn hoặc `// ignore_for_file` hàng loạt — không vỡ build nhưng tốn
  công dọn). **Thấp** nếu chỉ bật thêm 1-2 rule cụ thể.
- **Không tự thêm dependency mới** (đúng yêu cầu KHÔNG ĐƯỢC LÀM) — nếu chọn
  `very_good_analysis`, đây là 1 dev_dependency mới, cần bạn duyệt rõ ràng
  trước khi tôi thêm vào `pubspec.yaml`.
- **Khuyến nghị nếu phải chọn**: bắt đầu bằng bật thêm vài rule cụ thể quan
  trọng cho dự án AI/multi-domain này trước (VD: `always_declare_return_types`,
  `avoid_dynamic_calls`) thay vì nhảy thẳng sang bộ khắt khe toàn diện —
  giảm rủi ro phải dừng lại giữa chừng vì quá nhiều warning phát sinh.

---

## 8. Đặt tên lỗi thời còn sót

### 8a. `lib/features/assessment/nine_domains/` (đã ghi nhận từ đợt trước)
```
lib/features/assessment/nine_domains/
  comparison_video/
    comparison_detail_page.dart
    comparison_video_page.dart
    video_illustration_player_page.dart
  description/
    description_page.dart
```
Thư mục vẫn tên "nine_domains" dù code bên trong chỉ phục vụ 7 lĩnh vực
hiện tại (đã xác nhận không có logic 9-lĩnh-vực nào còn sót — chỉ là tên
thư mục lỗi thời).

**Đề xuất kế hoạch rename an toàn** (không thực thi ngay):
1. `git mv lib/features/assessment/nine_domains lib/features/assessment/domain_content`
   (giữ lịch sử git qua `git mv`, không phải xóa-tạo-lại).
2. Cập nhật toàn bộ `import '...nine_domains...'` trong `lib/` — cần grep
   chính xác số file bị ảnh hưởng trước khi làm (ước lượng nhanh: các trang
   `domain_hub_page.dart`, `domain_list_page.dart` khả năng có import tới
   2 trang con này).
3. Chạy `flutter analyze` xác nhận 0 lỗi import.
4. Build thử Android debug để chắc chắn không vỡ (rename thư mục hiếm khi
   ảnh hưởng build nhưng nên xác nhận).
- **Rủi ro thực thi**: Thấp-trung bình — thao tác cơ học (rename + sửa
  import), không đổi logic, nhưng cần cẩn thận không sót import nào (đặc
  biệt nếu có string reference tới đường dẫn, dù ít khả năng với Dart).
  Không phải thao tác 1 chiều, revert dễ dàng bằng git.

### 8b. Phát hiện thêm: `assets/videos/hanh_vi/` và `assets/videos/ung_xu/`
Trong lúc rà soát mục này, phát hiện 2 thư mục asset còn sót từ thời 9 lĩnh
vực, **không nằm trong đề xuất ban đầu của bạn nhưng liên quan trực tiếp**:
- `assets/videos/hanh_vi/.gitkeep` và `assets/videos/ung_xu/.gitkeep` — mỗi
  thư mục chỉ có 1 file `.gitkeep` rỗng (0 byte), không có video thật.
- **Xác nhận**: KHÔNG được khai báo trong `pubspec.yaml` (danh sách asset
  chỉ có 7 thư mục lĩnh vực hợp lệ), KHÔNG được `lib/` tham chiếu.
- Đề xuất: xóa 2 thư mục này cùng đợt rename ở mục 8a (cùng chủ đề "dọn
  tàn dư 9→7 lĩnh vực"), hoặc xử lý riêng nếu bạn muốn tách biệt.
- **Rủi ro thực thi**: Không có — 2 file rỗng, không tham chiếu.

---

## 9. Asset lớn (`assets/videos/` ~898MB)

Nhắc lại 3 phương án đã nêu ở đợt dọn dẹp trước, đặt trong bối cảnh thương
mại hóa cụ thể hơn:

### Phương án 1 — Giữ nguyên trong git (không đổi gì)
- Đơn giản nhất, không rủi ro.
- **Nhược điểm rõ hơn trong bối cảnh thương mại**: mỗi máy dev mới/mỗi lần
  CI checkout phải tải hết 898MB — khi có thêm người/AI coding tool cùng
  làm việc (đúng mục tiêu "dễ onboard" bạn nêu), đây sẽ là điểm nghẽn thật
  sự. Cũng làm chậm mọi thao tác git khác (clone, fetch).

### Phương án 2 — Git LFS
- Giảm dung lượng clone/pack đáng kể cho các thao tác thường ngày.
- **Nhược điểm**: Lịch sử `.git` HIỆN TẠI (đã có video ở dạng blob thường)
  **vẫn nặng y nguyên** trừ khi viết lại lịch sử (`git filter-repo`) —
  đúng như đã nêu, việc này **bị cấm tự ý làm**, phải hỏi riêng. Nếu chỉ
  chuyển các commit FUTURE sang LFS (video mới thêm sau này), lịch sử cũ
  vẫn nặng ~2GB như hiện tại — chỉ giảm tốc độ tăng thêm từ giờ trở đi, không
  giảm dung lượng đã có.
- Cần mọi máy dev cài `git-lfs`, cấu hình `.gitattributes`.
- **Rủi ro thực thi**: Trung bình — cấu hình LFS cho asset MỚI thêm vào thì
  an toàn (rủi ro thấp), nhưng xử lý asset ĐÃ CÓ trong lịch sử đòi viết lại
  lịch sử (rủi ro cao, ngoài phạm vi, cần hỏi riêng theo đúng yêu cầu).

### Phương án 3 — Tách ra khỏi git, tải qua CDN/object storage lúc build/runtime
- Video được upload lên S3/Cloudflare R2/CDN tương tự, app tải về lúc cần
  (hoặc lúc build đóng gói asset) thay vì bundle cứng trong APK/git.
- **Phù hợp nhất về dài hạn cho hướng thương mại đa nền tảng**: web app sau
  này (nếu có) không thể bundle 898MB video vào bundle JS — bắt buộc phải
  serve qua CDN dù muốn hay không. Làm sớm sẽ tránh phải làm lại khi có web.
- **Nhược điểm**: Cần hạ tầng storage/CDN thật (chi phí, vận hành), cần sửa
  code tải video (hiện `video_manifest_service.dart` đọc từ asset bundle
  local, cần đổi sang tải network + cache), cần xử lý trường hợp offline
  (app hiện tại là "local-first" — mất tính chất này với video nếu chuyển
  hẳn sang network-only, trừ khi làm cache).
- **Rủi ro thực thi**: **Cao nhất trong 3 phương án** — đổi kiến trúc tải
  asset, ảnh hưởng trực tiếp tính năng đang chạy tốt (`comparison_video/`),
  cần hạ tầng ngoài (tài khoản CDN/storage), không phải việc làm trong vài
  giờ.

### Khuyến nghị (chỉ là gợi ý)
Cho giai đoạn "chuẩn hóa trước khi mở rộng" hiện tại — **chưa nên chọn ngay**
vì cả 3 phương án đều có đánh đổi lớn phụ thuộc quyết định ở mục 1 (nếu
chọn multi-platform có web, Phương án 3 gần như bắt buộc sớm muộn; nếu chỉ
mobile app dài hạn, Phương án 1 hoặc 2 đủ dùng). Đề xuất **hoãn quyết định
này tới khi mục 1 (cấu trúc repo/đa nền tảng) đã chốt**, vì nó phụ thuộc
trực tiếp.

---

## Tổng hợp mức rủi ro để bạn dễ duyệt nhanh

| # | Mục | Rủi ro | 1 chiều/khó rollback? | Ảnh hưởng build? |
|---|---|---|---|---|
| 1 | Cấu trúc gốc (3 phương án) | PA1: không · PA2: thấp (ở repo này) · PA3: **cao** | PA3: không (git mv revert được) nhưng khối lượng lớn | PA3: có thể tạm vỡ nếu sai sót, cần test kỹ |
| 2 | `docs/` | Không | Không | Không |
| 3 | File chuẩn gốc | Thấp (LICENSE cần bạn chọn loại trước) | Không | Không |
| 4 | Versioning | Không (chỉ là quy ước) | Không | Không |
| 5 | Env/secrets | Thấp | Không | Không |
| 6 | CI/CD | Thấp | Không | Không (chỉ thêm file, không tự bật) |
| 7 | Lint | Thấp (1-2 rule) · Trung bình (đổi hẳn bộ) | Không | Không vỡ build, phát sinh warning cần dọn |
| 8a | Rename `nine_domains/` | Thấp-trung bình | Không (git mv) | Cần test sau khi sửa import |
| 8b | Xóa 2 `.gitkeep` thừa | Không | Không | Không |
| 9 | Asset video | PA1: không · PA2: trung bình (asset mới) / cao (asset cũ, cần lịch sử) · PA3: **cao** | PA2 (asset cũ): có, cần `git filter-repo` — **bị cấm, phải hỏi riêng** | PA3: có, đổi luồng tải video |

---

**Chưa thực thi gì.** Vui lòng cho biết mục nào duyệt, mục nào từ chối, mục
nào cần thêm thông tin trước khi quyết — đặc biệt mục 1 (cấu trúc gốc) và
mục 9 (asset video) vì 2 mục này phụ thuộc lẫn nhau.
