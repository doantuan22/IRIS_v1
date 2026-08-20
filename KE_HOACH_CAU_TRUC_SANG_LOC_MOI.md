# Kế Hoạch Thay Bộ Sàng Lọc Mới + Sửa Dải Tuổi 12-23 — Giai Đoạn A

> **Trạng thái: CHỈ AUDIT + THIẾT KẾ — CHƯA SỬA/XÓA/MIGRATE GÌ.**
> Dừng lại chờ duyệt trước khi sang Giai đoạn B.

Thời điểm: 2026-08-20. Database hiện tại ở **version 11** (bảng cuối cùng
thêm: `notifications`, xem `lib/data/local/database.dart:50`).

---

## Phần 1 — Audit toàn bộ dấu vết bộ sàng lọc 50 câu / 7 lĩnh vực

### 1.1 Bảng SQLite (3 bảng — toàn bộ sẽ bị xóa)

| Bảng | File định nghĩa | Thêm ở version | Ghi chú |
|---|---|---|---|
| `screenings` | `lib/data/local/tables/screenings_table.dart` | 1 (onCreate ban đầu) | Bảng cha — `id, child_id, tool_name, score, result_summary, performed_at, created_at`. **Không đặc thù riêng bộ 50 câu** (tên cột chung chung `tool_name`/`score`), nhưng thực tế hiện chỉ được ghi bởi luồng sàng lọc 50 câu → coi là 1 phần bộ cũ cần xóa cùng. |
| `screening_responses` | `lib/data/local/tables/screening_responses_table.dart` | 8 | Câu trả lời từng câu (`cau_hoi_id`, `linh_vuc`, `gia_tri` là '0'/'1'/'2'/'N/A'), FK tới `screenings.id`. |
| `screening_domain_scores` | `lib/data/local/tables/screening_domain_scores_table.dart` | 8 | Điểm theo 7 lĩnh vực, FK tới `screenings.id`. |

### 1.2 Asset dữ liệu nguồn

- `assets/data/sang_loc_50_cau_7_linh_vuc.json` (509 dòng, bộ câu hỏi 50
  câu/7 lĩnh vực đầy đủ) — **file DUY NHẤT** trong `assets/data/`. Sau khi
  xóa, thư mục `assets/data/` sẽ RỖNG — cần lưu ý `pubspec.yaml` đang khai
  báo cả thư mục (`- assets/data/`), một số phiên bản Flutter báo lỗi build
  khi thư mục asset khai báo bị rỗng hoàn toàn. **Cần xử lý 1 trong 2 cách ở
  Giai đoạn B**: (a) xóa luôn dòng khai báo `assets/data/` khỏi
  `pubspec.yaml` nếu không còn gì khác dùng thư mục này, hoặc (b) giữ dòng
  khai báo và xác nhận build vẫn qua với thư mục rỗng trước khi commit. Sẽ
  xác nhận bằng build thử thật ở Giai đoạn B, không đoán trước.

### 1.3 Model (domain)

- `lib/domain/models/screening.dart` — model `Screening`.
- `lib/domain/models/screening_response.dart` — model `ScreeningResponse`.
- `lib/domain/models/screening_domain_score.dart` — model `ScreeningDomainScore`.

### 1.4 Repository

- `lib/data/repositories/screening_repository.dart` — toàn bộ
  `ScreeningRepository` (các hàm `save`, `saveScreeningSession`,
  `getForChild`, `getScreeningsByChildId`, `getById`, `getLatestForChild`,
  `getResponses`, `getDomainScores`, `hasScreening`). **`hasScreening()`
  là điểm neo quan trọng nhất** — được gọi từ 5 nơi khác nhau (xem 1.6).

### 1.5 Service

- `lib/domain/services/screening_loader_service.dart` — nạp/parse JSON 50
  câu (`ScreeningLoaderService.loadQuestionnaire`/`parseJson`).
- `lib/domain/services/screening_scoring_service.dart` — toàn bộ thuật toán
  chấm điểm 50 câu/7 lĩnh vực cũ (`ScreeningScoringService.calculateScore`
  + các class `ScreeningQuestion`, `ScreeningQuestionnaireData`,
  `ScreeningScoreResult`, `DomainScoreCalculation`...). **Toàn bộ file này
  gắn với cấu trúc 50 câu — thay thế hoàn toàn, không sửa dần.**
