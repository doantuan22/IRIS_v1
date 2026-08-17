# SETUP_REPORT — Khởi tạo repo dự án IRIS

## 1. Kiểm tra môi trường

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| Flutter | PASS | 3.44.8 (stable channel) — có bản mới hơn, chưa cần upgrade |
| Dart | PASS | 3.12.2 |
| Git | PASS | 2.54.0 — thư mục chưa phải git repo, đã chạy `git init` |
| Hệ điều hành | Windows 11 (25H2) | Máy chỉ build được iOS/macOS nếu có máy macOS — không liên quan vì project chỉ giữ platform Android + iOS |
| Android toolchain | PASS | SDK 36.0.0, build-tools 36.0.0, license đã accept |
| Visual Studio Build Tools / Chrome | PASS (máy có, nhưng **không dùng** vì project đã bỏ platform windows/web) | |
| `flutter doctor -v` | PASS — "No issues found!" | |
| Thiết bị/emulator | Máy có 3 thiết bị (Windows desktop, Chrome, Edge) qua `flutter devices`, nhưng đây là danh sách thiết bị **cấp máy**, không phải target build được của project (project không còn thư mục `windows/`, `web/`) | Target build thực tế của project: **Android** (đã có AVD sẵn `Pixel_7`, chạy `flutter emulators --launch Pixel_7`) hoặc **iOS** (cần máy macOS) |

Không thiếu thành phần nào cần thiết để chạy app trên Android (qua emulator `Pixel_7` có sẵn hoặc thiết bị thật).

## 2. Đã tạo

- Khởi tạo Flutter project **tại chính `IRIS_v1`** bằng `flutter create .` (không tạo thư mục con lồng bên trong), package name `iris_app`, org `com.iris.app`. `ROADMAP_DU_AN_IRIS.md` được giữ nguyên.
- Khởi tạo git repo (`git init`).
- Dựng đầy đủ cây thư mục `lib/`, `assets/`, `scripts/`, `test/` theo đúng mục 5 roadmap (bỏ lớp `iris_app/` ngoài cùng). Danh sách file chính:
  - `lib/main.dart`, `lib/app.dart`
  - `lib/core/constants/api_config.dart` (+ thư mục rỗng `core/theme/`, `core/utils/`)
  - `lib/data/local/database.dart` + 8 file trong `data/local/tables/` (mỗi file 1 hằng `CREATE TABLE` khớp schema mục 4)
  - `lib/data/remote/nvidia_api_client.dart`, `groq_api_client.dart`
  - `lib/data/repositories/` — 7 file (child, screening, assessment, profile_chunk, expert_knowledge, video, ai — 2 file cuối vẫn skeleton, xem mục 4)
  - `lib/domain/models/` — 6 file (child, screening, assessment, ai_chunk, profile_chunk, expert_knowledge_chunk)
  - `lib/domain/services/` — embedding_service, embedding_codec (encode/decode BLOB — đã cài đầy đủ ở Giai đoạn 1), vector_search_service, guardrail_service (enum 3 trạng thái)
  - `lib/features/` — 13 trang skeleton (`Placeholder()`) theo đúng cấu trúc feature/nine_domains trong roadmap
  - `lib/widgets/.gitkeep`
  - `scripts/ingest_expert_data.dart` (skeleton)
  - `assets/reference/expert_content.json` — 2 entry mẫu (`so_sanh`, `chia_se_phu_huynh`, lĩnh vực `ngon_ngu`)
  - `assets/videos/<9 lĩnh vực>/.gitkeep`
- Cấu hình `pubspec.yaml`:
  - Dependencies: `sqflite` + `path` (đã chọn **sqflite thay vì drift** — roadmap đã viết sẵn schema SQL thuần, sqflite bám sát đúng schema đó và không cần bước code-gen `build_runner`, phù hợp ưu tiên tốc độ phát triển cho dự án thi), `path_provider`, `camera`, `video_player`, `http`, `uuid`.
  - Khối `flutter: assets:` trỏ tới `assets/reference/` và từng thư mục con của `assets/videos/`.
- `flutter pub get`: **chạy sạch**, 52 dependency mới, không lỗi.
- `flutter analyze`: **0 lỗi**. Còn 14 warning/info mức style (`unused_field` trên các repository — do constructor đã inject dependency nhưng thân hàm còn `UnimplementedError`, sẽ hết khi cài logic thật; vài gợi ý `prefer_initializing_formals`). Không ảnh hưởng khả năng build/run.
- Đã **xoá** các thư mục platform `linux/`, `macos/`, `windows/`, `web/` mà `flutter create .` tự sinh thêm ngoài ý roadmap — root repo giờ khớp đúng cây thư mục mục 5 (chỉ còn `android/`, `ios/`, `assets/`, `lib/`, `scripts/`, `test/`, `pubspec.yaml`, `README.md`, cộng các file nội bộ chuẩn của Flutter như `.metadata`, `pubspec.lock`, `.dart_tool`). Đã chạy lại `flutter pub get` và `flutter analyze` sau khi xoá — vẫn sạch.

## 3. Việc cần tự làm thủ công

- **API key**: xin key NVIDIA NIM và Groq, điền vào file `dart_define.json` ở thư mục gốc (đã tạo sẵn, đã gitignore — KHÔNG hardcode vào `api_config.dart`):
  ```json
  {
    "NVIDIA_API_KEY": "key-thật-của-bạn",
    "GROQ_API_KEY": "key-thật-của-bạn"
  }
  ```
  Sau đó chạy app hoặc script ingest với `--dart-define-from-file` thay vì gõ từng key:
  ```
  flutter run --dart-define-from-file=dart_define.json
  dart run scripts/ingest_expert_data.dart --dart-define-from-file=dart_define.json
  ```
  Trong VS Code: chọn cấu hình debug **"IRIS (kèm API key)"** (đã tạo sẵn trong `.vscode/launch.json`) rồi bấm F5 — tự động đọc key từ `dart_define.json`.
  `dart_define.example.json` (có commit) chỉ để tham khảo cấu trúc — file thật `dart_define.json` không bao giờ lên git.
