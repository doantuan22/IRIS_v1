# Audit Dọn Dẹp Repo IRIS_v1 — Giai Đoạn A

> **Trạng thái: CHỈ LIỆT KÊ — CHƯA XÓA GÌ.** Chờ xác nhận từng mục trước khi
> sang Giai đoạn B (thực thi).

Thời điểm audit: 2026-08-19.

---

## 0. Kiểm tra git status trước audit (bắt buộc theo yêu cầu)

Khi bắt đầu phiên này, git có **8 file thay đổi lớn chưa commit** (7 file
tài liệu bị xóa + `README.md` sửa lớn, tổng -2622/+120 dòng) — đúng loại rủi
ro đã cảnh báo trước. Theo xác nhận của bạn, đã tạo **1 commit checkpoint**
ghi nhận đúng hiện trạng đó trước khi bắt đầu audit:

```
commit 1f25402 — chore: checkpoint pending doc/test cleanup from previous session
```

Từ đây working tree đã sạch, audit bên dưới thực hiện trên trạng thái này.

`flutter analyze`: **0 issues** (chạy toàn bộ `lib/` + `test/`, xác nhận
không file nào trong 2 thư mục này có lỗi biên dịch/tham chiếu chết —
analyzer sẽ báo lỗi ngay nếu 1 test import class/hàm không còn tồn tại).

`flutter test`: đang chạy nền lúc soạn báo cáo này, kết quả sẽ được bổ sung
ngay khi có (xem mục 5).

---

## 1. Ảnh chụp màn hình / dữ liệu debug nằm ngoài `assets/` chính thức

Tất cả các thư mục dưới đây **không được `pubspec.yaml` khai báo làm asset**,
**không được bất kỳ file `.dart`/`.md` nào tham chiếu** (đã grep toàn repo),
và tên thư mục (tiền tố `.` hoặc nằm ngoài cấu trúc chuẩn) cho thấy đây là
sản phẩm phụ của các phiên làm việc thủ công (chụp màn hình đối chiếu UI,
dump log cài đặt/test) bị commit nhầm thay vì bị `.gitignore` loại trừ.

| Thư mục | Nội dung | Số file tracked | Dung lượng | Commit đưa vào | Tham chiếu tìm thấy |
|---|---|---|---|---|---|
| `.packaging_logs/` | log cài đặt/build APK release (`.txt`), ảnh chụp màn hình audit (`.png`), dump UI XML | 33 | 758K | `7b43d3a` (2026-08-18) | Không |
| `.scratch_e2e/` | ảnh chụp + dump XML luồng E2E thủ công (tạo hồ sơ, sàng lọc...) | 19 | 1.2M | `7b43d3a` (2026-08-18) | Không |
| `.scratch_screens/` | ~68 ảnh chụp màn hình rời rạc (tên `i1.png`, `k4.png`, `iris_ui_home.png`...) dùng đối chiếu UI trong quá trình redesign | 68 | 15M | `7b43d3a` (2026-08-18) | Không |
| `artifacts/ui_refresh/` | 21 ảnh chụp toàn bộ màn hình app sau đợt UI refresh (đặt tên `01_home.png`...`21_splash_home_transition.png`) | 23 | 4.1M | `8306ab9` (2026-08-17) | Không |

**Nhận định**: cả 4 thư mục đều là tài liệu tạm thời phục vụ 1 lần đối chiếu
UI/QA thủ công, không phải asset app dùng runtime, không phải tài liệu tham
khảo được README hay bất kỳ file nào trỏ tới. Tên có tiền tố `.` của 3 thư
mục đầu càng cho thấy ý định ban đầu là "scratch" (nháp) chứ không phải lưu
trữ lâu dài.

→ Đề xuất: **AN TOÀN ĐỂ XÓA** cả 4 thư mục (xem mục 6, danh sách tổng hợp).

---

## 2. Audit toàn bộ `test/` (42 file, ~7656 dòng)

Phân loại theo tiêu chí: đối chiếu import/class được test với `lib/` hiện tại
(qua `flutter analyze` — 0 lỗi biên dịch/import chết trên toàn bộ `test/`) +
đọc nội dung từng file nghi ngờ để xác định file đó test **tính năng đang
sống** hay **hành vi migration lịch sử** hay **tính năng đã biến mất**.

### 2a. Nhóm nghi ngờ ban đầu (nhắc tới 9 lĩnh vực / content_type cũ) — ĐÃ ĐỌC KỸ, KẾT LUẬN: HỢP LỆ, KHÔNG XÓA

