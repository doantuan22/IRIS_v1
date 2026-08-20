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

## Việc CHƯA làm — đúng phạm vi (thuộc Prompt 2)

- Chưa chuyển đổi nội dung 2 file Word thành dữ liệu câu hỏi thật.
- Chưa ingest dữ liệu thật (`sang_loc_20_cau_4_muc_tuoi.json` — file
  `.placeholder.json` hiện tại vẫn là dữ liệu giả).
- Chưa viết bộ test chính thức đối chiếu 3 ví dụ mẫu với tài liệu gốc
  (test tạm ở trên chỉ mô phỏng theo mô tả thuật toán, không đọc file
  Word thật).
- Chưa verify tích hợp thật trên thiết bị/emulator.
- Chưa rename 82 file video/`video_manifest.json` (quyết định: không làm).