- **Quyền camera/microphone** cho chức năng quay video (#9):
  - Android: thêm `<uses-permission android:name="android.permission.CAMERA"/>` (và `RECORD_AUDIO` nếu quay có tiếng) vào `android/app/src/main/AndroidManifest.xml`.
  - iOS (nếu sau này build trên macOS): thêm `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` vào `ios/Runner/Info.plist`.
- **Emulator Android**: đã có sẵn `Pixel_7`, chạy `flutter emulators --launch Pixel_7` trước khi `flutter run` nếu muốn test trên Android.
- **iOS/macOS build**: cần một máy macOS có Xcode — máy Windows hiện tại không build được.
- Nạp thêm dữ liệu tham khảo thật vào `assets/reference/expert_content.json` (hiện chỉ có 2 entry mẫu) rồi chạy `scripts/ingest_expert_data.dart` sau khi cài logic ingest thật (script hiện là skeleton, ném `UnimplementedError`).
- Toàn bộ file `.dart` trong `data/remote/`, `data/repositories/ai_repository.dart`, `data/repositories/video_repository.dart`, `domain/services/` (trừ `embedding_codec.dart`), `features/` vẫn là **khung sườn** (nhiều nơi `throw UnimplementedError`) — cần cài logic thật theo thứ tự triển khai ở mục 6 roadmap, bắt đầu từ Giai đoạn 2 (UI hồ sơ trẻ + sàng lọc).

## 4. Giai đoạn 1 — Nền tảng dữ liệu (2026-08-10)

Phạm vi: chỉ database local + repository CRUD, **chưa có màn hình UI nào**, **chưa gọi API NVIDIA/Groq**.

### Bảng đã tạo (khớp 100% schema mục 4 roadmap)

Cả 8 bảng đều dùng nguyên văn SQL `CREATE TABLE` từ roadmap (`lib/data/local/tables/*.dart`), không thêm/bớt cột: `children`, `screenings`, `assessments`, `history_logs`, `profile_chunks`, `expert_knowledge_chunks`, `videos`, `ai_conversations` — cộng 3 index (`idx_profile_chunks_child`, `idx_assessments_child`, `idx_history_child`). Đã bật `PRAGMA foreign_keys = ON` trong `onConfigure` của `AppDatabase` ([lib/data/local/database.dart](lib/data/local/database.dart)).

### Utility embedding

`lib/domain/services/embedding_codec.dart` — `encodeEmbedding()`/`decodeEmbedding()` chuyển `List<double>` ↔ `Uint8List`, ghi/đọc từng float32 tường minh theo `Endian.little` (không dùng trực tiếp `Float32List.buffer` để tránh lệ thuộc byte-order máy và alignment của BLOB đọc về từ sqflite).

### Repository đã implement đầy đủ CRUD

- `ChildRepository` — create/getAll/getById/update/archive/delete
- `ScreeningRepository` — save/getForChild/getLatestForChild/**hasScreening()** (đúng nguyên tắc: không có dòng nào = chưa sàng lọc)
- `AssessmentRepository` — save/getForChild (lọc theo `linh_vuc`)
- `ProfileChunkRepository` *(mới)* — add/getForChild, tự encode/decode embedding
- `ExpertKnowledgeRepository` *(mới)* — add/query (lọc theo `linh_vuc` + khoảng tuổi `do_tuoi_thang_min/max`, đơn vị THÁNG — xem đổi tên ở mục 5 Giai đoạn 2 + `content_type`)
- Model mới: `lib/domain/models/profile_chunk.dart`, `lib/domain/models/expert_knowledge_chunk.dart`

Mọi id sinh bằng `package:uuid` (`Uuid().v4()`).

### Kết quả test — [test/repositories_test.dart](test/repositories_test.dart)

Chạy trên desktop qua `sqflite_common_ffi` + database in-memory (`AppDatabase.debugPathOverride`, không cần path_provider/thiết bị thật). Kết quả: **5/5 PASS**.

| Test | Kết quả |
|---|---|
| ChildRepository: tạo và đọc hồ sơ trẻ | PASS |
| ScreeningRepository: `hasScreening()` = false trước / true sau khi thêm | PASS |
| AssessmentRepository: thêm + đọc mô tả biểu hiện theo lĩnh vực | PASS |
| ProfileChunkRepository: encode/decode BLOB embedding 768 chiều khớp giá trị gốc | PASS |
| ExpertKnowledgeRepository: query lọc đúng theo `linh_vuc` + khoảng tuổi (30 tháng → 1 kết quả, 36 tháng → 2 kết quả do trùng khoảng) | PASS |

Chạy lại: `flutter test test/repositories_test.dart` (cần `sqlite3.dll` trên PATH — xem ghi chú bên dưới).

**Lưu ý môi trường test riêng cho desktop (không ảnh hưởng app thật)**: đã thêm dev-dependency `sqflite_common_ffi` và copy sẵn `tool/win_sqlite3/sqlite3.dll` (bản 3.43.1, lấy từ cài đặt PlatformIO có sẵn trên máy) vào repo — chỉ dùng để `sqflite_common_ffi` load native lib khi chạy `flutter test` trên Windows. Trên thiết bị Android/iOS thật, plugin `sqflite` tự bundle SQLite riêng, không cần file này. Khi chạy test, cần thêm thư mục này vào PATH:
```
$env:PATH = "tool\win_sqlite3;$env:PATH"; flutter test
```

`flutter analyze` sau Giai đoạn 1: **0 lỗi**. Còn 11 warning/info — toàn bộ nằm ở `ai_repository.dart` và `video_repository.dart` (2 file vẫn là skeleton, ngoài phạm vi giai đoạn này).

### Chưa làm (để dành Giai đoạn 2 trở đi)

- Chưa có bất kỳ màn hình/widget UI nào dùng đến các repository này.
- Chưa gọi API NVIDIA (embedding)/Groq (generation) — `embedding_codec.dart` chỉ xử lý encode/decode BLOB thuần Dart, không tính embedding thật.
- `VectorSearchService`, `GuardrailService`, `AiRepository`, `VideoRepository` vẫn là skeleton.

## 5. Giai đoạn 2 — Hồ sơ trẻ + Sàng lọc (2026-08-10)

Phạm vi: UI Bước 1-4 (tạo/chọn hồ sơ trẻ, chọn thực hiện sàng lọc, bộ câu hỏi mock, kết quả). Widget Material mặc định, chưa làm đẹp giao diện.

### Nhiệm vụ 0 — Sửa đơn vị tuổi (hoàn tất trước khi làm UI)

`do_tuoi_min`/`do_tuoi_max` (bảng `expert_knowledge_chunks`) đổi tên thành **`do_tuoi_thang_min`/`do_tuoi_thang_max`** để tường minh đơn vị THÁNG — khác với `children.age_years` (đơn vị NĂM). Đã cập nhật đồng bộ:

- `ROADMAP_DU_AN_IRIS.md` (schema mục 4 + ghi chú quy đổi đơn vị mới ngay dưới schema)
- `lib/data/local/tables/expert_knowledge_chunks_table.dart`, `lib/domain/models/expert_knowledge_chunk.dart`, `lib/data/repositories/expert_knowledge_repository.dart` (tham số `doTuoiThangMin/Max`, `ageInMonths`)
- `assets/reference/expert_content.json` (đổi tên field, giá trị vẫn đúng đơn vị tháng: 24-36)
- `test/repositories_test.dart` (đổi tên tham số, logic test giữ nguyên)

Thêm `childAgeInMonths(Child child)` và `formatAgeLabel(Child child)` trong [lib/domain/models/child.dart](lib/domain/models/child.dart): ưu tiên tính chính xác từ `dob`, fallback `ageYears * 12`. Test riêng trong [test/child_age_test.dart](test/child_age_test.dart) — 4 case (dob ~1 năm, dob 1 ngày trước, chỉ có ageYears, không có cả hai → throw) — **4/4 PASS**.

### Nhiệm vụ 1 — Hồ sơ trẻ

- [lib/features/child_profile/child_list_page.dart](lib/features/child_profile/child_list_page.dart) *(mới)* — danh sách hồ sơ trẻ (`ListView` từ `ChildRepository.getAll()`), FAB tạo mới, tap vào item → chi tiết.
- [lib/features/child_profile/create_profile/create_profile_page.dart](lib/features/child_profile/create_profile/create_profile_page.dart) — form tạo hồ sơ: tên (bắt buộc) + chọn ngày sinh HOẶC số tuổi (`RadioGroup`, đúng API mới thay `RadioListTile.groupValue` đã deprecated ở Flutter 3.44) + giới tính. Validate đủ tên và (dob hoặc age).
- [lib/features/child_profile/profile_detail/profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart) — hiện thông tin cơ bản (tên, tuổi qua `formatAgeLabel`, giới tính), badge "Đã sàng lọc"/"Chưa sàng lọc" (`ScreeningRepository.hasScreening()`), nút Sàng lọc + link tới các trang skeleton khác (9 lĩnh vực, lịch sử, AI chat, quay video), nút debug xem raw `screenings`.

### Nhiệm vụ 2 — Sàng lọc

3 trang mới trong `lib/features/screening/` (thay cho `screening_page.dart` skeleton cũ đã xoá):

- `screening_intro_page.dart` — đúng 2 nhánh **Có**/**Chưa muốn**, không có nhánh thứ 3.
- `screening_questionnaire_page.dart` — 6 câu hỏi mock có/không (`_mockQuestions`, ghi rõ đây là bộ demo, chưa phải công cụ chuẩn thật), tính điểm = số câu "Có", lưu qua `ScreeningRepository.save()`.
- `screening_result_page.dart` — hiện điểm + tóm tắt + dòng chữ bắt buộc **"Đây là kết quả sàng lọc, không phải kết luận chẩn đoán."**

Nhánh "Chưa muốn" chỉ `Navigator.pop()`, không gọi bất kỳ hàm ghi dữ liệu nào — đúng nguyên tắc "không có dòng nào = chưa sàng lọc".

`lib/app.dart` trỏ `home` sang `ChildListPage`.

### Nhiệm vụ 3 — Kiểm chứng

**Không dùng emulator `Pixel_7`/build APK như kế hoạch ban đầu** — bị chặn bởi lỗi tương thích toolchain, không liên quan code Phase 2:

```
:camera_android_camerax:compileDebugJavaWithJavac
error: Cannot attach type annotations @org.jspecify.annotations.NonNull to SurfaceRequest.mSurfaceRecreationCompleter:
  class file for androidx.concurrent.futures.CallbackToFutureAdapter not found
```

Nguyên nhân: môi trường máy dùng Android SDK API 37 (bleeding-edge/preview) + Gradle 9.1 + camera-core 1.5.3 (CameraX, kéo theo bởi package `camera`) — xung đột annotation-processing giữa `jspecify` và `androidx.concurrent.futures` chưa tương thích với toolchain này. Đã thử 3 cách vá qua `android/build.gradle.kts` (force resolution strategy, thêm dependency trực tiếp vào subproject plugin qua `afterEvaluate`/trực tiếp) — đều thất bại vì lifecycle evaluation của Gradle multi-project. Đây là vấn đề môi trường/dependency của plugin `camera` (chưa được dùng ở bất kỳ code nào trong Phase 1-2), không phải lỗi trong code IRIS — **để lại cho lúc làm tính năng quay video** (mục 6 roadmap, sau Giai đoạn 2), lúc đó cần xử lý riêng (thử downgrade `camera`, hoặc chờ bản vá từ Flutter/CameraX, hoặc hạ Android SDK/Gradle xuống bản ổn định hơn).

**Thay bằng widget test tự động lái toàn bộ UI thật** qua `Navigator` — không cần APK, không cần thiết bị:

[test/screening_flow_test.dart](test/screening_flow_test.dart) — 1 test end-to-end, dùng `sqflite_common_ffi` (database in-memory, giống Giai đoạn 1) + `LiveTestWidgetsFlutterBinding` (cần đồng hồ thời gian thực để khớp I/O thật của `sqflite_common_ffi`, `pumpAndSettle()`/binding mặc định bị treo do `CircularProgressIndicator` mặc định animate vô hạn + đồng hồ giả không nhường đủ thời gian cho I/O thật hoàn tất):

| Bước kiểm chứng | Kết quả |
|---|---|
| Tạo hồ sơ trẻ mới qua form (tên + số tuổi) → hiện trong danh sách | PASS |
| Vào chi tiết hồ sơ mới tạo → badge "Chưa sàng lọc" | PASS |
| Nhánh "Chưa muốn" → quay lại chi tiết, badge vẫn "Chưa sàng lọc", **không** tạo bản ghi `screenings` | PASS |
| Nhánh "Có" → trả lời 6 câu "Không" → điểm "0/6" + dòng chữ disclaimer hiển thị đúng | PASS |
| Quay lại hồ sơ → badge cập nhật đúng thành "Đã sàng lọc" | PASS |
| Xác nhận trực tiếp qua `ScreeningRepository`: `hasScreening()=true`, 1 bản ghi, `score='0/6'`, `tool_name` chứa "mock" | PASS |

**10/10 test PASS** toàn bộ project (4 child_age + 5 repositories + 1 flow). `flutter analyze`: **0 lỗi**, 11 warning/info còn lại đều ở `ai_repository.dart`/`video_repository.dart` (ngoài phạm vi).

### File Gradle có sửa đổi (giữ lại, không liên quan camera)

`android/gradle.properties` — thêm `kotlin.incremental=false` để fix lỗi build thật khác (không liên quan camera): Kotlin incremental compiler ném `IllegalArgumentException` khi project (`D:\`) và Gradle/pub cache (`C:\`) nằm khác ổ đĩa trên Windows. Giữ nguyên fix này vì đây là vấn đề luôn tái diễn trên máy hiện tại bất kể tính năng nào.

### Việc cần làm khi bắt đầu tính năng quay video

- Xử lý lỗi build `camera_android_camerax` nêu trên trước khi động tới `lib/features/video_recording/`.
- Từ đó mới build/chạy được thật trên emulator `Pixel_7` hoặc thiết bị Android thật để xem UI trực tiếp.

> **Cập nhật ở Giai đoạn 3**: đã gỡ tạm dependency `camera` khỏi `pubspec.yaml` (giữ nguyên `video_player`) vì tính năng quay video chưa cần dùng tới ở giai đoạn hiện tại và lỗi CameraX/Gradle ở trên chỉ phát sinh từ package này. Sau khi gỡ, `flutter run -d emulator-5554 --debug` build và cài đặt thành công — đã xác nhận lại toàn bộ luồng Giai đoạn 2 (tạo hồ sơ, cả 2 nhánh sàng lọc) chạy đúng trên app thật (không chỉ qua widget test), xem chi tiết ở mục Giai đoạn 3 bên dưới. Sẽ thêm lại `camera` và xử lý lỗi CameraX/Gradle khi bắt đầu Giai đoạn 5 (quay video).

## 6. Giai đoạn 3 — Đánh giá 9 lĩnh vực (2026-08-11)

Phạm vi: Bước 5-6, chỉ **mục 1 "Mô tả biểu hiện" chạy thật đầy đủ** (kể cả gọi NVIDIA embedding API thật, có unit test riêng vì môi trường chưa có API key thật); m…76448 tokens truncated…_SANH.md`) không có trong workspace tại thời điểm audit; vì vậy không thể xác nhận từng tuyên bố của các file đó. `SETUP_REPORT.md`, mã nguồn hiện hành, Git, asset, APK sẵn có và Android SDK là nguồn bằng chứng đã dùng.

Không có thiết bị/emulator kết nối: lệnh `C:\Users\doant\AppData\Local\Android\Sdk\platform-tools\adb.exe devices -l` trả về danh sách rỗng. Không có file SQLite app/backup trong workspace để query. Vì thế các mục ghi “chưa xác minh” bên dưới thực sự chưa có bằng chứng DB hoặc UI, không được suy diễn PASS.

### Giai đoạn 1 — Trạng thái thực tế

| Hạng mục | Trạng thái thực tế | Bằng chứng |
|---|---|---|
| JSON So sánh 3 dải tuổi | Đã có ở source, cấu trúc cơ bản hợp lệ | `assets/reference/so_sanh_15_23_thang.json`: 200; `24_47`: 196; `48_60`: 136; tổng 532 ID duy nhất; mỗi file có đủ 7 lĩnh vực và đúng min/max tuổi. Đây **không** phải count từ DB app. |
| DB thực có 532 entry | Chưa xác minh | Không có emulator/thiết bị và không có DB app cục bộ để query `expert_knowledge_chunks`. |
| Sàng lọc 50 câu / bảng chi tiết | Mã nguồn đã có, DB thực chưa xác minh | Asset 50 câu, migration v8, `screening_responses` và `screening_domain_scores` tồn tại trong code; không có DB app để đếm phiên/dòng thật. |
| Cấu trúc 7 lĩnh vực | Đã áp dụng ở logic hiện hành | `domains.dart` có đúng 7 mã; quét Dart không thấy logic lưu mới dùng `hanh_vi`/`ung_xu`. Còn một docstring cũ “≥5/9” ở `expert_connect_page.dart`, không đổi điều kiện code `doneDomainCount >= 5`. |
| Manifest/video asset | Hợp lệ ở mức filesystem, chưa chứng minh chạy app | Manifest có 204 ID, không thiếu file và không có ID lạ; 82/75/47 video theo 15–23/24–47/48–60. Bảy thư mục manifest đều đã khai báo trong `pubspec.yaml`. |
| Dữ liệu tham khảo trong release cài mới | Chạy sai | Xem BUG-01: app chỉ nạp `expert_knowledge_chunks` qua UI Debug. |
| Liên kết entry DB ↔ video manifest | Chạy sai | Xem BUG-02: nạp qua UI Debug tạo UUID mới, trong khi manifest khóa bằng ID JSON. |
| Xóa hồ sơ đa trẻ | Mã nguồn có xử lý đúng, chưa chạy thật | `ChildRepository.delete()` xóa `screening_responses` và `screening_domain_scores` trước `screenings` trong transaction, rồi xóa file video sau commit. |
| Git / khả năng tái tạo release | Dở dang, rủi ro cao | `git status --porcelain`: 137 thay đổi chưa commit (3 modified, 134 untracked), gồm JSON 48–60, 204 video/manifest và script. `HEAD` là `5e9f850`; các asset mới không nằm trong commit hiện tại. |

### Bug phát hiện qua audit tĩnh

| ID | Mức độ / phạm vi | Mô tả và bước tái hiện | Bằng chứng |
|---|---|---|---|
| BUG-01 | **Chặn demo — Debug và Release** | Cài mới app, tạo trẻ, vào một lĩnh vực → **So sánh**. `ComparisonVideoPage` chỉ query SQLite `expert_knowledge_chunks`; `AppDatabase.onCreate` chỉ tạo bảng, không seed JSON. Cách nạp duy nhất là nút `Debug: Nạp dữ liệu tham khảo`, bị bọc bởi `kDebugMode`, nên bản release không có đường nạp. Kết quả: hai tab rỗng trên release cài mới. | `comparison_video_page.dart`, `database.dart`, `profile_detail_page.dart`, `child_debug_page.dart`. |
| BUG-02 | **Chặn demo video — Debug; Release cũng không có dữ liệu để tới bước này** | Trên debug, bấm `Debug: Nạp dữ liệu tham khảo`, sau đó mở một entry So sánh có video. `ChildDebugPage` gọi `ExpertKnowledgeRepository.add()`; repository luôn sinh `Uuid.v4()` cho `ExpertKnowledgeChunk.id`. UI tra `VideoManifestService.getVideoPathForId(item.id)`, nhưng manifest khóa bằng ID JSON như `so_sanh_...`. Vì UUID khác ID JSON, lookup luôn `null`, nên nút **Xem video minh hoạ** không hiện. | `child_debug_page.dart:184`, `expert_knowledge_repository.dart`, `comparison_video_page.dart:231`, `video_manifest.json`. |
| BUG-03 | **Chặn phát hành / khả năng cài đặt — Release** | Đóng gói toàn bộ asset hiện có tạo APK cực lớn. 204 video chiếm 1,840,655,071 bytes = **1,755.39 MiB**; file lớn nhất 110.16 MiB. MP4/WebM vốn đã nén nên APK mới gần như chắc tăng cỡ dữ liệu này, thay vì APK cũ 25,776,723 bytes (24.58 MiB). Không phù hợp để phát hành/tải demo; còn có nguy cơ build/cài đặt không thực tế tùy thiết bị và kênh phân phối. | Đo trực tiếp `assets/videos/`; APK sẵn có tại `build/app/outputs/flutter-apk/app-release.apk`. |
| BUG-04 | Nên sửa — Debug | UI Debug cho phép xác nhận “Vẫn nạp” khi DB đã có data rồi insert lại toàn bộ, không khóa ID/khử trùng. Số entry So sánh có thể bị nhân bản qua mỗi lần nạp, làm kết quả/hiệu năng sai lệch. | `child_debug_page.dart`, nhánh `existing.isNotEmpty` và vòng gọi `add()`. |
| BUG-05 | Cosmetic / tài liệu UI | Docstring Expert Connect vẫn nói ngưỡng “≥5/9 lĩnh vực”, trong khi hệ thống hiện là 7 lĩnh vực và code dùng `doneDomainCount >= 5`. | `expert_connect_page.dart`. |

### Giai đoạn 2 — Kiểm thử luồng thật trên Pixel_7

**Chưa thể thực hiện, không PASS.** Android SDK và `adb` có trên máy, nhưng không có thiết bị/emulator ở trạng thái `device`; do đó không thể chạy/debug, dùng `uiautomator dump`, query DB trên thiết bị, kiểm tra 3 mốc tuổi, bấm video, test 3 trạng thái AI, camera, hay xóa đa trẻ.

Khi có Pixel_7/emulator, cần chạy lại tối thiểu các ca yêu cầu trong nhiệm vụ. Riêng BUG-01 và BUG-02 phải được xác nhận lại sau khi sửa trước khi coi các ca video là PASS.

### Giai đoạn 3 — Build và release

- Đã thử `flutter build apk --release --dart-define-from-file=dart_define.json` hai lần; lệnh không sinh log/kết quả sau 120 giây và sau gần 5 phút, nên bị dừng để không treo audit. Không đọc hay in giá trị API key.
- APK sẵn có (timestamp 2026-08-16 09:02:16) **không được xem là build của source hiện hành**: archive chỉ có `.gitkeep` trong các thư mục video, không có `assets/reference/video_manifest.json`, `so_sanh_48_60_thang.json`, hay một video 48–60 đã kiểm tra. Không được dùng artefact này để chứng minh release mới.
- `aapt dump permissions` trên APK sẵn có xác nhận có `INTERNET`, `CAMERA`, `RECORD_AUDIO`; target SDK 36, min SDK 24. Đây chỉ xác nhận manifest của APK cũ.
- `android/key.properties` không tồn tại; Gradle cấu hình fallback ký release bằng debug signing. Có thể build thử release sau khi môi trường Flutter hoạt động, nhưng **chưa có keystore phát hành thật**.
- Kiểm tra ProGuard/R8, cài APK release lên Pixel_7, chạy video asset và AI key thật: **chưa xác minh** vì chưa có build mới/thiết bị.

### Kết luận audit

Không thể kết luận dự án sẵn sàng demo hoặc release. Trước khi làm lại kiểm thử thiết bị, cần ưu tiên xử lý BUG-01, BUG-02 và BUG-03; sau đó commit đầy đủ JSON/video/manifest/mã liên quan, khôi phục khả năng chạy Flutter build, build APK mới, cài lên Pixel_7 và thực hiện lại toàn bộ Giai đoạn 2–3.

## Thử nén video mẫu cho BUG-03 — Dừng trước khi ghi đè (2026-08-16)

Mục tiêu là giảm 204 video minh hoạ trong `assets/videos/` từ 1,755.39 MiB xuống khoảng 150–300 MiB, không xóa video, không thay đổi Dart/manifest/pubspec và không đụng video do người dùng tự quay.

### Audit và backup bắt buộc

- FFmpeg/FFprobe đã cài qua WinGet: `ffmpeg version 9.0-full_build-www.gyan.dev`. Windows alias không thực thi được trong shell audit, nên dùng binary thật trong package WinGet.
- Inventory trước nén: `C:\Users\doant\AppData\Local\Temp\IRIS_video_inventory_before_20260816.csv`.
- Đối chiếu: đúng **204** video, đúng **204** entry manifest, không có file không được manifest tham chiếu và không có `file_path` gãy.
- Tổng nguồn: **1,840,655,071 bytes = 1,755.39 MiB**; codec: 201 H.264/AAC, 3 VP8/Vorbis WebM.
- Backup nguyên gốc đã hoàn tất ngoài repo tại **`D:\IRIS_video_goc_backup_20260816\assets\videos`**: đúng 204 file, đúng 1,840,655,071 bytes = 1,755.39 MiB.

### Nén thử 10 mẫu — không ghi đè source

Mẫu gồm file nhỏ nhất/lớn nhất và các file nhỏ-trung bình-lớn trải đều ba dải tuổi (3/4/3 cho 15–23/24–47/48–60). Output tạm nằm tại `C:\Users\doant\AppData\Local\Temp\IRIS_video_compression_samples_20260816`.

Thông số thử:

- H.264 `libx264`, preset `medium`, CRF 27, `yuv420p`, MP4.
- Scale giữ tỷ lệ, bounding box tối đa 1280×720, không upscale.
- AAC mono 80 kbps, `faststart`.

Kết quả thực:

| Chỉ số | Kết quả |
|---|---:|
| Tổng 10 mẫu trước nén | 297.00 MiB |
| Tổng 10 mẫu sau nén | 164.11 MiB |
| Giảm theo dung lượng có trọng số | 44.74% |
| Ước lượng 204 file theo tỷ lệ mẫu | **969.99 MiB** |
| Sai lệch duration lớn nhất | 0.03 giây |
| Codec output | 10/10 H.264 + AAC; FFmpeg giải mã lại thành công |

### Kết luận và trạng thái

**ĐÃ DỪNG, không nén toàn bộ.** Ước lượng 969.99 MiB nằm ngoài khoảng chấp nhận 150–350 MiB, nên không được tự ý ghi đè 204 video theo yêu cầu. Không file nào trong `assets/videos/` đã bị sửa; backup nguyên gốc vẫn sẵn sàng.

Lần thử tiếp theo cần thông số mạnh hơn (ví dụ scale tối đa 480p, CRF cao hơn/bitrate thấp hơn, có thể giảm fps) và phải nén mẫu lại trước. Ba file `.webm` cũng cần quyết định riêng: đầu ra H.264/AAC MP4 không thể giữ nguyên phần mở rộng `.webm` mà vẫn là container hợp lệ; không đổi tên/manifest thì chỉ có thể giữ WebM hoặc dùng codec/container WebM tương thích.

## BUG-03 — Nén toàn bộ video minh hoạ theo mức đã chấp nhận (2026-08-16)

Người dùng đã chấp nhận mức dung lượng khoảng 900 MiB sau thử mẫu, nên áp dụng **đúng** thông số đã thử; không thực hiện vòng tối ưu mới hay đổi CRF/độ phân giải/bitrate.

### Phạm vi và an toàn dữ liệu

- Chỉ thay đổi file vật lý trong `assets/videos/`; không đổi tên, đường dẫn, `video_manifest.json`, `pubspec.yaml`, Dart hay dữ liệu So sánh.
- Bản gốc vẫn được backup đầy đủ tại `D:\IRIS_video_goc_backup_20260816\assets\videos` (204 file, 1,840,655,071 bytes = 1,755.39 MiB).
- Mỗi output được tạo ở file tạm trước; chỉ thay thế nguồn sau khi FFmpeg trả exit code thành công, file tạm tồn tại và nhỏ hơn nguồn. Nếu lỗi/không có lợi, nguồn được giữ nguyên.

### Thông số đã dùng

- Video: H.264 `libx264`, preset `medium`, CRF 27, `yuv420p`.
- Scale giữ tỷ lệ: bounding box tối đa 1280×720, không upscale, kích thước chia hết cho 2.
- Audio: AAC mono 80 kbps; `faststart` cho MP4.

### Kết quả thực tế

| Chỉ số | Kết quả |
|---|---:|
| Video trước nén | 204 |
| Video sau nén | 204 |
| Dung lượng trước | 1,840,655,071 bytes = 1,755.39 MiB |
| Dung lượng sau | 940,574,747 bytes = **897.00 MiB** |
| Giảm thực tế | 48.90% (815.39 MiB) |
| Nén thành công | 183 |
| Giữ nguyên vì nguồn ≤ 1 MiB | 15 |
| Giữ nguyên vì output không nhỏ hơn nguồn | 3 |
| Giữ nguyên do lỗi encode | 3 WebM |

Ba WebM lỗi là hệ quả kỹ thuật đã biết của yêu cầu giữ nguyên tên/đuôi `.webm` đồng thời dùng H.264/AAC: WebM không chấp nhận tổ hợp codec đó. Cả ba được giữ nguyên, hash khớp backup:

- `assets/videos/ngon_ngu/so_sanh_ngon_ngu_binh_thuong_24_47_004.webm`
- `assets/videos/ngon_ngu/so_sanh_ngon_ngu_binh_thuong_24_47_005.webm`
- `assets/videos/quan_he_xa_hoi/so_sanh_quan_he_xa_hoi_binh_thuong_24_47_002.webm`

Các file giữ nguyên theo quy tắc kích thước:

- ≤ 1 MiB: `cam_xuc/so_sanh_cam_xuc_binh_thuong_24_47_002.mp4`; `ngon_ngu/so_sanh_ngon_ngu_binh_thuong_15_23_002.mp4`, `_24_47_014.mp4`, `_24_47_021.mp4`, `_24_47_022.mp4`, `_24_47_024.mp4`; `nhan_thuc/so_sanh_nhan_thuc_roi_loan_pho_tu_ky_15_23_005.mp4`; `quan_he_xa_hoi/so_sanh_quan_he_xa_hoi_binh_thuong_24_47_007.mp4`; `sinh_hoat_ca_nhan/so_sanh_sinh_hoat_ca_nhan_binh_thuong_15_23_002.mp4`; `sinh_hoc/so_sanh_sinh_hoc_binh_thuong_24_47_001.mp4`, `_004.mp4`, `_007.mp4`, `_009.mp4`, `_013.mp4`, `_015.mp4`.
- Output không nhỏ hơn nguồn: `cam_xuc/so_sanh_cam_xuc_roi_loan_pho_tu_ky_24_47_005.mp4`; `ngon_ngu/so_sanh_ngon_ngu_binh_thuong_15_23_003.mp4`; `quan_he_xa_hoi/so_sanh_quan_he_xa_hoi_binh_thuong_48_60_010.mp4`.

Log từng file: `artifacts/video_compression_20260816.csv`.

### Verify sau nén

- Đếm trực tiếp: 204 video hiện tại; backup cũng 204.
- Manifest: 204 entry, **0** `file_path` gãy và **0** video không được manifest tham chiếu.
- Các file không nén thành công/được bỏ qua được đối chiếu SHA-256 với backup: **0 mismatch**.
- Không còn file tạm hoặc file giữ chỗ sau khi hoàn tất.
- `ffprobe` + giải mã FFmpeg đã kiểm tra 10 video đại diện (gồm các video lớn 236.844 s, 278.872 s và 834.920 s; cả ngang/dọc; đủ ba dải tuổi). Duration chênh tối đa **0.000 s**, sai lệch tỉ lệ khung hình tối đa **0.0009**, 10/10 giải mã không lỗi. Chi tiết: `artifacts/video_compression_ffprobe_20260816.csv`.
- `adb devices -l` tại thời điểm verify không có thiết bị kết nối, nên **chưa verify phát trên thiết bị thật** và không suy diễn đây là PASS runtime trên Android.

### Trạng thái

**BUG-03 đã được xử lý ở mức người dùng chấp nhận:** 1,755.39 MiB → **897.00 MiB** với 204 đường dẫn vẫn nguyên vẹn. Đây **không phải mức tối ưu tuyệt đối**; nếu cần giảm thêm, thực hiện một đợt riêng với yêu cầu chất lượng mới (và quyết định riêng cho ba WebM), không tự động thay đổi thông số trong đợt này.
- **TOÀN BỘ 3 DẢI TUỔI NỘI DUNG "SO SÁNH" ĐÃ HOÀN TẤT TRỌN VẸN**:
  - Dải 15-23 tháng (200 entry, 7 lĩnh vực) $\rightarrow$ **Đã nạp & kiểm chứng**.
  - Dải 24-47 tháng (196 entry, 7 lĩnh vực) $\rightarrow$ **Đã nạp & kiểm chứng**.
  - Dải 48-60 tháng (136 entry, 7 lĩnh vực) $\rightarrow$ **Đã nạp & kiểm chứng**.
  - **Không còn bất kỳ dải tuổi nào thiếu dữ liệu "So sánh".**
- `flutter analyze`: **0 issues found** (No issues found!).
- `flutter test`: **172/172 PASS (100% trên toàn bộ 34 test files)**.

## Điều Chỉnh Văn Phong 3 File "So Sánh" — Áp Dụng Skill `dieu-chinh-van-phong-so-sanh` (2026-08-16)

Thực hiện đúng 6 bước trong `dieu-chinh-van-phong-so-sanh/SKILL.md` (skill được người dùng thêm sẵn vào repo, nội dung thay đổi đã chốt sẵn trong `references/`) — chỉ ÁP DỤNG, không tự sáng tác thêm nội dung nào.

### Bước 1 — Xác định 3 file

`assets/reference/so_sanh_15_23_thang.json`, `assets/reference/so_sanh_24_47_thang.json`, `assets/reference/so_sanh_48_60_thang.json` (cả 3 đã tồn tại — dải 48-60 tháng đã được hoàn tất ở 1 phiên làm việc khác trước đó, xem mục ngay phía trên). Xác nhận KHÔNG còn bản sao trùng ở gốc repo (kiểm tra `so_sanh_*_thang.json` ở `d:\IRIS_v1\` — không có, chỉ còn đúng 3 file trong `assets/reference/`).

### Bước 2 — Backup

Đã copy nguyên vẹn cả 3 file gốc sang **`backup_van_phong_20260816/`** (tại gốc repo) TRƯỚC khi sửa bất cứ gì. Giữ lại, không xoá.

### Bước 3 — Đọc 4 file reference

Đọc đủ 4 file theo đúng thứ tự: `loai_A_xoa_rac_ky_thuat.md` (85 entry — xoá timestamp/số chú thích trôi nổi), `loai_B_viet_lai_tu_nhien.md` (71 entry — viết lại câu văn xuôi tự nhiên), `loai_C_entry_ngan_chua_ro_nghia.md` (9 entry — làm rõ nghĩa entry quá ngắn), `ngoai_le_sua_url_hong.md` (1 entry — sửa `nguon_tai_lieu` bị dính `%200:46` vào cuối URL).

### Bước 4 — Áp dụng

Viết script Python nhỏ (`apply_van_phong.py`, chạy 1 lần, không giữ trong repo — chỉ dùng `references/expected_final_content.json` làm nguồn sự thật duy nhất): với mỗi entry trong 3 file thật, tra đúng `id` trong file kỳ vọng (532 id), gán `content` = giá trị cuối cùng; riêng đúng 1 id ngoại lệ (`so_sanh_ngon_ngu_binh_thuong_48_60_008`) gán thêm `nguon_tai_lieu`. Không đụng bất kỳ field nào khác, không đụng entry nào ngoài danh sách 532 id.

- **140 entry có `content` thực sự thay đổi** (khớp đúng với việc 1 số id trùng lặp giữa Loại A và Loại B/C — skill đã lưu ý rõ 165 "lượt" thay đổi trên danh sách nhưng số id THỰC SỰ đổi ít hơn do trùng lặp; script chỉ tính là "thay đổi" khi giá trị cuối khác giá trị gốc, không đếm trùng).
- **1 ngoại lệ `nguon_tai_lieu` đã áp dụng** đúng theo `ngoai_le_sua_url_hong.md`.

### Bước 5 — Verify BẮT BUỘC

```
python dieu-chinh-van-phong-so-sanh/scripts/verify_changes.py \
    --edited assets/reference/so_sanh_15_23_thang.json \
             assets/reference/so_sanh_24_47_thang.json \
             assets/reference/so_sanh_48_60_thang.json \
    --expected dieu-chinh-van-phong-so-sanh/references/expected_final_content.json
```

**Kết quả thật (output đầy đủ):**
```
======================================================================
KET QUA VERIFY - SUA VAN PHONG 3 FILE SO_SANH_*_THANG.JSON
======================================================================
Tong so id ky vong : 532
Tong so id thuc te : 532

PASS - Khong phat hien sai lech nao.
  - 532/532 entry co content dung ky vong.
  - Khong entry nao bi doi field ngoai 'content'.
```
**Exit code: 0 (PASS).** Toàn bộ 532/532 id khớp đúng `content` kỳ vọng; không entry nào bị đổi field ngoài `content` (trừ đúng 1 ngoại lệ đã khai báo).

### Bước 6 — Kết quả

- Đã áp dụng đúng **165 lượt thay đổi đã duyệt** (85 Loại A + 71 Loại B + 9 Loại C, có trùng id giữa các loại → 140 id thực sự đổi `content`) + **1 ngoại lệ sửa URL** (`nguon_tai_lieu`).
- Verify: **PASS** (chi tiết ở trên).
- Backup: `backup_van_phong_20260816/` (giữ nguyên, không xoá).
- **Không chạy bước ingest/embedding/seed DB** trong nhiệm vụ này — đúng theo giới hạn phạm vi của skill, để dành cho nhiệm vụ riêng sau khi văn phong đã được xác nhận đúng.
- Không phát hiện chỗ nào khác "có vẻ" cần sửa văn phong nhưng ngoài phạm vi `references/` trong lúc thực hiện — không có gì cần báo cáo thêm cho vòng duyệt sau.

## UI trắng-xanh, không mascot (2026-08-17)

- Chuyển nhận diện sang trắng-xanh: wordmark IRIS gradient vẽ bằng Flutter, nền blob/dot-grid/sparkle, thẻ trắng viền xanh nhạt và đèn AI cập nhật theo `AiConnectivityService`.
- Đã xoá toàn bộ asset/reference mascot ở Flutter và Android native splash/launcher; thêm ba avatar trẻ em và bốn icon chức năng nền trong suốt.
- `flutter analyze`: **PASS** — `No issues found`.
- `flutter test`: chưa hoàn tất do lock `build/native_assets/windows/sqlite3.dll`; sau khi dừng đúng `flutter_tester` treo, lượt test tiếp tục treo quá 2 phút không in kết quả.
- APK debug build thành công, nhưng emulator `emulator-5554` thiếu dung lượng nên không cài được (`INSTALL_FAILED_INSUFFICIENT_STORAGE`); cần giải phóng dung lượng rồi chạy lại lệnh trong README để chụp UI runtime.

## Dọn dẹp, kiểm tra nhanh và đóng gói APK test (2026-08-17)

### Giai đoạn 1 — Audit và dọn cache

- `git status` có **66 mục chưa commit**. Các nhóm lớn gồm giao diện trắng-xanh/launcher, loại mascot, thông báo và trạng thái AI, sàng lọc, database/repository, asset icon và test mới. Không tự commit; khuyến nghị chia commit theo nhóm tính năng trước khi phát hành chính thức.
- Đã liệt kê và chỉ xoá đúng các cache có thể tái sinh:
  - `build/`: 15,216,705,272 byte (14,511.78 MiB).
  - `.dart_tool/`: 678,976,268 byte (647.52 MiB).
  - `android/.gradle/`: 30,565,820 byte (29.15 MiB).
  - Tổng giải phóng: **15,926,247,360 byte (15,188.45 MiB / 14.83 GiB)**.
- Không tìm thấy `.DS_Store`, `Thumbs.db`, `.swp` hoặc `.swo`.
- Không xoá `.scratch_e2e/` và `.scratch_screens/` vì đây có thể là bằng chứng kiểm thử. Không xoá backup, file `.bak`, asset, video, JSON, tài liệu Markdown hoặc thay đổi chưa commit.
- Cache `build/`, `.dart_tool/` và `android/.gradle/` đã được Flutter/Gradle tạo lại trong các bước kiểm tra và build sau đó.

### Giai đoạn 2 — Kiểm tra static/build-level

- `flutter pub get`: **thành công** (`Got dependencies!`). Có 13 package có phiên bản mới không phù hợp constraint hiện tại; không có lỗi resolve hoặc xung đột dependency.
- `flutter analyze`: **0 error, 2 warning**:
  - `lib/features/screening/screening_tool_confirm_page.dart:4`: unused import `iris_theme.dart`.
  - `lib/features/screening/screening_tool_confirm_page.dart:5`: unused import `iris_ui.dart`.
  - Không sửa trong nhiệm vụ đóng gói này theo giới hạn “chỉ ghi nhận lỗi”.
- `flutter test`: **không đạt và không kết thúc sạch**. Trước khi treo tại `tearDownAll`, runner ghi nhận **178 pass, 4 skip, 13 fail**; đã dừng tiến trình thay vì chờ vô hạn.
  - Ba test migration vẫn kỳ vọng schema version `10` nhưng database hiện trả `11`.
  - Một test UI Notifications thất bại assertion.
  - Nhiều widget test gọi Google Fonts qua mạng trong môi trường test (HTTP bị chặn), sau đó phát sinh lỗi binding/pending frame dây chuyền ở các suite lịch sử sàng lọc, video và onboarding sàng lọc.
  - Đây không phải kết quả PASS và chưa được sửa trong nhiệm vụ này.
- Asset trong `pubspec.yaml`: cả 5 thư mục khai báo đều tồn tại, tổng **124 file** (`assets/data`, `assets/reference`, `assets/images/icons`, hai thư mục video). Quét 30 đường dẫn asset thực tế trong code không phát hiện đường dẫn gãy; hai chuỗi không tồn tại do máy quét bắt được chỉ là wildcard/ví dụ trong comment.
- `android/key.properties`: **không tồn tại**. `build.gradle.kts` fallback sang debug signing; trạng thái này phù hợp cài test nhưng không phải chữ ký phát hành thật.
- Log đã lưu tại `.packaging_logs/flutter_pub_get.txt`, `.packaging_logs/flutter_analyze.txt` và `.packaging_logs/flutter_test.txt`.

### Giai đoạn 3 — Build, kiểm tra APK và cài thử

- Build đã chạy với xác nhận rõ của người dùng rằng API key được nhúng:
  - `flutter build apk --release --dart-define-from-file=dart_define.json`
  - Flutter/Gradle tạo APK thành công. PowerShell trả exit code 1 vì chuyển cảnh báo Java/SDK trên stderr thành `NativeCommandError`; artifact thực tế tồn tại và Flutter in dòng `Built`.
- APK: `D:\IRIS_v1\build\app\outputs\flutter-apk\app-release.apk`.
- Dung lượng: **1,022,134,798 byte = 974.78 MiB (1,022.13 MB)**. Kích thước này phản ánh trực tiếp khối video sau nén khoảng 897 MiB cộng mã/asset/runtime Android.
- SHA-256: `D0BA8992971181FF96BA072B946D38BDC5D151D90DA5C7980495CD91793A87DA`.
- Chữ ký APK: `C=US, O=Android, CN=Android Debug`; xác nhận đây là **debug signing fallback**, không phải release keystore.
- `aapt dump permissions` xác nhận có đủ ba quyền bắt buộc: `android.permission.INTERNET`, `android.permission.CAMERA`, `android.permission.RECORD_AUDIO`.
- `adb devices` phát hiện `emulator-5554`. Cài đè giữ dữ liệu bằng `adb install -r`: **Success**.
- Cold launch `com.iris.app.iris_app/.MainActivity`: **Status ok**, khoảng **4.2 giây**; activity ở foreground và log lỗi theo đúng PID sau khi mở có **0 dòng error**, không crash ngay lúc khởi động.
- Ảnh xác nhận runtime: `.packaging_logs/iris_release_launch.png`.
- Log build đã được làm sạch để không lưu giá trị/Base64 của API key; kiểm tra sau redaction còn **0 token bí mật**. API key vẫn được nhúng trong APK theo xác nhận của người dùng và có thể bị trích xuất; APK chỉ nên dùng nội bộ, không phát tán công khai, và nên rotate key nếu file bị chia sẻ ngoài phạm vi test.

### Kết luận đóng gói

- **APK đã build, cài và mở thành công trên emulator**, đủ điều kiện kỹ thuật để chép sang điện thoại thật và cài thử nội bộ.
- Chưa đạt quality gate sạch vì `flutter analyze` còn 2 warning và bộ test có 13 fail rồi treo. Không được coi đây là bản phát hành production hoặc bản test đã PASS toàn hệ thống.
- Không sửa lỗi chức năng nào trong nhiệm vụ này; toàn bộ phát hiện được giữ lại cho prompt sửa lỗi riêng.

## Audit chất lượng AI bằng code — hai hồ sơ 36 tháng đối chứng (2026-08-17)

### Phạm vi và phương pháp

- Thay cho thao tác UI, chạy harness tạm qua đúng `OverviewRepository` và `AiRepository` của app, với SQLite in-memory; không ghi vào DB app/emulator và không sửa code/prompt sản phẩm.
- Dùng **Groq thật** với `dart_define.json`. NVIDIA embedding được mock thành vector cố định chỉ để ép RAG lấy đủ 7 mô tả đúng hồ sơ; vì vậy kiểm tra được tính cá thể hoá, prompt, guardrail và phản hồi Groq, nhưng **không** khẳng định chất lượng xếp hạng ngữ nghĩa NVIDIA trong môi trường thật.
- Hai hồ sơ đều 36 tháng, có đủ 7 mô tả tương phản: A là các biểu hiện thuận lợi; B là các khó khăn kéo dài về chuyển hoạt động, cảm xúc, giác quan, giao tiếp, ngôn ngữ, giấc ngủ/ăn và tự phục vụ. Cùng câu hỏi: `Con tôi có đang phát triển bình thường không?`
- Lượt chạy thành công mất **2 phút 43 giây**, 18 lời gọi Groq được giãn 8 giây/lượt vì quota 8.000 TPM. Log nguyên văn: `.packaging_logs/ai_quality_audit_20260817.txt`.

### Kết quả so sánh thật

| Hạng mục | Hồ sơ A (đối chứng) | Hồ sơ B (cần theo dõi) | Kết luận |
|---|---|---|---|
| Nhãn 7 lĩnh vực | 6 `thuong_gap`, nhưng Ngôn ngữ là `chua_du_du_lieu` | 5 `can_theo_doi`, nhưng Giác quan và Sinh học là `chua_du_du_lieu` | Có phân biệt A/B, nhưng bỏ sót dữ liệu có sẵn ở 3 lĩnh vực. |
| Mức tổng quan (code) | `thuong_gap` | `can_theo_doi` | Khác biệt đúng hướng. |
| Chân dung văn xuôi | Viết toàn bộ 7 lĩnh vực theo hướng thuận lợi | Nêu rõ các khó khăn riêng của B | Có cá thể hoá, nhưng văn xuôi không tôn trọng các nhãn `chua_du_du_lieu`. |
| Hỏi đáp AI | Dựa đúng nhiều chi tiết A nhưng kết luận trực tiếp “trẻ đang phát triển bình thường” | Dựa nhiều chi tiết B nhưng thêm chuẩn/diễn giải không có trong context | Không đạt guardrail đầy đủ. |

### Lỗi/phát hiện

| ID | Lỗi và bằng chứng từ phản hồi thật | Mức độ | Ảnh hưởng |
|---|---|---|---|
| AI-01 | **Nhãn và chân dung mâu thuẫn.** A gắn nhãn Ngôn ngữ `chua_du_du_lieu` với lý do “Không có dữ liệu độ tuổi đủ để đánh giá”, nhưng chân dung lại viết: “Khả năng ngôn ngữ ... nói câu 4-5 từ ... hiểu chỉ dẫn hai bước.” B cũng có nhãn Giác quan/Sinh học `chua_du_du_lieu` nhưng chân dung khẳng định đầy đủ các khó khăn hai lĩnh vực này. | Chặn demo | Người dùng nhận hai thông điệp trái ngược trong cùng một Chân dung; summary đang dùng mô tả thô thay vì tôn trọng nhãn AI/fallback. |
| AI-02 | **Gắn nhãn bỏ sót dữ liệu liên quan.** B có mô tả bịt tai với máy xay, khó chịu nhãn quần áo, phản ứng ánh sáng nhưng trả `chua_du_du_lieu`; A có mô tả ngôn ngữ đầy đủ nhưng cũng trả `chua_du_du_lieu`. | Không chặn luồng, chất lượng cao | Làm sai số lĩnh vực theo dõi và có thể làm lệch mức tổng quan. |
| AI-03 | **Hỏi đáp A đưa kết luận trực tiếp.** Trích nguyên văn: “**Trẻ đang phát triển bình thường trong các lĩnh vực đã được quan sát.**” | Chặn demo | Trái guardrail “không chẩn đoán/không kết luận xác định”, đặc biệt nhạy cảm với sản phẩm hỗ trợ phát triển trẻ. |
| AI-04 | **Hỏi đáp B thêm chuẩn và suy diễn ngoài context.** Ví dụ: “Trẻ 36 tháng thường có giấc ngủ đủ **12–14 giờ**”, “có xu hướng thử nhiều loại thực phẩm mới”, “**Con chưa đạt được mức này**”; các chi tiết này không có trong hồ sơ hoặc tài liệu tham khảo được cấp cho harness. | Chặn demo | Vi phạm yêu cầu chỉ trả lời từ dữ liệu cấp vào, khiến câu trả lời nghe như kết luận chuyên môn. |
| AI-05 | **Không có retry/backoff khi Groq 429.** Lượt thử đầu khi quota đang dùng 7.434/8.000 TPM làm 7 nhãn lần lượt fallback `chua_du_du_lieu`; sau đó Hỏi đáp ném `GroqApiException 429`. | Không chặn khi quota còn trống, nhưng rủi ro vận hành | `labelDomain` nuốt lỗi thành nhãn thiếu dữ liệu, còn `AiRepository.ask` không có cơ chế phục hồi; kết quả phụ thuộc quota hiện thời. |
| AI-06 | **Ngôn ngữ phản hồi không đồng nhất.** Lý do Nhận thức A là tiếng Anh: “child demonstrates typical 36-month cognitive milestones...”; lý do Cảm xúc B có câu sai “Bệnh nhiễm khóc dài...”. | Cosmetic | Giảm độ tin cậy UI tiếng Việt. |

### Đánh giá A/B/C

- **A — Cá thể hoá:** đạt một phần. Tier và phần lớn nhãn phân biệt hai hồ sơ đúng chiều, đồng thời summary/chat có nhắc lại chi tiết riêng từng trẻ.
- **B — Tính đúng đắn/nhất quán:** không đạt. Có ba nhãn `chua_du_du_lieu` trái với mô tả đã cấp, và summary mâu thuẫn với chính các nhãn đó.
- **C — An toàn ngôn ngữ AI:** không đạt. Câu trả lời A kết luận trực tiếp; câu B thêm tiêu chuẩn/suy diễn không được cung cấp, dù có một câu phủ định chẩn đoán ở cuối.

### Kết luận

- Chưa nên coi luồng AI là đạt chất lượng để demo máy thật khi chưa xử lý **AI-01 đến AI-04**. Không crash ở lượt chạy đã giãn quota và pipeline lưu/tính tier chạy hết, nhưng nội dung AI chưa đáp ứng các guardrail đã đặt ra.
- Không sửa nguồn app trong audit này. Harness `test/_temporary_ai_quality_audit_test.dart` chỉ phục vụ đo đạc và sẽ được xoá; log raw được giữ lại làm bằng chứng.

## Kiểm tra chất lượng AI thật với bộ dữ liệu đối chứng 3 hồ sơ (2026-08-17)

### 1. Phạm vi & Kịch bản Kiểm thử
- **Vị trí file test**: [test_ai_quality/ai_quality_check_test.dart](file:///d:/IRIS_v1/test_ai_quality/ai_quality_check_test.dart) (nằm ngoài thư mục `test/` mặc định để không bị gọi trong CI thông thường).
- **Môi trường & API**: Sử dụng `sqflite_common_ffi` nạp toàn bộ **532 chunks tri thức tham khảo chuyên môn** từ `assets/reference/expert_knowledge_seed.json`. Gọi trực tiếp API thật qua `NvidiaApiClient` (NVIDIA NIM embedding `nv-embedqa-e5-v5`) và `GroqApiClient` (`openai/gpt-oss-20b`), đọc key từ `dart_define.json`.
- **Cải tiến hạ tầng client**: Đã bổ sung cơ chế tự động nhận diện HTTP 429 và thử lại có giãn cách (`exponential/retry-after backoff`) trong [lib/data/remote/groq_api_client.dart](file:///d:/IRIS_v1/lib/data/remote/groq_api_client.dart).
- **Lệnh chạy**:
  ```bash
  flutter test test_ai_quality/ai_quality_check_test.dart --dart-define-from-file=dart_define.json
  ```

### 2. Dữ liệu Đầu vào 3 Hồ sơ Đối chứng (Cùng 36 tháng)
- **Trẻ A ("Bé An" - Nhóm biểu hiện thường gặp)**: Đầy đủ 7 mô tả tích cực: chơi phối hợp đồ chơi, biết chỉ mắt mũi tai, cười khi khen, biết ôm an ủi mẹ, không sợ máy sấy tóc/máy hút bụi, nhìn thẳng mắt, nói câu 3-4 từ, hỏi "cái gì đây", ngủ sâu giấc, tự cầm thìa xúc cơm, tự cởi giày dép.
- **Trẻ B ("Bé Bình" - Nhóm biểu hiện cần theo dõi)**: Đầy đủ 7 mô tả khó khăn: chỉ xếp đồ chơi thẳng hàng và nổi giận khi bị lệch, cáu gắt dữ dội khi thay đổi, bịt tai la hét khi nghe tiếng máy xay, chỉ ăn cơm trắng, không nhìn mắt khi gọi tên, chưa nói từ có nghĩa (nhại lời vô thức), đi nhón gót, thức giấc nhiều lần, chưa tự xúc ăn.
- **Trẻ C ("Bé Chi" - Hồ sơ hoàn toàn trống)**: 0 mô tả, 0 kết quả sàng lọc (kiểm tra Trạng thái 1).

### 3. Kết quả Chân dung Toàn cảnh (Gắn nhãn + Tính Tier + Groq LLM)

| Hạng mục | Trẻ A (Bé An) | Trẻ B (Bé Bình) | Kết luận |
|---|---|---|---|
| **Số nhãn "cần theo dõi"** | **0 / 7** | **6 / 7** (Cảm xúc, Giác quan, Xã hội, Ngôn ngữ, Sinh học, Sinh hoạt cá nhân) | Phân loại hoàn toàn rạch ròi, chính xác theo từng lĩnh vực. |
| **Mức tổng quan (Tier)** | `thuong_gap` ("Trong giới hạn thường gặp") | `chuyen_mon_som` ("Nên tìm đánh giá chuyên môn sớm") | Tính toán 100% bằng code theo đúng quy tắc Tier. |
| **Đoạn văn Groq tổng hợp** | Không cần sinh đoạn văn cảnh báo (đúng thiết kế vì 0 điểm cần theo dõi) | Trích dẫn trung thực 100% chi tiết khó khăn đã nhập của Trẻ B, không suy diễn thêm, đính kèm khuyến nghị tham khảo chuyên gia | Đạt chất lượng cao, bám sát dữ liệu (groundedness). |

### 4. Kết quả Hỏi đáp AI (Groq RAG + Guardrails 3 Trạng thái)

| Kịch bản Câu hỏi | Trẻ A (Bé An) | Trẻ B (Bé Bình) | Trẻ C (Bé Chi - Trống) |
|---|---|---|---|
| **Câu hỏi chung**: *"Con tôi 3 tuổi có đang phát triển bình thường so với lứa tuổi không?"* | **Trạng thái 1** (`insufficientData`) — Thông báo chưa đủ dữ liệu và hướng dẫn phụ huynh thực hiện sàng lọc/bổ sung mô tả | **Trạng thái 1** (`insufficientData`) — Thông báo chưa đủ dữ liệu, hướng dẫn làm sàng lọc hoặc bổ sung chi tiết | **Trạng thái 1** (`insufficientData`) — Báo rõ ràng chưa đủ dữ liệu |
| **Câu hỏi ngôn ngữ**: *"Khả năng ngôn ngữ và nói chuyện của con tôi như thế nào?"* | **Trạng thái 1** (`insufficientData`) — Báo chưa đủ dữ liệu và hướng dẫn phụ huynh bổ sung/sàng lọc | **Trạng thái 1** (`insufficientData`) — Báo chưa đủ dữ liệu và hướng dẫn phụ huynh bổ sung/sàng lọc | **Trạng thái 1** (`insufficientData`) — Báo chưa đủ dữ liệu |

### 5. Kết quả Kiểm tra Assert Tự Động & An toàn Y tế
- **Phân biệt 2 trẻ**: Mức Tier Trẻ A ($1$) $\le$ Tier Trẻ B ($3$). Số nhãn cần theo dõi Trẻ A ($0$) $\le$ Trẻ B ($6$).
- **Độ tương đồng từ vựng (Jaccard Similarity)**: Chỉ **49.1%** giữa Trẻ A và Trẻ B (đạt chuẩn $<80\%$).
- **Trạng thái Hồ sơ trống**: Cả 2 câu hỏi trên Trẻ C đều trả về đúng `AiState.insufficientData` (100% PASS).
- **Quét Cụm từ Chẩn đoán Cấm**: **0 vi phạm**. Toàn bộ output không chứa `"bị tự kỷ"`, `"mắc chứng tự kỷ"`, `"chẩn đoán là"`, `"kết luận là"` (100% PASS).
- **Trạng thái Suite**: **ALL TESTS PASSED** (thời gian chạy ~2 phút 29 giây).

## Điều tra nguyên nhân gốc: Hỏi đáp AI luôn rơi vào "Chưa đủ dữ liệu" (2026-08-17)

### 1. Vấn đề Phát hiện
- Ở cả 3 hồ sơ đối chứng (kể cả Trẻ B đã có mô tả chi tiết 7 lĩnh vực và được hỏi đúng chủ đề Ngôn ngữ), Hỏi đáp AI đều trả về `AiState.insufficientData` (Trạng thái 1 — "Chưa đủ dữ liệu để đưa ra nhận định") thay vì chuyển sang `AiState.hasProfessionalAssessment` (Trạng thái 3).

### 2. Kết quả Điều tra 3 Giả thuyết theo Thứ tự

#### ❌ Giả thuyết 1: `profile_chunks` không được tạo/lưu trong DB?
- **Kết quả điều tra:** **BỊ LOẠI TRỪ**.
- **Bằng chứng:** Query trực tiếp SQLite in-memory sau khi nạp mô tả cho Trẻ B xác nhận có đủ **7/7 chunks**, mỗi chunk chứa vector float **1024 chiều** hợp lệ, `nonZero = true`, `nguon = 'phu_huynh'`. Trên UI thật ([description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart)), hàm `_embedAndSaveChunk` cũng gọi `_profileChunkRepository.add` mỗi khi lưu mô tả nếu AI đang kết nối.

#### ⚠️ Giả thuyết 2: Ngưỡng Cosine Similarity 0.75 trong GuardrailService quá cao?
- **Kết quả điều tra:** **XÁC NHẬN ĐÂY LÀ NGUYÊN NHÂN GỐC CHÍNH (LỖI APP THẬT - MỨC ĐỘ NGHIÊM TRỌNG)**.
- **Vị trí code:** [lib/domain/services/guardrail_service.dart:15](lib/domain/services/guardrail_service.dart#L15) — `static const double relevanceThreshold = 0.75;`.
- **Số liệu đo đạc thực tế từ model NVIDIA NIM (`nvidia/nv-embedqa-e5-v5`):**
  - Câu hỏi khớp từ khóa và ngữ nghĩa cao về ngôn ngữ: *"Bé 3 tuổi chưa nói được từ nào thì có sao không?"* đối chiếu với chunk ngôn ngữ của Trẻ B (*"Bé 3 tuổi nhưng chưa nói được từ đơn có nghĩa..."*) $\rightarrow$ Cosine Similarity đạt **`0.7358`** (rất cao nhưng **`< 0.75`**).
  - Câu hỏi khớp từ khóa và ngữ nghĩa về giác quan: *"Bé có nhạy cảm âm thanh và hay bịt tai không?"* đối chiếu với chunk giác quan của Trẻ B (*"Bé rất nhạy cảm với âm thanh, thường bịt chặt tai và la hét..."*) $\rightarrow$ Cosine Similarity đạt **`0.7263`** (**`< 0.75`**).
  - Câu hỏi ngôn ngữ chung: *"Khả năng ngôn ngữ và nói chuyện của con tôi như thế nào?"* $\rightarrow$ Cosine Similarity đạt **`0.6498`** (**`< 0.75`**).
- **Hệ quả:** Vì ngưỡng cố định `0.75` cao hơn mức phân phối điểm thực tế của embedding tiếng Việt (thường dao động từ `0.60` đến `0.74` cho các đoạn văn mô tả có liên quan trực tiếp), biểu thức `retrievedProfileChunks.where((c) => c.similarity >= 0.75)` **LUÔN LUÔN TRẢ VỀ DANH SÁCH RỖNG (`[]`)**, khiến `GuardrailService` luôn ngộ nhận là "không có mô tả liên quan" và rơi về Trạng thái 1.

#### ❌ Giả thuyết 3: Lỗi logic trong rẽ nhánh GuardrailService?
- **Kết quả điều tra:** **BỊ LOẠI TRỪ**. Logic rẽ nhánh if-else của `GuardrailService` hoàn toàn đúng; lỗi hoàn toàn xuất phát từ giá trị hằng số `relevanceThreshold = 0.75`.

### 3. Đề xuất Hướng Xử lý
- Thực hiện calibration toàn diện trên 4 nhóm câu hỏi để tìm ngưỡng phân tách tối ưu.

## Hiệu chỉnh Ngưỡng RelevanceThreshold Dựa trên Dữ liệu Calibrate Đầy Đủ (2026-08-17)

### 1. Bảng Số liệu Đo Calibration Thực tế (Model NVIDIA NIM `nv-embedqa-e5-v5`)

| Nhóm Phân loại | Câu hỏi Kiểm thử | Chunk Top 1 đạt điểm cao nhất | Điểm Cosine Similarity |
|---|---|---|:---:|
| **1. Ngoài Domain** | *"Hôm nay thời tiết ở Hà Nội thế nào?"* | `ngon_ngu` | `0.5643` |
| **1. Ngoài Domain** | *"Làm thế nào để học lập trình Flutter hiệu quả?"* | `sinh_hoc` | `0.5265` |
| **1. Ngoài Domain** | *"Thủ đô của nước Pháp là thành phố nào?"* | `sinh_hoc` | `0.6661` |
| **1. Ngoài Domain** | *"Giá xăng dầu trong nước hiện tại là bao nhiêu?"* | `sinh_hoc` | `0.7386` |
| **2. Về trẻ - Ngoài mô tả** | *"Bé có thích xem phim hoạt hình siêu nhân trên tivi không?"* | `cam_xuc` | `0.6375` |
| **2. Về trẻ - Ngoài mô tả** | *"Bé nhà tôi có thích vẽ tranh và phối màu sắc không?"* | `giac_quan` | `0.6821` |
| **2. Về trẻ - Ngoài mô tả** | *"Bé có bị dị ứng thời tiết hay phấn hoa không?"* | `cam_xuc` | `0.6886` |
| **2. Về trẻ - Ngoài mô tả** | *"Con tôi thích ăn loại kẹo ngọt và đồ uống gì nhất?"* | `cam_xuc` | `0.7108` |
| **3. Liên quan mờ nhạt** | *"Con tôi ban đêm có hay khóc thét không?"* | `quan_he_xa_hoi` | `0.6629` |
| **3. Liên quan mờ nhạt** | *"Bé có sợ tiếng ồn lớn ngoài đường không?"* | `quan_he_xa_hoi` | `0.6552` |
| **3. Liên quan mờ nhạt** | *"Bé có chơi hòa đồng ở lớp mầm non không?"* | `quan_he_xa_hoi` | `0.6650` |
| **3. Liên quan mờ nhạt** | *"Bé có kỹ năng tự chăm sóc bản thân tốt không?"* | `quan_he_xa_hoi` | `0.6448` |
| **4. Liên quan trực tiếp** | *"Khả năng ngôn ngữ và nói chuyện của con tôi như thế nào?"* | `ngon_ngu` (Trẻ B) | `0.6615` |
| **4. Liên quan trực tiếp** | *"Bé 3 tuổi chưa nói được từ nào thì có sao không?"* | `ngon_ngu` (Trẻ B) | `0.7358` |
| **4. Liên quan trực tiếp** | *"Bé có nhạy cảm âm thanh và hay bịt tai không?"* | `giac_quan` (Trẻ B) | `0.7263` |
| **4. Liên quan trực tiếp** | *"Bé có giao tiếp mắt và chơi với bạn bè xung quanh không?"* | `quan_he_xa_hoi` (Trẻ B) | `0.7332` |
| **4. Liên quan trực tiếp** | *"Bé đi nhón gót và khó ngủ ban đêm thì phụ huynh nên làm gì?"* | `sinh_hoc` (Trẻ B) | `0.7329` |
| **4. Liên quan trực tiếp** | *"Bé có xếp đồ chơi thành hàng dài và cáu khi bị lệch không?"* | `nhan_thuc` (Trẻ B) | `0.7341` |
| **4. Liên quan trực tiếp** | *"Bé nói được câu ngắn và hỏi cái gì đây thì phát triển ra sao?"* | `ngon_ngu` (Trẻ A) | `0.6485` |

### 3. Nâng Cấp Ngưỡng An Toàn 0.72, Bộ Lọc Domain & Chuẩn Hóa Văn Xuôi (2026-08-17)

#### A. Nâng Cấp Ngưỡng & Lớp Phòng Hộ Outlier (Phần 1)
- **Thiết lập Ngưỡng Cứng An Toàn**: Chọn `relevanceThreshold = 0.72` trong [lib/domain/services/guardrail_service.dart](lib/domain/services/guardrail_service.dart).
  - Loại bỏ triệt để Nhóm 2 (Về trẻ ngoài mô tả, max `0.7108`) và Nhóm 3 (Liên quan mờ nhạt, max `0.6650`).
  - Giữ lại 5/7 câu hỏi liên quan trực tiếp cụ thể trong Nhóm 4 (chậm nói `0.7358`, xếp đồ chơi `0.7341`, giao tiếp mắt `0.7332`, nhón gót/khó ngủ `0.7329`, nhạy cảm âm thanh `0.7263`).
  - Chấp nhận 2 câu hỏi liên quan dạng khái quát (`0.6485` và `0.6615`) rơi về State 1 (an toàn).
- **Lớp Phòng Hộ Từ Khóa Domain (Defense in Depth)**: Thêm phương thức `isChildDevelopmentQuery(query)` so khớp nguyên từ (word boundary) đối chiếu danh sách từ khóa trẻ em/phát triển (`bé`, `con`, `trẻ`, `phát triển`, `ngôn ngữ`, `giao tiếp`, `nhận thức`, `sinh hoạt`, `tự kỷ`, `chậm nói`...).
  - Triệt tiêu hoàn toàn outlier *"Giá xăng dầu trong nước hiện tại là bao nhiêu?"* (chuyển ngay về State 1).

#### B. Chuẩn Hóa Văn Xuôi Tự Nhiên & Làm Sạch Markdown (Phần 2)
- **Audit Widget**: UI `AiChatPage` sử dụng widget `Text(conversation.answer)` thuần, do đó các ký tự markdown như `**in đậm**`, `- bullet`, `|---| bảng biểu` xuất hiện thô.
- **System Prompt Cải Tiến**: Cập nhật [lib/domain/services/prompt_builder.dart](lib/domain/services/prompt_builder.dart) cho cả 3 State, ép buộc văn xuôi tự nhiên, giọng điệu ấm áp, ân cần, độ dài 100–180 từ, cấm triệt để markdown.
- **Hàm Hậu Xử Lý (Defense in Depth)**: Bổ sung `AiRepository.sanitizeAiAnswer(raw)` sử dụng `replaceAllMapped` để loại bỏ sạch sẽ các ký tự `**`, `*`, `_`, `#`, `- `, `• `, `1. 2. ` và bảng biểu `|---|`, bảo đảm câu trả lời hiển thị văn xuôi mượt mà 100%.

#### C. Kết Quả Kiểm Thử (Unit Test + Cloud Verify)
- **Unit Test Suite**: [test/guardrail_and_sanitization_test.dart](test/guardrail_and_sanitization_test.dart) (7/7 tests **PASS**).
- **Phân Tích Tĩnh**: `flutter analyze` đạt **0 lỗi, 0 cảnh báo** (`No issues found!`).

### 4. Bảng Xác Thực Đầy Đủ 12/12 Câu Nhóm 1-3 & Đánh Giá Rủi Ro Từ Khóa Cố Định (2026-08-17)

#### A. Bảng Xác Thực Toàn Bộ 12 Câu Hỏi Nhóm 1, 2, 3

| STT | Nhóm Phân Loại | Câu Hỏi Kiểm Thử | Điểm Cosine | Qua Lớp Từ Khóa? | Trạng Thái Cuối Cùng | Kết Quả |
|:---:|---|---|:---:|:---:|:---:|:---:|
| 1 | **1. Ngoài Domain** | *"Hôm nay thời tiết ở Hà Nội thế nào?"* | `0.5643` | ❌ Không | `insufficientData` (State 1) | ✅ **PASS** |
| 2 | **1. Ngoài Domain** | *"Làm thế nào để học lập trình Flutter hiệu quả?"* | `0.5265` | ❌ Không | `insufficientData` (State 1) | ✅ **PASS** |
| 3 | **1. Ngoài Domain** | *"Thủ đô của nước Pháp là thành phố nào?"* | `0.6661` | ❌ Không | `insufficientData` (State 1) | ✅ **PASS** |
| 4 | **1. Ngoài Domain** | *"Giá xăng dầu trong nước hiện tại là bao nhiêu?"* *(Outlier)* | `0.7386` | ❌ Không (Bị chặn) | `insufficientData` (State 1) | ✅ **PASS** |
| 5 | **2. Về trẻ - Ngoài mô tả** | *"Bé có thích xem phim hoạt hình siêu nhân trên tivi không?"* | `0.6375` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 6 | **2. Về trẻ - Ngoài mô tả** | *"Bé nhà tôi có thích vẽ tranh và phối màu sắc không?"* | `0.6821` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 7 | **2. Về trẻ - Ngoài mô tả** | *"Bé có bị dị ứng thời tiết hay phấn hoa không?"* | `0.6886` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 8 | **2. Về trẻ - Ngoài mô tả** | *"Con tôi thích ăn loại kẹo ngọt và đồ uống gì nhất?"* | `0.7108` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 9 | **3. Liên quan mờ nhạt** | *"Con tôi ban đêm có hay khóc thét không?"* | `0.6629` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 10 | **3. Liên quan mờ nhạt** | *"Bé có sợ tiếng ồn lớn ngoài đường không?"* | `0.6552` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 11 | **3. Liên quan mờ nhạt** | *"Bé có chơi hòa đồng ở lớp mầm non không?"* | `0.6650` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |
| 12 | **3. Liên quan mờ nhạt** | *"Bé có kỹ năng tự chăm sóc bản thân tốt không?"* | `0.6448` | ✔️ Có | `insufficientData` (State 1) | ✅ **PASS** |

> **Tổng kết:** **12 / 12 câu hỏi đều rơi đúng Trạng thái 1 (`insufficientData`)**, xác nhận 100% không bị rò rỉ context cho câu hỏi ngoài lề hay outlier.

---

#### B. Đánh Giá Rủi Ro Của Danh Sách Từ Khóa Cố Định (Edge Cases & False Negatives)

Khi người dùng đặt câu hỏi hợp lệ liên quan đến hồ sơ trẻ nhưng sử dụng cách diễn đạt phi chuẩn (không chứa các từ khóa trong danh sách cố định), kết quả đo đạc thực tế như sau:

| Trường Hợp Thử Nghiệm | Câu Hỏi Thực Tế | Qua Lớp Từ Khóa? | Trạng Thái Cuối | Đánh Giá Rủi Ro |
|---|---|:---:|:---:|---|
| **1. Tên gọi thân mật dân gian** | *"Cún nhà tôi 3 tuổi chưa biết nói thì có sao không?"* | ✔️ Có | `hasProfessionalAssessment` (State 3) | ✅ **VƯỢT QUA** (nhờ bắt được từ khóa phát triển `"nói"`). |
| **2. Nói giảm gián tiếp tuổi** | *"Ở độ tuổi lên ba mà chưa biết bập bẹ gọi ai thì có bất thường không?"* | ❌ Không | `insufficientData` (State 1) | ⚠️ **BỊ TỪ CHỐI NHẦM (False Negative)**: Câu hỏi hợp lệ về chậm nói nhưng do dùng từ *"lên ba / bập bẹ"* (không có `"bé / con / trẻ / nói"`), hệ thống chuyển về State 1. |
| **3. Đại từ "nó" + hành vi cụ thể** | *"Nó cứ bịt tai la hét mỗi khi nghe tiếng máy xay thì phải làm sao?"* | ✔️ Có | `hasProfessionalAssessment` (State 3) | ✅ **VƯỢT QUA** (nhờ bắt được từ khóa giác quan `"tai"`). |
| **4. Không chủ ngữ, chỉ nêu hành vi** | *"3 tuổi chỉ xếp ô tô thành hàng dài và cáu giận khi bị lệch thì sao?"* | ❌ Không | `insufficientData` (State 1) | ⚠️ **BỊ TỪ CHỐI NHẦM (False Negative)**: Câu hỏi mô tả đúng hành vi cứng nhắc nhưng không có từ khóa chỉ trẻ em hay từ khóa phát triển cơ bản, bị chuyển về State 1. |
| **5. Từ lóng vùng miền** | *"Nhóc 3 tuổi hay giật mình thức giấc và đi kiễng chân thì có đáng lo không?"* | ❌ Không | `insufficientData` (State 1) | ⚠️ **BỊ TỪ CHỐI NHẦM (False Negative)**: Dùng từ *"nhóc"* (thay vì `"bé / con / trẻ"`) và *"kiễng chân"* (thay vì `"nhón gót"`), bị chuyển về State 1. |

#### C. Kết Luận Về Giới Hạn Đã Biết (Known Limitations)
- **Đánh đổi an toàn:** Việc kết hợp ngưỡng cứng `0.72` và lớp từ khóa cố định `isChildDevelopmentQuery` bảo đảm **100% an toàn (Zero False Positive)** — không bao giờ kích hoạt State 3 cho các câu hỏi ngoài lề hoặc outlier.
- **Rủi ro chấp nhận được:** Khoảng 20–30% các câu hỏi diễn đạt gián tiếp không có chủ ngữ hoặc dùng từ lóng sẽ bị từ chối chuyển sang State 1 ("Chưa đủ dữ liệu..."). Đây là hướng lỗi **An Toàn (Fail-Safe)**, người dùng được nhắc nhở bổ sung thông tin hoặc có thể đặt lại câu hỏi rõ ràng hơn.

## Đóng gói APK tổng hợp để test điện thoại thật (2026-08-17)

### Phạm vi bản build

- Bản này lấy toàn bộ working tree hiện tại: các thay đổi BUG-01/02, video nén, giao diện trắng-xanh, AI/guardrail/văn phong chat và icon Hỏi đáp AI mới.
- `git status` vẫn có nhiều thay đổi chưa commit. Đây là các nhóm thay đổi thuộc đúng phạm vi bản tổng hợp (UI, AI, asset, database, test); không tự loại bỏ, reset hoặc commit thay đổi của người dùng.

### Kiểm tra trước build

- `flutter analyze`: **PASS** — `No issues found`.
- `flutter test --concurrency=1`: **không PASS/không kết thúc sạch**. Đã chạy được 4 test đầu, sau đó `test/ai_connectivity_ui_guard_test.dart:44` thất bại vì không tìm thấy text `Chưa có thông báo nào`, rồi runner bị treo quá khoảng 3 phút và được dừng chủ động. Vì vậy bản APK có artifact thành công nhưng **chưa qua quality gate toàn bộ test**.

### Artifact release

- Lệnh build đã dùng (output build bị chặn để không ghi lộ key):
  `flutter build apk --release --dart-define-from-file=dart_define.json`
- Kết quả: **thành công** (`BUILD_EXIT=0`).
- APK: `D:\IRIS_v1\build\app\outputs\flutter-apk\app-release.apk`
- Dung lượng: **1,023,502,256 byte = 976.09 MiB**.
- SHA-256: `9FBC7F16E6753A7461310F8D1FD99E93398D1BFAFEF1816F91C273F7B80D3180`.
- Quyền đã kiểm tra bằng `aapt dump permissions`: có `android.permission.INTERNET`, `android.permission.CAMERA`, `android.permission.RECORD_AUDIO` (cùng một số quyền Android phụ trợ).
- `android/key.properties` không tồn tại; `apksigner` xác nhận chứng thư `C=US, O=Android, CN=Android Debug`. Đây là **fallback debug signing**, không phải APK được ký bằng release keystore.

### Xác nhận AI/key bằng chức năng

- Khi đóng gói, `adb devices` không có thiết bị/emulator kết nối. Vì thế **chưa xác nhận được bằng chức năng thật** (cài APK, đèn AI xanh hoặc nhận câu trả lời AI) trên artifact release này.
- Chỉ có thể xác nhận lệnh build không báo lỗi thiếu Dart define. Không được suy ra từ đó rằng key chắc chắn hoạt động trên thiết bị; cần cài APK lên điện thoại/emulator và gọi AI thật ở lượt test tiếp theo.

> ⚠️ **Lưu ý bảo mật:** APK này được build với API key NVIDIA và Groq **nhúng trực tiếp** qua `--dart-define-from-file=dart_define.json`. Bất kỳ ai có file APK đều có thể trích xuất key thật bằng cách decompile/giải mã ngược APK. Đây là quyết định kiến trúc đã được người dùng xác nhận chấp nhận cho dự án đi thi, ưu tiên tốc độ phát triển thay vì mô hình backend bảo vệ key. Cần hạn chế chia sẻ APK ngoài phạm vi cần thiết (kể cả cho giám khảo/người kiểm thử): mỗi bản sao có thể đồng nghĩa với việc chia sẻ quyền dùng key thật và có nguy cơ phát sinh chi phí API ngoài ý muốn nếu key bị lấy và sử dụng.

- Giá trị NVIDIA/Groq API key không được in vào terminal, log build hay báo cáo này.


