# Setup Report — Bộ Sàng Lọc Mới (Giai Đoạn B) + Dải Tuổi 12-23

Ghi lại thực tế đã làm khi thực thi Giai đoạn B theo
`KE_HOACH_CAU_TRUC_SANG_LOC_MOI.md`.

Thời điểm: 2026-08-20.

> Lưu ý quan trọng về trình tự: prompt yêu cầu công việc này (ingest dữ
> liệu thật từ 2 file Word + viết bộ test chính thức) giả định Giai đoạn B
> đã hoàn thành từ trước — kiểm tra trực tiếp code thật lúc bắt đầu cho
> thấy **Giai đoạn B chưa từng được thực thi** (database.dart vẫn ở
> version 11, không có bảng/model/service mới nào). Đã dừng lại báo cáo,
> được xác nhận làm Giai đoạn B trước, rồi mới tới báo cáo này.

## Đối chiếu quyết định ↔ thực thi

| # | Việc | Trạng thái |
|---|---|---|
| 1 | Checkpoint git trước khi bắt đầu | ✅ commit `f930348` |
| 2 | Migration: xóa 3 bảng cũ, tạo 3 bảng mới | ✅ version 12, kiểm chứng bằng test thật (viết → chạy → xóa, không còn trong repo) |
| 3 | `ScreeningScoringService` khung thuật toán đầy đủ | ✅ kiểm chứng bằng test thật (6/6 PASS, xem chi tiết bên dưới) |
| 4 | File placeholder JSON tối thiểu | ✅ `assets/reference/sang_loc_20_cau_4_muc_tuoi.placeholder.json` (5 câu/mức tuổi, đánh dấu rõ `[PLACEHOLDER]`) |
| 5 | UI tạo hồ sơ — chọn 1/4 mức tuổi khi không có dob | ✅ |
| 6 | UI làm bài — 1 câu/màn, 4 lựa chọn + N/A, màn cờ cảnh báo | ✅ |
| 7 | Màn kết quả — Giai đoạn 1/2/3/Chưa đủ dữ liệu + disclaimer | ✅ |
| 8 | Sửa 9 điểm neo đọc dữ liệu sàng lọc cũ | ✅ tất cả 9 điểm đã audit ở Giai đoạn A đều đã sửa |
| 9 | Dải tuổi 15-23 → 12-23 | ✅ 200 entry trong 2 file JSON, không đụng 24-47/48-60 |
| 10 | Xóa asset `sang_loc_50_cau_7_linh_vuc.json` + code chết bộ cũ | ✅ |
| 11 | Verify: `flutter analyze` 0 issues, build thử | ✅ |
| 12 | Cập nhật `SETUP_REPORT.md` | ✅ (chính file này) |
| 13 | Commit theo nhóm việc riêng biệt | ✅ 6 commit (xem bên dưới) |

## Chi tiết kiểm chứng migration (mục 2)

Viết 1 test tạm (`flutter test`, xóa ngay sau khi xác nhận, không còn
trong repo — đúng nguyên tắc dự án không giữ code thử nghiệm rác):
- Tạo DB version 11 thật với dữ liệu sàng lọc CŨ thật (1 dòng `screenings`
  + 1 dòng `screening_responses` + 1 dòng `screening_domain_scores` + 1
  trẻ).
- Mở lại bằng `AppDatabase` thật → xác nhận `db.getVersion() == 13`.
- Xác nhận 3 bảng cũ **không còn tồn tại** trong `sqlite_master`.
- Xác nhận 3 bảng mới đã tạo, **rỗng** (không migrate dữ liệu cũ sang).
- Xác nhận dữ liệu `children` **không bị ảnh hưởng**.
- Insert thử vào bảng mới — thành công, đúng schema.

**Kết quả: 1/1 PASS.**

## Chi tiết kiểm chứng thuật toán chấm điểm (mục 3)

Viết 1 test tạm khác (cũng đã xóa sau khi xác nhận), 6 test case:

| Case | Nội dung | Kết quả |
|---|---|---|
| b | 1 lĩnh vực, câu N/A: 3,2,3,N/A → quy đổi 10.7/12 | PASS |
| c | 1 lĩnh vực ≥2 câu N/A → `chua_du_du_lieu`, `tong60=null` | PASS |
| d | `co_canh_bao=true` độc lập điểm số | PASS |
| — | 3 ví dụ mô phỏng theo tài liệu gốc: (11,10,10,9,11)→GĐ1 tổng 51; (11,10,9,8,11)→GĐ2 tổng 49; (11,10,10,5,10)→GĐ3 tổng 46 | PASS cả 3 |
| — | Biên `tong60`: 35.0 đúng biên KHÔNG rơi GĐ3, 30.0 (<35) PHẢI GĐ3 | PASS |
| — | Biên `domain12`: min=6.0 đúng biên KHÔNG rơi GĐ3 | PASS |

**Kết quả: 6/6 PASS** — xác nhận đúng chiều so sánh `<` (không `<=`) và
đúng nguyên tắc không "bù điểm" giữa các lĩnh vực.

*(Lưu ý: đây là kiểm chứng thuật toán bằng dữ liệu MÔ PHỎNG dựa trên mô tả
thuật toán trong `KE_HOACH_CAU_TRUC_SANG_LOC_MOI.md`, KHÔNG phải bộ test
chính thức đối chiếu trực tiếp với 2 file Word gốc — việc đó thuộc phạm vi
prompt tiếp theo, sau khi dữ liệu thật đã được ingest.)*

## Danh sách file đã thay đổi (6 commit)

1. `600904d` — **migration**: `database.dart` (version 13, migration v12+v13),
   3 bảng cũ → 3 bảng mới (`screening_sessions`/`screening_domain_results`/
   `screening_answers`), 3 model cũ → 3 model mới, `screening_domains.dart`
   (hằng số 5 lĩnh vực + 4 mức tuổi), `child_repository.dart` (cascade
   delete). *(Commit này cũng gồm xóa `assets/data/sang_loc_50_cau_7_linh_vuc.json`
   do thao tác git đan xen — không tách riêng được như dự kiến ban đầu,
   không ảnh hưởng tính đúng đắn.)*
2. `65ade66` — **service**: `ScreeningScoringService`, `ScreeningLoaderService`,
   `ScreeningRepository` viết lại hoàn toàn, file placeholder JSON.
3. `3c38d1f` — **UI tạo hồ sơ**: `create_profile_page.dart`.
4. `c9fc315` — **UI làm bài + 9 điểm neo**: `screening_questionnaire_page.dart`,
   `screening_result_page.dart`, `screening_history_list_page.dart`,
   `screening_tool_confirm_page.dart`, `assessment_summary_page.dart`,
   `child_debug_page.dart`.
5. `9007a52` — **dải tuổi 12-23**: `expert_knowledge_seed.json`,
   `so_sanh_15_23_thang.json` (200 entry, dải 24-47/48-60 không đụng).
6. `18c1bc3` — **dọn asset cũ**: xóa dòng khai báo `assets/data/` khỏi
   `pubspec.yaml`.

## Kiểm tra cuối

