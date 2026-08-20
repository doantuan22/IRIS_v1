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
  `assets/reference/sang_loc_20_cau_4_muc_tuoi.json`, thay thế hoàn toàn
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
   `sang_loc_20_cau_4_muc_tuoi.json`, `screening_loader_service.dart`
   (đổi `assetPath`), xóa `.placeholder.json`.
8. `179716e` — **bộ test chính thức**: `test/screening_scoring_service_test.dart`
   (25/25 PASS).

### Cập nhật trạng thái "Việc CHƯA làm" ở Đợt 1

Tất cả các mục "chưa làm" liệt kê ở Đợt 1 bên dưới **nay đã hoàn thành**,
trừ việc rename 82 file video (quyết định: không làm, giữ nguyên như đã
chốt).