- `lib/domain/services/screening_change_service.dart` — `ValueNotifier`
  thông báo "vừa lưu 1 bài sàng lọc" cho các trang đang mở. **Không đặc thù
  bộ 50 câu — có thể GIỮ NGUYÊN, dùng lại cho bộ mới** (chỉ là cơ chế
  notify chung).

### 1.6 UI — 5 trang trong `lib/features/screening/`

| Trang | Vai trò | Đặc thù bộ 50 câu? |
|---|---|---|
| `screening_intro_page.dart` | Bước 3 — hỏi "Có muốn sàng lọc?" | Không đặc thù (chỉ điều hướng), nhưng text "bài sàng lọc 50 câu" cần sửa nếu còn sót — **đã kiểm tra: trang này không hardcode số 50**. |
| `screening_tool_confirm_page.dart` | Bước 3 — xác nhận công cụ | **CÓ** — hardcode text "Bộ câu hỏi sàng lọc 50 câu (7 lĩnh vực)" + mô tả 4 mức lựa chọn cũ (dòng 49-57). |
| `screening_questionnaire_page.dart` | Làm bài — 1 câu/màn hình | **CÓ, nặng nhất** — toàn bộ logic đọc `ScreeningQuestionnaireData` (bộ 50 câu), gọi `ScreeningScoringService.calculateScore`, lưu qua `ScreeningRepository.saveScreeningSession` (đúng 3 bảng cũ), UI 4 lựa chọn (0/1/2/N/A) theo thang cũ. Thay thế hoàn toàn. |
| `screening_result_page.dart` | Kết quả | **CÓ** — đọc `ScreeningDomainScore` (7 lĩnh vực), hiển thị "Điểm theo 7 lĩnh vực", dùng `Screening.score`/`resultSummary` (bảng cũ). |
| `screening_history_list_page.dart` | Bước 9 — lịch sử | **CÓ** — dùng `ScreeningRepository.getScreeningsByChildId` (bảng `screenings` cũ), text "bài sàng lọc 50 câu". |

### 1.7 MỌI nơi khác đọc dữ liệu từ 3 bảng cũ (ngoài `lib/features/screening/`)

Đây là phần quan trọng nhất theo yêu cầu — audit đầy đủ **9 điểm neo**:

| # | File | Dòng | Cách dùng | Cần sửa gì ở Giai đoạn B |
|---|---|---|---|---|
| 1 | `lib/data/repositories/ai_repository.dart` | 72, 78, 86 | Gọi `_screeningRepository.hasScreening(childId)` để xác định **Guardrail AI Trạng thái 2** (`AiState.hasScreening`) | Đổi sang gọi hàm tương đương đọc bảng screening mới (VD `hasNewScreening`/đổi tên hàm) |
| 2 | `lib/domain/services/guardrail_service.dart` | 8-12, 91, 116-119 | Định nghĩa `enum AiState { insufficientData, hasScreening, hasProfessionalAssessment }` + logic dùng `hasScreeningResult: bool` | **Bản thân enum/logic không đọc DB trực tiếp** — chỉ nhận `bool` từ ngoài truyền vào, nên KHÔNG cần sửa gì bên trong `GuardrailService`, chỉ cần bên gọi (`ai_repository.dart`) truyền đúng giá trị mới |
| 3 | `lib/data/repositories/child_repository.dart` | 111-122 | Cascade delete: xóa `screening_responses`/`screening_domain_scores`/`screenings` khi xóa hồ sơ trẻ | Đổi sang cascade delete 3 bảng MỚI |
| 4 | `lib/features/child_profile/profile_detail/profile_detail_page.dart` | 30-119 | Hiển thị badge "Đã sàng lọc"/"Chưa sàng lọc" qua `hasScreening()` | Đổi nguồn dữ liệu |
| 5 | `lib/features/home/home_page.dart` | 175-280, 522-527 | Badge trạng thái sàng lọc trên Trang chủ + nút mở `ScreeningHistoryListPage` | Đổi nguồn dữ liệu |
| 6 | `lib/features/expert_connect/expert_connect_page.dart` | 72-101 | Tính `_NeedLevel` (mức độ cần kết nối chuyên gia) dựa 1 phần vào `hasScreening()` | Đổi nguồn dữ liệu |
| 7 | `lib/features/screening/assessment_summary_page.dart` | 37-87 | **Bước 4 "Tổng hợp hồ sơ & đề xuất hướng đánh giá"** — dùng `hasScreening()` + `getLatestForChild()` (đọc `Screening.score`/`toolName`/`performedAt`) để sinh gợi ý | Đổi nguồn dữ liệu + định dạng hiển thị điểm (thang 60 thay vì %) |
| 8 | `lib/features/child_profile/profile_detail/child_debug_page.dart` | 25-41 | Trang debug — liệt kê `screenings` thô của 1 trẻ | Đổi nguồn dữ liệu (trang debug, rủi ro thấp) |
| 9 | `lib/domain/models/history_log.dart` + `lib/features/history/history_page.dart` | — | `event_type='sang_loc'` là 1 giá trị TỰ DO lưu trong `history_logs` (bảng KHÔNG đổi schema), do `screening_questionnaire_page.dart` ghi text mô tả | Chỉ cần sửa text mô tả sự kiện khi viết lại trang làm bài mới, KHÔNG cần đổi bảng `history_logs` |