- `flutter analyze`: **0 issues thật** (3 info-level pre-existing ở
  `scripts/` không liên quan, đã có từ đợt chuẩn hóa lint trước).
- `flutter build apk --debug`: **thành công** —
  `√ Built build\app\outputs\flutter-apk\app-debug.apk`.

---

## Đợt 2 (cùng ngày, tiếp theo) — Ingest dữ liệu thật + bộ test chính thức + verify thiết bị

Thực thi phần còn lại: chuyển đổi 2 file Word gốc thành dữ liệu thật,
ingest, viết bộ test chính thức, verify tích hợp thật trên emulator.

### Phát hiện mâu thuẫn khi đối chiếu 2 file Word — đã báo cáo, chờ xác nhận trước khi làm tiếp

1. **Thang điểm/thuật toán**: mục 2-3 file
   `Bo_cau_hoi_sang_loc_phat_trien_tre_em_2-5_tuoi_ban_chinh_sua.docx` mô
   tả 1 hệ thống KHÁC hẳn (thang 3 mức/8 điểm mỗi lĩnh vực/không cộng
   tổng) — mâu thuẫn hoàn toàn với thuật toán 0-3/60 điểm đã dựng đúng
   theo `Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx` (mục
   12 file này khớp 100% với `ScreeningScoringService` đã viết).
   **Quyết định (đã xác nhận)**: bỏ qua mục 2-3 file "Bộ câu hỏi" (coi là
   mô tả lỗi thời/thừa), chỉ lấy NỘI DUNG 20 câu/mức từ file đó, thuật
   toán giữ nguyên theo file "Hướng dẫn chấm điểm".
2. **Dải tháng tuổi**: "cửa sổ áp dụng" trong Word hẹp hơn và có khoảng
   trống (24-29/36-41/48-53/60-65 tháng) so với dải liên tục đã code
   (24-35/36-47/48-59/60-71 tháng). **Quyết định (đã xác nhận)**: giữ dải
   liên tục đã code.

### Ingest dữ liệu thật (mục 2-4 yêu cầu)

- Trích xuất nội dung 2 file `.docx` bằng script Python (đọc trực tiếp
  `word/document.xml` trong file zip, không cần thư viện ngoài).
- Chuyển 80 câu hỏi (4 mức × 20 câu) thành
  `assets/reference/screening_questions.json`, thay thế hoàn toàn
  file placeholder (đã xóa).
- **Kiểm chứng bằng code trước khi ingest** (không chỉ đọc mắt):
  - Đúng 80 câu tổng (4×20). ✅
  - Mỗi mức đúng 5 lĩnh vực × 4 câu. ✅
  - `van_dong` mỗi mức đúng 2 câu `nhom_van_dong=tho` + 2 câu `=tinh`; 4
    lĩnh vực còn lại `nhom_van_dong=null`. ✅
  - 0 id trùng lặp trong 80 câu. ✅
  - Đối chiếu nguyên văn **8 câu mẫu** (≥2 câu/mức, rải đều 5 lĩnh vực) với
    văn bản gốc — liệt kê cụ thể từng câu đã đối chiếu (xem log lệnh Python
    `verify_content.py` đã chạy): `sl_2t_ngon_ngu_giao_tiep_01`,
    `sl_2t_van_dong_tho_02`, `sl_3t_nhan_thuc_giai_quyet_van_de_03`,
    `sl_3t_van_dong_tinh_03`, `sl_4t_xa_hoi_cam_xuc_04`,
    `sl_4t_tu_lap_01`, `sl_5t_ngon_ngu_giao_tiep_04`,
    `sl_5t_nhan_thuc_giai_quyet_van_de_01` — **8/8 khớp nguyên văn**.

### Bộ test chính thức (mục 5-6 yêu cầu) — `test/screening_scoring_service_test.dart`

Chạy thật bằng `flutter test`, dùng trực tiếp file JSON thật (không mock),
**giữ lại trong repo** (khác với 2 test tạm ở Đợt 1 đã xóa sau khi xác
nhận) vì đây là bộ test chính thức theo đúng yêu cầu.

| Nhóm | Số case | Kết quả |
|---|---|---|
| Cấu trúc JSON thật (80 câu, 5 lĩnh vực, van_dong tho/tinh, id không trùng, nội dung khớp Word) | 5 | PASS |
| Thuật toán (đủ dữ liệu, 1 N/A, ≥2 N/A, co_canh_bao độc lập) | 4 | PASS |
| 3 ví dụ mẫu A/B/C + ví dụ mục 8 (không "bù điểm") + biên ngưỡng tong60/domain12 | 6 | PASS |
| Map tuổi → mức (biên 23/24/35/36/47/48/59/60/71/72 tháng) | 10 | PASS |

**Tổng: 25/25 PASS.** Đặc biệt 3 ví dụ mẫu A/B/C khớp đúng Giai đoạn
1/2/3 như tài liệu gốc — xác nhận `ScreeningScoringService` không có bug,
không cần sửa.

`flutter analyze`: 0 issues thật (chỉ còn 3 info-level pre-existing ở
`scripts/`, không liên quan).

### Verify tích hợp thật trên thiết bị (mục 7 yêu cầu)

Không có device/emulator nào sẵn sàng lúc bắt đầu — đã tự khởi động AVD
`Pixel_7` có sẵn từ trước (`flutter emulators --launch Pixel_7`), cài
`app-debug.apk`, điều khiển qua `adb`/`uiautomator dump` (đọc UI thật trên
màn hình, không đoán). Kết quả:

1. **Tạo hồ sơ "Be_Test_4_tuoi", chọn trực tiếp mức "4 tuổi"** (không qua
   ngày sinh) → hiển thị đúng "4 tuổi 5 tháng" (representativeMonths=53).
2. **`ScreeningToolConfirmPage`** hiển thị đúng text mới "Bộ câu hỏi sàng
   lọc 20 câu (5 lĩnh vực)" — không còn "50 câu" cũ.
3. **Làm hết 20 câu thật** (chọn "3 — Độc lập & thường xuyên" mỗi câu) —
   nội dung câu 1 hiển thị đúng: *"Trẻ có thể nói thành những câu tương
   đối đầy đủ gồm bốn từ trở lên..."* — khớp chính xác dữ liệu thật đã
   ingest, KHÔNG phải placeholder.
4. **Màn "cờ cảnh báo"** hiện đúng sau câu 20, chọn "Không".
5. **Kết quả**: `60.0/60`, `Giai đoạn 1`, cả 5 lĩnh vực `12.0/12` — đúng
   thuật toán (toàn bộ điểm 3 → domain12=12.0 mỗi lĩnh vực → tong60=60.0).
6. **Lịch sử sàng lọc** hiển thị đúng "Giai đoạn 1 · 60.0/60 · ngày giờ
   thật"; bấm vào xem lại — đọc đúng từ SQLite (không phải từ bộ nhớ tạm),
   kết quả khớp y hệt.