Đây là điểm quan trọng nhất của audit: các test này **KHÔNG** test tính năng
đã chết — chúng test **logic migration schema** (`onUpgrade` trong
`lib/data/local/database.dart`) mà bản thân logic đó **vẫn đang tồn tại và
chạy thật** mỗi khi 1 người dùng cũ nâng cấp app lên version DB mới nhất
(hiện là version 11). Xóa các test này sẽ làm mất coverage cho đúng phần rủi
ro nhất của app (migrate dữ liệu thật của người dùng đang cài đặt cũ).

| File | Test gì | Vì sao KHÔNG phải rác |
|---|---|---|
| `seven_domains_migration_test.dart` | Migration v5→v6: xóa sạch dữ liệu `hanh_vi`/`ung_xu` ở 4 bảng khi chuyển 9→7 lĩnh vực | Test đúng code migration `onVersion < 6` đang tồn tại tại `database.dart:130-163` |
| `expert_knowledge_cleanup_migration_test.dart` | Migration v8→v9: xóa `content_type IN ('chia_se_phu_huynh','bac_si')` | Test đúng code `onVersion < 9` tại `database.dart:191-204` |
| `chan_dung_and_overview_description_migration_test.dart` | Migration v6→v7: xóa `content_type='chan_dung'`, thêm cột `mo_ta_tong_hop` | Test đúng code `onVersion < 7` tại `database.dart:164-184` |
| `validate_so_sanh_data_test.dart` | Validator dữ liệu `so_sanh` phải **phát hiện và từ chối** `linh_vuc` đã gỡ (`hanh_vi`/`ung_xu`) | Đây chính là bài test đảm bảo dữ liệu cũ KHÔNG lọt qua — xóa test này sẽ mất khả năng phát hiện hồi quy |

### 2b. `real_cloud_ai_verification_test.dart` — CẦN QUYẾT ĐỊNH (không xóa file, nhưng có 1 dòng dữ liệu mẫu lỗi thời)

- File này **chỉ chạy khi có API key thật** (`skip: !ApiConfig.hasAiConfig`),
  mặc định `flutter test` bỏ qua toàn bộ group này — không ảnh hưởng CI/test
  suite thường ngày.
- Dòng 63: `linhVuc: 'hanh_vi'` khi tạo `profile_chunks` mẫu — đây là 1 domain
  code đã bị gỡ khỏi `domains.dart`, chỉ dùng làm chuỗi tự do lưu DB (cột
  `linh_vuc` không có ràng buộc FK/CHECK), nên **test không lỗi**, nhưng dữ
  liệu mẫu không còn phản ánh đúng 7 lĩnh vực hiện tại.
- → Đề xuất: **CẦN TÔI QUYẾT ĐỊNH** — sửa `'hanh_vi'` thành 1 domain hợp lệ
  (VD `'ngon_ngu'`) hay giữ nguyên (vì không ảnh hưởng chức năng, chỉ là dữ
  liệu mẫu trong 1 test luôn bị skip mặc định).

### 2c. Toàn bộ 37 file test còn lại — TIẾP TỤC HỢP LỆ (đối chiếu 1-1 với `lib/` hiện tại)

Đã grep xác nhận: không có file nào tham chiếu `PartStepIndicator`,
`onboarding_page.dart`, `ai_chunk.dart` (các tên bạn nêu ví dụ) — những file
này **đã được xóa khỏi cả `lib/` lẫn `test/` từ trước**, không còn sót gì.
Từ khóa `onboarding` chỉ xuất hiện trong `screening_flow_test.dart` và các
trang `screening/*` — đây là khái niệm "hoàn tất giới thiệu sàng lọc" đang
sống trong `ScreeningChangeService`, không phải trang `onboarding_page.dart`
đã xóa.

37 file còn lại map 1-1 với service/repository/page đang tồn tại trong
`lib/` (đã đối chiếu tên file ↔ tên class được import): AI chat/guardrail,
child/screening/video repository, vector search, overview tier, so sánh
video theo độ tuổi (`so_sanh_15_23`/`24_47`/`48_60`), v.v. Không phát hiện
file nào test tính năng đã xóa.

→ Đề xuất: **GIỮ NGUYÊN TOÀN BỘ**, không nằm trong phạm vi xóa.

### 2d. Thư mục `test_ai_quality/`

