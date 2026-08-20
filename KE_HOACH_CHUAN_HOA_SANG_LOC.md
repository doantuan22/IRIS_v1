# Kế Hoạch Chuẩn Hóa Bộ Sàng Lọc Mới — Giai Đoạn A

> **Trạng thái: CHỈ AUDIT + ĐỀ XUẤT — CHƯA ĐỔI TÊN FILE, CHƯA THÊM COMMENT
> NÀO.** Dừng lại chờ duyệt trước khi sang Giai đoạn B.

Thời điểm: 2026-08-20.

---

## Phần 1 — Audit file dữ liệu cần đổi tên

### 1.1 Danh sách đầy đủ

Chỉ có **đúng 1 file** cần đổi tên — đã xác nhận không còn file placeholder
nào sót lại (`find` toàn repo cho `*placeholder*` ra rỗng, đã bị xóa hoàn
toàn ở đợt ingest dữ liệu thật trước đó):

| File hiện tại | Vấn đề |
|---|---|
| `assets/reference/sang_loc_20_cau_4_muc_tuoi.json` | Tên tiếng Việt không dấu, dài (33 ký tự không kể đuôi), không nhất quán với style các file khác cùng thư mục |

### 1.2 Đối chiếu style đặt tên hiện có trong `assets/reference/`

```
expert_content.json
expert_content_so_sanh.json
expert_knowledge_seed.json          <- tiếng Anh, được lib/ đọc trực tiếp
sang_loc_20_cau_4_muc_tuoi.json     <- tiếng Việt, cần đổi
so_sanh_15_23_thang.json            <- tiếng Việt (file nguồn thô, không phải app runtime đọc)
so_sanh_24_47_thang.json
so_sanh_48_60_thang.json
video_manifest.json                 <- tiếng Anh, được lib/ đọc trực tiếp
```

Nhận xét: 2 file **thực sự được code Dart runtime đọc trực tiếp**
(`expert_knowledge_seed.json`, `video_manifest.json`) đều đặt tên tiếng
Anh ngắn gọn. Các file tiếng Việt còn lại (`so_sanh_*_thang.json`,
`expert_content*.json`) là dữ liệu nguồn thô/dev-only, không phải asset
runtime chính thức — ngoài phạm vi nhiệm vụ này (nhiệm vụ chỉ yêu cầu
chuẩn hóa file liên quan **bộ sàng lọc mới**). → File sàng lọc nên theo
đúng style của 2 file runtime kia.

### 1.3 Toàn bộ vị trí tham chiếu tên file (grep thật, không đoán)

Grep `sang_loc_20_cau_4_muc_tuoi` trên toàn repo (loại `build/`,
`.dart_tool/`) — **đúng 6 dòng, 3 file**:

| File | Dòng | Nội dung |
|---|---|---|
| `lib/domain/services/screening_loader_service.dart` | 15 | `'assets/reference/sang_loc_20_cau_4_muc_tuoi.json';` — hằng số `assetPath`, **điểm duy nhất code runtime đọc file** |
| `test/screening_scoring_service_test.dart` | 19 | `'assets/reference/sang_loc_20_cau_4_muc_tuoi.json',` — đường dẫn đọc trực tiếp bằng `File(...)` trong `setUpAll` |
| `SETUP_REPORT.md` | 22, 125, 196, 215 | 4 chỗ nhắc tên file (lịch sử + mô tả) |

**Đã xác nhận KHÔNG có ở**:
- `pubspec.yaml` — chỉ khai báo cả thư mục `assets/reference/` (dòng 47),
  không khai báo tên file lẻ → **không cần sửa** khi đổi tên.
- `README.md` — không nhắc tên file này.
- `KE_HOACH_CAU_TRUC_SANG_LOC_MOI.md` — tài liệu viết TRƯỚC khi file dữ
  liệu thật tồn tại, không nhắc đúng tên file này → không cần sửa.
- `CHANGELOG.md` — không nhắc.
- Không có script ingest/seed riêng cho file này (khác với
  `expert_knowledge_seed.json` có `scripts/generate_expert_knowledge_seed.dart`
  riêng) — bộ câu hỏi sàng lọc được đọc thẳng từ asset, không qua bước
  ingest/tiền xử lý nào.

### 1.4 Đề xuất tên mới

| Tên hiện tại | Đề xuất | Lý do |
|---|---|---|
| `sang_loc_20_cau_4_muc_tuoi.json` | **`screening_questions.json`** | Tiếng Anh, ngắn gọn, đúng nội dung (bộ câu hỏi sàng lọc), nhất quán style với `expert_knowledge_seed.json`/`video_manifest.json` — không cần nhồi số lượng câu/mức tuổi vào tên file (thông tin đó đã có trong `meta`/cấu trúc JSON, không cần lặp lại ở tên file, giống cách `video_manifest.json` không ghi số lượng video trong tên) |