**Xác nhận đã audit hết**: grep toàn bộ `lib/` cho từ khóa
`screening`/`Screening`/`sang_loc` ra đúng 27 file — đã liệt kê đủ 27/27 ở
trên (bảng, model, repository, service, UI, và các điểm neo ngoài
`features/screening/`). `lib/core/theme/iris_assets.dart` chỉ chứa 2 hằng
số đường dẫn icon (`iconScreening`, `screeningChecklistIllustration`) —
**dùng lại được cho bộ mới, không cần đổi**.

---

## Phần 2 — Audit vị trí hardcode dải tuổi 15-23 tháng

### 2.1 Trong code Dart (`lib/`)

**Xác nhận: KHÔNG có hardcode dải 15/23 nào trong `lib/`.** Toàn bộ UI
(`comparison_video_page.dart`, `comparison_detail_page.dart`,
`vector_search_service.dart`) truy vấn động qua cột
`do_tuoi_thang_min`/`do_tuoi_thang_max` trong `expert_knowledge_chunks`,
không có số 15/23 viết cứng ở đâu trong logic Dart. Dòng duy nhất nhắc tới
"15_23" trong `lib/` là 1 comment docstring ở
`lib/domain/services/expert_knowledge_seed_service.dart:23` (liệt kê tên 3
file nguồn) — chỉ cần cập nhật comment này nếu đổi TÊN file (xem 2.3).

### 2.2 Dữ liệu đã ingest trong DB (runtime)

- Bảng `expert_knowledge_chunks`, `content_type='so_sanh'`,
  `do_tuoi_thang_min=15 AND do_tuoi_thang_max=23` — dữ liệu này được
  **seed lại từ file JSON mỗi khi bảng rỗng** (`ExpertKnowledgeSeedService.seedIfEmpty`,
  chạy trong `onOpen`), KHÔNG phải hardcode trong code Dart mà là dữ liệu
  nạp từ `assets/reference/expert_knowledge_seed.json`. → Sửa gốc ở file
  JSON (2.3), rồi kích hoạt lại seed (2.4), không cần UPDATE SQL thủ công.

### 2.3 File JSON nguồn — xác định rõ cần đổi gì