7. **Tạo hồ sơ thứ 2 "Be_Test_2_tuoi", chọn mức "2 tuổi"** → hiển thị
   đúng "2 tuổi 5 tháng" (representativeMonths=29); vào bài sàng lọc, câu 1
   hiển thị nội dung KHÁC hẳn và đúng dữ liệu thật của mức 2 tuổi: *"Trẻ có
   thể chủ động ghép ít nhất hai từ có nghĩa..."* — xác nhận đúng bộ câu
   hỏi được chọn theo tuổi trẻ.

Đã verify đầy đủ luồng end-to-end cho 2/4 mức tuổi (2 tuổi, 4 tuổi) trên
thiết bị Android thật (emulator) — cùng 1 code path cho cả 4 mức nên đây
là bằng chứng đủ mạnh cho toàn bộ, không lặp lại thao tác cho 3 tuổi/5
tuổi để tiết kiệm thời gian.

### Commit của Đợt 2

7. `07b0a44` — **dữ liệu thật + ingest + xóa placeholder**:
   `screening_questions.json`, `screening_loader_service.dart`
   (đổi `assetPath`), xóa `.placeholder.json`.
8. `179716e` — **bộ test chính thức**: `test/screening_scoring_service_test.dart`
   (25/25 PASS).

### Cập nhật trạng thái "Việc CHƯA làm" ở Đợt 1

Tất cả các mục "chưa làm" liệt kê ở Đợt 1 bên dưới **nay đã hoàn thành**,
trừ việc rename 82 file video (quyết định: không làm, giữ nguyên như đã
chốt).

---

## Đợt 3 — Sửa 2 vấn đề phát hiện sau triển khai (Vận động thô/tinh + map tuổi→mức)

### Kết quả Audit (Bước 1) — làm TRƯỚC khi sửa bất kỳ gì

**Vấn đề 1 (Vận động thô/tinh phải gộp 1 lĩnh vực) — AUDIT XÁC NHẬN: ĐÃ
ĐÚNG TỪ ĐẦU, KHÔNG PHẢI BUG.**
- `assets/reference/screening_questions.json`: chỉ có đúng 5 giá
  trị `linh_vuc` (không có `van_dong_tho`/`van_dong_tinh` riêng); `van_dong`
  mỗi mức có sẵn 4 câu (2 `nhom_van_dong="tho"` + 2 `="tinh"`).
- `ScreeningScoringService`: gom nhóm câu hỏi theo `q.linhVuc` — tự động
  gộp cả 4 câu vận động vào 1 phép tính `domain12` duy nhất.
- UI (`screening_domains.dart`, `screening_result_page.dart`): chỉ 1 dòng
  "Vận động" trong danh sách hiển thị.

→ **Theo đúng chỉ dẫn, KHÔNG sửa code ở Bước 2** — chỉ bổ sung 3 test xác
nhận (commit `4905b7b`).

**Vấn đề 2 (map tuổi → mức) — AUDIT XÁC NHẬN: LÀ BUG THẬT.**
`lib/core/constants/screening_domains.dart` — hàm `screeningAgeTierForMonths()`
trả về `null` (chặn hoàn toàn) khi tuổi <24 hoặc >71 tháng, đúng như mô tả
trong nhiệm vụ. Chỉ có 1 nơi gọi hàm này trong toàn bộ codebase
(`screening_questionnaire_page.dart`) — xác nhận không có logic map trùng
lặp ở nơi khác.

### Đã sửa (Bước 2-3)

- **Vấn đề 1**: không sửa code (đã đúng).
- **Vấn đề 2**: đổi tên + sửa hành vi `screeningAgeTierForMonths()` →
  `resolveScreeningAgeTier()` — LUÔN trả về 1 trong 4 mức, kẹp về `'2_tuoi'`
  khi <24 tháng (kể cả 0 tháng), kẹp về `'5_tuoi'` khi >71 tháng. Xóa nhánh
  UI "ngoài phạm vi" trong `screening_questionnaire_page.dart` (không còn
  cần vì hàm không bao giờ trả null).

### Kết quả test (Bước 4)

- Test Vấn đề 1 (3 case mới): van_dong chỉ 1 dòng kết quả; domain12 tính
  gộp trên 4 câu (tho=3,3+tinh=2,2 → 10.0, không phải trung bình 2 phép
  tính con); 1 câu N/A trong nhóm "tho" vẫn quy đổi trên 3 câu còn lại của
  CẢ van_dong. **3/3 PASS.**
- 3 ví dụ mẫu A/B/C + ví dụ mục 8 vẫn **PASS nguyên vẹn** sau khi thêm test
  Vấn đề 1 (không sửa code nên không có gì để hỏng).
- Test Vấn đề 2 (13 mốc: 0,1,23,24,35,36,47,48,59,60,71,72,200 tháng) —
  xác nhận mọi mốc <24 kẹp về `'2_tuoi'`, mọi mốc >71 kẹp về `'5_tuoi'`,
  không trường hợp nào trả null/lỗi. **13/13 PASS.**