Thư mục này (chứa `ai_quality_check_test.dart`, 454 dòng) đã bị xóa trong
đúng đợt thay đổi chưa commit ở mục 0, nay đã nằm trong commit checkpoint
`1f25402`. Đã kiểm tra: thư mục `test_ai_quality/` hiện **không còn tồn tại**
trong working tree — không cần hành động thêm ở Giai đoạn B cho mục này.

---

## 3. Đối chiếu "code chết" README từng nhắc tới

Grep toàn repo (loại trừ `build/`, `.dart_tool/`) cho `onboarding_page.dart`
và `ai_chunk.dart`: **không tìm thấy** — xác nhận đã xóa sạch từ trước, không
có gì sót lại.

Không phát hiện thêm file `.bak`, `*_old.dart`, `* copy*`, `*_backup.*` nào
trong repo.

---

## 4. File/cấu hình khác đã kiểm tra — ĐỀU ỔN, KHÔNG PHẢI RÁC

| Mục | Kết luận |
|---|---|
| `build/`, `.dart_tool/` | Không bị commit nhầm — đúng như `.gitignore` (`.dart_tool/` và `/build/` đã có trong `.gitignore`), xác nhận qua `git ls-files` không trả về gì trong 2 thư mục này |
| `iris_app.iml`, `.idea/` | Không tracked (đúng — `.gitignore` có `*.iml` và `.idea/`) |
| `dart_define.json` (key thật) | Không tracked (đúng — có trong `.gitignore`), chỉ `dart_define.json.example` được track |
| `android/key.properties` | Không tồn tại/không tracked — chỉ có `key.properties.example` được track (đúng chuẩn) |
| `tools/.video_manager_config.json` | Không tracked (đúng — có dòng riêng trong `.gitignore`) |
| `.vscode/launch.json`, `.vscode/settings.json` | Được track có chủ đích (dòng `.gitignore` chú thích rõ lý do giữ lại cấu hình VS Code chung cho team) |
| `.metadata` | File chuẩn do Flutter CLI tự sinh, quy ước luôn commit — không phải rác |
| `scripts/*.dart`, `scripts/*.sql`, `scripts/*.py` | Công cụ ingest dữ liệu chuyên môn (NVIDIA embedding, seed `expert_knowledge_chunks`) — được `lib/domain/services/expert_knowledge_seed_service.dart` và `child_debug_page.dart` trỏ tới trong docstring, có test riêng (`ingest_expert_data_test.dart`, `ingest_so_sanh_data_test.dart`, `validate_so_sanh_data_test.dart`) — đang hoạt động, không phải rác |
| `tools/video_manager_tool.py`, `tools/test_video_manager_tool.py` | Công cụ quản lý asset video, có test riêng, đang dùng |
| `assets/data/`, `assets/reference/` (8 file JSON) | Đều được `pubspec.yaml` khai báo hoặc load runtime qua asset bundle (bộ câu hỏi sàng lọc, dữ liệu tham khảo chuyên môn) — không phải rác |

---

## 5. Vấn đề riêng: dung lượng `assets/videos/` (~898MB, tổng `assets/` ~924MB)

- Xác nhận bằng `du -sh`: `assets/videos/` = **898MB**, nằm trong 7 thư mục
  con theo đúng 7 lĩnh vực (khai báo đầy đủ trong `pubspec.yaml`).
- File lớn nhất: 66MB (`nhan_thuc/so_sanh_nhan_thuc_roi_loan_pho_tu_ky_24_47_011.mp4`).
- Repo git hiện tại (`.git/`) đã nặng **1.97 GiB** (pack size) — phần lớn đến
  từ lịch sử các video này.
- Đây là **asset thật, đang được `video_manifest_service.dart` và các trang
  `comparison_video/` sử dụng runtime** — **KHÔNG nằm trong phạm vi xóa**.
- Theo đúng chỉ dẫn "KHÔNG ĐƯỢC LÀM": tôi **không tự ý đổi cách lưu trữ**.
  Nêu đề xuất để bạn chốt riêng, tách khỏi việc dọn dẹp file rác lần này:
  - **Phương án 1 (Git LFS)**: chuyển toàn bộ `assets/videos/**/*.mp4` sang
    Git LFS. Ưu điểm: giảm mạnh dung lượng clone/pack cho người mới; nhược
    điểm: cần cấu hình LFS trên mọi máy dev + CI, và lịch sử `.git` cũ vẫn
    nặng trừ khi làm thêm bước `git filter-repo` (thao tác viết lại lịch sử
    — rủi ro cao, cần bạn duyệt riêng nếu muốn).
  - **Phương án 2 (giữ nguyên trong git, không LFS)**: đơn giản, không rủi
    ro, nhưng repo tiếp tục nặng theo thời gian nếu thêm video mới.
  - **Phương án 3 (tách asset video ra ngoài git, tải về lúc build/CDN)**:
    phù hợp nhất cho "hạ tầng thương mại" nhưng là thay đổi kiến trúc lớn,
    ngoài phạm vi dọn dẹp lần này.
  - → Đây chỉ là đề xuất tham khảo, **chờ bạn chốt phương án**, không đưa
    vào Giai đoạn B của lần dọn dẹp này.