| File | Vai trò | Có cần đổi tên file? | Có cần đổi giá trị field? |
|---|---|---|---|
| `assets/reference/so_sanh_15_23_thang.json` | File NGUỒN thô (chưa có embedding) — input cho `scripts/generate_expert_knowledge_seed.dart` | **Không bắt buộc** — chỉ là tên file định danh, không được `lib/` runtime đọc trực tiếp | **CÓ** — 200 entry đều có `do_tuoi_thang_min: 15, do_tuoi_thang_max: 23` (đếm bằng grep) + `meta.do_tuoi_thang_min/max` — đổi hết `15`→`12` |
| `assets/reference/expert_knowledge_seed.json` | File ĐÍCH có sẵn embedding — **file DUY NHẤT app runtime thực sự đọc** (`ExpertKnowledgeSeedService.seedAssetPath`) | Không áp dụng (không có "15_23" trong tên file) | **CÓ** — đúng 200 entry có `"do_tuoi_thang_min":15` cần đổi thành `12`. **Không cần gọi lại NVIDIA API để re-embed** — trường `embedding` tính từ nội dung text (`content`), không phụ thuộc số tháng tuổi, nên sửa trực tiếp field số nguyên trong JSON là đủ, an toàn. |
| `assets/reference/expert_content_so_sanh.json` | Dữ liệu dev/test cũ, dùng bởi `scripts/ingest_expert_data.dart`/`ingest_so_sanh_data.dart`/`validate_so_sanh_data.dart` (script CLI độc lập, KHÔNG chạy trong app) | Không áp dụng | Có 28 chỗ nhắc "15_23" — **out of scope cho việc sửa app thật**, nhưng nên sửa đồng bộ nếu các script này còn được dùng để re-generate dữu liệu sau này (quyết định ở Giai đoạn B, rủi ro thấp vì không ảnh hưởng app) |

### 2.4 Video asset — điểm cần lưu ý riêng, KHÔNG có trong yêu cầu gốc nhưng liên quan trực tiếp

- **82 file video** trong `assets/videos/*/` có tên dạng
  `so_sanh_<linh_vuc>_<phan_loai>_15_23_<số>.mp4` (VD
  `so_sanh_cam_xuc_binh_thuong_15_23_001.mp4`).
- **`video_manifest.json`** dùng đúng các ID này làm key (VD
  `"so_sanh_nhan_thuc_binh_thuong_15_23_001"`), trỏ tới đường dẫn file
  tương ứng.
- **Xác nhận: không có code Dart nào parse số tháng tuổi TỪ tên file/ID** —
  việc lọc theo độ tuổi hoàn toàn dựa vào cột `do_tuoi_thang_min/max` trong
  DB (khác hẳn với ID chuỗi). Vì vậy:
  - **Sửa dải tuổi 12-23 KHÔNG bắt buộc phải rename 82 file video + sửa
    `video_manifest.json` để app chạy đúng chức năng** — chỉ cần sửa 2 file
    JSON ở mục 2.3.
  - Rename 82 file (đổi `_15_23_` → `_12_23_` trong tên file thật + key
    JSON) chỉ có ý nghĩa **thẩm mỹ/nhất quán đặt tên**, không ảnh hưởng
    chức năng, nhưng là thao tác rủi ro cao hơn hẳn (82 file vật lý +
    `cap_doi_id` trong `expert_knowledge_seed.json` tham chiếu chéo giữa
    các entry — cần audit thêm nếu muốn làm).
  - **Đề xuất: KHÔNG rename video/manifest trong đợt này** (không nằm
    trong yêu cầu, rủi ro không tương xứng lợi ích) — chỉ sửa 2 file JSON
    số liệu. Xin xác nhận lại nếu bạn muốn làm cả phần rename.

### 2.5 Cơ chế kích hoạt lại seed sau khi sửa JSON

Theo đúng pattern đã dùng ở migration version 10 (`database.dart:205-223`
— xóa sạch `content_type='so_sanh'` cũ để buộc `onOpen` seed lại từ file
JSON mới), migration cho việc sửa 15→12 sẽ theo cùng pattern: **DELETE
toàn bộ `content_type='so_sanh'` hiện có trong DB người dùng cũ**, sau đó
`onOpen` tự động `seedIfEmpty` nạp lại từ `expert_knowledge_seed.json` đã
sửa — không cần viết UPDATE SQL thủ công cho từng dòng.

---

## Phần 3 — Thiết kế schema SQLite mới (CHƯA migrate)

### 3.1 Xác định số version

Database hiện tại: `version: 11`. Theo đúng convention 1-version-1-mục-đích
đã áp dụng xuyên suốt dự án (xem lịch sử version 1→11 trong
`database.dart`), đề xuất **2 version riêng biệt** dù cùng 1 đợt code, để
audit trail rõ ràng và có thể rollback độc lập:

- **Version 12** — thay thế bộ sàng lọc: xóa 3 bảng cũ
  (`screenings`/`screening_responses`/`screening_domain_scores`), tạo 3
  bảng mới.
- **Version 13** — xóa sạch `expert_knowledge_chunks` content_type='so_sanh'
  (buộc reseed từ `expert_knowledge_seed.json` đã sửa dải 12-23).