Phương án khác đã cân nhắc và loại:
- `screening_20_4tiers.json` — vẫn nhồi số liệu vào tên, không cần thiết.
- `screening_data.json` — quá chung chung, không rõ là bộ câu hỏi hay kết
  quả.
- `screening_questionnaire.json` — đồng nghĩa nhưng dài hơn không cần
  thiết so với `screening_questions.json`.

---

## Phần 2 — Audit file code cần bổ sung comment

Phạm vi: chỉ 17 file thuộc bộ sàng lọc mới (đã grep xác nhận đây là toàn
bộ file có liên quan trong `lib/`/`test/`, không tính phần Đánh giá 7 lĩnh
vực).

### 2.1 Bắt buộc có comment kỹ (logic/quy tắc nghiệp vụ không hiển nhiên)

| File | Hiện trạng | Cần bổ sung |
|---|---|---|
| `lib/domain/services/screening_scoring_service.dart` | Đã có comment ở phần ngưỡng/mô tả giai đoạn, nhưng **`calculateScore()` thiếu giải thích quy tắc ưu tiên Giai đoạn 3→2→1** (tại sao kiểm tra GĐ3 trước, lý do "không để điểm cao che lấp lĩnh vực yếu") — hiện chỉ có code, không có comment tại khối `if/else if/else` (dòng 208-216). **`_calculateDomainScore()` (private, dòng 225) hoàn toàn KHÔNG có doc comment**, công thức quy đổi `diemTho / (3 * soCauTraLoi) * 12` (dòng 255) không có comment giải thích ý nghĩa (chuẩn hóa điểm về thang 12 khi có N/A). Các field trong `ScreeningQuestion`/`DomainScoreCalculation` phần lớn không có comment riêng từng field (`id`, `linhVuc`, `thuTuTrongLinhVuc`, `noiDung`, `diemTho`, `soCauTraLoi`, `soCauNa`). | Thêm: (a) comment tại `_calculateDomainScore` giải thích rõ công thức + lý do quy đổi thay vì lấy điểm thô trực tiếp khi có N/A; (b) comment tại khối if/else giải thích thứ tự ưu tiên 3→2→1 và lý do chống "bù điểm"; (c) comment field-level cho các field còn thiếu trong 2 class trên. |
| `lib/core/constants/screening_domains.dart` | `resolveScreeningAgeTier()` đã có docstring khá đầy đủ (giải thích rõ quy tắc kẹp 2 đầu + lý do) từ đợt sửa Vấn đề 2 trước — **đạt yêu cầu, không cần sửa thêm**. `screeningDomainColors`/`screeningAnswerOptionLabels` cũng đã có comment giải thích lý do (tránh thang đỏ-vàng-xanh). | Rà soát lại 1 lượt, có thể chỉ cần bổ sung nhỏ, KHÔNG phải viết lại — mức độ thấp hơn scoring_service. |
| `lib/data/local/database.dart` (chỉ đoạn migration version 12 + 13 liên quan sàng lọc) | Đã có comment đầy đủ, giải thích rõ lý do xóa bảng cũ/tạo bảng mới và lý do version 13 (reseed so_sanh) — **đạt yêu cầu, không cần sửa**. | Không cần. |
| `lib/domain/models/screening_session.dart` | Có docstring class-level tốt, nhưng field `coCanhBao` (dòng 10) **không có comment** — đây là field DỄ HIỂU NHẦM NHẤT trong toàn bộ model: cột này còn tồn tại trong schema (không migration) nhưng logic tính/dùng đã bị gỡ hoàn toàn ở đợt trước (task "bỏ màn cờ cảnh báo"), nên **giá trị luôn là `false` kể từ đó** — người đọc code sau này rất dễ tưởng nhầm đây là field đang hoạt động. | Bắt buộc thêm comment giải thích rõ hiện trạng "luôn false, giữ lại vì lý do schema, xem lịch sử ở SETUP_REPORT.md". |
| `lib/domain/models/screening_domain_result.dart` | Field-level comment thiếu cho `diemTho`, `soCauTraLoi`, `soCauNa` (chỉ có `mucLinhVuc` và class-doc). | Bổ sung field-level. |
| `lib/domain/models/screening_answer.dart` | Tương tự — thiếu comment cho `cauHoiId`, `linhVuc`. `nhomVanDong` đã có giải thích ở class-doc (đủ). | Bổ sung nhỏ. |
| `lib/data/local/tables/screening_sessions_table.dart`, `screening_domain_results_table.dart`, `screening_answers_table.dart` | Đã có comment SQL khá đầy đủ từ đợt dựng schema — **đạt yêu cầu phần lớn**, riêng `screening_sessions_table.dart` có đoạn giải thích `co_canh_bao` nhưng viết theo hướng "đang dùng" — **cần cập nhật nhẹ để khớp hiện trạng đã gỡ logic** (tránh mâu thuẫn với model ở trên). | Cập nhật nhỏ 1 chỗ trong `screening_sessions_table.dart`. |