---

## 6. TỔNG HỢP — 2 DANH SÁCH CẦN BẠN DUYỆT

### ✅ AN TOÀN ĐỂ XÓA (đề xuất — chờ xác nhận)

| # | Mục | Lý do |
|---|---|---|
| 1 | `.packaging_logs/` (toàn bộ, 33 file, 758K) | Log/ảnh debug 1 lần, không được tham chiếu, tên thư mục dạng scratch |
| 2 | `.scratch_e2e/` (toàn bộ, 19 file, 1.2M) | Ảnh/dump QA thủ công 1 lần, không tham chiếu |
| 3 | `.scratch_screens/` (toàn bộ, 68 file, 15M) | Ảnh đối chiếu UI tạm thời, không tham chiếu |
| 4 | `artifacts/ui_refresh/` (toàn bộ, 23 file, 4.1M) | Ảnh chụp full-screen sau đợt UI refresh, không tham chiếu, mục đích đã hoàn thành |

Tổng: **143 file, ~21MB** loại khỏi git, không ảnh hưởng bất kỳ chức năng
hay test nào (đã xác nhận zero reference).

### ❓ CẦN TÔI QUYẾT ĐỊNH

| # | Mục | Vấn đề | Lựa chọn đề xuất |
|---|---|---|---|
| 1 | `test/real_cloud_ai_verification_test.dart` dòng 63 (`linhVuc: 'hanh_vi'`) | Dữ liệu mẫu dùng domain code đã gỡ, nhưng không gây lỗi (test luôn bị skip mặc định) | (a) Sửa thành domain hợp lệ, hay (b) giữ nguyên vì không ảnh hưởng chức năng |
| 2 | Chiến lược lưu trữ `assets/videos/` (898MB) | Repo `.git` đã 1.97GiB | Chọn 1 trong 3 phương án ở mục 5, hoặc để lại xử lý ở giai đoạn hạ tầng riêng |
| 3 | Thư mục `lib/features/assessment/nine_domains/` | **Không phải rác** (code đang chạy), nhưng tên thư mục còn ghi "nine_domains" dù đã chuyển sang 7 lĩnh vực — đây là refactor/rename, KHÔNG thuộc phạm vi "xóa rác" của tác vụ này, chỉ ghi nhận để bạn cân nhắc ở 1 tác vụ riêng sau |

---

## 7. Kết quả `flutter test` (baseline trước khi xóa)

### 7a. Lần chạy đầu (`flutter test` toàn bộ 42 file, không loại trừ) — PHÁT HIỆN VẤN ĐỀ NGOÀI PHẠM VI

Chạy full suite mất bất thường lâu (~26 phút vẫn chưa xong, CPU gần như rảnh
→ nghi treo). Đã dừng tiến trình để lấy log, log xác nhận:

- **`test/ai_connectivity_ui_guard_test.dart`** có ít nhất 2 test treo đúng
  **10 phút/test** rồi mới `TimeoutException` — đây là nguyên nhân chính
  khiến cả suite chạy rất lâu (2 test này một mình đã ăn ~20 phút).
- **`test/video_flow_no_situation_test.dart`**: nhiều test FAIL vì
  `google_fonts` cố tải font `Fredoka-Bold` qua network thật trong môi
  trường test (bị chặn, trả lỗi) — thiếu mock cho `google_fonts` trong test
  setup.
- Một loạt lỗi khung `'_pendingFrame == null': is not true` /
  `'!inTest': is not true` xuất hiện xen kẽ — dấu hiệu ô nhiễm giữa các
  test (`testWidgets` trước đó không dọn sạch timer/animation trước khi
  test sau bắt đầu).
- Tại thời điểm dừng (chưa chạy hết 42 file): **185 PASS / 4 skip / 16 FAIL**.