### 3.2 Bảng 1 — `screening_answers` (câu trả lời từng câu)

```sql
CREATE TABLE screening_answers (
  id TEXT PRIMARY KEY,
  screening_id TEXT NOT NULL REFERENCES screening_sessions(id),
  child_id TEXT NOT NULL REFERENCES children(id),
  muc_tuoi_lam_bai TEXT NOT NULL,   -- '2_tuoi' | '3_tuoi' | '4_tuoi' | '5_tuoi'
  cau_hoi_id TEXT NOT NULL,
  linh_vuc TEXT NOT NULL,            -- 'ngon_ngu_giao_tiep' | 'nhan_thuc_giai_quyet_van_de'
                                      -- | 'van_dong' | 'xa_hoi_cam_xuc' | 'tu_lap'
  nhom_van_dong TEXT,                -- nullable; CHỈ dùng khi linh_vuc='van_dong':
                                      -- 'tho' | 'tinh'; NULL cho 4 lĩnh vực còn lại
  diem INTEGER,                      -- 0-3, NULL nếu la_na = 1
  la_na INTEGER NOT NULL DEFAULT 0,  -- boolean (0/1) — SQLite không có kiểu BOOL riêng,
                                      -- theo đúng convention project (xem cột `co_canh_bao`
                                      -- bảng 3 cũng dùng INTEGER 0/1)
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_answers_screening ON screening_answers(screening_id);
CREATE INDEX idx_screening_answers_child ON screening_answers(child_id);
```

Ghi chú thiết kế:
- `child_id` được lưu TRỰC TIẾP ở bảng answers (không chỉ qua FK gián
  tiếp qua `screening_id`) — giữ đúng pattern hiện có của
  `profile_chunks`/`assessments` (luôn có `child_id` trực tiếp ở bảng chi
  tiết), giúp query lịch sử theo trẻ không cần JOIN.
- `diem` kiểu `INTEGER` cho phép NULL khi N/A — khác bảng cũ
  (`screening_responses.gia_tri TEXT` ép cả '0'/'1'/'2'/'N/A' vào 1 cột
  TEXT) — thiết kế mới rõ ràng hơn về kiểu dữ liệu, tránh phải parse chuỗi
  khi tính điểm.

### 3.3 Bảng 2 — `screening_domain_results` (điểm theo lĩnh vực)

```sql
CREATE TABLE screening_domain_results (
  id TEXT PRIMARY KEY,
  screening_id TEXT NOT NULL REFERENCES screening_sessions(id),
  child_id TEXT NOT NULL REFERENCES children(id),
  linh_vuc TEXT NOT NULL,
  diem_tho INTEGER NOT NULL,         -- tổng điểm thô đã trả lời (0-3 mỗi câu, tối đa 4 câu)
  so_cau_tra_loi INTEGER NOT NULL,   -- số câu CÓ điểm (0-3), không tính N/A
  so_cau_na INTEGER NOT NULL,        -- số câu N/A trong lĩnh vực này (tối đa 4)
  diem_quy_doi_12 REAL,              -- NULL nếu so_cau_tra_loi < 3 (chưa đủ dữ liệu)
  muc_linh_vuc TEXT NOT NULL,        -- 'du_lieu_du' | 'chua_du_du_lieu'
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_domain_results_screening ON screening_domain_results(screening_id);
```

### 3.4 Bảng 3 — `screening_sessions` (bảng tổng, thay cho `screenings` cũ)

```sql
CREATE TABLE screening_sessions (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  muc_tuoi_lam_bai TEXT NOT NULL,    -- '2_tuoi' | '3_tuoi' | '4_tuoi' | '5_tuoi'
  tong_diem_60 REAL,                 -- NULL nếu bất kỳ lĩnh vực nào chưa đủ dữ liệu
  giai_doan TEXT NOT NULL,           -- '1' | '2' | '3' | 'chua_du_du_lieu'
  co_canh_bao INTEGER NOT NULL DEFAULT 0,  -- boolean (0/1) — cờ "mất kỹ năng đã từng có
                                            -- / lo ngại phát triển rõ rệt"
  ngay_thuc_hien TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_screening_sessions_child ON screening_sessions(child_id);
```