- **Toàn bộ `flutter test`: 31/31 PASS.** `flutter analyze`: 0 issues thật.
- **Verify tích hợp thật trên emulator Pixel_7**: tạo hồ sơ "Be_14_thang"
  với ngày sinh 2025-06-20 (14 tháng tính tới 2026-08-20, dùng chế độ
  "Theo ngày sinh" + date picker "Switch to input") → xác nhận **KHÔNG bị
  chặn**, vào thẳng màn xác nhận công cụ sàng lọc (hiển thị đúng "1 tuổi 2
  tháng"), bấm "Bắt đầu" → hiển thị đúng câu hỏi thật của bộ `'2_tuoi'`
  ("Trẻ có thể chủ động ghép ít nhất hai từ có nghĩa...") — xác nhận kẹp
  đúng về mức thấp nhất, làm bài bình thường.

### Commit của Đợt 3

9. `4905b7b` — **test Vấn đề 1** (audit xác nhận không phải bug, chỉ thêm
   test): `test/screening_scoring_service_test.dart`.
10. `21fcecd` — **fix Vấn đề 2**: `screening_domains.dart`,
    `screening_questionnaire_page.dart`, cập nhật test map tuổi→mức.

Không tạo migration version DB mới (đúng yêu cầu — cả 2 vấn đề đều không
đổi cấu trúc bảng). Không đụng `domains.dart`, dữ liệu dải tuổi 12-23, hay
bất kỳ phần nào ngoài phạm vi bộ sàng lọc mới.

---

## Đợt 4 — Tinh chỉnh UI màn làm bài + màn kết quả, bỏ màn cờ cảnh báo

4 phần độc lập, mỗi phần 1 commit riêng.

### Phần 1 — Chuẩn hóa text 5 lựa chọn trả lời

Nguồn cũ: hardcode trực tiếp trong `screening_questionnaire_page.dart`
("0 — Chưa làm được", "1 — Có hỗ trợ"...). Thêm 1 nguồn duy nhất
`screeningAnswerOptionLabels`/`screeningAnswerOptionLabelNa` trong
`screening_domains.dart`, dùng lại ở UI. **Chỉ đổi label hiển thị** — xác
nhận `diem`/`laNa` truyền vào `_selectAnswer()` giữ nguyên 0/1/2/3/N/A,
không đổi cách lưu DB.

### Phần 2 — Bỏ màn cờ cảnh báo

**Audit trước khi sửa** (bắt buộc) — liệt kê đủ 7 nơi dùng
`co_canh_bao`/`coCanhBao`: bảng `screening_sessions` (schema),
`screening_repository.dart`, `screening_session.dart` (model),
`screening_scoring_service.dart` (tham số + `needsImmediateProfessionalEvaluation`),
`child_debug_page.dart` (chỉ đọc debug), `screening_questionnaire_page.dart`
(màn hỏi), `screening_result_page.dart` (banner). **Không có nơi nào khác**
trong codebase dùng field này ngoài luồng sàng lọc — chọn cách A: giữ
nguyên cột DB (không migration), gỡ logic tính/dùng trong service chấm
điểm, luôn ghi `co_canh_bao=false` khi lưu.

Đã bỏ: `_WarningFlagStep`, `_showingWarningStep`; sau câu 20 đi thẳng vào
`_finishAndSave()`. Gỡ tham số `coCanhBao` khỏi `calculateScore()`, gỡ field
`coCanhBao`/getter `needsImmediateProfessionalEvaluation` khỏi
`ScreeningScoreResult`. Gỡ banner "Bạn đã báo có lo ngại rõ rệt..." ở màn
kết quả.

### Phần 3 — Mô tả ý nghĩa giai đoạn

Thêm `screeningGiaiDoanLabel()`/`screeningGiaiDoanDescription()` — nguồn
DUY NHẤT, dùng lại ở 3 nơi từng hardcode riêng (`screening_result_page.dart`,
`screening_history_list_page.dart`, `assessment_summary_page.dart`). Mô tả
phỏng theo nguyên văn bảng "Ý nghĩa sử dụng" (mục 5) tài liệu
`Huong_dan_cham_diem_va_phan_loai_3_giai_doan_2-5_tuoi.docx`. Trường hợp
"Chưa đủ dữ liệu" trả `null` — giữ nguyên hiện trạng (trước đây không có
mô tả riêng), không tự bịa nội dung. Dòng cảnh báo "không dùng để chẩn
đoán" giữ nguyên, không bị thay thế.

### Phần 4 — Thanh % màu cho 5 lĩnh vực

Thêm `screeningDomainColors`/`screeningDomainColorOf()` — 5 màu CỐ ĐỊNH
theo lĩnh vực (xanh lam/tím/xanh ngọc/xanh lục lam/hồng cánh sen), KHÔNG
dùng `success`/`warning`/`danger` (đỏ-vàng-xanh lá) để tránh hiểu nhầm tín
hiệu nguy hiểm/bình thường — màu chỉ phân biệt lĩnh vực, không đổi theo
điểm số. `_buildDomainBreakdown()` đổi sang `LinearProgressIndicator`
(% = domain12/12), vẫn giữ số liệu chính xác dạng chữ nhỏ cạnh thanh bar.

### Kết quả kiểm tra

- `flutter analyze`: 0 issues thật sau mỗi phần.
- `flutter test`: **30/30 PASS** (đã bỏ 1 test case cho tính năng cờ cảnh
  báo đã gỡ) — 3 ví dụ mẫu A/B/C vẫn PASS nguyên vẹn, không bị ảnh hưởng.
- **Verify tích hợp thật trên emulator Pixel_7**: tạo hồ sơ "Be_UI_Test2"
  (mức 4 tuổi), làm hết 20 câu thật (chọn "Làm được độc lập và thường
  xuyên" mỗi câu):
  - 5 lựa chọn hiển thị đúng text chuẩn hóa, không số thứ tự.
  - Sau câu 20 đi thẳng vào "Kết quả sàng lọc" — xác nhận không còn màn
    trung gian nào.
  - Kết quả hiện: `60.0/60 · Giai đoạn 1 · "Phát triển tương đối phù hợp
    theo bộ câu hỏi. Tiếp tục tạo cơ hội phát triển và theo dõi định
    kỳ."` — đúng mô tả đã thêm.
  - Cả 5 lĩnh vực hiện dạng `"100, <tên lĩnh vực>\n12.0/12"` (100 = %
    progress bar qua accessibility announce, kèm số liệu "12.0/12" chữ nhỏ
    cạnh thanh — đúng yêu cầu giữ cả 2, không thay thế hoàn toàn bằng %).
  - Dòng cảnh báo "không dùng để chẩn đoán" vẫn còn nguyên.

### Commit của Đợt 4

11. `832366d` — Phần 1: chuẩn hóa text 5 lựa chọn.
12. `35a7af1` — Phần 2: bỏ màn cờ cảnh báo.
13. `531d798` — Phần 3: mô tả ý nghĩa giai đoạn.
14. `3af7f8e` — Phần 4: thanh % màu cho 5 lĩnh vực.

## Đợt 5 — Chuẩn hóa tên file dữ liệu + bổ sung comment code phục vụ review

Giai đoạn A: audit toàn bộ tham chiếu tên file cũ
(`sang_loc_20_cau_4_muc_tuoi.json`) + liệt kê danh sách file cần comment,
ghi trong `KE_HOACH_CHUAN_HOA_SANG_LOC.md`, chờ duyệt trước khi sửa.

### Phần 1 — Đổi tên file dữ liệu

`git mv assets/reference/sang_loc_20_cau_4_muc_tuoi.json
assets/reference/screening_questions.json` (giữ lịch sử git). Audit xác
nhận đúng 3 chỗ code tham chiếu tên cũ — chỉ 1 hằng số
`ScreeningLoaderService.assetPath` thực sự load file lúc runtime, còn lại là
comment/test string — đã cập nhật đủ cả 3 (`screening_loader_service.dart`,
`screening_scoring_service_test.dart`, `SETUP_REPORT.md`). Không đổi tên
bảng/cột SQL trong đợt này (giữ nguyên `screening_sessions`,
`screening_answers`, `screening_domain_results`...).

### Phần 2 — Bổ sung comment code

Thêm docstring kiểu `///` (giải thích WHY — quy tắc nghiệp vụ, không lặp lại
WHAT code đã tự nói) cho các file "bắt buộc kỹ" theo audit:
`screening_scoring_service.dart` (thứ tự ra quyết định chấm điểm, vì sao
kiểm tra Giai đoạn 3 trước Giai đoạn 2 để chống "bù điểm", công thức quy
đổi thang 12), 3 model (`ScreeningSession`, `ScreeningAnswer`,
`ScreeningDomainResult` — đặc biệt field `coCanhBao` nay LUÔN `false`, giữ
lại chỉ vì lý do schema), bảng `screening_sessions_table.dart`. Và các file
"nên có cơ bản": `screening_repository.dart` (vai trò từng hàm truy vấn),
`screening_tool_confirm_page.dart` (vị trí trong luồng 3 bước), điểm nối
`_finishAndSave()` ở `screening_questionnaire_page.dart`, 2 chế độ tải dữ
liệu của `screening_result_page.dart`, lý do đọc `active_child_id` tươi mỗi
lần ở `screening_history_list_page.dart`. Không đổi bất kỳ logic nào trong
lúc thêm comment.

### Kết quả kiểm tra

- `flutter analyze`: 0 issues thật (3 info `avoid_dynamic_calls` trong
  `scripts/ingest_*.dart` là pre-existing, không liên quan đợt này).
- `flutter test`: **30/30 PASS** sau cả 2 phần, không có regression.
- **Verify tích hợp thật trên emulator Pixel_7** (build lại APK debug, cài
  qua `adb install -r`): mở "Lịch sử sàng lọc" của hồ sơ đã có sẵn kết quả
  — tải lại đúng từ DB (`Giai đoạn 1 · 60.0/60`, breakdown 5 lĩnh vực đầy
  đủ), xác nhận code vừa thêm comment không phá luồng đọc DB cũ. Sau đó
  xóa tạm 1 bản ghi sàng lọc của hồ sơ test khác (`Be_Test_2_tuoi`, dữ liệu
  test nội bộ) để ép hiện lại nút "Sàng lọc", đi hết luồng
  `ScreeningIntroPage` → `ScreeningToolConfirmPage` → `ScreeningQuestionnairePage`:
  màn làm bài hiện đúng "Câu 1/20", nội dung câu hỏi thật và 5 lựa chọn —
  xác nhận `screening_questions.json` (tên file mới) load được từ asset
  bundle, không có lỗi "Không tải được bộ câu hỏi".

### Commit của Đợt 5

15. `374ab05` — Giai đoạn A: kế hoạch chuẩn hóa (audit).
16. `330a93d` — Phần 1: đổi tên file dữ liệu + sửa tham chiếu.
17. `3b6ada3` — Phần 2a: comment service chấm điểm + 3 model + bảng SQL.
18. `97098bc` — Phần 2b: comment repository + các màn hình UI.

## Đợt 6 — Tinh chỉnh UI/UX 3 màn + tách logic chân dung theo N lĩnh vực

Giai đoạn A: audit hiển thị tuổi trẻ toàn app (A1), đoạn text dài chưa
justify toàn app (A2), và đọc code thật logic "Xem chân dung" hiện tại
(A3) — ghi trong `KE_HOACH_TINH_CHINH_UI_CHAN_DUNG.md`, chờ duyệt trước
khi sửa. 2 điểm mở đã chốt trước khi vào Giai đoạn B: (1) giữ nguyên 9 vị
trí tuổi "Nhóm 2" (subtitle định danh trên Trang chủ/danh sách hồ
sơ/dashboard/chi tiết hồ sơ), chỉ xóa 3 vị trí "Nhóm 1" (tuổi trong ngoặc
cạnh tên/tiêu đề); (2) nút "Xem chân dung" khi 0/7 lĩnh vực là MỜ NHƯNG
VẪN HIỂN THỊ, không ẩn hẳn.

### B1 — Màn Tạo hồ sơ trẻ

Đổi "Không rõ ngày sinh — chọn mức tuổi" → "Chọn theo độ tuổi". Xóa dòng
"Dải tháng tuổi hiện dùng là giả định làm việc..." khỏi UI người dùng —
comment kỹ thuật tương đương ở chỗ quy đổi `dob` (đã có sẵn từ trước) giữ
nguyên cho dev/reviewer.

### B2 — Xóa tuổi thừa + viết lại mô tả sàng lọc + canh 2 lề toàn app

Xóa `(${formatAgeLabel(...)})` tại đúng 3 vị trí Nhóm 1
(`screening_tool_confirm_page.dart`, `comparison_detail_page.dart`,
`comparison_video_page.dart`). Viết lại đoạn mô tả bộ câu hỏi sàng lọc cho
tự nhiên hơn, giữ nguyên thông tin (20 câu, 5 lĩnh vực, thang 0-3 + N/A).

Thêm widget dùng chung `IrisParagraph` (`core/widgets/iris_ui.dart`) — mặc
định `textAlign: TextAlign.justify`, cho override `style`/`textAlign` khi
cần — áp dụng tại 18 vị trí đoạn mô tả dài theo audit A2 (văn bản chân
dung do AI sinh, nhận xét chuyên gia mô phỏng, nội dung so sánh chuyên
gia, mô tả trung tâm Tường Minh, các disclaimer, mô tả 7 lĩnh vực, câu hỏi
sàng lọc...). Hợp nhất `_domainIntroTextTemp`/`_domainIntroText` (2 bản
sao trùng nội dung ở `description_page.dart`/`domain_hub_page.dart`) về 1
constant chung `domainIntroText` trong `core/constants/domains.dart`.

### B3 — Nút "Xem chân dung" trên hub 7 lĩnh vực

Trước đây nút chỉ tồn tại trên cây widget khi đủ 7/7 lĩnh vực (đặt phía
trên `GridView`). Sửa `domain_list_page.dart`: nút luôn hiển thị — mờ
(`onPressed: null`) khi 0/7, sáng lên và điều hướng sang Chân dung toàn
cảnh từ 1/7 trở lên — dời xuống cuối màn hình, sau danh sách 7 thẻ lĩnh
vực. Card "Tiếp tục ngay" giữ nguyên logic cũ (đã đúng sẵn: tự ẩn khi đủ
7/7), không sửa.

### B4 — Tách "tổng hợp văn bản theo N lĩnh vực" khỏi "tính tier" (thay đổi logic)

Trọng tâm rủi ro cao nhất của đợt này. Trước khi sửa, audit A3 xác nhận có
3 lớp gate cứng yêu cầu đủ 7/7 (`OverviewPortraitPage._load()`,
`OverviewRepository.computeAndSaveOverview()`,
`OverviewRepository.labelAllDomains()`), và việc sinh văn bản chân dung
đang phụ thuộc trực tiếp vào việc tính tier thành công (gọi nối tiếp
trong cùng 1 hàm).

Thêm 2 entrypoint MỚI, HOÀN TOÀN TÁCH BIỆT với pipeline 7/7 cũ (không dùng
chung hàm/flag `bool partial`):
- `OverviewRepository.generatePartialSummaryDescription(Child)`: đọc đúng
  N lĩnh vực (1-6) đã có mô tả, KHÔNG gọi `labelAllDomains`/`labelDomain`
  (bước gắn nhãn chỉ có ý nghĩa cho tier), KHÔNG tính tier, KHÔNG lưu
  `overview_summaries` — trả thẳng cho UI, luôn tổng hợp lại theo dữ liệu
  DB mới nhất mỗi lần gọi (không cache).
- `PromptBuilder.buildPartialOverviewPortraitSummaryPrompt()`: không nhận
  `tierLabel` (chưa có tier ở bước này), thêm guardrail rõ ràng cấm suy
  diễn/generalize sang lĩnh vực chưa có dữ liệu và cấm mọi nhận định về
  "mức độ tổng quan" dưới mọi hình thức (kể cả gợi ý ngầm qua ngôn từ).

`OverviewPortraitPage._load()` bỏ điều kiện chặn cứng
`doneDomains.length < domains.length`. Thêm nhánh `_buildPartial` cho
1<=N<7: CHỈ hiện văn bản tổng hợp (hoặc thông báo lỗi + nút "Tổng hợp
lại" nếu AI lỗi) kèm đúng 1 dòng trạng thái "Chân dung dựa trên N/7 lĩnh
vực đã đánh giá — mức độ tổng quan sẽ hiển thị sau khi hoàn thành đủ 7
lĩnh vực" — TUYỆT ĐỐI không có bất kỳ card/nhãn/màu mức độ nào trong nhánh
này. Nhánh N=7 (`_buildReady`, có tier, giữ nguyên `_ExpertConnectBanner`)
không thay đổi. `overview_tier_calculator.dart` và mọi ngưỡng tier giữ
nguyên 100%, không đụng tới.

### Kết quả kiểm tra

- `flutter analyze`: 0 issues thật trong `lib/` (3 info `avoid_dynamic_calls`
  trong `scripts/ingest_*.dart` là pre-existing, không liên quan đợt này).
- `flutter test`: **30/30 PASS** (bộ test `screening_scoring_service_test.dart`
  hiện có) — không có regression, đúng như kỳ vọng vì đợt này không đụng
  tới bộ sàng lọc/logic chấm điểm.
- **Chưa verify được trên thiết bị/emulator thật** trong phiên làm việc
  này (không có thiết bị/emulator khả dụng trong môi trường thực thi) —
  các kịch bản cần người thực hiện xác nhận trực tiếp trên app: B1 (label
  mới + hết dòng giả định), B2 (hết tuổi ở 3 vị trí Nhóm 1, còn nguyên ở
  Nhóm 2, mô tả sàng lọc + canh lề), B3 (nút mờ ở 0/7, sáng từ 1/7, đúng vị
  trí cuối màn), B4 (chân dung N<7 đúng nội dung/không suy diễn/không hiện
  tier, cập nhật đúng khi làm thêm lĩnh vực, tier + "Tiếp tục ngay" đúng
  hành vi khi đủ 7/7).

### Commit của Đợt 6

19. `1774ebb` — Giai đoạn A: kế hoạch tinh chỉnh UI (audit, chưa code).
20. `223151b` — B1: label + bỏ dòng giả định màn tạo hồ sơ.
21. `c6142de` — B2: xóa tuổi thừa + viết lại mô tả sàng lọc + canh 2 lề.
22. `89bc03f` — B3: nút "Xem chân dung" luôn hiện, mờ/sáng theo doneCount.
23. `d43124a` — B4: tách tổng hợp chân dung N lĩnh vực khỏi tính tier.

## Đợt 7 — Sửa icon AI chưa tách nền + siết guardrail chân dung N<7 khỏi thêu dệt

Sau khi xem UI thật, phát hiện 2 vấn đề: icon AI ở màn Hỏi đáp AI có
viền/nền lạ, và văn bản "Chân dung dựa trên N/7 lĩnh vực" (tính năng vừa
thêm ở Đợt 6/B4) đang trả lời lan man, thêu dệt chi tiết/tình huống không
có trong mô tả thật của người dùng — vi phạm guardrail "không suy diễn"
đã đặt ra ở B4.

### Phần 1 — Icon AI chưa tách nền + canh lề bong bóng chat

**Audit nguyên nhân**: `IrisAssetIcon` (widget hiển thị icon,
`core/widgets/iris_ui.dart`) chỉ là `Image.asset(...)` thuần, KHÔNG có
`Container`/`BoxDecoration` bọc ngoài — loại trừ nguyên nhân code render.
Kiểm tra trực tiếp file `assets/images/icons/ai_chat_v2.png`
(`file <path>`) xác nhận: **PNG RGB 8-bit, KHÔNG có kênh alpha** — 4 góc
ảnh (ngoài hình icon bo góc) được xuất bằng màu đen đặc (~`rgb(0,0,0)`)
thay vì trong suốt. Đây là lỗi ở khâu xuất file ảnh gốc, không phải lỗi
code.

**Cách sửa**: viết script Python (Pillow) flood-fill từ 4 biên ảnh, gộp
mọi pixel "gần đen" (tổng kênh màu < 130) liên thông với biên thành
`alpha=0`, giữ nguyên phần icon (bao gồm 2 mắt tối màu ở giữa — KHÔNG bị
xoá vì không liên thông với vùng nền qua đường biên). Kết quả:
`assets/images/icons/ai_chat_v2.png` giờ là PNG RGBA, ~187k/1.57M pixel
(nền 4 góc) chuyển trong suốt, icon giữ nguyên hình dạng/màu sắc gốc. Icon
này dùng chung ở cả `ai_chat_page.dart` (bong bóng trả lời) và
`profile_detail_page.dart` — cả 2 nơi cùng được sửa nhờ sửa đúng 1 file
asset.

Áp dụng `IrisParagraph` (đã có sẵn từ Đợt 6/B2) cho
`Text(conversation.answer)` trong `_ConversationBubble` — canh 2 lề đồng
bộ với các đoạn mô tả dài khác trong app.

### Phần 2 — Guardrail chân dung N<7 (thêu dệt chi tiết bịa)

**Audit Bước 1 — xác định nguyên nhân trước khi sửa**:
- Đọc lại `OverviewRepository.generatePartialSummaryDescription()`: xác
  nhận hàm này ĐỌC THẲNG từ `assessments` (content_type='mo_ta'), KHÔNG
  gọi `labelDomain`/`_expertKnowledgeRepository`/`_vectorSearchService` ở
  bất kỳ đâu — **loại trừ hoàn toàn** nghi vấn "lẫn dữ liệu tham khảo
  chuyên môn (`expert_knowledge_chunks`) vào ngữ cảnh cá nhân của trẻ".
- Đọc lại `OverviewPortraitPage._load()`: xác nhận nhánh `1<=N<7` chỉ gọi
  `generatePartialSummaryDescription`, KHÔNG có đường dẫn nào gọi nhầm
  `computeAndSaveOverview`/`labelAllDomains` (2 hàm đó chỉ được gọi từ
  `_compute()`, vốn chỉ gắn với nút ở nhánh N=7) — loại trừ nghi vấn code
  gọi nhầm pipeline.
- Kết luận: nguyên nhân gốc nằm ở **thiết kế prompt**
  (`buildPartialOverviewPortraitSummaryPrompt`), không phải rò rỉ dữ liệu
  hay lỗi gọi hàm:
  1. Yêu cầu cứng "độ dài khoảng 100-180 từ" buộc model phải "bù đắp" bằng
     chi tiết tự thêm khi dữ liệu gốc chỉ là 1 câu ngắn.
  2. Khung nhiệm vụ "viết một đoạn văn xuôi... phác hoạ bức tranh" mời gọi
     văn phong sáng tác/diễn giải mở rộng, thay vì diễn đạt lại đúng dữ
     liệu.
  3. Guardrail cũ chỉ nói chung chung "không thêm thông tin ngoài dữ
     liệu", không cấm rõ ràng việc bịa ví dụ minh hoạ/tình huống cụ thể —
     đúng loại lỗi quan sát được trong thực tế ("khi được hỏi... trẻ sẽ
     nhanh chóng chỉ ra tên...", "trong trò chơi mô hình hoặc đồ chơi xếp
     hình...").

**Bước 2 — Sửa**: viết lại toàn bộ
`buildPartialOverviewPortraitSummaryPrompt`:
- Đổi khung nhiệm vụ thành "DIỄN ĐẠT LẠI (paraphrase) — KHÔNG PHẢI sáng
  tác".
- Guardrail #1-2 mới: cấm rõ ràng, cụ thể việc thêm chi tiết/hành vi/kỹ
  năng không có trong dữ liệu, kèm ví dụ phản diện đúng loại lỗi đã quan
  sát ("khi được hỏi...", "trong lúc chơi xếp hình/mô hình...").
- Guardrail #6 mới: bỏ yêu cầu số từ tối thiểu cứng — độ dài PHẢI tỉ lệ
  thuận với dữ liệu gốc, cho phép chỉ 1-2 câu nếu mô tả gốc ngắn, cấm rõ
  "kéo dài bằng nội dung tự thêm để cho đủ ý".
- Thêm bước tự kiểm tra cuối prompt: mỗi câu viết ra phải truy được về
  đúng câu chữ/ý trong "Mô tả người dùng" đã cho.
- Đồng bộ `userQuestion` ở lệnh gọi Groq trong `overview_repository.dart`
  theo đúng khung "diễn đạt lại" mới (trước đó vẫn dùng chữ "viết đoạn văn
  xuôi tổng hợp bức tranh...", cùng loại ngôn từ mời gọi sáng tác).
- Có cân nhắc thêm `max_tokens` ở tầng gọi Groq API để giới hạn cứng độ
  dài, nhưng **quyết định KHÔNG làm** — `GroqApiClient.generate()` là hạ
  tầng dùng chung cho nhiều luồng khác (chat, gắn nhãn lĩnh vực, tổng hợp
  N=7), sửa signature ở đó sẽ vượt phạm vi "chỉ prompt partial N<7" đã
  yêu cầu và tăng rủi ro ảnh hưởng luồng khác không liên quan.
- Không đụng `overview_tier_calculator.dart`, `computeAndSaveOverview`,
  `labelAllDomains`, hay bộ sàng lọc/7 lĩnh vực.

### Kết quả kiểm tra

- `flutter analyze`: 0 issues trong `lib/` (3 info pre-existing ở
  `scripts/` không liên quan).
- `flutter test`: 30/30 PASS, không regression.
- **Chưa verify được bằng ảnh chụp màn hình thật/gọi Groq API thật** trong
  phiên làm việc này — môi trường thực thi không có thiết bị/emulator và
  không có kết nối gọi API AI thật để kiểm tra trực tiếp câu trả lời sau
  khi sửa prompt. Cần người thực hiện tự verify trên máy: (1) icon AI
  không còn viền đen, text trả lời canh đều 2 bên; (2) nhập 1 mô tả ngắn
  cụ thể cho 1 lĩnh vực, bấm "Xem chân dung", đối chiếu văn bản trả về chỉ
  chứa đúng nội dung đã mô tả, không có ví dụ/tình huống bịa thêm; (3) lặp
  lại với 1 mô tả rất ngắn (1 câu) để xác nhận AI không "bù đắp" cho đủ
  dài.

### Commit của Đợt 7

24. `98cdd13` — Phần 1: tách nền icon AI + canh 2 lề bong bóng trả lời AI.
25. `9e591e5` — Phần 2: siết guardrail chống thêu dệt cho chân dung N<7.

## Đợt 8 — Bỏ màn xác nhận trung gian trước Chân dung toàn cảnh + sửa nguyên nhân AI chậm/không ra kết quả

### Phần 1 — Audit hiện trạng 2 nhánh trước khi sửa

Đọc lại `OverviewPortraitPage` (code thật, không dựa theo báo cáo cũ):
- **Nhánh N<7** (`_load()`): đã tự động gọi
  `generatePartialSummaryDescription` ngay khi vào màn từ đợt B4 (Đợt 6) —
  KHÔNG cần bấm nút để bắt đầu. Đúng như mong đợi, không có gì cần sửa cho
  phần "tự động hoá" ở nhánh này.
- **Nhánh N=7** (`_load()` cũ): CHỈ đọc `summary` có sẵn trong bảng
  `overview_summaries` — KHÔNG tự gọi `labelAllDomains`/
  `computeAndSaveOverview`. Nếu `summary == null` (lần đầu vào màn, chưa
  từng tổng hợp), `_buildReady()` hiện thẻ "Đã có đủ mô tả cho cả 7 lĩnh
  vực. Bấm nút bên dưới để tổng hợp Chân dung toàn cảnh." với
  `FilledButton` gọi `_compute()` — xác nhận ĐÚNG là màn xác nhận trung
  gian thấy trong ảnh chụp, cần bỏ.

### Phần 2 — Bỏ màn xác nhận trung gian

Sửa `_load()`: khi đủ 7/7 và CHƯA có `summary`, tự động gọi
`labelAllDomains` + `computeAndSaveOverview` ngay trong lúc tải màn. Cả 2
nhánh N<7 và N=7 giờ đều tự động phân tích ngay khi vào màn, không cần
thao tác thêm.

Thêm dòng "Đang phân tích dữ liệu bằng AI, quá trình này có thể mất vài
giây..." dưới spinner loading — tránh hiểu nhầm màn trống/lỗi khi AI đang
xử lý (đặc biệt quan trọng cho nhánh N=7 vì giờ có thể mất 15-20s, xem
Phần 3).

Tách hàm `_fetchReadyState()` (CHỈ đọc DB, không gọi AI) dùng chung cho cả
`_load()` và `_compute()`, tránh 1 bug logic phát sinh từ việc tự động
hoá: nếu `_compute()` (nút "Tính toán lại"/"Thử lại") vẫn gọi qua
`_reload()` → `_load()` như code cũ, `_load()` sẽ thấy `summary` có thể
vẫn null (VD do `insufficientData`) và tự động tính lại LẦN NỮA — gọi
trùng toàn bộ pipeline AI cho đúng 1 lần bấm nút của người dùng. Nút
"Tính toán lại" (N=7) và "Tổng hợp lại" (N<7) GIỮ NGUYÊN, không xoá —
đúng như yêu cầu, đây là hành động chủ động làm mới, khác với lần tải đầu
tiên (tự động). Đổi text/nhãn nút khi `summary == null` sau khi đã tự
động thử — từ "Bấm nút bên dưới để tổng hợp" (ngụ ý chưa từng thử) sang
"Chưa thể tính mức tổng quan lúc này — hệ thống đã thử tự động nhưng...
Bấm nút bên dưới để thử lại" + nhãn nút "Thử lại", đúng thực tế là ĐÃ thử.

### Phần 3 — Điều tra + xử lý nguyên nhân AI chậm/không ra kết quả

**Điều tra bằng lệnh gọi API THẬT** (dùng đúng key trong `dart_define.json`,
gọi trực tiếp qua `curl`, không đoán):

1. Timeout hiện tại (30s Groq, 15s NVIDIA, xem `groq_api_client.dart`/
   `nvidia_api_client.dart`) — đo 15+ lần gọi đơn lẻ thực tế: thời gian
   phản hồi chỉ ~0.6-2s/lần. **Không phải nguyên nhân** — timeout đủ dư.
2. Mô phỏng ĐÚNG pipeline N=7 auto-compute (7 lần tuần tự [NVIDIA embed +
   Groq gắn nhãn] + 1 lần Groq tổng hợp cuối = 8 lệnh gọi Groq liên tiếp
   trong dưới 20 giây), chạy 3 lần: **2/3 lần dính hàng loạt lỗi HTTP
   429** ngay từ giữa pipeline (5-6/8 lệnh Groq bị từ chối).
3. Đọc thẳng body lỗi 429 thật: `"Rate limit reached for model
   openai/gpt-oss-20b ... on tokens per minute (TPM): Limit 8000, Used
   5430, Requested 2731. Please try again in 1.2075s."` — xác nhận đây là
   **giới hạn TPM (token/phút) = 8000** của tổ chức/key hiện dùng, KHÔNG
   phải lỗi mạng hay bug code.
4. Đào sâu nguyên nhân token cao: model `openai/gpt-oss-20b` tự sinh
   nhiều "reasoning token" ẩn (chain-of-thought) trước khi trả lời — đo
   trên CÙNG 1 prompt: mặc định 226 reasoning token/lần gọi, tổng 345
   token. Các token này KHÔNG hề được app dùng
   (`GroqApiClient.generate()` chỉ đọc `message.content`, bỏ qua
   `message.reasoning` hoàn toàn) — thuần túy lãng phí ngân sách TPM.
   Test tham số `reasoning_effort=low` (Groq hỗ trợ chính thức cho model
   này, giá trị hợp lệ: `low`/`medium`/`high`) trên CÙNG prompt: giảm còn
   67 reasoning token, tổng 193 token (**giảm ~44% tổng token/lần gọi**),
   nội dung câu trả lời thực tế không đổi chất lượng.
5. Đọc lại `labelDomain`: bắt MỌI exception (kể cả 429 sau khi hết lượt
   retry) và fallback im lặng về nhãn `chua_du_du_lieu` (không rethrow,
   không báo hiệu riêng "do rate limit"). Đối chiếu `overview_tier_calculator.dart`:
   nếu `≥4/7` lĩnh vực rơi vào `chua_du_du_lieu`, `computeAndSaveOverview`
   trả `insufficientData` và KHÔNG lưu `overview_summaries`. **Đây chính
   là cơ chế gây hiện tượng "phân tích xong mà không ra kết quả"** — do
   rate limit dồn dập tạm thời (transient), không phải do trẻ thật sự
   thiếu dữ liệu mô tả.

**Kết luận nguyên nhân gốc**: kiến trúc gọi 8 lệnh Groq TUẦN TỰ, DỒN DẬP
trong một khoảng thời gian ngắn (<20s) cho pipeline N=7, kết hợp với việc
mỗi lệnh tốn nhiều token hơn cần thiết (do reasoning token mặc định),
khiến pipeline RẤT DỄ chạm trần TPM=8000 giữa chừng — gây chậm (do phải
chờ retry theo "try again in Xs") và trong trường hợp xấu gây mất kết quả
hoàn toàn (do fallback `chua_du_du_lieu` hàng loạt → `insufficientData`).

**Cách đã sửa** (chỉ sửa thông số/luồng gọi kỹ thuật, KHÔNG đổi thuật
toán tier hay nội dung AI sinh):
- `GroqApiClient.generate()`: thêm tham số tuỳ chọn `reasoningEffort`
  (mặc định `null` — giữ nguyên hành vi cũ 100% cho mọi caller khác, VD
  `AiRepository` dùng cho Hỏi đáp AI chính không bị ảnh hưởng). Khi có
  giá trị, truyền `'reasoning_effort': ?reasoningEffort` vào body request.
  Tăng `maxAttempts` từ 3 lên 4 — có căn cứ: mọi lần 429 thật đều kèm
  `retry-after`/"try again in Xs" ngắn (1-9 giây), thêm 1 lần thử không
  tốn nhiều thời gian nhưng tăng đáng kể tỷ lệ thành công qua chuỗi gọi
  liên tiếp.
- `OverviewRepository`: truyền `reasoningEffort: 'low'` cho cả 3 lệnh gọi
  Groq của tính năng chân dung (`labelDomain`, `_generateSummaryDescription`
  cho N=7, `generatePartialSummaryDescription` cho N<7). Thêm khoảng nghỉ
  400ms (`_labelCallSpacing`) giữa các lần gọi gắn nhãn tuần tự trong
  `labelAllDomains` để giảm áp lực dồn cục lên token bucket TPM.

**Verify độ tin cậy bằng lệnh gọi THẬT sau khi sửa** (không phải đoán —
mô phỏng lại chính xác pipeline N=7 với đúng tham số mới, 5 lần liên
tiếp):

| Lần chạy | Tổng thời gian | Số lệnh Groq bị 429 | Kết quả |
|---|---|---|---|
| 1 | 15.84s | 0/8 | Thành công |
| 2 | 16.36s | 0/8 | Thành công |
| 3 | 15.52s | 0/8 | Thành công |
| 4 | 16.62s | 0/8 | Thành công |
| 5 | 16.05s | 0/8 | Thành công |

**5/5 lần thành công hoàn toàn** (tất cả 40 lệnh Groq across 5 lần chạy
đều `attempts=1`, không lần nào cần retry) — so với TRƯỚC khi sửa: 2/3
lần chạy dính hàng loạt 429. Thời gian trung bình ~16s/lần cho toàn bộ
pipeline N=7 (7 lần gắn nhãn + 1 lần tổng hợp) — chấp nhận được, có loading
text rõ ràng ở Phần 2 nên người dùng không hiểu nhầm treo máy.

Nhánh N<7 (chỉ 1 lệnh Groq, vốn không có vấn đề vì không đủ để chạm trần
TPM) verify riêng: 5/5 thành công, ~0.55-0.8s/lần.

### Kết quả kiểm tra

- `flutter analyze`: **0 issues** trong `lib/` (sạch tuyệt đối, kể cả 3
  info pre-existing ở `scripts/` không tính vì nằm ngoài `lib/`).
- `flutter test`: 30/30 PASS, không regression.
- Đã verify độ tin cậy bằng lệnh gọi API thật (xem bảng trên) — không
  phải chỉ chạy `flutter analyze`/test đơn thuần.
- **Chưa verify được luồng UI đầy đủ trên thiết bị/emulator thật** (bấm
  "Xem chân dung" từ hub → xác nhận vào thẳng màn tự động phân tích,
  không còn màn trung gian) — môi trường thực thi không có thiết bị/emulator.
  Verify API thật ở trên xác nhận ĐÚNG tầng gọi AI hoạt động tin cậy, còn
  luồng UI (auto-trigger, loading text, nút "Thử lại") cần người thực
  hiện tự xác nhận bằng mắt trên máy.

### Commit của Đợt 8

26. `635cf37` — Phần 2: bỏ màn xác nhận trung gian, tự động phân tích khi vào màn.
27. `83ef012` — Phần 3: điều tra + xử lý nguyên nhân AI chậm/không ra kết quả.