### 2.2 Nên có comment cơ bản (mục đích tổng thể, điểm nối luồng)

| File | Hiện trạng | Cần bổ sung |
|---|---|---|
| `lib/data/repositories/screening_repository.dart` | Có comment tổng quan ở đầu file + vài chỗ, nhưng phần lớn method public (`getForChild`, `getSessionsByChildId`, `getById`, `getLatestForChild`, `getAnswers`, `getDomainResults`, `hasScreening`) không có docstring riêng giải thích mục đích/khác biệt giữa các hàm gần giống nhau (VD `getForChild` vs `getSessionsByChildId` — thực chất là alias, dễ gây thắc mắc "sao có 2 hàm giống nhau"). | Thêm docstring ngắn cho các method public, đặc biệt giải thích `getForChild`/`getSessionsByChildId` là alias. |
| `lib/features/screening/screening_intro_page.dart` | Đã có comment khá tốt (15 dòng/109 dòng, giải thích rõ lý do dùng `push` thay vì `pushReplacement`). | Đạt yêu cầu, không cần sửa. |
| `lib/features/screening/screening_tool_confirm_page.dart` | **Gần như không có comment nào** (1 dòng/80 dòng) — không giải thích vai trò màn hình trong luồng tổng thể (Bước 3, giữa Intro và Questionnaire). | Thêm docstring class-level giải thích vị trí trong luồng. |
| `lib/features/screening/screening_questionnaire_page.dart` | 11 dòng comment/494 dòng — có vài chỗ quan trọng đã giải thích (VD lý do gỡ màn cờ cảnh báo), nhưng thiếu comment ở các đoạn UI dài (danh sách `_AnswerOptionTile`) và ở `_finishAndSave` (điểm nối service chấm điểm + lưu DB + ghi lịch sử). | Thêm comment ở các điểm nối luồng chính, không cần comment từng dòng UI. |
| `lib/features/screening/screening_result_page.dart` | 7 dòng/413 dòng — thiếu giải thích 2 chế độ hiển thị (`scoreResult` trong bộ nhớ vs đọc lại từ DB qua `screeningId`) dù đây là điểm dễ nhầm lẫn khi đọc code lần đầu (docstring class hiện có nhắc sơ nhưng method-level thiếu). | Bổ sung docstring ở `_buildContent`/`_loadFromDb` giải thích rõ 2 luồng dữ liệu. |
| `lib/features/screening/screening_history_list_page.dart` | 4 dòng/301 dòng — thiếu giải thích tại sao luôn đọc `active_child_id` "tươi" thay vì cache (đã có 1 comment ngắn ở `_loadData` nhưng có thể rõ hơn). | Bổ sung nhỏ. |
| `lib/domain/services/screening_loader_service.dart` | Đã có comment vừa đủ (giải thích cache, tách `parseJson` để test không cần Flutter engine). | Đạt yêu cầu, không cần sửa. |
| `lib/domain/services/screening_change_service.dart` | File nhỏ (17 dòng), đã có class-doc giải thích mục đích. | Đạt yêu cầu, không cần sửa. |
| `lib/features/screening/screening_intro_page.dart` | (đã liệt kê ở trên) | — |

### 2.3 Không cần sửa (đã đạt chuẩn từ các đợt trước)

`screening_domains.dart` (phần lớn), `database.dart` (đoạn migration
sàng lọc), `screening_loader_service.dart`, `screening_change_service.dart`,
`screening_intro_page.dart`, 3 file bảng SQL (phần lớn) — do các đợt sửa
trước (Giai đoạn B, sửa Vấn đề 1/2) đã viết comment giải thích khá kỹ theo
đúng tinh thần "giải thích TẠI SAO" ngay từ đầu.

---

## Tổng hợp việc sẽ làm ở Giai đoạn B (nếu được duyệt)

1. Đổi tên `assets/reference/sang_loc_20_cau_4_muc_tuoi.json` →
   `assets/reference/screening_questions.json`.
2. Sửa 2 vị trí code tham chiếu: `screening_loader_service.dart:15`,
   `test/screening_scoring_service_test.dart:19`.
3. Cập nhật 4 chỗ nhắc tên file cũ trong `SETUP_REPORT.md`.
4. Bổ sung comment theo đúng mức độ ở bảng 2.1/2.2 — **không sửa bất kỳ
   dòng logic nào**, không comment tràn lan ở chỗ đã đạt chuẩn (2.3).
5. Verify: `flutter analyze`, `flutter test` (đặc biệt 3 ví dụ mẫu A/B/C),
   build + verify thật trên emulator sau khi đổi tên file.
6. Commit tách riêng: 1 commit đổi tên + sửa tham chiếu, các commit riêng
   cho từng nhóm file bổ sung comment (không gộp đổi tên với thêm comment).

---

**Chưa đổi gì.** Chờ bạn duyệt tên file mới (`screening_questions.json`
hoặc tên khác) và phạm vi comment ở mục 2 trước khi sang Giai đoạn B.