Đổi tên bảng cha từ `screenings` → `screening_sessions` (thay vì giữ tên
cũ) để: (a) tránh nhầm lẫn với dữ liệu/khái niệm cũ khi đọc code sau này,
(b) tên mới mô tả đúng bản chất "1 lần làm bài" rõ hơn tên cũ vốn dùng
chung chung cho nhiều loại công cụ sàng lọc tiềm năng. **Xin xác nhận lại
tên bảng này khi duyệt** — nếu muốn giữ tên `screenings` cho ngắn gọn, có
thể đổi lại dễ dàng vì đằng nào cũng tạo bảng mới.

### 3.5 Migration `onUpgrade` — version 12 (viết sẵn, CHƯA áp dụng)

```dart
if (oldVersion < 12) {
  await db.execute('DROP TABLE IF EXISTS screening_responses');
  await db.execute('DROP TABLE IF EXISTS screening_domain_scores');
  await db.execute('DROP TABLE IF EXISTS screenings');
  await db.execute(screeningAnswersTableCreate);
  await db.execute(screeningDomainResultsTableCreate);
  await db.execute(screeningSessionsTableCreate);
}
```

Và cập nhật `onCreate` (cài mới) để tạo thẳng 3 bảng mới thay vì 3 bảng cũ.

### 3.6 Migration `onUpgrade` — version 13 (viết sẵn, CHƯA áp dụng)

```dart
if (oldVersion < 13) {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name = 'expert_knowledge_chunks'",
  );
  if (tables.isNotEmpty) {
    try {
      await db.execute(
        "DELETE FROM expert_knowledge_chunks WHERE content_type = 'so_sanh'",
      );
    } catch (_) {}
  }
}
```
(Giống hệt pattern version 10 đã có — `onOpen` sau đó tự `seedIfEmpty` nạp
lại từ `expert_knowledge_seed.json` đã sửa dải 12-23.)

### 3.7 5 lĩnh vực mới — hằng số độc lập với `domains.dart` (7 lĩnh vực)

Đề xuất file mới `lib/core/constants/screening_domains.dart` (KHÔNG sửa
`domains.dart` hiện có — đúng yêu cầu 2 bộ lĩnh vực độc lập hoàn toàn):

```dart
const List<ScreeningDomain> screeningDomains = [
  ScreeningDomain(code: 'ngon_ngu_giao_tiep', label: 'Ngôn ngữ - Giao tiếp'),
  ScreeningDomain(code: 'nhan_thuc_giai_quyet_van_de', label: 'Nhận thức - Giải quyết vấn đề'),
  ScreeningDomain(code: 'van_dong', label: 'Vận động'),  // gồm 2 nhóm con: 'tho'/'tinh'
  ScreeningDomain(code: 'xa_hoi_cam_xuc', label: 'Xã hội - Cảm xúc'),
  ScreeningDomain(code: 'tu_lap', label: 'Tự lập'),
];

const List<String> screeningAgeTiers = ['2_tuoi', '3_tuoi', '4_tuoi', '5_tuoi'];
```

---

## Việc CHƯA làm ở Giai đoạn A (đúng phạm vi)

- Chưa tạo/sửa file nào trong `lib/`, `assets/`, `pubspec.yaml`.
- Chưa viết `ScreeningScoringService` mới.
- Chưa tạo file placeholder JSON.
- Chưa sửa UI tạo hồ sơ/làm bài/kết quả.
- Chưa chạy migration nào.

---

**Chờ duyệt trước khi sang Giai đoạn B**, đặc biệt các điểm cần xác nhận:
1. Tên bảng `screening_sessions` (mục 3.4) — giữ hay đổi lại `screenings`?
2. Có rename 82 file video + `video_manifest.json` theo dải 12-23 không
   (mục 2.4) — đề xuất KHÔNG làm, chỉ sửa số liệu JSON.
3. Cách xử lý thư mục `assets/data/` rỗng sau khi xóa file 50 câu (mục
   1.2) — xóa khai báo trong `pubspec.yaml` hay giữ và xác nhận build vẫn
   qua.
4. `assets/reference/expert_content_so_sanh.json` (28 chỗ "15_23", dùng
   bởi script CLI dev-only) — có cần sửa đồng bộ không (mục 2.3).