**Quan trọng**: cả 3 vấn đề trên **không liên quan gì tới danh sách file đề
xuất xóa ở mục 6** — chúng là vấn đề sức khỏe test suite có sẵn từ trước,
nằm trong `ai_connectivity_ui_guard_test.dart` và `video_flow_no_situation_test.dart`
(2 file đang test tính năng đang sống, không nằm trong danh sách nghi ngờ).
Theo đúng nguyên tắc "không gộp dọn dẹp với thay đổi tính năng khác", **tôi
không tự sửa các lỗi này** — ghi nhận riêng, chờ bạn quyết định có xử lý ở
1 tác vụ khác hay không.

### 7b. Lần chạy 2 (loại trừ `ai_connectivity_ui_guard_test.dart` +
`real_cloud_ai_verification_test.dart`) — KẾT QUẢ CHÍNH THỨC

**185 PASS / 14 FAIL** trên 41 file (~199 test case). Đây là baseline
"trước dọn dẹp" chính thức.

**Quan trọng — cả 14 fail đều KHÔNG liên quan tới danh sách xóa ở mục 6**,
chia làm 3 nhóm nguyên nhân độc lập, tất cả đã tồn tại từ trước, không do
audit/dọn dẹp gây ra. Theo quyết định của bạn, **Giai đoạn B chỉ dọn rác,
không đụng tới 14 fail này** — ghi nhận riêng để xử lý ở tác vụ khác:

**Nhóm A — lệch số version schema DB (3 test)**: `seven_domains_migration_test.dart`,
`chan_dung_and_overview_description_migration_test.dart`,
`overview_migration_test.dart` hardcode `expect(await db.getVersion(), 10)`
nhưng `database.dart` đã lên version 11 (thêm bảng `notifications`) sau khi
viết test. Đây là 3 file tôi đã xác nhận là hợp lệ (test đúng migration đang
sống) — chỉ cần đồng bộ lại số version, không phải xóa hay đổi logic.

**Nhóm B — `google_fonts` cố tải font qua network thật trong test (lan ra
nhiều test)**: ảnh hưởng `screening_history_test.dart`,
`screening_flow_test.dart`, `video_flow_no_situation_test.dart` — thiếu mock
`google_fonts` trong test setup, gây lỗi rồi ô nhiễm sang các
`testWidgets` chạy ngay sau (`_pendingFrame`/`!inTest` assertion).

**Nhóm C — nội dung/kỳ vọng lệch nhau (2-3 test)**: `prompt_builder_test.dart`
kỳ vọng văn phong cũ ("phụ huynh/giáo viên") trong khi `prompt_builder.dart`
hiện dùng văn phong khác ("phụ huynh và giáo viên"); `ai_repository_test.dart`
có 1 case đáng chú ý hơn — kỳ vọng câu mặc định nhưng thực tế nhận về prompt
Trạng thái 1, cần điều tra riêng (có thể là bug thật, không chỉ do test cũ);
`screening_history_test.dart` có 1 case tìm `OutlinedButton` không thấy (UI
có thể đã đổi loại nút).

Danh sách đầy đủ 14 fail nằm trong log `flutter test`, không lặp lại ở đây
để tránh trùng lặp — có thể chạy lại lệnh dưới đây bất cứ lúc nào để tái
hiện:
```
flutter test $(find test -maxdepth 1 -name "*.dart" ! -name "ai_connectivity_ui_guard_test.dart" ! -name "real_cloud_ai_verification_test.dart")
```

Baseline tĩnh (đếm bằng grep, chỉ mang tính tham khảo):
- 42 file test, ~7656 dòng.
- ~163 khối `test(...)` + ~43 khối `testWidgets(...)`.

---

## 8. Giai đoạn B — kết quả thực thi (đã hoàn tất)

Đã duyệt và thực thi đúng danh sách ở mục 6:
- Xóa 4 thư mục (142 file, ~21MB): `.packaging_logs/`, `.scratch_e2e/`,
  `.scratch_screens/`, `artifacts/ui_refresh/`.
- Sửa `test/real_cloud_ai_verification_test.dart` dòng 63:
  `linhVuc: 'hanh_vi'` → `linhVuc: 'ngon_ngu'`.

Kiểm tra sau khi xóa:
- `flutter analyze`: **0 issues** (không đổi so với trước).
- `flutter test` (loại trừ 2 file như mục 7b): **185 PASS / 14 FAIL — khớp
  chính xác với baseline trước dọn dẹp**, xác nhận việc xóa không làm hỏng
  bất kỳ test nào đang PASS, và không phát sinh fail mới.

Chi tiết đầy đủ + 2 commit git xem `SETUP_REPORT.md`.
