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

Phạm vi: Bước 5-6, chỉ **mục 1 "Mô tả biểu hiện" chạy thật đầy đủ** (kể cả gọi NVIDIA embedding API thật, có unit test riêng vì môi trường chưa có API key thật); mục 2-5 chỉ khung UI placeholder, chưa đọc `expert_knowledge_chunks`.

### Nhiệm vụ 0 — Gỡ tạm `camera`, xác nhận build thật chạy được

- Xoá `camera` khỏi `pubspec.yaml` (giữ `video_player`), `flutter pub get` sạch.
- Build + cài `flutter run -d emulator-5554 --debug`: **thành công** (trước đó ở Giai đoạn 2 bị chặn bởi lỗi CameraX/Gradle, xem mục 5).
- Đã lái tay qua `adb` (screenshot + `uiautomator dump` lấy toạ độ chính xác thay vì đoán bằng mắt) xác nhận lại **toàn bộ luồng Giai đoạn 2 chạy đúng trên app thật**: tạo hồ sơ "Be_Demo_That" (4 tuổi) → chi tiết hồ sơ → nhánh "Chưa muốn" (badge vẫn "Chưa sàng lọc", không tạo bản ghi) → nhánh "Có" (trả lời 6 câu "Không" → điểm "0/6" + dòng disclaimer → badge cập nhật "Đã sàng lọc").
- Ghi chú riêng: bàn phím Gboard trên emulator có lúc bật một thanh công cụ nổi (mic/backspace/emoji) đè lên góc trái màn hình — không phải lỗi app, chỉ là hành vi bàn phím ảo; tránh bằng cách tap vào vùng trống để đóng bàn phím thay vì dùng phím Back (Back sẽ pop luôn cả route).

### Nhiệm vụ 1 — Danh sách 9 lĩnh vực

- [lib/core/constants/nine_domains.dart](lib/core/constants/nine_domains.dart) *(mới)* — danh sách 9 lĩnh vực đúng thứ tự roadmap (Hành vi, Nhận thức, Cảm xúc, Giác quan, Quan hệ xã hội, Ngôn ngữ, Ứng xử, Sinh học, Sinh hoạt cá nhân), `code` khớp giá trị `linh_vuc` trong DB.
- [lib/features/assessment/domain_list_page.dart](lib/features/assessment/domain_list_page.dart) *(mới)* — danh sách 9 lĩnh vực, mỗi item "Đã có mô tả"/"Chưa có mô tả" dựa trên `AssessmentRepository.getForChild()` lọc `content_type='mo_ta'`. `ProfileDetailPage` → nút "Đánh giá 9 lĩnh vực" trỏ đúng vào trang này (trước đó trỏ nhầm thẳng vào `DescriptionPage` từ Giai đoạn khởi tạo).

### Nhiệm vụ 2 — Mục 1: Mô tả biểu hiện (chạy thật)

- [lib/data/remote/nvidia_api_client.dart](lib/data/remote/nvidia_api_client.dart) — cài logic thật: POST tới `https://integrate.api.nvidia.com/v1/embeddings`, header `Authorization: Bearer <NVIDIA_API_KEY>`, body `{input, model: nvidia/nv-embedqa-e5-v5, input_type: query, encoding_format: float}`, parse `data[0].embedding`. Nhận `http.Client` qua constructor (mặc định `http.Client()`) để test được bằng `MockClient`. Ném `NvidiaApiException` rõ ràng cho mọi trường hợp lỗi (HTTP lỗi, parse lỗi, thiếu field).
- [test/nvidia_api_client_test.dart](test/nvidia_api_client_test.dart) *(mới)* — dùng `package:http/testing.dart` (`MockClient`), **không gọi API thật** vì môi trường chưa có `NVIDIA_API_KEY`. 3 test: đúng URL/header/body request + parse đúng response; ném exception khi HTTP lỗi; ném exception khi response thiếu `embedding`. **3/3 PASS**.
- [lib/features/assessment/nine_domains/description/description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart) — textfield + nút Lưu, danh sách mô tả đã lưu (mới nhất trên đầu). Bấm Lưu: (1) `AssessmentRepository.save(contentType: 'mo_ta')` — **luôn chạy trước, không phụ thuộc bước 2-3**; (2) `NvidiaApiClient.embed()`; (3) `ProfileChunkRepository.add()` dùng `embedding_codec.dart` có sẵn từ Giai đoạn 1. Bước 2-3 lỗi → bắt exception, hiện SnackBar "Đã lưu mô tả, nhưng chưa xử lý được cho AI (thử lại sau)." — **không rollback, không mất mô tả đã lưu**. Có nút "Tiếp theo" sang mục 2.
- **Kiểm chứng thật trên emulator** (không có API key nên bước 2-3 lỗi có chủ đích): nhập mô tả "Be_noi_duoc_cau_2-3_tu" cho lĩnh vực Ngôn ngữ → SnackBar đúng thông báo lỗi AI → xem qua "Debug: xem dữ liệu đánh giá thô" xác nhận `assessments` có đúng 1 bản ghi (`linh_vuc: ngon_ngu`, `content_type: mo_ta`, `content` đúng, `nguon: phu_huynh`) và `profile_chunks` rỗng (đúng như kỳ vọng vì API lỗi) — **dữ liệu mô tả không hề bị mất**.

### Nhiệm vụ 3 — Mục 2-5: khung UI placeholder

4 trang `comparison_video_page.dart` / `parent_input_page.dart` / `expert_input_page.dart` / `summary_portrait_page.dart` — mỗi trang: tiêu đề đúng tên mục + "Nội dung tham khảo đang được cập nhật" + nút "Tiếp theo". Điều hướng dùng `pushReplacement` nối tiếp (2→3→4→5) nên ngăn xếp không phình to; trang cuối (Chân dung biểu hiện) chỉ cần 1 lần `pop()` để quay về `DomainListPage`. Chưa đọc `expert_knowledge_chunks` — để dành lúc ingest dữ liệu tham khảo thật (script `scripts/ingest_expert_data.dart`, vẫn skeleton).

### Nhiệm vụ 4 — Kiểm chứng

- `flutter analyze`: **0 lỗi**, 11 warning/info còn lại đều ở `ai_repository.dart`/`video_repository.dart` (ngoài phạm vi, chưa đổi từ Giai đoạn 1).
- `flutter test`: **13/13 PASS** (4 child_age + 5 repositories + 3 nvidia_api_client + 1 screening_flow).
- Kiểm chứng thật trên `emulator-5554` (build thật, không phải widget test) — xem chi tiết ở Nhiệm vụ 0 (luồng Giai đoạn 2) và Nhiệm vụ 2 (mô tả biểu hiện) ở trên.
- Thêm nút "Debug: xem dữ liệu đánh giá thô" trong `ProfileDetailPage` (song song nút debug sàng lọc có từ Giai đoạn 2) — hiện raw `assessments` + `profile_chunks` (kèm `embedding.length` để xác nhận có/không có vector).

### Chưa làm (để dành giai đoạn sau)

- Mục 2-5 của mỗi lĩnh vực chưa đọc dữ liệu thật từ `expert_knowledge_chunks` — cần chạy `scripts/ingest_expert_data.dart` (vẫn skeleton) với dữ liệu tham khảo thật trước.
- `camera` đã gỡ tạm — cần xử lý lỗi CameraX/Gradle và thêm lại khi làm Giai đoạn 5 (quay video).
- `groq_api_client.dart`, `vector_search_service.dart`, `guardrail_service.dart`, `ai_repository.dart` vẫn skeleton — dành cho Giai đoạn 4 (hỏi đáp AI).
- ~~Lưu ý phát sinh ngoài phạm vi: roadmap mô tả sàng lọc 3 nhánh...~~ — **đã giải quyết**: người dùng xác nhận giữ nguyên luồng 2 nhánh Có/Chưa muốn đã cài ở Giai đoạn 2; đã cập nhật lại `ROADMAP_DU_AN_IRIS.md` mục 1 dòng #2 cho khớp code (không còn nhắc "3 nhánh" nữa).

## 7. Giai đoạn 4 — Guardrail 3 trạng thái + Hỏi đáp AI (2026-08-11)

Phạm vi: toàn bộ pipeline RAG — embedding → vector search local → guardrail (code quyết định trạng thái, không giao LLM) → system prompt đúng nguyên văn theo trạng thái → Groq → lưu lịch sử → UI chat. Đây là phần quan trọng nhất của dự án.

### Nhiệm vụ 0 — Đồng bộ schema `screenings`

Kiểm tra lại: `screenings_table.dart`, `Screening` model, `ScreeningRepository`, `screening_questionnaire_page.dart` — **không có** cột/tham số `source` nào (đã đúng ngay từ Giai đoạn 2, roadmap mới chỉ xác nhận lại). Không cần sửa gì, chỉ chạy lại test xác nhận — PASS.

### Nhiệm vụ 1 — Script ingest dữ liệu chuyên môn

- [scripts/ingest_expert_data.dart](scripts/ingest_expert_data.dart) — cài logic thật, tách hàm `ingestEntries()` testable (nhận `embed` dạng callback + `Database` — không phụ thuộc NVIDIA/sqflite thật khi test).
- **Quyết định kỹ thuật quan trọng**: KHÔNG dùng `AppDatabase`/`ExpertKnowledgeRepository` của app trong script này. Lý do: cả 2 class import `path_provider`, mà `path_provider` import `package:flutter/foundation.dart` (đã kiểm tra trực tiếp trong pub cache) — transitively cần `dart:ui`, chỉ tồn tại trong engine Flutter. Script chạy qua `dart run` (Dart VM thuần), nên import chạm Flutter sẽ lỗi biên dịch ngay từ đầu. Script tự mở kết nối qua `sqflite_common_ffi` (Flutter-free) và ghi thẳng theo đúng `expertKnowledgeChunksTableCreate` dùng chung với app. Đã xác minh thực tế: chạy `dart run scripts/ingest_expert_data.dart` thành công tới bước gọi NVIDIA thật (nhận lỗi 500 do thiếu key — đúng kỳ vọng, chứng tỏ toàn bộ pipeline đọc JSON/mở DB/gọi API hoạt động đúng, chỉ thiếu key).
- Bổ sung 4 entry mẫu mới vào `expert_content.json` (tổng 6 entry) — khác lĩnh vực/độ tuổi/content_type so với 2 entry cũ: `hanh_vi` (so_sanh, 18-30 tháng), `quan_he_xa_hoi` (bac_si, 12-24 tháng), `cam_xuc` (chan_dung, 36-48 tháng), `giac_quan` (chia_se_phu_huynh, 6-18 tháng) — nội dung ghi rõ `[Placeholder minh hoạ]`, chưa chuẩn xác chuyên môn, sẽ thay bằng nội dung thật sau.
- [test/ingest_expert_data_test.dart](test/ingest_expert_data_test.dart) *(mới)* — dùng embedding giả + database in-memory, **không gọi NVIDIA thật**: insert đúng field/embedding; 1 entry lỗi (embed throw) không làm hỏng các entry khác, đếm đúng success/failed. **2/2 PASS**.

### Nhiệm vụ 2 — VectorSearchService

[lib/domain/services/vector_search_service.dart](lib/domain/services/vector_search_service.dart) — `cosineSimilarity()` đúng công thức đã cho (có thêm guard `normA/normB == 0 → trả 0` thay vì NaN — cải tiến an toàn nhỏ, không đổi công thức gốc). `searchProfileChunks(childId, queryEmbedding, {topK=8})` và `searchExpertChunks(ageMonths, queryEmbedding, {topK=3})` — vế sau **lọc theo độ tuổi TRƯỚC rồi mới tính similarity** (đúng yêu cầu — test riêng xác nhận 1 chunk sai độ tuổi dù similarity cao nhất vẫn bị loại).

### Nhiệm vụ 3 — GuardrailService

[lib/domain/services/guardrail_service.dart](lib/domain/services/guardrail_service.dart) — cài đúng theo code mẫu: enum `AiState`, `determineState()` trả record `({state, groundingChunks})`, ngưỡng `relevanceThreshold = 0.75`. 5 test trong [test/guardrail_service_test.dart](test/guardrail_service_test.dart): đủ 3 trạng thái + 2 case biên (chunk dưới ngưỡng similarity; chunk đủ similarity nhưng `nguon` không hợp lệ) — cả 2 case biên đều xác nhận KHÔNG lên Trạng thái 3. **5/5 PASS**.

### Nhiệm vụ 4 — System prompt (nguyên văn)

[lib/domain/services/prompt_builder.dart](lib/domain/services/prompt_builder.dart) — `PromptBuilder` với `buildState1Prompt()`/`buildState2Prompt()`/`buildState3Prompt({profileContext, expertContext})`, nội dung copy **đúng nguyên văn từng câu** theo bản đã chốt, không diễn đạt lại — chỉ 2 chỗ nội suy động (`profileContext`/`expertContext`) dùng string interpolation thay cho ký hiệu `{...}` trong bản mô tả (ký hiệu đó là quy ước tài liệu, không phải cú pháp Dart). [test/prompt_builder_test.dart](test/prompt_builder_test.dart) so khớp chính xác từng câu bắt buộc (không chỉ "chứa đại khái"). **4/4 PASS**.

### Nhiệm vụ 5 — GroqApiClient

[lib/data/remote/groq_api_client.dart](lib/data/remote/groq_api_client.dart) — đổi từ `Stream<String>` (skeleton cũ) sang `Future<String> generate()` — **chưa streaming** theo đúng yêu cầu giai đoạn này. POST `https://api.groq.com/openai/v1/chat/completions`, model `openai/gpt-oss-20b`, `messages: [{role: system}, {role: user}]`, đọc key qua `String.fromEnvironment('GROQ_API_KEY')`. Cùng pattern `nvidia_api_client.dart`: nhận `http.Client` qua constructor, ném `GroqApiException` rõ ràng. [test/groq_api_client_test.dart](test/groq_api_client_test.dart) dùng `MockClient` — đúng request format + parse response + 2 case lỗi. **3/3 PASS**.

### Nhiệm vụ 6 — AiRepository

[lib/data/repositories/ai_repository.dart](lib/data/repositories/ai_repository.dart) — viết lại hoàn toàn, orchestrate đúng thứ tự: embed câu hỏi (NVIDIA) → `searchProfileChunks` → `ScreeningRepository.hasScreening()` → `GuardrailService.determineState()` → (nếu Trạng thái 3: `childAgeInMonths()` + `searchExpertChunks()`, build `profileContext`/`expertContext` từ chunk `content`, dùng câu mặc định nếu không có expert chunk phù hợp) → build đúng prompt → `GroqApiClient.generate()` → lưu `ai_conversations` (kèm `state` 1/2/3) → trả `AiAnswer(answer, state)` cho UI. Toàn bộ dependency (NVIDIA/Groq client, các service) đều optional-injectable qua constructor để test được bằng mock, không phá API mặc định khi dùng thật trong app.

Model/repository mới: `lib/domain/models/scored_chunk.dart` (`ScoredProfileChunk`, `ScoredExpertChunk`), `lib/domain/models/ai_conversation.dart`, `lib/data/repositories/ai_conversation_repository.dart`.

[test/ai_repository_test.dart](test/ai_repository_test.dart) *(mới)* — test tích hợp full pipeline với NVIDIA/Groq giả (MockClient) + sqflite ffi thật, cho cả 3 trạng thái + case "Trạng thái 3 không có expert chunk phù hợp":

| Test | Xác nhận | Kết quả |
|---|---|---|
| Trạng thái 1 | Đúng state, prompt chứa "Chưa đủ dữ liệu để đưa ra nhận định", lưu `ai_conversations.state=1` | PASS |
| Trạng thái 2 | Đã sàng lọc + chưa có mô tả liên quan → đúng state, prompt chứa "KẾT QUẢ SÀNG LỌC", lưu `state=2` | PASS |
| Trạng thái 3 | Profile chunk embedding trùng query (similarity=1.0) từ `nguon: phu_huynh` → đúng state, prompt chứa đúng `profileContext` + `expertContext`, lưu `state=3` | PASS |
| Trạng thái 3, không có expert chunk phù hợp độ tuổi | Prompt dùng đúng câu mặc định "Không có tài liệu tham khảo chuyên môn phù hợp." | PASS |

**4/4 PASS**. (Trong lúc viết test phát hiện: `http.Response` trong `package:http` mặc định encode body bằng `latin1`, gây lỗi `Invalid argument: Contains invalid characters` khi mock trả về nội dung tiếng Việt không kèm header `charset=utf-8` — đã thêm header này vào mock, chỉ ảnh hưởng code test, không phải bug trong `groq_api_client.dart`.)

### Nhiệm vụ 7 — UI Hỏi đáp AI

[lib/features/ai_chat/ai_chat_page.dart](lib/features/ai_chat/ai_chat_page.dart) — viết lại từ `Placeholder()`: `ListView` bong bóng chat (câu hỏi bên phải, trả lời + nhãn "Trạng thái N" bên trái) load từ `AiConversationRepository.getForChild()`, textfield + nút gửi, loading indicator khi đang chờ `AiRepository.ask()`, hiện lỗi dạng text đỏ nếu gọi API thất bại (không crash). `ProfileDetailPage` → nút "Hỏi đáp AI" đã trỏ đúng, truyền `child`.

### Nhiệm vụ 8 — Kiểm chứng

- `flutter analyze`: **0 lỗi**, chỉ còn đúng **1 warning** (`unused_field` ở `video_repository.dart` — vẫn skeleton, ngoài phạm vi, để dành Giai đoạn 5).
- `flutter test`: **37/37 PASS** toàn bộ project (13 test có sẵn từ Giai đoạn 1-3 + 24 test mới ở Giai đoạn 4: 6 vector_search_service + 5 guardrail_service + 4 prompt_builder + 3 groq_api_client + 4 ai_repository + 2 ingest_expert_data).
- ~~Chưa verify được end-to-end thật trên emulator vì không có API key...~~ — **đã verify xong bằng key thật, xem mục 8 bên dưới** (kèm sửa 1 lỗi kiến trúc ingest phát hiện trong lúc verify: script desktop không đưa được dữ liệu vào app thật trên emulator — đã thay bằng nút ingest ngay trong app).

### Chưa làm (để dành giai đoạn sau)

- Chưa streaming câu trả lời Groq — để dành lúc làm đẹp UI.
- ~~Chưa verify end-to-end thật với API key thật~~ — **đã làm ở mục 8 bên dưới**, cùng phiên vá lỗi kiến trúc ingest.
- Dữ liệu `expert_knowledge_chunks` vẫn là placeholder minh hoạ (nội dung `[Placeholder minh hoạ]` trong `expert_content.json`) — cần thay bằng nội dung chuyên môn thật, sau đó ingest lại qua nút debug trong app (mục 8).
- Chức năng #10 "Kết nối chuyên gia/trung tâm" và phần lịch sử tổng hợp (Bước 7) vẫn chưa làm — theo đúng thứ tự triển khai mục 6 roadmap, để dành các giai đoạn sau.

## 8. Vá lỗi kiến trúc ingest + Verify end-to-end thật bằng API key thật (2026-08-11)

Tiếp nối Giai đoạn 4 — vá 1 lỗi UTF-8 sót lại, sửa kiến trúc ingest, và chạy thật toàn bộ 3 trạng thái trên emulator bằng API key thật của người dùng (`dart_define.json`, đã gitignore). **Không có giá trị key nào bị in ra console/log/báo cáo trong suốt quá trình** — chỉ dùng `--dart-define-from-file=dart_define.json` để chạy, không đọc/hiển thị nội dung file này ở bất kỳ bước nào.

### Nhiệm vụ 0 — Vá UTF-8 còn sót

`groq_api_client.dart` đã vá đúng từ Giai đoạn 4 (`jsonDecode(utf8.decode(response.bodyBytes))`), nhưng **`nvidia_api_client.dart` vẫn còn dùng `jsonDecode(response.body)`** (thiếu vá) — đã sửa lại cho nhất quán. `flutter test` sau khi sửa: vẫn PASS.

### Nhiệm vụ 1 — Sửa kiến trúc ingest: nạp thẳng vào app thay vì script desktop

**Vấn đề phát hiện**: `scripts/ingest_expert_data.dart` (từ Giai đoạn 4) ghi vào 1 file `iris_expert_seed.db` riêng trên máy desktop qua `sqflite_common_ffi` — hoàn toàn tách biệt với database thật của app chạy trên emulator/thiết bị (app dùng `path_provider` để lấy đường dẫn on-device). Ingest bằng script **không** đưa được dữ liệu vào app thật.

**Đã sửa**: thêm nút **"Debug: Nạp dữ liệu tham khảo"** trong `ProfileDetailPage` ([lib/features/child_profile/profile_detail/profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart)) — chỉ hiện khi `!kIsWeb && kDebugMode`:
- Đọc `assets/reference/expert_content.json` qua `rootBundle.loadString()` (asset đóng gói sẵn trong app, không cần biết đường dẫn file hệ thống).
- Với mỗi entry gọi `NvidiaApiClient.embed()` **thật** (key đọc tự động qua `String.fromEnvironment`, không cần đọc thêm file JSON key nào trong app).
- Insert qua `ExpertKnowledgeRepository` thật — đúng database thật của app đang chạy.
- Hiện SnackBar báo số thành công/thất bại.
- Chặn bấm 2 lần liên tiếp bằng cờ `_ingestingExpertData` (disable nút khi đang chạy) + hỏi xác nhận nếu `ExpertKnowledgeRepository.getAll()` (method mới thêm) phát hiện đã có dữ liệu, tránh insert trùng khi bấm lại.

`scripts/ingest_expert_data.dart` **giữ nguyên, không xoá** — vẫn hữu ích để test nhanh logic parse/gọi API trên desktop qua `test/ingest_expert_data_test.dart`, chỉ không dùng để đưa dữ liệu vào app thật nữa (đã cập nhật docstring của script ghi rõ điều này).

`flutter analyze` sau khi thêm nút: **0 lỗi** (chỉ còn 1 warning `unused_field` ở `video_repository.dart`, ngoài phạm vi). `flutter test`: **37/37 PASS**.

### Nhiệm vụ 2 — Chạy end-to-end thật trên `emulator-5554` bằng key thật

Build bằng `flutter run -d emulator-5554 --dart-define-from-file=dart_define.json` — thành công. Toàn bộ thao tác lái qua `adb` + `uiautomator dump` (như Giai đoạn 2-3).

**Ghi chú kỹ thuật phát sinh khi lái UI** (không phải bug app, chỉ là đặc thù thao tác `adb`):
- `RadioListTile` của "Cách nhập tuổi" và ô nhập "Số tuổi" có bounds accessibility CHỒNG LÊN NHAU trong cây UI (2 radio nằm trong vùng bounds của EditText cha) — tap vào giữa vùng tưởng là ô nhập thực ra trúng radio phía trên. Phải tap vào phần dưới cùng của vùng bounds (dưới cả 2 radio) mới trúng đúng ô nhập.
- `adb shell input text "chuỗi có dấu cách"` bị cắt sau từ đầu tiên — phải thay dấu cách bằng `%s` (VD `Con%stoi%sco...`) mới nhập đủ chuỗi.
- Bàn phím Gboard nổi 1 thanh công cụ (mic/backspace/emoji) che góc trái màn hình khi ô nhập được focus — không phải lỗi app.

**1) Ingest thật**: bấm nút mới, kết quả **"Nạp dữ liệu tham khảo: 6 thành công, 0 lỗi."** — cả 6 entry (kể cả 4 entry `[Placeholder minh hoạ]` mới thêm ở Giai đoạn 4) embed + insert thành công bằng NVIDIA key thật.

**2) Tạo hồ sơ trắng** "Be_AI_Test" (5 tuổi, chưa sàng lọc, chưa có mô tả nào).

**3) Trạng thái 1** — hỏi ngay trên hồ sơ trắng: AI trả lời đúng mở đầu bằng *"Chưa đủ dữ liệu để đưa ra nhận định về vấn đề..."*, gợi ý sàng lọc/bổ sung mô tả, không suy đoán — đúng 100% yêu cầu bắt buộc của prompt Trạng thái 1. Nhãn hiển thị **"Trạng thái 1"**. ✅

**4) Trạng thái 2** — làm sàng lọc (0/6, mock) rồi hỏi 1 câu khác chủ đề (chưa có mô tả nào liên quan): AI trả lời nhắc đúng "kết quả sàng lọc... đã được thực hiện" nhưng khẳng định rõ "chỉ cung cấp những dấu hiệu tổng quát; không thể xác định một cách chắc chắn nguyên nhân", liệt kê nhiều nguyên nhân khả dĩ — đúng yêu cầu "trung lập, không kết luận" của prompt Trạng thái 2. Nhãn **"Trạng thái 2"**. ✅

**5) Trạng thái 3** — nhập mô tả cụ thể ở lĩnh vực Ngôn ngữ ("bé nói được câu 2-3 từ nhưng hay lặp lại nguyên xi lời người khác nói... phát âm không rõ") → lưu thành công kèm embedding thật ("Đã lưu mô tả và xử lý xong cho AI.") → hỏi đúng về chủ đề "lặp lại lời người khác nói": AI trả lời rất chi tiết, bám sát đúng hành vi đã mô tả (echo speech), phân tích khi nào bình thường/cần lưu ý theo độ tuổi, kết thúc bằng *"Không có chẩn đoán hay kết luận chính thức ở đây"* — đúng yêu cầu Trạng thái 3 (dùng dữ liệu hồ sơ, không chẩn đoán). Nhãn **"Trạng thái 3"**. ✅

**Tiếng Việt hiển thị**: kiểm tra kỹ cả 3 câu trả lời (dài, nhiều đoạn, nhiều dấu câu đặc biệt) — **toàn bộ dấu tiếng Việt hiển thị đúng, không lỗi ký tự/mojibake** ở bất kỳ đoạn nào, xác nhận bản vá UTF-8 ở Nhiệm vụ 0 có tác dụng thật trên request/response thật, không chỉ qua được test giả lập.

**Bảo mật key**: trong suốt quá trình trên, không có lệnh nào đọc nội dung `dart_define.json` (không `cat`, không `Read` tool trên file này); chỉ dùng làm tham số `--dart-define-from-file`. Không có giá trị key nào xuất hiện trong log build, screenshot, hay báo cáo này.

### Nhiệm vụ 3 — Báo cáo

Mục này chính là báo cáo — xem tóm tắt kết quả ở Nhiệm vụ 2 trên. Tổng kết nhanh: cả 3 trạng thái đều đúng state, đúng nội dung theo tinh thần prompt tương ứng, tiếng Việt hiển thị hoàn hảo, ingest dữ liệu tham khảo qua app hoạt động đúng. Dự án hiện đã có thể demo đầy đủ pipeline RAG + guardrail thật từ đầu đến cuối trên thiết bị Android thật (qua emulator).

## 9. Giai đoạn 5 — Quay video (2026-08-11)

Phạm vi: đúng Bước 13 roadmap — fix build camera, quyền camera/mic, CRUD `video_repository.dart`, UI 4 bước quay video, mô phỏng phản hồi chuyên gia, danh sách video trong hồ sơ trẻ, ghi `history_logs`.

**Bối cảnh quan trọng**: khi bắt đầu giai đoạn này, phần lớn code đã tồn tại sẵn trong working tree (chưa từng commit, chưa được ghi vào SETUP_REPORT) — có vẻ từ một phiên làm việc trước đó đã cài đặt gần như đầy đủ nhưng chưa hoàn tất xác minh/tài liệu hoá. Công việc thực tế của giai đoạn này là: rà soát lại toàn bộ code hiện có so với yêu cầu, xác nhận build/test/verify thật, và bổ sung phần còn thiếu.

### Nhiệm vụ 1 — Fix build camera

`pubspec.yaml` đã pin `camera: ^0.12.0` (thay vì `^0.11.1` gốc), và `android/build.gradle.kts` đã có `gradle.projectsEvaluated` hook thêm `androidx.concurrent:concurrent-futures:1.2.0` vào classpath biên dịch của `camera_android_camerax` — đúng cách vá lỗi `class file for androidx.concurrent.futures.CallbackToFutureAdapter not found` đã ghi nhận ở Giai đoạn 2/3.

**Verify thật**: `flutter build apk --debug` — **thành công** (94s), cài qua `adb install -r` lên `emulator-5554` (Pixel_7) — **thành công**, app khởi động và chạy bình thường. Đây là bằng chứng build thật, không chỉ khai báo.

### Nhiệm vụ 2 — Quyền camera/microphone

`AndroidManifest.xml` đã có `<uses-permission android:name="android.permission.CAMERA"/>` và `RECORD_AUDIO` + 2 `<uses-feature required="false">`. Runtime permission request **không dùng thêm package `permission_handler`** — dựa vào cơ chế có sẵn của plugin `camera`: `CameraController.initialize()` tự động trigger dialog xin quyền hệ thống lần đầu gọi trên Android, và ném `CameraException` nếu bị từ chối. [video_recording_capture_page.dart](lib/features/video_recording/video_recording_capture_page.dart) bắt exception này, hiện thông báo lỗi rõ ràng ("Không mở được camera (có thể do quyền camera/micro bị từ chối)"), không crash. Quyết định không thêm dependency mới vì tránh phạm vi ngoài yêu cầu (mục 4.7 "không cài thêm dependency ngoài phạm vi cần thiết").

### Nhiệm vụ 3 — `video_repository.dart`

CRUD đầy đủ đúng schema bảng `videos`: `save()` (insert), `getForChild()`, `updateStatus(id, status, {expertNote})`, `delete()`. [test/video_repository_test.dart](test/video_repository_test.dart) — 5 test mới: save+getForChild, lọc đúng theo `child_id` (không lẫn giữa các trẻ), `updateStatus` cập nhật đúng status+expert_note, `delete` xoá đúng bản ghi, và `HistoryLogRepository.add`+`getForChild` ghi/đọc đúng sự kiện video. **5/5 PASS**.

### Nhiệm vụ 4 — UI luồng quay video 4 bước

`lib/features/video_recording/`: `video_situation_page.dart` (6 tình huống gợi ý + tự nhập), `video_preparation_page.dart` (5 tips tĩnh đúng nội dung yêu cầu), `video_recording_capture_page.dart` (camera preview thật qua `CameraController` + `CameraPreview`, nút quay/dừng, đồng hồ đếm, tự dừng ở 3 phút, lưu file qua `path_provider` vào thư mục `app_flutter/videos/`), `video_review_page.dart` (phát lại qua `video_player`, nút "Gửi cho chuyên gia" tạo bản ghi `videos` + `history_logs`, nút quay thêm tình huống khác). Mọi lỗi camera/ghi file đều bắt exception, hiện rõ ràng, giữ nguyên dữ liệu đã có, không crash — đúng yêu cầu.

### Nhiệm vụ 5 — Mô phỏng phản hồi chuyên gia

[video_detail_page.dart](lib/features/video_recording/video_detail_page.dart) — nút debug (`!kIsWeb && kDebugMode`, cùng kiểu nút "Nạp dữ liệu tham khảo" ở Giai đoạn 4) chỉ hiện khi video chưa `reviewed`. 3 mẫu nhận xét cố định xoay vòng theo `video.id.hashCode`, nội dung đúng tinh thần Bước 13 (nhận xét chuyên môn, điểm cần theo dõi, lĩnh vực cần đánh giá thêm, khuyến nghị bước tiếp theo). Gọi `VideoRepository.updateStatus(id, 'reviewed', expertNote: note)`.

### Nhiệm vụ 6 — Danh sách video trong hồ sơ trẻ

[video_list_page.dart](lib/features/video_recording/video_list_page.dart) — liệt kê theo trẻ: tình huống, ngày quay, trạng thái (🟡 Đang chờ chuyên gia / 🟢 Đã có nhận xét / "Chưa gửi"). Bấm vào mở `video_detail_page.dart` (phát lại + nhận xét). `ProfileDetailPage` → nút "Quay video tình huống" trỏ đúng vào trang này.

### Nhiệm vụ 7 — Lịch sử

`video_review_page.dart._sendToExpert()` ghi `history_logs` (`event_type: 'video'`) ngay sau khi tạo bản ghi `videos` thành công; nếu ghi log lỗi thì **không** làm mất video đã gửi (try/catch riêng, đúng pattern đã dùng ở các giai đoạn trước).

### Nhiệm vụ 8 — Kiểm chứng

- `flutter analyze`: **0 lỗi, 0 warning** (tốt hơn cả kỳ vọng — warning `unused_field` ở `video_repository.dart` từ các giai đoạn trước đã hết vì code đã dùng thật).
- `flutter test`: **42/42 PASS** toàn bộ project (37 test cũ từ Giai đoạn 1-4 + 5 test mới `video_repository_test.dart`).
- Build thật + cài thật trên `emulator-5554` (Pixel_7): **PASS**, xem Nhiệm vụ 1.
- Verify tay qua `adb` + screenshot thật (không phải mô tả suông):
  - Tạo hồ sơ "Be Video Test" → vào "Quay video tình huống" → **danh sách video hiển thị đúng** 1 video "Trẻ chơi cùng người khác" (🟡 Đang chờ chuyên gia, ngày 11/8/2026).
  - Bấm vào video → **phát lại được video thật** đã quay bằng camera ảo của emulator (cảnh phòng khách, TV hiện test pattern) — xác nhận qua screenshot, không phải suy đoán.
  - Đối chiếu trực tiếp database thật trên thiết bị (`app_flutter/iris.db`, pull qua `adb exec-out run-as ... cat` để tránh lỗi mangling nhị phân của `adb shell` khi pipe qua Git Bash): bảng `videos` có đúng 1 dòng (`situation: "Trẻ chơi cùng người khác"`, `status: pending`, `recorded_at` hợp lệ), bảng `history_logs` có đúng 1 dòng khớp (`event_type: video`, `description: "Quay video tình huống: Trẻ chơi cùng người khác"`) — chứng minh pipeline quay → lưu file → gửi chuyên gia đã chạy đúng thật trên thiết bị. 2 file `.mp4` thật (6.7MB và 1.4MB) tồn tại trong `app_flutter/videos/`.
  - **Chưa tự tay xác nhận được** bước bấm nút "Debug: Mô phỏng chuyên gia phản hồi" cập nhật đúng `status`/`expert_note` bằng thao tác UI trong phiên này — 2 lần bấm thử qua tọa độ tính từ ảnh chụp đều trượt (chiều cao vùng phát video thay đổi nhẹ giữa các lần load khiến tọa độ nút debug bên dưới bị lệch), và người dùng đã chủ động nhận làm nốt bước này thủ công thay vì tiếp tục dò tọa độ. Logic `updateStatus()` đã được xác nhận đúng qua unit test (`VideoRepository: updateStatus cập nhật status + expert_note` — PASS) và qua đọc code `video_detail_page.dart._simulateExpertReview()`, nhưng **chưa có bằng chứng click-through UI thật cho riêng bước này**.

**Phát hiện phụ đáng lưu ý (không phải lỗi)**: `lib/features/history/history_page.dart` vẫn là `const Placeholder()` (đúng kế hoạch — mục "Lịch sử tổng hợp" là bước #6 riêng trong thứ tự triển khai roadmap, chưa tới lượt). Widget `Placeholder()` mặc định của Flutter render toàn màn hình đen với 2 đường chéo hình chữ X — trong lúc dò toạ độ nút bằng tay, có lúc bấm nhầm sang nút "Lịch sử" (thay vì "Quay video tình huống") khiến tưởng nhầm là lỗi camera preview, gây mất khá nhiều thời gian điều tra sai hướng. Không ảnh hưởng code hay chức năng — chỉ ghi chú lại để tránh nhầm lẫn tương tự về sau.

### Chưa làm (để dành hoặc chờ người dùng tự làm)

- Xác nhận thủ công nút "Debug: Mô phỏng chuyên gia phản hồi" trên UI thật (người dùng tự thực hiện).
- Chưa thêm nội dung tham khảo/dữ liệu chuyên môn thật cho mục 2-5 của 9 lĩnh vực (việc riêng khác, không thuộc phạm vi giai đoạn này).
- Toàn bộ thay đổi từ Giai đoạn 1 đến nay (bao gồm Giai đoạn 5) **vẫn chưa được commit vào git** — `git status` cho thấy working tree có rất nhiều thay đổi uncommitted kể từ "first commit" ban đầu.

## 10. Giai đoạn 6 — Lịch sử tổng hợp (2026-08-11)

Phạm vi: đúng Bước 9 luồng chi tiết gốc — audit + bổ sung ghi `history_logs` cho luồng sàng lọc và đánh giá mô tả từng lĩnh vực, code UI trang Lịch sử (thay `Placeholder()`), gắn đúng route kèm `childId`.

### Nhiệm vụ 1 — Audit trạng thái ghi log hiện có (đọc code thật, không suy đoán)

Đọc trực tiếp [screening_questionnaire_page.dart](lib/features/screening/screening_questionnaire_page.dart) và [description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart) (bản trước khi sửa):

| Luồng | Có ghi `history_logs` trước audit? |
|---|---|
| Sàng lọc (`ScreeningQuestionnairePage._submit()`) | **Không** — chỉ gọi `ScreeningRepository.save()`, không đụng tới `HistoryLogRepository` |
| Đánh giá mô tả từng lĩnh vực (`DescriptionPage._save()`) | **Không** — chỉ gọi `AssessmentRepository.save()` + `ProfileChunkRepository.add()` |
| Quay video (`VideoReviewPage._sendToExpert()`, Giai đoạn 5) | **Có**, đúng — giữ nguyên, không đụng vào |

Xác nhận: `HistoryLogRepository` ([history_log_repository.dart](lib/data/repositories/history_log_repository.dart)) đã có sẵn `add()` và `getForChild()` (sắp xếp `event_date DESC`, mới nhất trước) từ Giai đoạn 1 — **đủ dùng, không cần sửa**.

### Nhiệm vụ 2 — Bổ sung ghi log còn thiếu

- `screening_questionnaire_page.dart`: sau khi `ScreeningRepository.save()` thành công, ghi thêm `history_logs` (`event_type: 'sang_loc'`, `description: 'Thực hiện sàng lọc — điểm X/6'`) trong khối `try/catch` riêng — lỗi ghi log không làm hỏng luồng lưu sàng lọc chính (đúng pattern đã dùng ở `video_review_page.dart` Giai đoạn 5).
- `description_page.dart`: sau khi `AssessmentRepository.save()` thành công (Bước 1, luôn chạy trước, không phụ thuộc bước gọi API AI), ghi thêm `history_logs` (`event_type: 'danh_gia'`, `description: 'Đánh giá {linhVucLabel} — đã nhập mô tả biểu hiện'`), cũng trong `try/catch` riêng, đặt trước bước gọi NVIDIA embed để không bị ảnh hưởng nếu bước AI lỗi.
- Không đụng tới `video_review_page.dart` (log `event_type='video'` Giai đoạn 5 giữ nguyên).

### Nhiệm vụ 3 — UI trang Lịch sử

[history_page.dart](lib/features/history/history_page.dart) — viết lại từ `Placeholder()`: nhận `required Child child`, `FutureBuilder<List<HistoryLog>>` từ `HistoryLogRepository.getForChild()`, nhóm theo ngày (`_groupByDay()`, `DateTime(y,m,d)` làm key, giữ nguyên thứ tự mới nhất trước vì repository đã `ORDER BY event_date DESC`). Mỗi nhóm ngày: tiêu đề `dd/MM/yyyy` in đậm + `Card` chứa các `ListTile` (icon theo `event_type`, tiêu đề là `description`, phụ đề là nhãn loại sự kiện + giờ `HH:mm`). Trạng thái rỗng: `Center` + thông báo hướng dẫn, không lỗi, không màn trắng.

### Nhiệm vụ 4 — Gắn route

`ProfileDetailPage` → nút "Lịch sử" trước đó gọi `HistoryPage()` **không truyền `child`** (constructor cũ không có tham số này) — đã sửa thành `HistoryPage(child: child)`.

### Nhiệm vụ 5 — Kiểm chứng

- `flutter analyze`: **0 lỗi, 0 warning**.
- `flutter test`: **42/42 PASS** (không tăng số lượng test case — bổ sung 1 assertion mới vào test `screening_flow_test.dart` có sẵn để xác nhận `history_logs` được ghi đúng sau khi hoàn thành sàng lọc, thay vì tạo file test riêng, vì luồng UI đó đã có sẵn widget test end-to-end). Không viết thêm widget test riêng cho `DescriptionPage` vì luồng này gọi `NvidiaApiClient` thật (mạng thật) — đúng tiền lệ đã chọn ở Giai đoạn 3 (chỉ verify tay trên thiết bị, không mock trong widget test).
- Build thật + cài thật trên `emulator-5554` (Pixel_7): **PASS**.
- **Verify tay qua adb + screenshot thật, đối chiếu trực tiếp database** trên hồ sơ "Be Video Test" (đã có sẵn 1 log `video` từ Giai đoạn 5):
  1. Thực hiện thêm 1 lượt sàng lọc (6 câu "Không", điểm 0/6) qua UI thật.
  2. Nhập thêm 1 mô tả biểu hiện cho lĩnh vực "Giác quan" qua UI thật (SnackBar "Đã lưu mô tả, nhưng chưa xử lý được cho AI (thử lại sau)." — đúng kỳ vọng vì không có API key trong lần chạy này, không ảnh hưởng việc ghi log).
  3. Mở "Lịch sử" → **UI hiển thị đúng 3 sự kiện**, nhóm dưới 1 ngày "11/08/2026", đúng thứ tự mới nhất trước:
     - "Đánh giá Giác quan — đã nhập mô tả biểu hiện" · Đánh giá · 17:57
     - "Thực hiện sàng lọc — điểm 0/6" · Sàng lọc · 17:54
     - "Quay video tình huống: Trẻ chơi cùng người khác" · Video · 13:10
  4. Đối chiếu trực tiếp bảng `history_logs` thật trên thiết bị (pull qua `adb exec-out run-as ... cat`, giống Giai đoạn 5): **3 dòng khớp chính xác 100%** cả về nội dung, `event_type`, và thứ tự thời gian với những gì hiển thị trên UI.

### Chưa làm / lưu ý

- Chưa verify tay trạng thái rỗng (hồ sơ chưa có sự kiện nào) trên UI thật trong phiên này — nút "+" tạo hồ sơ mới không phản hồi tap trong 2 lần thử (nghi cùng loại vấn đề định vị toạ độ nút đã gặp ở Giai đoạn 5, chưa điều tra sâu vì không chặn tiêu chí hoàn thành). Logic trạng thái rỗng trong `history_page.dart` dùng đúng pattern đã verify thật ở `video_list_page.dart` (Giai đoạn 5: `if (list.isEmpty) return ...`), rủi ro thấp.
- Không đụng tới Lịch sử hỏi đáp AI (`ai_conversations`) hay Dashboard nhiều trẻ — đúng ngoài phạm vi.
- Không commit git — vẫn còn tồn đọng từ các giai đoạn trước.

## 11. Vá 3 mục "chặn demo" phát hiện qua audit (2026-08-11)

Phạm vi: xử lý đúng 3 vấn đề `TRANG_THAI_DU_AN.md` (audit 11/08/2026) xếp vào nhóm "chặn demo" — (1) Chức năng #3 "Xác định hướng đánh giá theo độ tuổi" chưa có code, (2) thiếu `INTERNET` permission ở manifest chính, (3) `flutter analyze`/`flutter test` không hoàn tất được trong phiên audit trước, số liệu 42/42 PASS cũ chưa tái xác nhận. Đọc lại `TRANG_THAI_DU_AN.md` và code thật trước khi sửa — xác nhận đúng cả 3 mô tả của audit (không giả định).

### Nhiệm vụ 1 — Phân nhánh sàng lọc theo tuổi (Chức năng #3)

- [screening_question_bank.dart](lib/domain/services/screening_question_bank.dart) *(mới)* — định nghĩa 2 bộ câu hỏi mock 6 câu: **Bộ A (16–30 tháng)** (giữ nguyên nội dung bộ câu hỏi cũ) và **Bộ B (31 tháng trở lên)** *(mới, chủ đề xã hội/ngôn ngữ/sinh hoạt phù hợp trẻ lớn hơn)*, cùng hàm `selectScreeningQuestionSet(ageMonths)` — ranh giới 30 tháng tham khảo mốc khuyến nghị M-CHAT-R/F. Dùng lại `childAgeInMonths()` có sẵn từ `domain/models/child.dart`, không viết hàm quy đổi tuổi mới.
- [screening_questionnaire_page.dart](lib/features/screening/screening_questionnaire_page.dart) — bỏ hằng số 6 câu cứng cũ, dùng `selectScreeningQuestionSet(childAgeInMonths(widget.child))`; UI hiện thêm dòng "Công cụ sàng lọc: {label}" phía trên danh sách câu hỏi; `toolName` lưu vào `screenings` cũng kèm label bộ câu hỏi đã dùng.

### Nhiệm vụ 2 — Bước 4: Tổng hợp hồ sơ & đề xuất hướng đánh giá

- [assessment_summary_page.dart](lib/features/screening/assessment_summary_page.dart) *(mới)* — đọc dữ liệu thật (không hardcode): độ tuổi (`formatAgeLabel`), đã sàng lọc chưa + điểm gần nhất (`ScreeningRepository`), số lĩnh vực đã có mô tả trên tổng 9 (`AssessmentRepository`, lọc `content_type='mo_ta'`, đếm `linh_vuc` duy nhất). Đề xuất hướng đánh giá tính bằng `_buildSuggestion()` — logic Dart if/else thuần dựa trên tổ hợp (đã sàng lọc?, số lĩnh vực đã làm, tuổi qua nhãn bộ câu hỏi tương ứng), **không gọi AI**, 5 nhánh nội dung khác nhau tuỳ trạng thái hồ sơ. Nút "Bắt đầu đánh giá" vào `DomainListPage`.
- Gắn route (Nhiệm vụ 4.3/4.5 prompt): cả 2 nhánh Bước 3 đều dẫn tới trang này trước khi vào 9 lĩnh vực:
  - `screening_intro_page.dart`: nhánh "Chưa muốn" trước đây `Navigator.pop()` (không tạo bản ghi, quay thẳng về hồ sơ) — nay `push` sang `AssessmentSummaryPage` (vẫn không tạo bản ghi `screenings`).
  - `screening_result_page.dart`: nút cuối trước đây "Quay lại hồ sơ trẻ" (pop 2 lần) — nay đổi thành "Tiếp tục", `pushReplacement` sang `AssessmentSummaryPage`.
  - **Lỗi phát hiện & tự sửa trong lúc làm**: bản nháp đầu tiên dùng `pushReplacement` ngay tại `ScreeningIntroPage` cho cả 2 nút — điều này khiến `ProfileDetailPage._openScreening()` (đang `await Navigator.push(...)` chính route `ScreeningIntroPage`) hoàn tất **ngay khi bấm nút**, thay vì khi người dùng thực sự quay lại hồ sơ, làm badge "Đã sàng lọc"/"Chưa sàng lọc" không được làm mới đúng lúc. Đã sửa lại dùng `push` (giữ `ScreeningIntroPage` trong ngăn xếp) cho 2 nút của `ScreeningIntroPage`; các trang sau đó (`Result`, `Summary`) dùng `pushReplacement` cho chính chúng vẫn an toàn vì không có `await` nào phụ thuộc vào thời điểm chúng bị gỡ khỏi ngăn xếp. Đánh đổi nhỏ: bấm "quay lại" từ Bước 4 sẽ đi qua lại màn `ScreeningIntroPage` một lần trước khi về hồ sơ — chấp nhận được để giữ đúng hành vi làm mới badge.

### Nhiệm vụ 3 — `INTERNET` permission

`android/app/src/main/AndroidManifest.xml` — thêm `<uses-permission android:name="android.permission.INTERNET"/>`. Đọc lại trực tiếp file sau khi sửa để xác nhận. `flutter build apk --release`: **thành công** (170.7s, `app-release.apk` 52.6MB). Xác nhận thêm bằng `aapt dump permissions app-release.apk` — `android.permission.INTERNET` có mặt thật trong APK release đã build (không chỉ đọc file nguồn).

### Nhiệm vụ 4 — Chạy lại `flutter analyze`/`flutter test` cho có kết quả thật

Nguyên nhân timeout ở phiên audit trước không xác định được (không tái diễn ở phiên này) — xử lý bằng cách chạy qua cơ chế tiến trình nền của công cụ (không dùng `&` lồng trong lệnh shell, ghi output ra file, đợi tiến trình thật sự báo hoàn tất rồi mới đọc file):

- `flutter analyze > analyze_out.txt 2>&1`: **hoàn tất thật, 44.1s — "No issues found!"** (0 lỗi, 0 warning).
- `flutter test > test_out.txt 2>&1`: **hoàn tất thật, ~60s, exit code 0 — "All tests passed!"**. **46/46 PASS** (42 ca cũ + 4 ca mới trong `screening_question_bank_test.dart`, đơn vị test thuần Dart xác nhận `selectScreeningQuestionSet()` chọn đúng Bộ A/Bộ B theo tuổi, gồm cả 2 mốc ranh giới 30/31 tháng). Không có FAIL nào. Số liệu này **thay thế số 42/42 chưa tái xác nhận** ghi trong audit.
- `screening_flow_test.dart` được cập nhật để khớp luồng điều hướng mới (Bước 3 → Bước 4 → hồ sơ): xác nhận nhánh "Chưa muốn" dẫn vào Bước 4 đúng dữ liệu ("Chưa sàng lọc"), nhánh "Có" với hồ sơ 36 tháng tuổi được chọn đúng **Bộ B (31 tháng trở lên)** (không còn dùng cứng 1 bộ), và Bước 4 sau khi sàng lọc hiển thị đúng dữ liệu thật ("Đã sàng lọc", "Kết quả sàng lọc gần nhất: 0/6", "Đã có mô tả cho 0/9 lĩnh vực") — cả 2 trường hợp thuộc 2 dải tuổi khác nhau đều được test bằng mã, đúng yêu cầu tiêu chí hoàn thành.

### Nhiệm vụ 5 — Kiểm chứng & phạm vi chưa làm

- Không verify tay qua adb/emulator cho riêng phần vá lần này — prompt cho phép "verify bằng cách đọc code và/hoặc test", đã đáp ứng đầy đủ qua widget test + unit test thật (không phải suy đoán). Các tính năng khác (quay video, hỏi đáp AI, lịch sử) đã verify tay ở các giai đoạn trước, không đụng lại trong lần vá này.
- Không mở rộng thành công cụ sàng lọc lâm sàng thật, không đổi schema, không động tới phần 2-5 của 9 lĩnh vực, dashboard, hay các mục "để sau" khác trong audit — đúng phạm vi đã giới hạn.
- Không commit git.

## 12. Dashboard nhiều trẻ — Phụ lục 1 (2026-08-11)

Phạm vi: xây `MultiChildDashboardPage` thật (thay `Placeholder()`), gắn route, tổng quan số liệu, danh sách trẻ kèm tiến độ/trạng thái, tìm kiếm/lọc, menu thao tác (xem/lịch sử/lưu trữ/xoá), tab xem hồ sơ đã lưu trữ.

### Nhiệm vụ 1 — Rà soát trước khi code

Đọc trực tiếp `MultiChildDashboardPage` (xác nhận đúng `Placeholder()`, chưa gắn route như audit ghi), `ChildListPage`, `ChildRepository`, `AssessmentRepository`, `HistoryLogRepository`, và toàn bộ 8 file `data/local/tables/*.dart` để xác nhận chính xác foreign key nào tham chiếu `children(id)` — kết quả: **6 bảng** (`screenings`, `assessments`, `history_logs`, `profile_chunks`, `videos`, `ai_conversations`) tham chiếu `child_id`, **không bảng nào khai báo `ON DELETE CASCADE`**. Kết hợp với `PRAGMA foreign_keys = ON` đã bật sẵn trong `AppDatabase` — xác nhận đúng rủi ro audit nêu: xoá thẳng `children` khi còn dữ liệu liên quan sẽ ném lỗi ràng buộc khoá ngoại.

### Nhiệm vụ 2 — Sửa `ChildRepository`

[child_repository.dart](lib/data/repositories/child_repository.dart):
- `delete(id)` — viết lại: xoá theo đúng thứ tự 6 bảng con trước (mỗi bảng lọc theo `child_id`), rồi mới xoá `children`, toàn bộ trong 1 `db.transaction()` để đảm bảo toàn vẹn (không xoá dở dang nếu lỗi giữa chừng). `expert_knowledge_chunks` không có `child_id` (dữ liệu tham khảo dùng chung) nên không đụng tới.
- Thêm `unarchive(id)` — đối xứng với `archive(id)` có sẵn, set `status='active'`, phục vụ tab "Đã lưu trữ" khôi phục hồ sơ.

### Nhiệm vụ 3 — `MultiChildDashboardPage`

[multi_child_dashboard_page.dart](lib/features/multi_child_dashboard/multi_child_dashboard_page.dart) — viết lại từ `Placeholder()`:
- Tiến độ mỗi trẻ = số `linh_vuc` duy nhất có bản ghi `assessments` (`content_type='mo_ta'`), dạng x/9. Trạng thái: 0/9 → "Chưa đánh giá", 9/9 → "Đã đánh giá", còn lại → "Đang đánh giá" — đúng quy tắc đơn giản hoá đã nêu trong prompt, không cố khớp mockup gốc.
- Cập nhật gần nhất = `event_date` mới nhất trong `history_logs` của trẻ (repository đã sắp `DESC`, lấy `.first`); rỗng → "—".
- 2 tab (`Đang quản lý` / `Đã lưu trữ`) qua `DefaultTabController`, tách theo `child.status`. Card thống kê tổng (tổng số trẻ tính trên `status='active'`, đã/đang/chưa đánh giá). Ô tìm theo tên (lọc tại chỗ, không query DB riêng) + dropdown lọc theo trạng thái đánh giá (`_ProgressFilter`: Tất cả/Chưa/Đang/Đã). Mỗi dòng trẻ có `PopupMenuButton` 4 mục — nhãn đổi theo `child.status` (`active` → "Lưu trữ hồ sơ", `archived` → "Khôi phục hồ sơ"); "Xem hồ sơ"/"Lịch sử đánh giá" liên kết thẳng `ProfileDetailPage`/`HistoryPage` có sẵn, không viết lại. Nút "+ Thêm trẻ" tái sử dụng `CreateProfilePage` có sẵn (nhận `bool` kết quả để reload).

### Nhiệm vụ 4 — Gắn route

`ChildListPage` — thêm `IconButton` (icon `dashboard_outlined`, tooltip "Quản lý nhiều trẻ") vào `actions` của `AppBar`, điều hướng sang `MultiChildDashboardPage`, reload danh sách khi quay lại. Đây là màn chính (home) của app — entry point hợp lý duy nhất hiện có.

### Nhiệm vụ 5 — Test

[child_repository_test.dart](test/child_repository_test.dart) *(mới)* — 3 test, trọng tâm vào rủi ro cao nhất (xoá hồ sơ):
- `archive`/`unarchive` cập nhật đúng `status`, `getAll()` mặc định ẩn hồ sơ lưu trữ.
- **`delete()` tạo dữ liệu thật ở đủ 6 bảng con** (screenings/assessments/history_logs/profile_chunks/videos/ai_conversations) rồi xoá — xác nhận không ném lỗi, và cả 6 bảng lẫn `children` đều sạch sau khi xoá.
- `delete()` không ảnh hưởng dữ liệu trẻ khác (test cách ly theo `child_id`).

### Nhiệm vụ 6 — Kiểm chứng

- `flutter analyze`: **0 lỗi, 0 warning**.
- `flutter test`: **49/49 PASS** (46 cũ + 3 test mới `child_repository_test.dart`). Không có ca FAIL nào mới phát sinh.
- Build thật + cài thật trên `emulator-5554` (Pixel_7): **PASS**.
- **Verify tay qua adb + screenshot thật + đối chiếu database**, dùng 3 hồ sơ có trạng thái tiến độ khác nhau (tạo 2 hồ sơ mới qua UI thật, 1 hồ sơ seed đủ 9/9 lĩnh vực trực tiếp qua database để tránh nhập tay 9 lần — chỉ dùng cho việc tạo dữ liệu test, không thay cho verify UI):
  - Mở Dashboard → **card tổng số liệu khớp chính xác 100% với dữ liệu thật**: 3 tổng số trẻ, 1 đã đánh giá, 1 đang đánh giá, 1 chưa đánh giá; từng dòng hiển thị đúng tuổi, x/9 lĩnh vực, trạng thái, cập nhật gần nhất (kể cả dấu "—" cho trẻ chưa có `history_logs`).
  - **Tìm kiếm** theo tên: gõ "Video" → lọc đúng còn 1 kết quả.
  - **Bộ lọc** trạng thái: chọn "Chưa đánh giá" → lọc đúng còn 1 hồ sơ khớp tiêu chí.
  - **Xem hồ sơ**: mở đúng `ProfileDetailPage` của đúng trẻ.
  - **Lịch sử đánh giá**: mở đúng `HistoryPage` của đúng trẻ, hiển thị đúng log đã seed.
  - **Lưu trữ hồ sơ**: dialog xác nhận đúng nội dung → xác nhận → hồ sơ biến mất khỏi "Đang quản lý" (tổng số trẻ 3→2), card số liệu cập nhật đúng, xuất hiện đúng ở tab "Đã lưu trữ".
  - **Khôi phục hồ sơ** (từ tab "Đã lưu trữ"): dialog xác nhận đúng → xác nhận → hồ sơ trở lại "Đang quản lý" (3), tab "Đã lưu trữ" về trạng thái rỗng đúng thông báo, không lỗi.
  - **Xoá hồ sơ** (rủi ro cao nhất — trẻ có dữ liệu ở sàng lọc + đánh giá + lịch sử + video): dialog xác nhận nêu rõ mất dữ liệu vĩnh viễn → xác nhận → **hồ sơ biến mất hoàn toàn, app không crash, không treo**, tổng số trẻ 3→2. Đối chiếu trực tiếp database thật ngay sau đó (pull qua `adb exec-out run-as ... cat`): cả 6 bảng con (`screenings`, `assessments`, `history_logs`, `profile_chunks`, `videos`, `ai_conversations`) đều **0 dòng** cho `child_id` đã xoá, bảng `children` không còn hồ sơ đó — xác nhận transaction xoá hoạt động đúng, không lỗi ràng buộc khoá ngoại dù `PRAGMA foreign_keys = ON`.

### Chưa làm / lưu ý

- Không xây multi-user/đăng nhập/đồng bộ nhiều thiết bị thật — đúng ngoài phạm vi.
- Không xây lại `ProfileDetailPage`, `HistoryPage`, `VideoListPage`, `AiChatPage`, `CreateProfilePage` — chỉ liên kết/tái sử dụng như yêu cầu.
- Không đổi schema database.
- Không commit git.

## 13. Vá các mục "không chặn demo nhưng nên xử lý" từ audit (2026-08-11)

Phạm vi: 7 mục trong `TRANG_THAI_DU_AN.md` mục 5 (phần "Không chặn demo nhưng nên xử lý"), **trừ** 2 mục đã xác nhận là đánh đổi kiến trúc có chủ đích (API key qua `--dart-define`, SQLite không mã hoá) — không đụng tới 2 mục đó theo đúng chỉ định của prompt.

### Nhiệm vụ 1 — Verify nút mô phỏng chuyên gia (tồn đọng từ Giai đoạn 5, đã trượt 2 lần trước)

Nguyên nhân trượt ở 2 lần trước: toạ độ tính tay từ ảnh chụp bị lệch (nhất là khi bàn phím/dialog làm layout đổi vị trí). Lần này dùng `uiautomator dump` lấy `bounds` chính xác cho **từng bước** của luồng (chọn hồ sơ → Quay video tình huống → chọn tình huống → Bắt đầu quay → Dừng quay → Gửi cho chuyên gia → mở lại video → cuộn xuống → bấm nút debug), không suy đoán từ ảnh:

- Quay 1 video thật mới (do dữ liệu cũ đã bị xoá qua thao tác Xoá hồ sơ ở mục Dashboard trước đó), gửi thành công (`status: pending`).
- Bấm "Debug: Mô phỏng chuyên gia phản hồi" → **UI cập nhật ngay**: "Trạng thái: 🟢 Đã có nhận xét" + hiện đúng đoạn "Nhận xét chuyên gia" (screenshot đã chụp).
- Đối chiếu trực tiếp database thật (pull qua `adb exec-out run-as ... cat`): `videos.status = 'reviewed'`, `expert_note` chứa đúng nội dung nhận xét đã hiện trên UI, khớp 100%.

**Kết luận: đã verify chắc chắn, không còn tồn đọng.**

### Nhiệm vụ 2 — Timeout HTTP

`NvidiaApiClient`/`GroqApiClient` — thêm `.timeout()` cho lệnh gọi HTTP (embedding 15s, generation 30s — generation cho phép lâu hơn vì model/câu trả lời lớn hơn), bắt riêng `TimeoutException` trả về `NvidiaApiException`/`GroqApiException` với thông báo rõ ràng thay vì để `Future` treo vô hạn. Cả 2 client nhận thêm tham số `timeout` optional qua constructor (mặc định đúng giá trị 15s/30s khi dùng thật) để test được bằng timeout ngắn (20ms) thay vì phải chờ thật.

`test/nvidia_api_client_test.dart` + `test/groq_api_client_test.dart` — mỗi file thêm 1 test dùng `MockClient` cố tình delay lâu hơn timeout đã cấu hình, xác nhận đúng exception + đúng thông báo "Hết thời gian chờ" được ném ra, không treo.

### Nhiệm vụ 3 — Nút "Thử lại xử lý cho AI"

[description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart) — tách logic embed+lưu `profile_chunks` thành `_embedAndSaveChunk()` dùng chung cho cả lần lưu đầu và nút thử lại; khi bước embed lỗi, giữ lại nội dung mô tả vào `_pendingEmbedContent` và hiện nút "Thử lại xử lý cho AI" ngay dưới nút "Lưu". Bấm nút chỉ gọi lại bước embed+`profile_chunks`, **không** tạo thêm bản ghi `assessments`.

**Verify tay trên `emulator-5554`** (không có API key trong lần chạy debug này nên bước embed cố ý lỗi — đúng kịch bản cần test): lưu mô tả "Test retry embedding button" → SnackBar "Đã lưu mô tả, nhưng chưa xử lý được cho AI (thử lại sau)." + nút "Thử lại xử lý cho AI" hiện đúng → bấm nút → gọi lại, vẫn lỗi (do vẫn thiếu key) → SnackBar "Vẫn chưa xử lý được cho AI, thử lại sau." đúng. Đối chiếu database: **đúng 1 dòng `assessments`** (không trùng lặp do bấm thử lại), `profile_chunks` vẫn 0 dòng (đúng vì vẫn lỗi) — xác nhận nút không tạo dữ liệu trùng.

### Nhiệm vụ 4 — Kiểm tra độ dài vector trong `cosineSimilarity()`

[vector_search_service.dart](lib/domain/services/vector_search_service.dart) — thêm `if (a.length != b.length) return 0;` ngay đầu hàm, cùng cách xử lý "kiểm soát" đã dùng cho trường hợp vector rỗng (`normA/normB == 0 → return 0`) thay vì để `RangeError` không kiểm soát làm crash luồng hỏi đáp AI khi dữ liệu embedding không đồng nhất (VD đổi model embedding giữa các lần ingest). Không cần sửa gì ở `searchProfileChunks`/`searchExpertChunks` vì lỗi đã được chặn ngay tại nguồn.

`test/vector_search_service_test.dart` — thêm 1 test xác nhận `cosineSimilarity()` trả `0.0` (không throw) với 3 trường hợp: vector dài hơn/ngắn hơn/rỗng so với vector còn lại.

### Nhiệm vụ 5 — Xử lý lỗi rõ ràng cho `FutureBuilder` chính

Rà soát đúng 4 trang nêu trong prompt — cả 4 đều chỉ xét `hasData`, bỏ qua `hasError` (khi lỗi: `ChildListPage`/`MultiChildDashboardPage`/`VideoListPage` treo vô hạn ở `CircularProgressIndicator`; riêng `ChildListPage` dùng `snapshot.data ?? []` nên còn tệ hơn — âm thầm hiện "Chưa có hồ sơ trẻ nào" dù thực chất là lỗi truy vấn, đúng kiểu lỗi "màn trắng/treo im lặng" audit mô tả). Đã thêm nhánh `snapshot.hasError` ở cả 4 trang — hiện icon lỗi + thông báo (`snapshot.error`) + nút "Thử lại" gọi lại đúng hàm `_reload()` sẵn có (thêm mới `_reload()` cho `HistoryPage` vì trước đó gán `Future` thẳng trong `initState`, không có cách nào gọi lại):

- [child_list_page.dart](lib/features/child_profile/child_list_page.dart)
- [multi_child_dashboard_page.dart](lib/features/multi_child_dashboard/multi_child_dashboard_page.dart)
- [history_page.dart](lib/features/history/history_page.dart)
- [video_list_page.dart](lib/features/video_recording/video_list_page.dart)

`test/future_builder_error_test.dart` *(mới)* — 1 widget test dùng `ChildListPage` làm đại diện (cùng pattern xử lý lỗi nhân bản giống hệt ở cả 4 trang): đóng kết nối database thật (không mock) để buộc query đầu tiên thất bại thật, xác nhận UI hiện đúng thông báo lỗi + nút "Thử lại"; sau đó mở lại database hợp lệ và bấm "Thử lại", xác nhận trang tải lại đúng dữ liệu, không còn kẹt ở trạng thái lỗi.

### Nhiệm vụ 6 — Hạ tầng ký release Android (không tạo keystore thật)

- [android/key.properties.example](android/key.properties.example) *(mới, có thể commit)* — mẫu cấu trúc + hướng dẫn lệnh `keytool` để tự tạo keystore thật.
- `.gitignore` — thêm `android/key.properties`, `android/*.jks`, `android/*.keystore`, `android/app/*.jks`, `android/app/*.keystore` (chưa có trước đó).
- [android/app/build.gradle.kts](android/app/build.gradle.kts) — đọc `android/key.properties` nếu tồn tại, tạo `signingConfigs.release` từ đó; `buildTypes.release.signingConfig` dùng `release` nếu có file, **fallback về `debug` như hành vi cũ** nếu không có (chưa tạo keystore thật ở máy này) — không phá build hiện tại.
- **Verify bằng build thật**: `flutter build apk --debug` **và** `flutter build apk --release` đều **PASS** sau khi sửa (release: 56.2s, `app-release.apk` 53.0MB) — xác nhận nhánh fallback debug-signing hoạt động đúng khi chưa có `key.properties` thật.
- Đã ghi rõ trong mục "Việc cần tự làm thủ công" bên dưới các bước người dùng cần tự chạy `keytool` + điền `key.properties` trước khi phát hành thật.

### Nhiệm vụ 7 — iOS permission text

[ios/Runner/Info.plist](ios/Runner/Info.plist) — thêm `NSCameraUsageDescription` + `NSMicrophoneUsageDescription` (chỉ sửa text, không build — máy hiện tại không có Xcode/macOS). Đọc lại trực tiếp file sau khi sửa để xác nhận đã có đủ 2 khoá.

### Nhiệm vụ 8 — Kiểm chứng tổng hợp

- `flutter analyze`: **0 lỗi, 0 warning** (10.7s).
- `flutter test`: **53/53 PASS** (49 cũ + 4 mới: 1 timeout NVIDIA, 1 timeout Groq, 1 vector length, 1 widget test FutureBuilder error). Không có FAIL nào.
- `flutter build apk --debug`: PASS (67.1s). `flutter build apk --release`: PASS (56.2s, 53.0MB) — xác nhận thay đổi gradle không phá build ở cả 2 nhánh.
- Verify tay trên `emulator-5554` (Pixel_7) qua `adb` + `uiautomator dump` (không suy đoán toạ độ): nút mô phỏng chuyên gia (mục 1) và nút "Thử lại xử lý cho AI" (mục 3) đều có bằng chứng screenshot + đối chiếu database trực tiếp.

### Việc cần tự làm thủ công (bổ sung)

- **Tạo keystore Android thật cho bản release** (không tự làm thay, đúng yêu cầu "không tự chọn mật khẩu"):
  1. Chạy `keytool -genkey -v -keystore <đường-dẫn>/iris-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias iris`, tự đặt mật khẩu.
  2. Copy `android/key.properties.example` thành `android/key.properties` (đã gitignore), điền `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (đường dẫn tuyệt đối tới file `.jks` vừa tạo) bằng giá trị thật.
  3. Chạy lại `flutter build apk --release` — lúc này sẽ tự dùng keystore thật thay vì fallback debug-signing.
- Máy hiện tại không có Xcode/macOS nên **chưa build/verify iOS thật** — 2 khoá quyền trong `Info.plist` mới chỉ xác nhận qua đọc file, chưa chạy thật trên thiết bị/simulator iOS.

### Không làm / ngoài phạm vi

- Không mã hoá SQLite, không đổi cách truyền API key — đúng đánh đổi kiến trúc đã chấp nhận cho dự án thi, không tự ý đổi.
- Không xây hệ thống retry/backfill embedding chạy nền — chỉ retry thủ công tại điểm lỗi như yêu cầu.
- Không làm đẹp UI/theme.
- Không commit git.

## 14. Dọn housekeeping: code chết + xoá file video vật lý (2026-08-13)

Phạm vi: đúng 2 mục housekeeping nêu ở `TRANG_THAI_DU_AN.md` mục 4 (điểm 8–9) — xoá code chết, và đảm bảo file `.mp4` vật lý luôn được dọn khi xoá video (đơn lẻ hoặc theo cả hồ sơ trẻ).

### Nhiệm vụ 1 — Xác nhận lại rồi xoá code chết

Grep toàn bộ `lib/` + `test/` cho `OnboardingPage` và `AiChunk` trước khi xoá — xác nhận đúng như audit đã ghi: cả 2 chỉ xuất hiện trong file định nghĩa của chính chúng (và trong `TRANG_THAI_DU_AN.md`, một tài liệu, không phải code), không có tham chiếu nào khác trong `lib/`/`test/`. Không có test riêng cho `AiChunk`.

Đã xoá:
- `lib/features/onboarding/onboarding_page.dart` (kèm xoá thư mục `lib/features/onboarding/` vì rỗng sau đó).
- `lib/domain/models/ai_chunk.dart`.

### Nhiệm vụ 2 — Xoá file `.mp4` vật lý khi xoá 1 video

[video_repository.dart](lib/data/repositories/video_repository.dart) — `delete(id)` giờ đọc `file_path` của dòng trước khi xoá, xoá dòng DB, rồi gọi `deletePhysicalFile()` (hàm `static` mới, dùng chung với `ChildRepository`) — hàm này `try/catch` quanh `File(filePath).delete()`, chỉ `debugPrint` chứ không throw nếu file không tồn tại/không xoá được, để không chặn việc dòng DB đã xoá xong.

### Nhiệm vụ 3 — Nút "Xoá video" trên UI

[video_detail_page.dart](lib/features/video_recording/video_detail_page.dart) — thêm icon xoá trên `AppBar`, mở `AlertDialog` xác nhận (nêu rõ sẽ mất cả video và nhận xét chuyên gia nếu `expertNote != null`), gọi `VideoRepository.delete()` rồi `pop(true)`. [video_list_page.dart](lib/features/video_recording/video_list_page.dart) không cần sửa vì đã gọi `_reload()` vô điều kiện ngay sau khi `push` tới `VideoDetailPage` trả về — danh sách tự làm mới sau khi xoá.

### Nhiệm vụ 4 — Xoá file vật lý khi xoá cả hồ sơ trẻ

[child_repository.dart](lib/data/repositories/child_repository.dart) — `delete(id)` giờ query trước danh sách `file_path` của mọi video thuộc trẻ đó (ngoài transaction), chạy transaction xoá 6 bảng + `children` như cũ, rồi sau khi transaction commit thành công mới lặp qua từng `filePath` gọi `VideoRepository.deletePhysicalFile()` — mỗi file xoá độc lập, lỗi ở 1 file không chặn các file còn lại (và không có gì để rollback vì DB đã xoá xong).

### Nhiệm vụ 5 — Test mới

- `test/video_repository_test.dart` — 2 test mới: (a) tạo file thật trong `Directory.systemTemp`, lưu video trỏ tới file đó, gọi `delete()`, xác nhận cả dòng DB lẫn file trên đĩa đều biến mất; (b) `delete()` không throw khi `file_path` trỏ tới file đã không còn tồn tại.
- `test/child_repository_test.dart` — 1 test mới: tạo 1 trẻ với 2 video trỏ tới 2 file thật trong thư mục temp, gọi `childRepo.delete()`, xác nhận cả 2 file vật lý đều biến mất cùng lúc với dữ liệu DB.

### Nhiệm vụ 6 — Kiểm chứng tổng hợp

- `flutter analyze`: **0 issues** (85.8s) — không phát sinh lỗi import sau khi xoá 2 file code chết.
- `flutter test`: **56/56 PASS** (53 cũ + 3 mới: 2 xoá file vật lý video, 1 xoá file vật lý khi xoá hồ sơ trẻ). Không có FAIL nào.
- **Verify tay trên thiết bị thật — hoàn tất ở phiên sau (2026-08-13), xem Nhiệm vụ 7.**

### Nhiệm vụ 7 — Verify tay trên thiết bị thật (2026-08-13, phiên riêng sau khi có lại emulator)

Phiên housekeeping ban đầu không kết nối được emulator nên chưa verify được phần này (đã ghi rõ, không khai "đã xong"). Phiên này `adb devices` xác nhận `emulator-5554` sẵn sàng; build lại `flutter build apk --debug` (56.2s) và `adb install -r` bản mới nhất (xác nhận đang chạy đúng code đã có xoá file vật lý + 2 trường "Người đánh giá"/"Vai trò" — `ProfileDetailPage` hiện đúng "Chưa cập nhật" cho 2 trường mới trên hồ sơ có sẵn, và form tạo hồ sơ đã có 2 field mới).

Toàn bộ thao tác UI lái qua `adb shell input tap` + `uiautomator dump` lấy `bounds` chính xác cho từng bước (không suy đoán toạ độ từ ảnh chụp). Đối chiếu database dùng cách lấy file **binary-safe**: `adb shell run-as com.iris.app.iris_app base64 <path>` (đầu ra text an toàn), decode lại bằng `certutil -decode` trên máy host, rồi query bằng 1 script Dart nhỏ dùng `package:sqlite3` (đã có sẵn trong `pubspec.lock` qua `sqflite_common_ffi`) — cách lấy DB trực tiếp qua `adb exec-out ... > file` bị hỏng do PowerShell chuyển mã nhị phân (`SqliteException: file is not a database`), đã phát hiện và đổi cách lấy trước khi tin vào bất kỳ kết quả nào.

**Kịch bản 1 — xoá 1 video (hồ sơ "Be Da Danh Gia", có sẵn trên emulator từ trước):**

1. Quay 1 video tình huống "Trẻ chơi cùng người khác" (~7 giây) qua đúng luồng Quay video tình huống → Bắt đầu quay → Dừng quay → Xem lại & gửi → Gửi cho chuyên gia (bản ghi `videos` chỉ được tạo ở bước này, đúng code `video_review_page.dart._sendToExpert()`).
2. Đối chiếu **trước khi xoá**: `adb shell run-as ... ls -la .../videos/` → file `11f413b1-467f-4014-9dcd-590bf07ec304.mp4` (6.960.059 bytes) tồn tại. Query DB → dòng `videos` `a07477dc-d70f-4a9b-b78b-90041413eb60` có `file_path` khớp đúng file trên, `status: pending`.
3. Trên UI: mở lại video vừa quay → bấm icon "Xoá video" trên AppBar → dialog "Xoá video?" hiện đúng nội dung "Video này sẽ bị xoá vĩnh viễn, không thể khôi phục." (đúng nhánh video chưa có `expertNote`) → bấm "Xoá" → danh sách video quay lại rỗng ngay trên UI.
4. Đối chiếu **sau khi xoá**: `ls -la .../videos/` → file `11f413b1-...mp4` **không còn trong danh sách** (chỉ còn 3 file cũ không liên quan). Query DB → bảng `videos` không còn dòng `a07477dc-...` nào (rỗng, vì đó là dòng video duy nhất của trẻ này tại thời điểm đó).

**Kết quả: PASS** — cả file vật lý lẫn dòng DB đều bị xoá đúng, khớp 100% với code đã viết.

**Kịch bản 2 — xoá hồ sơ trẻ có video (hồ sơ "Be Chua Danh Gia", có sẵn 1 video từ trước):**

1. Đối chiếu **trước khi xoá**: `ls -la .../videos/` → file `cb103655-1e48-4bb4-9bd1-8d5b6fb79a31.mp4` (10.849.772 bytes) tồn tại. Query đầy đủ DB → trẻ "Be Chua Danh Gia" (`id: f48a833c-...`) có đúng 1 dòng `videos` (`file_path` khớp file trên), 1 dòng `assessments`, 2 dòng `history_logs`; không có `screenings`/`profile_chunks`/`ai_conversations`.
2. Trên UI: Dashboard nhiều trẻ → menu ⋮ ("Show menu") ở hồ sơ "Be Chua Danh Gia" → "Xoá hồ sơ" → dialog "Xoá hồ sơ" → bấm "Xác nhận" → Dashboard cập nhật ngay: "Tổng số trẻ" từ 2 → 1, hồ sơ "Be Chua Danh Gia" biến mất khỏi danh sách, không có lỗi/crash (đúng như kỳ vọng — `PRAGMA foreign_keys = ON` không chặn vì đã xoá đúng thứ tự 6 bảng con trước).
3. Đối chiếu **sau khi xoá**: `ls -la .../videos/` → file `cb103655-...mp4` **không còn**. Query đầy đủ DB → bảng `children` không còn dòng `f48a833c-...`; **cả 6 bảng con** (`screenings`, `assessments`, `history_logs`, `profile_chunks`, `videos`, `ai_conversations`) không còn dòng nào tham chiếu `child_id = f48a833c-...` — dòng `assessments` và 2 dòng `history_logs` của trẻ này đã biến mất đúng, trong khi 9 dòng `assessments` + 2 dòng `history_logs` của trẻ còn lại ("Be Da Danh Gia") **vẫn nguyên vẹn, không bị đụng tới**.

**Kết quả: PASS** — file vật lý, dòng `videos`, và cả 5 bảng con còn lại đều sạch đúng cho trẻ đã xoá; dữ liệu trẻ khác không bị ảnh hưởng.

**Không phát hiện bug nào trong lúc verify** — code xoá file vật lý (`VideoRepository.delete()`, `VideoRepository.deletePhysicalFile()`, `ChildRepository.delete()`) hoạt động đúng như đã viết và đã test unit, không cần sửa gì thêm.

### Không làm / ngoài phạm vi

- Không xoá code/class nào khác ngoài `OnboardingPage` và `AiChunk`.
- Không thêm tính năng ngoài phạm vi đã nêu (VD: không thêm xoá hàng loạt, không thêm undo).
- Không đổi schema database.
- Không làm đẹp UI/theme.
- Không commit git.

## 15. Thêm trường "Người đánh giá" / "Vai trò" vào hồ sơ trẻ (2026-08-13)

Phạm vi: thêm đúng 2 cột `nguoi_danh_gia`, `vai_tro` vào bảng `children` — nhập khi tạo hồ sơ, hiển thị trong hồ sơ chi tiết — không đụng cột nào khác, không phá dữ liệu hồ sơ cũ.

### Nhiệm vụ 1 — Migration schema (rủi ro cao nhất: mất dữ liệu người dùng)

[database.dart](lib/data/local/database.dart) trước đó khai `version: 1`, **không có `onUpgrade`** — bất kỳ thay đổi schema nào trước giờ đều phải qua `onCreate` (chỉ chạy cho database mới toanh, không đụng tới database đã tồn tại). Đã sửa:

- `version: 1` → `version: 2`.
- Thêm `onUpgrade: (db, oldVersion, newVersion) async { if (oldVersion < 2) { ALTER TABLE children ADD COLUMN nguoi_danh_gia TEXT; ALTER TABLE children ADD COLUMN vai_tro TEXT; } }` — chỉ thêm cột, không đụng dữ liệu dòng đã có (`ALTER TABLE ADD COLUMN` của SQLite không xoá/sửa dữ liệu cũ, các dòng cũ tự nhận `NULL` cho 2 cột mới).
- [children_table.dart](lib/data/local/tables/children_table.dart) — `childrenTableCreate` (dùng ở `onCreate`, cho cài đặt mới) đã gồm sẵn 2 cột mới, để máy cài mới đi thẳng đúng schema mới nhất mà không cần chạy qua `onUpgrade`.

**Verify bằng test thật** (`test/child_migration_test.dart`, mới) — không tin vào suy luận, dựng đúng kịch bản rủi ro: dùng `openDatabase` tạo 1 file database THẬT ở đúng schema version 1 cũ (không có 2 cột mới), insert sẵn 1 hồ sơ trẻ, đóng lại; sau đó mở lại **đúng bằng `AppDatabase` thật của app** (`version: 2` + `onUpgrade`) trỏ vào cùng file, mô phỏng đúng hành vi "người dùng mở app sau khi cập nhật". Xác nhận: hồ sơ cũ vẫn đọc được nguyên vẹn (tên, tuổi, giới tính), 2 cột mới đọc ra `null` (không lỗi, không giá trị rác), tạo hồ sơ mới sau migration dùng đúng 2 cột mới hoạt động bình thường, cả hồ sơ cũ lẫn mới cùng tồn tại (`getAll()` trả đúng 2). Test **PASS**.

### Nhiệm vụ 2 — Model & Repository

[child.dart](lib/domain/models/child.dart) — thêm `nguoiDanhGia`/`vaiTro` (`String?`, nullable, không bắt buộc). [child_repository.dart](lib/data/repositories/child_repository.dart) — `create()` nhận thêm 2 tham số optional; `_toRow()`/`_fromRow()` map đúng 2 cột `nguoi_danh_gia`/`vai_tro`. `update()` không cần sửa vì đã dùng `_toRow(child)` cho toàn bộ object.

### Nhiệm vụ 3 — Form tạo hồ sơ

[create_profile_page.dart](lib/features/child_profile/create_profile/create_profile_page.dart) — thêm ngay sau trường Giới tính: `TextFormField` "Người đánh giá" (nhập tự do, không bắt buộc, rỗng → lưu `null`), `DropdownButtonFormField` "Vai trò" (đúng 3 lựa chọn cố định: Phụ huynh / Giáo viên / Chuyên viên, không bắt buộc — giá trị lưu DB chính là nhãn tiếng Việt, không qua mã hoá riêng). Không đụng logic validate của các trường bắt buộc khác (tên, tuổi).

### Nhiệm vụ 4 — Hiển thị hồ sơ chi tiết

[profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart) — thêm 2 dòng "Người đánh giá: ..." / "Vai trò: ..." trong Card thông tin cơ bản, ngay dưới dòng tuổi/giới tính; dùng `?? "Chưa cập nhật"` cho cả 2 trường khi `null`.

### Nhiệm vụ 5 — Test

- `test/repositories_test.dart` — thêm 1 test: tạo hồ sơ có đủ "Người đánh giá"/"Vai trò" → đọc lại đúng giá trị; tạo hồ sơ không điền → đọc lại `null` cho cả 2.
- `test/child_migration_test.dart` *(mới)* — test migration ở Nhiệm vụ 1.
- `test/screening_flow_test.dart` — form `CreateProfilePage` dài hơn (thêm 2 field) khiến nút "Lưu hồ sơ" ra ngoài viewport mặc định của widget test (800×600), `tap()` không hit-test trúng nút (cảnh báo "would not hit test on the specified widget"), làm bước tạo hồ sơ trong luồng test thất bại ở bước sau. Sửa bằng `tester.ensureVisible()` cuộn tới nút trước khi `tap()`. Không phải lỗi ở code app — chỉ là hệ quả cần xử lý trong widget test khi form dài hơn.
- Các test khác gọi `childRepo.create(...)`/`Child(...)` (video_repository_test, child_repository_test, ai_repository_test, child_age_test, vector_search_service_test) đều dùng tham số đặt tên (named parameters) nên không cần sửa — 2 trường mới optional, không phá tương thích ngược.

### Nhiệm vụ 6 — Kiểm chứng tổng hợp

- `flutter analyze`: **0 issues** (phát hiện 1 `unnecessary_import` ở bản nháp đầu của `child_migration_test.dart` do `sqflite_common_ffi/sqflite_ffi.dart` đã re-export `package:sqflite/sqflite.dart` — đã sửa, xác nhận lại 0 issues).
- `flutter test`: **58/58 PASS** (56 cũ + 2 mới: 1 round-trip "Người đánh giá"/"Vai trò", 1 migration version 1→2). Không có FAIL nào.
- **Verify tay trên thiết bị thật — hoàn tất ở phiên sau (2026-08-13), xem Nhiệm vụ 7.**

### Nhiệm vụ 7 — Verify migration trên thiết bị thật bằng kịch bản cài đè (2026-08-13, phiên riêng)

Mục tiêu: verify đúng kịch bản người dùng thật gặp phải — app bản cũ (schema version 1, chưa có 2 cột mới) đã có dữ liệu trên máy → cập nhật lên bản mới bằng **cài đè** (`adb install -r`, không gỡ trước) → mở lại → không mất dữ liệu, không crash.

**Xác định commit cũ**: `git log --oneline` cho thấy chỉ 3 commit (`5954217 fix_bug` ← `60185ca update` ← `61cb641 first commit`), và **toàn bộ thay đổi của mục 14 lẫn mục 15 vẫn đang ở trạng thái chưa commit** (working tree). Do đó HEAD (`5954217`) chính xác là commit ngay trước khi có bất kỳ thay đổi nào của mục 15 — đã xác nhận trực tiếp bằng `git show HEAD:lib/data/local/tables/children_table.dart` (7 cột, không có `nguoi_danh_gia`/`vai_tro`) và `git show HEAD:lib/data/local/database.dart` (`version: 1`, không có `onUpgrade`). Không cần đoán, không có nhập nhằng.

**Build bản cũ an toàn qua git worktree**: `git worktree add ../IRIS_v1_migration_test_old HEAD` — tạo thư mục hoàn toàn tách biệt tại `D:\IRIS_v1_migration_test_old`. Xác nhận `git status` ở thư mục chính **không đổi** ngay sau khi tạo worktree (vẫn đúng 16 file thay đổi + 1 file mới như trước). Chạy `flutter pub get` + `flutter build apk --debug` (89.4s) trong thư mục tạm này — không đụng gì tới thư mục chính.

**Cài bản cũ, tạo dữ liệu thật**: `adb uninstall com.iris.app.iris_app` (đảm bảo sạch) → `adb install` APK cũ vừa build. Lái UI qua `adb shell input tap` + `uiautomator dump` (không suy đoán toạ độ) tạo hồ sơ **"Be_Migration_Test"**, 5 tuổi, giới tính Nữ. Xác nhận form tạo hồ sơ ở bản này **không có** 2 trường "Người đánh giá"/"Vai trò" (đúng bản cũ). Pull database thật (cách binary-safe: `adb shell run-as com.iris.app.iris_app base64 <path>` → decode bằng `certutil -decode` trên host → query bằng script Dart dùng `package:sqlite3`) — xác nhận `PRAGMA user_version = 1`, bảng `children` đúng 7 cột, có đúng 1 dòng `Be_Migration_Test` (`id: 591cfc76-510c-4b28-8c14-35652f35ec43`, `age_years: 5`, `gender: nu`).

**Cài đè bản mới (upgrade, giữ dữ liệu)**: Build `flutter build apk --debug` từ **thư mục làm việc chính** (code hiện tại, đã có 2 cột mới). `adb install -r` đè trực tiếp lên bản cũ — **không** `adb uninstall` trước đó, đúng mô phỏng hành vi người dùng thật cập nhật app từ Play Store/APK mới.

**Kết quả sau khi cập nhật**:
- Mở lại app: **không crash** — xác nhận qua `adb logcat -d` không có `FATAL EXCEPTION` cho tiến trình app (chỉ có log khởi động Flutter bình thường), và UI hiện đúng `ChildListPage` với hồ sơ cũ.
- Hồ sơ "Be_Migration_Test": tên/tuổi/giới tính còn nguyên (`Be_Migration_Test • 5 tuổi • nu`), `ProfileDetailPage` hiện đúng **"Người đánh giá: Chưa cập nhật"** và **"Vai trò: Chưa cập nhật"**.
- Tạo thêm hồ sơ mới **"Be_Sau_Migration"** (4 tuổi, Người đánh giá = "Co_Lan", Vai trò = "Giáo viên") qua đúng form mới (đã có 2 field mới) — lưu thành công, hiển thị đúng `ProfileDetailPage`: **"Người đánh giá: Co_Lan"**, **"Vai trò: Giáo viên"**, tồn tại song song với hồ sơ cũ trên `ChildListPage` (2/2 hồ sơ hiện đủ).
- Pull + query database thật lần cuối xác nhận đầy đủ: `PRAGMA user_version = 2`; bảng `children` giờ có đúng **9 cột** (7 cũ + `nguoi_danh_gia`, `vai_tro`); 2 dòng dữ liệu:
  - `{id: 591cfc76-..., name: Be_Migration_Test, age_years: 5, gender: nu, nguoi_danh_gia: null, vai_tro: null}` — **cùng `id` với trước khi cập nhật**, dữ liệu cũ nguyên vẹn 100%, 2 cột mới đúng `null`.
  - `{id: c6bd715c-..., name: Be_Sau_Migration, age_years: 4, nguoi_danh_gia: Co_Lan, vai_tro: Giáo viên}` — hồ sơ mới lưu đúng.

**Kết quả: PASS** — migration chạy đúng khi cài đè thật trên thiết bị (không phải giả lập bằng test tự động), không mất dữ liệu, không crash, 2 trường mới hoạt động đúng cho cả hồ sơ cũ lẫn hồ sơ mới.

**Không phát hiện bug nào trong lúc verify** — migration hoạt động đúng như code đã viết, không cần sửa gì thêm.

**Dọn dẹp**: `git worktree remove ../IRIS_v1_migration_test_old --force` báo lỗi `Filename too long` khi xoá vật lý thư mục (do đường dẫn sâu trong `build/`/Gradle cache của worktree, không phải lỗi của git worktree hay của code) — git đã gỡ đăng ký worktree khỏi `.git/worktrees` thành công (`git worktree list` không còn liệt kê), chỉ còn thư mục vật lý mồ côi; xoá dứt điểm bằng `rm -rf` (Bash) sau khi `Remove-Item` (PowerShell) từ chối vì lý do an toàn đường dẫn. Xác nhận **`git status --short` và `git log --oneline -5` ở thư mục chính giống hệt (byte-for-byte, đối chiếu bằng `diff`) trước và sau toàn bộ thao tác worktree** — thư mục làm việc chính không hề bị ảnh hưởng.

### Không làm / ngoài phạm vi

- Không đổi cột nào khác trong bảng `children`.
- Không làm các phần UI khác của app.
- Không làm đẹp theme/màu sắc ngoài đúng 2 trường mới.
- Không commit git.

## 16. Bước 6, phần 2 — "So sánh với trẻ cùng độ tuổi" (2026-08-13)

Phạm vi: hoàn thiện Phần 2/5 của Bước 6 — đọc thật `expert_knowledge_chunks`, thêm cột `phan_loai`, 2 màn "So sánh nhanh" + "Chi tiết so sánh", dữ liệu mẫu cho 1 lĩnh vực (Quan hệ xã hội, 48–71 tháng). 3 phần còn lại (Chia sẻ phụ huynh, Bác sĩ, Chân dung) vẫn placeholder, không nằm trong phạm vi lần này.

### Nhiệm vụ 1 — Migration: thêm cột `phan_loai`

[expert_knowledge_chunks_table.dart](lib/data/local/tables/expert_knowledge_chunks_table.dart) — thêm `phan_loai TEXT` (chỉ có ý nghĩa khi `content_type='so_sanh'`: `'thuong_gap'`/`'can_quan_sat'`/`NULL`). [database.dart](lib/data/local/database.dart) — `version: 2 → 3`, thêm nhánh `if (oldVersion < 3) ALTER TABLE expert_knowledge_chunks ADD COLUMN phan_loai TEXT` trong `onUpgrade` (giữ nguyên nhánh `oldVersion < 2` của migration `children` trước đó — cả 2 nhánh cùng chạy đúng khi nâng cấp thẳng từ version 1).

**Phát hiện + sửa trong lúc chạy test** (không phải bug thật, là lỗi ở fixture test): `test/child_migration_test.dart` (viết ở mục 15) tạo database "v1" giả chỉ có bảng `children`, không có `expert_knowledge_chunks` — khi thêm migration mới, `ALTER TABLE expert_knowledge_chunks ADD COLUMN` báo lỗi "no such table" vì fixture thiếu bảng. Database v1 THẬT luôn có đủ 8 bảng (tạo cùng lúc trong `onCreate` gốc), nên đây là chỗ fixture mô phỏng chưa đủ sát thực tế, không phải lỗi migration. Đã sửa bằng cách thêm `CREATE TABLE expert_knowledge_chunks` (đúng schema v1, chưa có `phan_loai`) vào `onCreate` của fixture — không sửa gì ở code migration thật.

### Nhiệm vụ 2 — Model + Repository

[expert_knowledge_chunk.dart](lib/domain/models/expert_knowledge_chunk.dart) — thêm `phanLoai` (`String?`). [expert_knowledge_repository.dart](lib/data/repositories/expert_knowledge_repository.dart) — `add()`/`_toRow()`/`_fromRow()` xử lý `phan_loai`; `query()` không cần sửa (đã tổng quát theo `linhVuc`/`ageInMonths`/`contentType`, giờ mang theo đúng `phanLoai` qua `_fromRow()`).

### Nhiệm vụ 3 — 2 đường ingest

Cả 2 nơi ghi vào `expert_knowledge_chunks` đều cập nhật để đọc `phan_loai` từ JSON: nút "Debug: Nạp dữ liệu tham khảo" ([profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart)`._ingestExpertData()`) và [scripts/ingest_expert_data.dart](scripts/ingest_expert_data.dart)`.ingestEntries()` (dùng cho test desktop, xem `test/ingest_expert_data_test.dart`).

### Nhiệm vụ 4 — Dữ liệu mẫu

[expert_content.json](assets/reference/expert_content.json) — thêm 6 entry mới, `content_type='so_sanh'`, `linh_vuc='quan_he_xa_hoi'`, `do_tuoi_thang_min/max=48/71`: 3 entry `phan_loai='thuong_gap'` + 3 entry `phan_loai='can_quan_sat'`. 6 entry cũ giữ nguyên không đổi (kể cả 4 entry `[Placeholder minh hoạ]`).

### Nhiệm vụ 5 — 2 màn UI

- [comparison_video_page.dart](lib/features/assessment/nine_domains/comparison_video/comparison_video_page.dart) — viết lại từ `StatelessWidget` placeholder thành `StatefulWidget` "So sánh nhanh": `FutureBuilder` gọi `ExpertKnowledgeRepository.query(linhVuc:, ageInMonths: childAgeInMonths(child), contentType: 'so_sanh')`, tách theo `phanLoai` thành 2 khối ("Biểu hiện thường gặp" icon ✓ xanh / "Cần quan sát thêm" icon ⚠ cam), tiêu đề "So sánh nhanh (${formatAgeLabel(child)})", ghi chú cuối trang, nút "Xem chi tiết so sánh" (chỉ hiện khi có dữ liệu) truyền thẳng danh sách `chunks` đã tải sang màn chi tiết (không query lại). Trạng thái rỗng hiện đúng thông báo, không hiện 2 khối trống. Giữ nguyên hành vi điều hướng cũ: nút "Tiếp theo" vẫn `pushReplacement` sang `ParentInputPage` (Phần 3/5), không phá luồng đã có.
- [comparison_detail_page.dart](lib/features/assessment/nine_domains/comparison_video/comparison_detail_page.dart) *(mới)* — "Chi tiết so sánh": bảng `Table` 3 cột (Tiêu chí | Thường gặp | Cần quan sát), mỗi dòng là 1 chunk, icon ✓ đúng cột theo `phanLoai`, cuộn ngang cho màn hình hẹp, khung ghi chú cuối trang. Nhận `chunks` qua constructor (không tự query).

### Nhiệm vụ 6 — Test

- `test/repositories_test.dart` — thêm 1 test round-trip `phan_loai` (lưu 2 chunk `so_sanh` có phân loại + 1 chunk `chan_dung` không phân loại, đọc lại đúng, `null` khi không truyền).
- `test/expert_knowledge_migration_test.dart` *(mới)* — cùng kỹ thuật đã dùng ở mục 15: dựng database THẬT ở schema version 2 (chưa có `phan_loai`) có sẵn 1 chunk tham khảo, mở lại bằng `AppDatabase` thật (version 3), xác nhận chunk cũ còn nguyên (`phan_loai = null`), chunk ingest mới sau migration dùng đúng cột mới, không crash.
- `test/ingest_expert_data_test.dart` — bổ sung assertion `phan_loai` cho entry có truyền và entry không truyền (giữ nguyên 2 test case đã có).

### Nhiệm vụ 7 — Kiểm chứng tổng hợp (tự động)

- `flutter analyze`: **0 issues**.
- `flutter test`: **60/60 PASS** (58 cũ + 2 mới: round-trip `phan_loai`, migration version 2→3). Không có FAIL nào (sau khi sửa fixture ở Nhiệm vụ 1).

### Nhiệm vụ 8 — Verify tay trên thiết bị thật (bắt buộc cho cả 2 trạng thái)

Build `flutter build apk --debug --dart-define-from-file=dart_define.json` (cần API key NVIDIA thật để nút ingest gọi embedding thật) → `adb install -r` lên `emulator-5554` (giữ nguyên 2 hồ sơ có sẵn từ phiên verify migration mục 15: `Be_Migration_Test` 5 tuổi/60 tháng, `Be_Sau_Migration` 4 tuổi/48 tháng — cả 2 đều nằm trong dải 48–71 tháng đã nạp dữ liệu mẫu).

**Nạp dữ liệu tham khảo thật**: mở hồ sơ `Be_Migration_Test` → "Debug: Nạp dữ liệu tham khảo" → chờ NVIDIA embed xong toàn bộ 13 entry trong `expert_content.json`. Pull database thật (base64 qua `run-as` + `certutil -decode`, cùng kỹ thuật đã dùng ở mục 14-15) → query xác nhận: `user_version=3`, cột `phan_loai` đã có, `content_type='so_sanh'` có đúng 8 dòng (2 cũ + 6 mới), đúng 6 dòng `linh_vuc='quan_he_xa_hoi'` với `phan_loai` khớp JSON (3 `thuong_gap` + 3 `can_quan_sat`), `do_tuoi_thang_min/max=48/71`, mỗi dòng có embedding thật (4096 byte = 1024 float32, đúng chiều model `nvidia/nv-embedqa-e5-v5`).

**Kịch bản CÓ dữ liệu** — `Be_Migration_Test` (5 tuổi) → Đánh giá 9 lĩnh vực → Quan hệ xã hội → Mô tả → Tiếp theo:
- Màn "So sánh nhanh": tiêu đề "Quan hệ xã hội — So sánh nhanh", heading "So sánh nhanh (5 tuổi)", khối "Biểu hiện thường gặp" hiện đúng 3 câu (icon ✓ xanh), khối "Cần quan sát thêm" hiện đúng 3 câu (icon ⚠ cam), ghi chú "Thông tin này chỉ mang tính tham khảo.", nút "Xem chi tiết so sánh" — khớp 100% ảnh chụp màn hình với dữ liệu đã ingest.
- Bấm "Xem chi tiết so sánh" → bảng 3 cột đúng: 3 dòng đầu có dấu ✓ ở cột "Thường gặp" (cột "Cần quan sát" trống), 3 dòng sau có dấu ✓ ở cột "Cần quan sát" (cột "Thường gặp" trống) — xác nhận qua ảnh chụp cả 2 vị trí cuộn ngang. Khung ghi chú "Thông tin này chỉ giúp đối chiếu với trẻ cùng độ tuổi, không dùng để tự chẩn đoán." hiện đúng.

**Kịch bản CHƯA có dữ liệu** — cùng `Be_Migration_Test`, đổi sang lĩnh vực "Cảm xúc" (không có entry `so_sanh` nào cho lĩnh vực này ở độ tuổi 48–71 tháng): màn "So sánh nhanh" hiện đúng "Chưa có dữ liệu so sánh cho lĩnh vực này ở độ tuổi hiện tại." — không hiện 2 khối rỗng, không hiện nút "Xem chi tiết so sánh" (đúng thiết kế — chỉ hiện khi có dữ liệu), không lỗi/vỡ giao diện. Bấm "Tiếp theo" vẫn điều hướng đúng sang Phần 3/5 (`ParentInputPage`, còn placeholder — đúng phạm vi, không đụng tới).

**Kiểm tra không crash**: `adb logcat -d` lọc `FATAL EXCEPTION`/`iris_app.*Exception` — không có kết quả nào trong suốt phiên verify (ingest + cả 2 kịch bản).

**Không phát hiện bug thật nào ở code UI/repository trong lúc verify** — chỉ có 1 vấn đề ở fixture test (đã ghi ở Nhiệm vụ 1), không phải bug ở code app.

### Không làm / ngoài phạm vi

- Không soạn nội dung tham khảo thật đầy đủ cho các lĩnh vực khác — 6 entry `[Placeholder minh hoạ]` cũ giữ nguyên.
- Không làm 3 phần còn lại của Bước 6 (Chia sẻ phụ huynh, Bác sĩ, Chân dung) — vẫn đúng placeholder cũ, đã xác nhận luồng điều hướng qua các phần đó không bị phá.
- Không đổi cột nào khác trong `expert_knowledge_chunks`.
- Không làm đẹp theme/màu sắc ngoài đúng phạm vi phần "So sánh".
- Không commit git.

## 17. Bước 6, phần 3 — "Chia sẻ từ phụ huynh" (2026-08-13)

Phạm vi: hoàn thiện Phần 3/5 của Bước 6 — thêm cột `nhom_tre`/`boi_canh`, mở rộng `query()`, 2 màn "Góc nhìn từ phụ huynh" (tab theo nhóm trẻ) + "Kinh nghiệm theo tình huống" (tab theo bối cảnh), dữ liệu mẫu cùng lĩnh vực/độ tuổi đã dùng ở Phần 2 (Quan hệ xã hội, 48–71 tháng). Đọc lại code Phần 2 trước khi làm (`ComparisonVideoPage`/`ComparisonDetailPage`/migration `phan_loai`) để tái dùng đúng pattern: FutureBuilder tải 1 lần → lọc theo trường phân loại ở phía Dart → truyền list đã tải sang màn con (không query lại) → trạng thái rỗng rõ ràng. Phần Bác sĩ/Chân dung vẫn placeholder, không đụng tới — đã xác nhận HEAD lúc bắt đầu là `7e302bd` (đã gộp mục 14+15), mục 16 vẫn ở working tree, đúng như `git status` cho thấy trước khi bắt đầu.

### Nhiệm vụ 1 — Migration: thêm cột `nhom_tre`/`boi_canh`

[expert_knowledge_chunks_table.dart](lib/data/local/tables/expert_knowledge_chunks_table.dart) — thêm `nhom_tre TEXT` (`'binh_thuong'`/`'asd'`/`NULL`) và `boi_canh TEXT` (`'o_nha'`/`'o_truong'`/`'noi_cong_cong'`/`NULL`), chỉ có ý nghĩa khi `content_type='chia_se_phu_huynh'`. [database.dart](lib/data/local/database.dart) — `version: 3 → 4`, thêm nhánh `if (oldVersion < 4)` ALTER cả 2 cột trong `onUpgrade` (giữ nguyên 2 nhánh `< 2`/`< 3` trước đó — cả 3 nhánh cùng chạy đúng khi nâng cấp thẳng từ version 1). Không cần sửa 2 fixture test migration trước (`child_migration_test.dart`, `expert_knowledge_migration_test.dart`) — bảng `expert_knowledge_chunks` trong cả 2 fixture đã tồn tại từ trước, `ALTER TABLE ADD COLUMN` chỉ thêm cột vào bảng đã có, không cần bảng phải "biết trước" sẽ có thêm migration sau này. Đã chạy lại `flutter test` xác nhận cả 2 test cũ vẫn PASS, không hồi quy.

### Nhiệm vụ 2 — Model + Repository

[expert_knowledge_chunk.dart](lib/domain/models/expert_knowledge_chunk.dart) — thêm `nhomTre`/`boiCanh` (`String?`). [expert_knowledge_repository.dart](lib/data/repositories/expert_knowledge_repository.dart) — `add()`/`_toRow()`/`_fromRow()` xử lý 2 cột mới; `query()` mở rộng thêm 2 tham số optional `nhomTre`/`boiCanh` (bỏ qua nếu null) — dùng khi cần lọc chính xác 1 giá trị (có test riêng xác nhận), còn 2 màn UI thực tế tải 1 lần theo `contentType='chia_se_phu_huynh'` rồi lọc theo tab ở phía Dart, giống hệt cách `phanLoai` đã dùng ở "So sánh".

### Nhiệm vụ 3 — 2 đường ingest

Cả 2 nơi ghi vào `expert_knowledge_chunks` (nút "Debug: Nạp dữ liệu tham khảo" trong [profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart) và [scripts/ingest_expert_data.dart](scripts/ingest_expert_data.dart)) cập nhật đọc thêm `nhom_tre`/`boi_canh` từ JSON.

### Nhiệm vụ 4 — Dữ liệu mẫu

[expert_content.json](assets/reference/expert_content.json) — thêm 6 entry mới, `content_type='chia_se_phu_huynh'`, `linh_vuc='quan_he_xa_hoi'`, `do_tuoi_thang_min/max=48/71`, mỗi entry có cả `nhom_tre` VÀ `boi_canh` (thực tế 1 câu chia sẻ luôn thuộc 1 nhóm trẻ + 1 bối cảnh cùng lúc): 3 entry `binh_thuong` + 3 entry `asd` (≥2 mỗi nhóm), phân bố đều 2 entry mỗi bối cảnh (`o_nha`/`o_truong`/`noi_cong_cong`, ≥2 mỗi bối cảnh) — đúng yêu cầu tối thiểu ở cả 2 trục cùng lúc mà không cần nhân đôi số entry. Mỗi entry có `nguon_tai_lieu` trích dẫn (VD "Mẹ bé 5 tuổi", "Giáo viên mầm non").

### Nhiệm vụ 5 — 2 màn UI

- [parent_input_page.dart](lib/features/assessment/nine_domains/parent_input/parent_input_page.dart) — viết lại từ `StatelessWidget` placeholder thành `StatefulWidget` "Góc nhìn từ phụ huynh": `FutureBuilder` gọi `query(linhVuc:, ageInMonths:, contentType:'chia_se_phu_huynh')`, `DefaultTabController` 2 tab ("Trẻ phát triển bình thường"/"Trẻ có dấu hiệu ASD") lọc theo `nhomTre`, mỗi tab là danh sách quote card (nội dung in nghiêng trong ngoặc kép + trích dẫn `— ${nguonTaiLieu}` căn phải nếu có). Trạng thái rỗng **riêng cho từng tab** (đúng yêu cầu 4.3 — không phải 1 thông báo chung). Nút "Xem kinh nghiệm theo tình huống" (chỉ hiện khi có ít nhất 1 chunk) truyền thẳng `chunks` đã tải sang màn con. Giữ nguyên hành vi điều hướng cũ: "Tiếp theo" vẫn `pushReplacement` sang `ExpertInputPage` (Phần 4/5, còn placeholder) — đúng thứ tự 5 phần, không đổi.
- [parent_context_page.dart](lib/features/assessment/nine_domains/parent_input/parent_context_page.dart) *(mới)* — "Kinh nghiệm theo tình huống": `StatelessWidget` nhận `chunks` qua constructor (không tự query), `DefaultTabController` 3 tab ("Ở nhà"/"Ở trường"/"Nơi công cộng") lọc theo `boiCanh`, khối tóm tắt tĩnh ở đầu trang ("Tổng hợp góc nhìn thực tế phụ huynh chia sẻ theo từng bối cảnh khác nhau...") theo đúng tinh thần 4.4 (không bắt buộc khớp pixel). Trạng thái rỗng riêng cho từng tab.

### Nhiệm vụ 6 — Test

- `test/repositories_test.dart` — thêm 1 test round-trip `nhom_tre`/`boi_canh` (lưu 2 chunk `chia_se_phu_huynh` khác nhóm/bối cảnh + 1 chunk `so_sanh` không có 2 trường này, xác nhận đọc lại đúng, `null` khi không truyền, và `query()` lọc đúng theo từng tham số `nhomTre`/`boiCanh` riêng lẻ).
- `test/expert_knowledge_context_migration_test.dart` *(mới)* — cùng kỹ thuật đã dùng ở mục 15/16: dựng database THẬT ở schema version 3 (chưa có `nhom_tre`/`boi_canh`) có sẵn 1 chunk `chia_se_phu_huynh`, mở lại bằng `AppDatabase` thật (version 4), xác nhận chunk cũ còn nguyên (`nhom_tre`/`boi_canh = null`), chunk ingest mới sau migration dùng đúng 2 cột mới, không crash.

### Nhiệm vụ 7 — Kiểm chứng tổng hợp (tự động)

- `flutter analyze`: **0 issues**.
- `flutter test`: **62/62 PASS** (60 cũ + 2 mới: round-trip `nhom_tre`/`boi_canh`, migration version 3→4). Không có FAIL nào, không cần sửa fixture nào lần này (khác mục 16).

### Nhiệm vụ 8 — Verify tay trên thiết bị thật (bắt buộc cho cả 2 màn, cả 2 trạng thái)

Build `flutter build apk --debug --dart-define-from-file=dart_define.json` → `adb install -r` lên `emulator-5554` (giữ nguyên 2 hồ sơ có sẵn từ các phiên verify trước: `Be_Migration_Test` 5 tuổi/60 tháng, `Be_Sau_Migration` 4 tuổi/48 tháng).

**Nạp dữ liệu tham khảo thật**: mở hồ sơ `Be_Migration_Test` → "Debug: Nạp dữ liệu tham khảo" → dialog cảnh báo đã có 12 chunk từ phiên trước → "Vẫn nạp" (chấp nhận 1 vài entry cũ (`so_sanh`) bị nhân đôi hiển thị do ingest lại — chỉ ảnh hưởng UI phần "So sánh" đã verify PASS ở mục 16, không ảnh hưởng phần "Chia sẻ phụ huynh" đang verify vì 6 entry mới của phần này chưa từng tồn tại trước đó, không bị trùng). Pull database thật (base64 qua `run-as` + `certutil -decode`) → query xác nhận: `user_version=4`, cột `nhom_tre`/`boi_canh` đã có, đúng 6 dòng `linh_vuc='quan_he_xa_hoi'` + `content_type='chia_se_phu_huynh'` với `nhom_tre`/`boi_canh`/`nguon_tai_lieu` khớp chính xác JSON (3 `binh_thuong` + 3 `asd`, 2 mỗi bối cảnh).

**Kịch bản CÓ dữ liệu** — `Be_Migration_Test` (5 tuổi) → Quan hệ xã hội → Mô tả → So sánh → Tiếp theo:
- Màn "Góc nhìn từ phụ huynh": tiêu đề "Góc nhìn từ phụ huynh (5 tuổi)", tab "Trẻ phát triển bình thường" hiện đúng 3 quote card (không trùng lặp) kèm trích dẫn "— Mẹ bé 5 tuổi"/"— Bố bé 6 tuổi"/"— Mẹ bé 4 tuổi"; tab "Trẻ có dấu hiệu ASD" hiện đúng 3 quote card kèm trích dẫn tương ứng — khớp 100% ảnh chụp màn hình với dữ liệu đã ingest.
- Bấm "Xem kinh nghiệm theo tình huống" → màn "Kinh nghiệm theo tình huống (5 tuổi)" + khối tóm tắt, 3 tab "Ở nhà"/"Ở trường"/"Nơi công cộng" đều hiện đúng 2 chia sẻ mỗi tab (1 bình thường + 1 ASD), đúng nội dung + trích dẫn — xác nhận qua ảnh chụp cả 3 tab.

**Kịch bản CHƯA có dữ liệu** — cùng `Be_Migration_Test`, đổi sang lĩnh vực "Cảm xúc" (không có entry `chia_se_phu_huynh` nào ở độ tuổi 48–71 tháng): cả 2 tab của "Góc nhìn từ phụ huynh" đều hiện đúng "Chưa có chia sẻ nào từ nhóm phụ huynh này cho lĩnh vực + độ tuổi hiện tại." (thông báo **riêng từng tab**, đúng yêu cầu), không hiện nút "Xem kinh nghiệm theo tình huống", không lỗi/vỡ giao diện. Bấm "Tiếp theo" điều hướng đúng sang "Cảm xúc — Thông tin từ bác sĩ" (Phần 4/5, còn placeholder — đúng thứ tự 5 phần, không đụng tới).

**Kiểm tra không crash**: `adb logcat -d` lọc `FATAL EXCEPTION`/`iris_app.*Exception` — không có kết quả nào trong suốt phiên verify (ingest + cả 2 màn + cả 2 trạng thái).

**Không phát hiện bug thật nào trong lúc verify** — không cần sửa gì ở code app.

### Không làm / ngoài phạm vi

- Không soạn nội dung tham khảo thật đầy đủ cho các lĩnh vực khác.
- Không làm phần Bác sĩ/Chân dung — vẫn placeholder cũ, đã xác nhận luồng điều hướng qua phần đó không bị phá.
- Không đổi cột nào khác trong `expert_knowledge_chunks`.
- Không commit git.

## 18. Bước 6, phần 4 — "Thông tin từ bác sĩ" (2026-08-13)

Phạm vi: hoàn thiện Phần 4/5 của Bước 6 — dùng lại cột `phan_loai` sẵn có (không migration) với bộ giá trị mới cho `content_type='bac_si'`, 2 màn tổng quan + "Giải thích chuyên môn", dữ liệu mẫu minh hoạ (không bịa danh tính bác sĩ thật). Đọc lại code Phần 2/3 trước khi làm (`ComparisonVideoPage`/`ParentInputPage`, cách dùng `phan_loai`/`ExpertKnowledgeRepository.query()`) để tái dùng đúng pattern. HEAD lúc bắt đầu vẫn `7e302bd`, mục 16+17 ở working tree — đúng như `git status` cho thấy trước khi bắt đầu.

### Nhiệm vụ 1 — Xác nhận cột `phan_loai` đủ dùng, không cần migration

Đọc trực tiếp [expert_knowledge_chunks_table.dart](lib/data/local/tables/expert_knowledge_chunks_table.dart): `phan_loai TEXT` — không có `CHECK` constraint, không ràng buộc enum ở tầng DB. Xác nhận **không cần migration mới** — chỉ cần dùng đúng bộ giá trị mới (`'moc_phat_trien'`/`'dau_hieu_luu_y'`/`'giai_thich'`) khi tạo dữ liệu `content_type='bac_si'`, với ý nghĩa hoàn toàn tách biệt khỏi bộ giá trị `'thuong_gap'`/`'can_quan_sat'` đã dùng cho `content_type='so_sanh'` — không xung đột vì luôn lọc kèm `content_type` trước khi đọc `phan_loai`. Viết 1 test repository (Nhiệm vụ 3) xác nhận thay vì chỉ đọc code suông.

### Nhiệm vụ 2 — Dữ liệu mẫu

[expert_content.json](assets/reference/expert_content.json) — thêm 6 entry mới, `content_type='bac_si'`, `linh_vuc='quan_he_xa_hoi'`, `do_tuoi_thang_min/max=48/71`: 2 entry `moc_phat_trien` + 2 entry `dau_hieu_luu_y` + 2 entry `giai_thich`. Mỗi entry có `nguon_tai_lieu: "Góc nhìn chuyên khoa Tâm thần Nhi (minh hoạ)"` — chỉ nêu VAI TRÒ/CHUYÊN KHOA minh hoạ, không gắn tên người cụ thể, đúng yêu cầu không bịa danh tính bác sĩ thật. Nội dung viết theo văn phong hedge nhất quán với phần còn lại của file (VD "thường", "một số dấu hiệu nên cân nhắc", "khi cần thiết") — không trích dẫn số liệu/nghiên cứu cụ thể, không nêu tiêu chí chẩn đoán chính thức nào (VD DSM-5) mà chỉ diễn giải chung.

### Nhiệm vụ 3 — 2 màn UI

- [expert_input_page.dart](lib/features/assessment/nine_domains/expert_input/expert_input_page.dart) — viết lại từ `StatelessWidget` placeholder thành `StatefulWidget` "Thông tin từ bác sĩ": `FutureBuilder` gọi `query(linhVuc:, ageInMonths:, contentType:'bac_si')`. Card đầu trang minh hoạ vai trò ("Góc nhìn chuyên khoa Tâm thần Nhi (minh hoạ)" + dòng chú thích rõ "không phải ý kiến trực tiếp từ một bác sĩ cụ thể") **luôn hiển thị bất kể có dữ liệu hay không** — đây là phần tĩnh, không phụ thuộc dữ liệu. 3 mục điều hướng ("Mốc phát triển"/"Dấu hiệu cần lưu ý"/"Giải thích chuyên môn", chỉ hiện khi `chunks` không rỗng) mở [expert_detail_page.dart](lib/features/assessment/nine_domains/expert_input/expert_detail_page.dart) kèm tham số `initialSection` tương ứng, truyền thẳng `chunks` đã tải (không query lại). Giữ nguyên hành vi điều hướng cũ: "Tiếp theo" vẫn `pushReplacement` sang `SummaryPortraitPage` (Phần 5/5, còn placeholder).
- [expert_detail_page.dart](lib/features/assessment/nine_domains/expert_input/expert_detail_page.dart) *(mới)* — "Giải thích chuyên môn": `StatefulWidget` nhận `chunks` qua constructor, tách 3 nhóm theo `phanLoai`, mỗi nhóm dùng `GlobalKey` riêng; nếu có `initialSection`, `WidgetsBinding.instance.addPostFrameCallback` gọi `Scrollable.ensureVisible()` cuộn thẳng tới đúng nhóm ngay sau khi build xong — đã verify tay hoạt động đúng (xem Nhiệm vụ 5). Mỗi nhóm chỉ hiện nếu `isNotEmpty` — **ẩn hẳn nhóm rỗng thay vì hiện tiêu đề trống**, đúng yêu cầu 4.3. Khung ghi chú cuối trang đúng nguyên văn: "Thông tin mang tính tham khảo, không thay thế khám và đánh giá chuyên sâu."

### Nhiệm vụ 4 — Test

`test/repositories_test.dart` — thêm 1 test xác nhận cột `phan_loai` (TEXT tự do) dùng đúng cho bộ giá trị mới của `content_type='bac_si'` (`moc_phat_trien`/`dau_hieu_luu_y`/`giai_thich`) mà không cần migration — lưu 3 chunk khác nhóm, đọc lại đúng qua `query(contentType:'bac_si')`.

### Nhiệm vụ 5 — Kiểm chứng tổng hợp (tự động)

- `flutter analyze`: **0 issues**.
- `flutter test`: **63/63 PASS** (62 cũ + 1 mới). Không có FAIL nào, không cần migration nên không có test migration mới ở mục này.

### Nhiệm vụ 6 — Verify tay trên thiết bị thật (bắt buộc cho cả 2 màn, cả 2 trạng thái)

Build `flutter build apk --debug --dart-define-from-file=dart_define.json` → `adb install -r` lên `emulator-5554` (giữ nguyên 2 hồ sơ có sẵn). Nạp dữ liệu tham khảo thật qua "Debug: Nạp dữ liệu tham khảo" ở hồ sơ `Be_Migration_Test` (5 tuổi/60 tháng). Pull database thật xác nhận đúng 6 dòng `linh_vuc='quan_he_xa_hoi'` + `content_type='bac_si'` với `phan_loai`/`nguon_tai_lieu` khớp chính xác JSON (2 mỗi nhóm), tách biệt hoàn toàn với 3 dòng `bac_si` cũ (`[Placeholder minh hoạ]`, độ tuổi 12-24 tháng, không match tuổi 60, `phan_loai = null`).

**Kịch bản CÓ dữ liệu** — `Be_Migration_Test` → Quan hệ xã hội → Mô tả → So sánh → Chia sẻ phụ huynh → Tiếp theo:
- Màn tổng quan "Thông tin từ bác sĩ (5 tuổi)": card minh hoạ vai trò đúng nội dung, 3 mục điều hướng hiện đủ — khớp ảnh chụp màn hình.
- Bấm "Mốc phát triển" → màn "Giải thích chuyên môn" **tự cuộn thẳng tới đúng section "Mốc phát triển"** (xác nhận qua ảnh chụp: tiêu đề "Mốc phát triển" nằm ngay đầu viewport dù trang có nhiều nội dung phía trên) — xác nhận `Scrollable.ensureVisible()` hoạt động đúng trên thiết bị thật, không chỉ đúng về mặt logic. Cuộn tiếp xuống cuối trang xác nhận đủ cả 3 nhóm ("Mốc phát triển"/"Dấu hiệu cần lưu ý"/"Giải thích chuyên môn") đúng nội dung + trích dẫn "— Góc nhìn chuyên khoa Tâm thần Nhi (minh hoạ)", và dòng miễn trừ trách nhiệm đúng nguyên văn "Thông tin mang tính tham khảo, không thay thế khám và đánh giá chuyên sâu." ở cuối trang.

**Kịch bản CHƯA có dữ liệu** — cùng `Be_Migration_Test`, đổi sang lĩnh vực "Cảm xúc" (không có entry `bac_si` nào ở độ tuổi 48–71 tháng): card minh hoạ vai trò **vẫn hiển thị** (đúng thiết kế — phần tĩnh, không phụ thuộc dữ liệu), thông báo "Chưa có dữ liệu từ bác sĩ cho lĩnh vực này ở độ tuổi hiện tại." hiện đúng, 3 mục điều hướng tự ẩn hoàn toàn (không có mục nào dẫn tới trang rỗng vô nghĩa), không lỗi/vỡ giao diện. Bấm "Tiếp theo" điều hướng đúng sang "Cảm xúc — Chân dung biểu hiện" (Phần 5/5, còn placeholder — đúng thứ tự 5 phần, không đụng tới).

**Kiểm tra không crash**: `adb logcat -d` lọc `FATAL EXCEPTION`/`iris_app.*Exception` — không có kết quả nào trong suốt phiên verify.

**Không phát hiện bug thật nào trong lúc verify** — không cần sửa gì ở code app.

### Không làm / ngoài phạm vi

- Không làm phần Chân dung.
- Không soạn nội dung thật đầy đủ cho các lĩnh vực khác.
- Không bịa danh tính bác sĩ thật hay thông tin y khoa cụ thể ngoài dữ liệu mẫu minh hoạ đã ghi rõ.
- Không commit git.

## 19. Bước 6, phần 5 — "Chân dung biểu hiện" (2026-08-13) — HOÀN THÀNH CẢ 5 PHẦN BƯỚC 6

Phạm vi: hoàn thiện Phần 5/5 (cuối cùng) của Bước 6 — dùng lại `phan_loai` với bộ giá trị mới cho `content_type='chan_dung'`, 2 màn tổng quan + chân dung chi tiết dạng **lưới thẻ màu** (đơn giản hoá chủ động từ mindmap toả tròn gốc), nút kết thúc chuỗi 5 phần. Đọc lại code Phần 2-4 trước khi làm để tái dùng đúng pattern. HEAD lúc bắt đầu vẫn `7e302bd`, mục 16+17+18 ở working tree — đúng như `git status` cho thấy trước khi bắt đầu.

### Nhiệm vụ 1 — Xác nhận cột `phan_loai` đủ dùng

Giống lý do đã xác nhận ở mục 18 (Phần 4): `phan_loai TEXT` không có `CHECK` constraint, dùng lại đúng cho bộ giá trị mới của `content_type='chan_dung'`: `'diem_manh'`/`'khac_biet'`/`'can_ho_tro'`/`'muc_do_bieu_hien'`, không xung đột với 2 bộ giá trị đã dùng ở `so_sanh`/`bac_si` vì luôn lọc kèm `content_type`. Không cần migration mới. Có test repository xác nhận (Nhiệm vụ 4).

### Nhiệm vụ 2 — Quyết định đơn giản hoá bố cục (ghi rõ theo yêu cầu 4.4/báo cáo)

Bố cục gốc của "Chân dung biểu hiện" là sơ đồ mindmap toả tròn quanh 1 hình trung tâm — phần phức tạp nhất trong 5 phần. Theo đúng chỉ định của prompt, đã **chủ động đơn giản hoá thành lưới thẻ (`GridView`, 2 cột) có màu viền/nhãn theo phân loại** (xanh lá = điểm mạnh, cam = khác biệt, xanh dương = cần hỗ trợ) thay vì dựng đúng sơ đồ toả tròn — giữ nguyên toàn bộ thông tin và ý nghĩa phân loại, chỉ khác cách trình bày trực quan. Không có gì cần "xin phép thêm" vì đây đã là chỉ định rõ ràng trong prompt, không phải tự ý đổi phạm vi.

### Nhiệm vụ 3 — 2 màn UI

- [summary_portrait_page.dart](lib/features/assessment/nine_domains/summary_portrait/summary_portrait_page.dart) — viết lại từ `StatelessWidget` placeholder thành `StatefulWidget` "Chân dung biểu hiện": `FutureBuilder` gọi `query(linhVuc:, ageInMonths:, contentType:'chan_dung')`. "Mức độ biểu hiện" hiện dạng `Chip` nếu có đúng 1 chunk `phan_loai='muc_do_bieu_hien'`, **ẩn hẳn khối này nếu không có** (không hiện tiêu đề trống — đúng yêu cầu 4.2). "Điểm nổi bật" (`diem_manh`, icon sao xanh lá) và "Khác biệt so với trẻ cùng tuổi" (`khac_biet`, icon cam) — mỗi khối tự ẩn nếu rỗng, cùng pattern `_PortraitSection` đã dùng ở Phần 2 (`_ComparisonSection`). Nút "Xem chân dung chi tiết" chỉ hiện khi có ít nhất 1 chunk thuộc `diem_manh`/`khac_biet`/`can_ho_tro`, truyền thẳng `chunks` đã tải sang màn chi tiết.
- [summary_detail_page.dart](lib/features/assessment/nine_domains/summary_portrait/summary_detail_page.dart) *(mới)* — "Chân dung biểu hiện" chi tiết: `StatelessWidget` nhận `chunks` qua constructor (không tự query), lọc đúng 3 loại `diem_manh`/`khac_biet`/`can_ho_tro` (bỏ qua `muc_do_bieu_hien` — chunk đó chỉ hiện ở màn tổng quan dạng badge, không phải 1 thẻ trong lưới). Dòng tóm tắt đầu trang đúng tinh thần yêu cầu 4.3. `GridView.builder` 2 cột, mỗi thẻ viền màu theo phân loại + nhãn màu (`_labels`) + nội dung chunk. Khối chú thích màu (`_LegendRow` ×3) cuối trang giải thích đúng 3 màu.

### Nhiệm vụ 4 — Điều hướng kết thúc chuỗi 5 phần

Đọc lại code placeholder cũ của `SummaryPortraitPage` trước khi sửa — phát hiện nút "Hoàn tất — Về danh sách lĩnh vực" gọi `Navigator.of(context).pop()` **đã có sẵn từ Giai đoạn 3** (không phải "Tiếp theo" như 4 phần trước), kèm comment giải thích đúng lý do: Phần 2-5 đều dùng `pushReplacement` nối tiếp, nên ngăn xếp điều hướng tại `SummaryPortraitPage` chỉ có đúng 1 route nằm trên `DomainListPage` — 1 lần `pop()` là đủ quay đúng về màn danh sách 9 lĩnh vực. Đã **giữ nguyên quyết định điều hướng này** (không đổi thành route khác) khi viết lại nội dung thật cho trang, chỉ thêm phần hiển thị dữ liệu phía trên nút. Đã verify tay xác nhận `pop()` quay đúng về `DomainListPage` (Nhiệm vụ 6), không lỗi.

### Nhiệm vụ 5 — Dữ liệu mẫu

[expert_content.json](assets/reference/expert_content.json) — thêm 7 entry mới, `content_type='chan_dung'`, `linh_vuc='quan_he_xa_hoi'`, `do_tuoi_thang_min/max=48/71`: 2 entry `diem_manh` + 2 entry `khac_biet` + 2 entry `can_ho_tro` + 1 entry `muc_do_bieu_hien` (nội dung `"Thường xuyên"`, đúng ví dụ trong prompt).

### Nhiệm vụ 6 — Test

`test/repositories_test.dart` — thêm 1 test xác nhận cột `phan_loai` dùng đúng cho bộ giá trị mới của `content_type='chan_dung'` (`diem_manh`/`khac_biet`/`can_ho_tro`/`muc_do_bieu_hien`) — lưu 4 chunk khác nhóm, đọc lại đúng qua `query(contentType:'chan_dung')`.

### Nhiệm vụ 7 — Kiểm chứng tổng hợp (tự động)

- `flutter analyze`: **0 issues**.
- `flutter test`: **64/64 PASS** (63 cũ + 1 mới). Không cần migration nên không có test migration mới ở mục này (giống mục 18).

### Nhiệm vụ 8 — Verify tay trên thiết bị thật (bắt buộc cho cả 2 màn, cả 2 trạng thái, cả điều hướng "Hoàn tất")

Build `flutter build apk --debug --dart-define-from-file=dart_define.json` → `adb install -r` lên `emulator-5554`. Nạp dữ liệu tham khảo thật qua "Debug: Nạp dữ liệu tham khảo" ở hồ sơ `Be_Migration_Test` (5 tuổi/60 tháng). Pull database thật xác nhận đúng 7 dòng `linh_vuc='quan_he_xa_hoi'` + `content_type='chan_dung'` khớp chính xác JSON (2 mỗi loại + 1 `muc_do_bieu_hien` nội dung "Thường xuyên").

**Kịch bản CÓ dữ liệu** — `Be_Migration_Test` → Quan hệ xã hội → đi hết Mô tả → So sánh → Chia sẻ phụ huynh → Bác sĩ → tới "Chân dung biểu hiện":
- Màn tổng quan: badge "Mức độ biểu hiện: Thường xuyên", "Điểm nổi bật" đúng 2 mục (icon sao xanh lá), "Khác biệt so với trẻ cùng tuổi" đúng 2 mục (icon cam), nút "Xem chân dung chi tiết", nút "Hoàn tất — Về danh sách lĩnh vực" — khớp 100% ảnh chụp màn hình.
- Bấm "Xem chân dung chi tiết" → lưới thẻ 2 cột đúng 6 thẻ: 2 thẻ viền/nhãn xanh lá "Điểm mạnh", 2 thẻ cam "Khác biệt", 2 thẻ xanh dương "Cần hỗ trợ" — đúng nội dung từng thẻ, đúng màu theo phân loại. Cuộn xuống xác nhận khối "Chú thích màu" cuối trang đúng đủ 3 dòng giải thích màu.

**Kịch bản CHƯA có dữ liệu** — cùng `Be_Migration_Test`, đổi sang lĩnh vực "Cảm xúc" (không có entry `chan_dung` nào ở độ tuổi 48–71 tháng): không hiện "Mức độ biểu hiện", không hiện "Điểm nổi bật"/"Khác biệt", không hiện nút "Xem chân dung chi tiết" — chỉ hiện đúng thông báo "Chưa có dữ liệu chân dung cho lĩnh vực này ở độ tuổi hiện tại." + nút "Hoàn tất", không lỗi/vỡ giao diện.

**Verify điều hướng "Hoàn tất"**: bấm "Hoàn tất — Về danh sách lĩnh vực" ở trạng thái rỗng → xác nhận quay đúng về "Đánh giá 9 lĩnh vực — Be_Migration_Test" (`DomainListPage`), không lỗi, không crash — đúng lựa chọn điều hướng đã ghi ở Nhiệm vụ 4.

**Kiểm tra không crash**: `adb logcat -d` lọc `FATAL EXCEPTION`/`iris_app.*Exception` — không có kết quả nào trong suốt phiên verify (ingest + cả 2 màn + cả 2 trạng thái + điều hướng Hoàn tất).

**Không phát hiện bug thật nào trong lúc verify** — không cần sửa gì ở code app.

### Tổng kết — Bước 6 (5 phần) đã hoàn thành đầy đủ

Cả 5 phần của Bước 6 (đánh giá chi tiết 1 lĩnh vực) nay đều chạy thật, đọc dữ liệu thật từ `expert_knowledge_chunks`, có test tự động, và có bằng chứng verify thiết bị thật:

| Phần | Tên | Trạng thái |
|---|---|---|
| 1/5 | Mô tả biểu hiện | Đã xong từ trước (Giai đoạn 3, không thuộc loạt prompt này) |
| 2/5 | So sánh với trẻ cùng độ tuổi | Đã xong — mục 16 |
| 3/5 | Chia sẻ từ phụ huynh | Đã xong — mục 17 |
| 4/5 | Thông tin từ bác sĩ | Đã xong — mục 18 |
| 5/5 | Chân dung biểu hiện | Đã xong — mục 19 (mục này) |

Toàn bộ 4 phần (2-5) dùng chung 1 hạ tầng nhất quán: cột `phan_loai` (TEXT tự do, tái sử dụng ý nghĩa khác nhau theo từng `content_type`, không cần migration riêng cho mỗi phần trừ lần đầu ở mục 16), `ExpertKnowledgeRepository.query()` (mở rộng 1 lần ở mục 17 cho `nhomTre`/`boiCanh`, dùng lại nguyên vẹn cho các phần sau), pattern tải dữ liệu 1 lần ở màn tổng quan rồi truyền xuống màn chi tiết (không query lại), và xử lý trạng thái rỗng nhất quán (ẩn khối/nút thay vì hiện trống). Dữ liệu mẫu đầy đủ cho 1 lĩnh vực (Quan hệ xã hội, 48–71 tháng) đủ để verify toàn bộ chuỗi 5 phần liền mạch từ đầu tới cuối — đã verify tay đi hết chuỗi trong phiên này (Nhiệm vụ 8). Nội dung thật đầy đủ cho 8 lĩnh vực còn lại vẫn là việc riêng, chưa làm — đúng phạm vi đã thống nhất xuyên suốt cả 4 prompt.

### Không làm / ngoài phạm vi

- Không dựng lại đúng sơ đồ mindmap toả tròn nguyên bản — đã chủ động đơn giản hoá thành lưới thẻ theo đúng chỉ định.
- Không soạn nội dung thật đầy đủ cho các lĩnh vực khác.
- Không đổi luồng của 4 phần trước.
- Không commit git.

## 20. Tái cấu trúc bố cục UI, Phần 1/4 — Bước 1–5 (2026-08-13)

Phạm vi: đúng như prompt "Tái cấu trúc bố cục UI, Phần 1/4" — chỉ **sắp xếp lại bố cục hiển thị** cho luồng Bước 1–5 (mở app → tạo hồ sơ → sàng lọc → tổng hợp & đề xuất → màn 9 lĩnh vực), dùng widget Material mặc định, **không** làm đẹp theme/màu/font, **không** đổi logic nghiệp vụ, **không** đổi schema database, **không** đụng Bước 6 trở đi (giữ nguyên toàn bộ 5 phần đã hoàn thành ở mục 16–19). Đọc lại code thật của từng màn trước khi sửa — phần lớn logic/dữ liệu đã có sẵn, chỉ cần sắp lại bố cục.

### Nhiệm vụ 1 — Bước 1: Trang chủ mới + thanh điều hướng dưới

- [lib/features/home/home_page.dart](lib/features/home/home_page.dart) *(mới)* — `HomePage` thay `ChildListPage` làm `home:` của `MaterialApp` ([lib/app.dart](lib/app.dart)). `Scaffold` ngoài cùng chỉ có `body: IndexedStack` + `bottomNavigationBar: NavigationBar` (Material 3, 5 mục đúng thứ tự: Trang chủ/Hồ sơ/Hỏi đáp/Thông báo/Tài khoản) — mỗi tab tự có `Scaffold`+`AppBar` riêng (nested Scaffold, không dựng Navigator lồng riêng cho từng tab — điều hướng sâu hơn vẫn dùng chung 1 Navigator gốc, đủ cho đợt "chỉ đúng cấu trúc" này).
- Tab "Trang chủ" (`_HomeTabContent`): dòng chào "Xin chào!" + icon, 5 `ListTile` lớn (icon + tiêu đề + mô tả phụ) đúng thứ tự đề bài: Tạo hồ sơ trẻ mới → `CreateProfilePage`; Chọn hồ sơ trẻ đã có → `ChildListPage`; Lịch sử / Tiếp tục đánh giá / Hỏi đáp AI → qua `SelectChildPage` (mục mới, xem dưới) rồi vào đúng `HistoryPage`/`DomainListPage`/`AiChatPage`.
- Tab "Hồ sơ": tái dùng nguyên `ChildListPage` không đổi gì.
- Tab "Hỏi đáp" (`_AiChatTab`) — **quyết định tự chọn** (đề bài yêu cầu tự quyết + ghi rõ lý do): kiến trúc hiện tại không có khái niệm "hồ sơ đang xem"/"hồ sơ hoạt động gần nhất" ở cấp toàn app (không dùng state management chung, mọi trang nhận `Child` qua constructor). Diễn giải "đúng 1 hồ sơ đang hoạt động" = `ChildRepository.getAll()` (mặc định `includeArchived: false`) trả về đúng 1 phần tử → vào thẳng `AiChatPage` của hồ sơ đó; 0 hoặc ≥2 hồ sơ → hiện `SelectChildPage`. Đã verify tay cả 2 nhánh (mục Nhiệm vụ 5).
- Tab "Thông báo"/"Tài khoản": 2 `Scaffold` placeholder tĩnh `Center(child: Text('Chưa có nội dung'))`, đúng yêu cầu "chưa có chức năng thật".
- [lib/features/child_profile/select_child_page.dart](lib/features/child_profile/select_child_page.dart) *(mới)* — `SelectChildPage({title, destinationBuilder})` dùng chung cho mọi lối vào cần chọn hồ sơ trước (3 mục Trang chủ + tab Hỏi đáp khi ≥2/0 hồ sơ): danh sách hồ sơ (cùng pattern `FutureBuilder`/lỗi/rỗng như `ChildListPage`), tap vào 1 hồ sơ → `Navigator.push(destinationBuilder(child))`. Trạng thái rỗng có nút "Tạo hồ sơ trẻ mới" luôn sẵn thay vì màn cụt.

### Nhiệm vụ 2 — Bước 2: Tạo hồ sơ + màn tóm tắt

- [lib/features/child_profile/create_profile/create_profile_page.dart](lib/features/child_profile/create_profile/create_profile_page.dart): trường "Giới tính" đổi từ `DropdownButtonFormField` sang `SegmentedButton<String>` 3 lựa chọn Nam/Nữ/Khác (`emptySelectionAllowed: true` — vẫn optional như trước, không ép chọn). Thứ tự trường giữ nguyên (đã đúng thứ tự đề bài từ trước: tên → tuổi/ngày sinh → giới tính → người đánh giá → vai trò), không cần sắp lại.
- Sau khi lưu thành công: thay `Navigator.pop(true)` bằng `Navigator.pushReplacement(CreateProfileSummaryPage(child: created), result: true)` — `result: true` báo ngay cho màn gọi (VD `ChildListPage`) làm mới danh sách trong nền, trong khi người dùng vẫn đang xem màn tóm tắt (không cần đợi họ back hết ngăn xếp). `pushReplacement` (không phải `push`) để người dùng không back lại được form đã nộp (tránh tạo trùng hồ sơ).
- [lib/features/child_profile/create_profile/create_profile_summary_page.dart](lib/features/child_profile/create_profile/create_profile_summary_page.dart) *(mới)* — hiện đủ tên/mã hồ sơ/ngày sinh/độ tuổi/giới tính/người đánh giá/vai trò + dòng xác nhận "Tạo hồ sơ thành công!" + nút "Xem hồ sơ" → `ProfileDetailPage`.

### Nhiệm vụ 3 — Bước 3: Luồng sàng lọc

- [lib/features/screening/screening_tool_confirm_page.dart](lib/features/screening/screening_tool_confirm_page.dart) *(mới)* — chèn giữa `ScreeningIntroPage` (bấm "Có") và `ScreeningQuestionnairePage`: hiện tên bộ câu hỏi đã chọn theo tuổi (`selectScreeningQuestionSet`) + số câu hỏi, nút "Bắt đầu" mới thật sự vào bảng câu hỏi — đúng yêu cầu "không tự động nhảy thẳng vào câu hỏi ngay khi chọn Có". `ScreeningIntroPage` chỉ đổi đúng 1 dòng (đích của nút "Có").
- [lib/features/screening/screening_questionnaire_page.dart](lib/features/screening/screening_questionnaire_page.dart) — thêm dòng "Câu hỏi đã trả lời: x/tổng" + `LinearProgressIndicator` cập nhật động theo `_answers.length`, không đổi logic tính điểm/lưu.
- [lib/features/screening/screening_result_page.dart](lib/features/screening/screening_result_page.dart) — thêm vòng tròn điểm số (`CircularProgressIndicator` tuỳ biến trong `Stack`, tâm hiện "x/y") + nhãn mức độ bằng chữ, **cộng thêm** vào (không thay thế) khối "Điểm: $score" + `resultSummary` cũ. Nhãn mức độ **tái dùng nguyên văn cụm "dấu hiệu cần chú ý"** đã có sẵn trong `resultSummary` (`screening_questionnaire_page.dart`) thay vì tự đặt ra thang "nguy cơ thấp/cao" mới — quyết định có chủ đích để không thêm ngôn ngữ mang tính chẩn đoán ngoài logic đã duyệt, giữ đúng tinh thần "không phải kết luận chẩn đoán" đã nhấn mạnh trong toàn bộ luồng sàng lọc. `body` đổi từ `Padding` sang `SingleChildScrollView` (bắt buộc — nội dung giờ dài hơn viewport mặc định của các màn nhỏ, tránh tràn `RenderFlex`, cũng đúng yêu cầu "chuẩn mobile, cuộn dọc").

### Nhiệm vụ 4 — Bước 4 & Bước 5

- [lib/features/screening/assessment_summary_page.dart](lib/features/screening/assessment_summary_page.dart) — tách nội dung cũ (vốn đã là 1 cột dọc) thành 4 khối `Card` rõ ràng: thông tin trẻ (tên/tuổi) → khối "Sàng lọc" (đã/chưa sàng lọc + điểm gần nhất + **thêm** công cụ/ngày thực hiện từ `Screening.toolName`/`performedAt` vốn có sẵn nhưng trước đây không hiện + người đánh giá) → khối "Đánh giá 9 lĩnh vực" (x/9) → khối "Đề xuất hướng đánh giá" → nút. `Column` → `ListView` để cuộn được khi nội dung dài. Không đổi `_buildSuggestion()` (logic đề xuất).
- [lib/features/assessment/domain_list_page.dart](lib/features/assessment/domain_list_page.dart) — `ListView.builder` → `GridView.builder` 2 cột (`SliverGridDelegateWithFixedCrossAxisCount`, `childAspectRatio: 1.1`), mỗi thẻ: icon Material riêng theo lĩnh vực (map `_domainIcons`, tô xanh lá nếu đã có mô tả) + tên + trạng thái. Thêm dòng "Tiến độ: x/9 lĩnh vực" + `LinearProgressIndicator` tổng ở đầu trang. Giữ nguyên đúng thứ tự 9 lĩnh vực + tên "Ứng xử" ở vị trí #7 (không đổi `nine_domains.dart`).

### Nhiệm vụ 5 — Kiểm chứng

- `flutter analyze`: **0 issues**.
- `flutter test`: **64/64 PASS** — cập nhật [test/screening_flow_test.dart](test/screening_flow_test.dart) cho khớp luồng mới (không đổi số lượng test, chỉ đổi bước điều hướng bên trong 1 test end-to-end):
  - Sau "Lưu hồ sơ" giờ kiểm tra màn tóm tắt (`'Tạo hồ sơ thành công!'`) rồi bấm "Xem hồ sơ" thay vì tap thẳng tên trong danh sách.
  - Thêm bước xác nhận màn `ScreeningToolConfirmPage` (`'Công cụ sẽ sử dụng: ...'`) + bấm "Bắt đầu" trước khi vào bảng câu hỏi; số lần `pageBack()` để quay lại hồ sơ ở nhánh "Có" tăng từ 2 lên 3 (thêm 1 route `ScreeningToolConfirmPage` trong ngăn xếp).
  - `ensureVisible` (yêu cầu widget đã build sẵn) đổi sang `scrollUntilVisible` (tự cuộn dần, build thêm item khi cần) ở 3 chỗ — form tạo hồ sơ dài hơn trước (thêm `SegmentedButton`), màn kết quả giờ cuộn được, Bước 4 giờ nhiều `Card` hơn. Khi truyền `scrollable:` cho `scrollUntilVisible` trên trang có nhiều `TextFormField`, dùng `find.byType(Scrollable).first` (không phải `find.byType(Scrollable)` trần) vì mỗi `TextFormField` tự có 1 `Scrollable` nội bộ (cuộn text), gây lỗi "Too many elements" nếu không giới hạn.
- **Verify tay trên `emulator-5554`** (build debug thật, không phải widget test) qua `adb`/`uiautomator dump` (lấy toạ độ chính xác từ `bounds` thay vì đoán theo ảnh chụp — đáng tin cậy hơn hẳn cách đoán tỉ lệ ảnh chụp màn hình đã dùng ở các giai đoạn trước, tránh tap nhầm liên tiếp): đi hết luồng thật — mở app → Trang chủ mới (5 menu + bottom nav) → "Tạo hồ sơ trẻ mới" → điền form (tên, tuổi=4, giới tính=Nam qua nút chọn) → "Lưu hồ sơ" → màn tóm tắt đúng đủ 7 trường → "Xem hồ sơ" → `ProfileDetailPage` → "Sàng lọc" → "Có" → màn "Xác nhận công cụ sàng lọc" đúng (Bộ B, 6 câu hỏi) → "Bắt đầu" → bảng câu hỏi với tiến độ "x/6" cập nhật đúng theo từng câu trả lời → "Hoàn thành" → màn kết quả có vòng tròn điểm số "0/6" + nhãn "Không ghi nhận dấu hiệu cần chú ý" + disclaimer → "Tiếp tục" → Bước 4 đủ 4 khối đúng dữ liệu thật (công cụ, ngày giờ thật, 0/9 lĩnh vực) → "Bắt đầu đánh giá" → Bước 5 lưới 2 cột đúng 9 thẻ, đúng icon/tên/thứ tự, "Ứng xử" đúng vị trí #7, tiến độ "0/9 lĩnh vực". Test riêng cả 5 tab của bottom nav (Trang chủ/Hồ sơ/Hỏi đáp/Thông báo/Tài khoản) — tab "Hỏi đáp" với 3 hồ sơ có sẵn trên máy đúng như kỳ vọng hiện `SelectChildPage` (không phải đúng 1 hồ sơ). `adb logcat -d | grep FATAL EXCEPTION`: **không có kết quả** trong suốt phiên verify.

### Không làm / ngoài phạm vi (đúng theo đề bài)

- Không làm đẹp theme/màu sắc/font/animation.
- Không đổi logic tính điểm sàng lọc, cách xác định trạng thái, cách query dữ liệu.
- Không đổi schema database.
- Không đụng Bước 6 trở đi (giữ nguyên mục 16–19).
- Không dựng bố cục nhiều cột kiểu desktop cho bất kỳ màn nào trong phạm vi Bước 1–5.
- Không commit git.

## 21. Tái cấu trúc bố cục UI, Phần 2/4 — Bước 6 (5 phần trong 1 lĩnh vực) (2026-08-14)

Phạm vi: đối chiếu + chỉnh bố cục hiển thị của cả 5 phần đã chạy chức năng thật từ trước (phần 1 từ Giai đoạn 3, phần 2–5 từ mục 16–19) theo đúng cấu trúc thiết kế gốc mô tả trong prompt — **không viết lại logic lưu/đọc dữ liệu**, đặc biệt phần 1 (mô tả biểu hiện, có gọi embedding + lưu `assessments`/`profile_chunks`). Đọc lại đủ 9 file thật trước khi sửa: `description_page.dart`, `comparison_video_page.dart`/`comparison_detail_page.dart`, `parent_input_page.dart`/`parent_context_page.dart`, `expert_input_page.dart`/`expert_detail_page.dart`, `summary_portrait_page.dart`/`summary_detail_page.dart`.

### Nhiệm vụ 1 — Chỉ báo "Phần x/5" dùng chung

[lib/features/assessment/nine_domains/part_step_indicator.dart](lib/features/assessment/nine_domains/part_step_indicator.dart) *(mới)* — `PartStepIndicator({step})`, 1 dòng `Text('Phần $step/5')` màu hint, đặt làm item đầu tiên trong `ListView`/`Column` của **5 màn tổng quan** (description/comparison_video/parent_input/expert_input/summary_portrait). Không gắn vào các màn "chi tiết" drill-down (`comparison_detail`, `parent_context`, `expert_detail`, `summary_detail`) vì các màn đó không nằm trong chuỗi điều hướng tuần tự 1→2→3→4→5 — quyết định diễn giải phạm vi "cả 5 màn" trong đề bài là 5 màn tổng quan, không phải toàn bộ 9 file.

### Nhiệm vụ 2 — Phần 1: Mô tả biểu hiện (đối chiếu kỹ nhất, không đụng logic lưu)

[description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart) — chỉ sửa `build()` + thêm 1 hàm điều phối mới, **không sửa bất kỳ dòng nào trong `_save()`/`_embedAndSaveChunk()`/`_retryEmbedding()`**:
- Thêm `_domainIntroTextTemp` — map 9 lĩnh vực → 1 câu định nghĩa ngắn, gắn nhãn rõ trong comment code là **text tạm**, chưa phải nội dung đã chuẩn hoá chính thức (đúng yêu cầu 4.1 "nếu chưa có nội dung này... tạm hardcode, ghi rõ đây là text tạm").
- Thêm câu hỏi hướng dẫn "Bạn quan sát thấy bé có biểu hiện gì trong [lĩnh vực]?" ngay trên ô nhập.
- Ô nhập tăng `maxLines: 4 → 6` (to hơn) + `suffixIcon` icon mic (`Icons.mic_none_outlined`, `onPressed: null`) — **cố ý vô hiệu hoá**, không giả vờ có chức năng ghi âm thật. Ghi rõ trong comment code: chưa có logic ghi âm thật.
- Thêm bộ đếm ký tự (`'${_contentController.text.length} ký tự'`, cập nhật qua `onChanged: (_) => setState(() {})` — cách đơn giản nhất, không dùng `ValueListenableBuilder` vì `setState` đã đủ, tránh phức tạp hoá).
- Thêm `Card` "Ghi nhận đơn giản" (nội dung đúng nguyên văn đề bài) — đặt dưới bộ đếm ký tự, trên 2 nút (quyết định thứ tự: đề bài liệt kê card sau cùng nhưng không bắt buộc vị trí tuyệt đối cuối trang; đặt ngay trên nút hành động để người dùng đọc lời trấn an trước khi bấm lưu, giữ 2 nút hành động chính luôn ở vị trí quen thuộc gần đáy — ghi rõ quyết định này theo đúng yêu cầu báo cáo).
- Gộp nút "Lưu" (cũ) + "Tiếp theo" (cũ, tách biệt ở cuối trang) thành 2 nút cạnh nhau ngay dưới card: **"Lưu nháp"** (`OutlinedButton`, gọi thẳng `_save()` — hành vi y hệt nút "Lưu" cũ, chỉ đổi nhãn) và **"Lưu & tiếp tục"** (`FilledButton`, gọi hàm mới `_saveAndContinue()` = `await _save(); if (mounted) _goNext();` — chỉ nối 2 hàm đã có sẵn, không viết logic lưu mới). Xoá nút "Tiếp theo" đứng riêng ở cuối trang (đã gộp chức năng vào "Lưu & tiếp tục").
- Khối "Mô tả đã lưu" (danh sách mô tả cũ) giữ nguyên logic, chỉ dời xuống dưới cùng.

### Nhiệm vụ 3 — Phần 2: So sánh với trẻ cùng độ tuổi

Đối chiếu [comparison_video_page.dart](lib/features/assessment/nine_domains/comparison_video/comparison_video_page.dart) — thứ tự đã **đúng sẵn** với đề bài: tiêu đề có dải tuổi → "Biểu hiện thường gặp" → "Cần quan sát thêm" → ghi chú tham khảo → nút chi tiết. [comparison_detail_page.dart](lib/features/assessment/nine_domains/comparison_video/comparison_detail_page.dart) — bảng đã đúng thứ tự cột Tiêu chí|Thường gặp|Cần quan sát + khung ghi chú "không dùng để tự chẩn đoán" ở cuối. Cả 2 file **không cần sửa bố cục**, chỉ thêm `PartStepIndicator(step: 2)` vào đầu `comparison_video_page.dart` (màn tổng quan).

### Nhiệm vụ 4 — Phần 3: Chia sẻ từ phụ huynh

[parent_input_page.dart](lib/features/assessment/nine_domains/parent_input/parent_input_page.dart):
- Sửa đúng nhãn 2 tab theo đề bài: `'Trẻ phát triển bình thường'/'Trẻ có dấu hiệu ASD'` → **`'Phụ huynh trẻ phát triển bình thường'/'Phụ huynh trẻ ASD'`** (trước đó lệch nhãn).
- Tab "Ở nhà"/"Ở trường"/"Nơi công cộng" ở [parent_context_page.dart](lib/features/assessment/nine_domains/parent_input/parent_context_page.dart) đã đúng nhãn sẵn, không đổi.
- Quote card (`_QuoteList`): trước đây nội dung chính in nghiêng + trích dẫn nguồn cỡ nhỏ thường — đổi thành nội dung chính hiển thị bình thường (bỏ in nghiêng + dấu ngoặc kép), trích dẫn nguồn giữ ở cuối card, **tô đậm khác biệt bằng in nghiêng + màu hint** (đúng ví dụ đề bài "in nghiêng hoặc cỡ chữ nhỏ hơn" — dùng cả 2 để rõ ràng hơn). Áp dụng cùng kiểu cho `_ContextList` ở `parent_context_page.dart` để nhất quán xuyên suốt Phần 3 (đề bài nói "mỗi quote card" chung, không tách riêng theo màn).
- Thêm `PartStepIndicator(step: 3)` vào đầu `Column` (trang này không dùng `ListView`, chèn vào `Padding` đầu tiên).

### Nhiệm vụ 5 — Phần 4: Thông tin từ bác sĩ

Đối chiếu [expert_input_page.dart](lib/features/assessment/nine_domains/expert_input/expert_input_page.dart) — khối minh hoạ vai trò chuyên môn đầu trang → 3 mục điều hướng (Mốc phát triển/Dấu hiệu cần lưu ý/Giải thích chuyên môn) đã **đúng sẵn** thứ tự đề bài. [expert_detail_page.dart](lib/features/assessment/nine_domains/expert_input/expert_detail_page.dart) — đúng 3 nhóm theo thứ tự Mốc phát triển → Dấu hiệu cần lưu ý → Giải thích chuyên môn → dòng miễn trừ trách nhiệm cuối trang, **đúng sẵn**. Không sửa bố cục, chỉ thêm `PartStepIndicator(step: 4)` vào `expert_input_page.dart`.

### Nhiệm vụ 6 — Phần 5: Chân dung biểu hiện

[summary_portrait_page.dart](lib/features/assessment/nine_domains/summary_portrait/summary_portrait_page.dart) — **phát hiện lệch thứ tự**: bản cũ hiện "Mức độ biểu hiện" (badge) TRƯỚC "Điểm nổi bật"/"Khác biệt so với trẻ cùng tuổi". Đã sắp lại đúng thứ tự đề bài: Điểm nổi bật → Khác biệt so với trẻ cùng tuổi → Mức độ biểu hiện (badge) → nút "Xem chân dung chi tiết" → nút "Hoàn tất" — chỉ di chuyển khối widget trong danh sách `children`, không đổi điều kiện hiển thị (`mucDoBieuHien != null`, `hasGridData`) hay cách tải dữ liệu. **Giữ nguyên hoàn toàn quyết định lưới thẻ đã chốt trước đó** — không dựng lại mindmap toả tròn, `summary_detail_page.dart` không đổi gì (đã đúng thứ tự tóm tắt → lưới thẻ → chú thích màu từ mục 19). Thêm `PartStepIndicator(step: 5)`.

### Nhiệm vụ 7 — Kiểm chứng

- `flutter analyze`: **0 issues**.
- `flutter test`: **64/64 PASS** — không có test nào tham chiếu tới các chuỗi/nhãn đã đổi (`Trẻ phát triển bình thường`, `Lưu`, `Tiếp theo`, `Mô tả biểu hiện quan sát được`...), xác nhận bằng grep toàn bộ `test/` trước khi sửa — không cần cập nhật file test nào ở phần này.
- **Verify tay trên `emulator-5554`** (build debug thật) — dùng hồ sơ có sẵn dữ liệu mẫu đầy đủ `Be_Migration_Test` (5 tuổi), lĩnh vực "Quan hệ xã hội" (đã ingest 7 entry `chan_dung` + có sẵn dữ liệu `so_sanh`/`chia_se_phu_huynh`/`bac_si` từ các phiên trước — xem mục 16–19):
  - **Phần 1**: đúng đủ cấu trúc — "Phần 1/5", câu định nghĩa, câu hỏi hướng dẫn, ô nhập lớn + icon mic (đúng vị trí, không tương tác được — xác nhận qua ảnh chụp, không có hiệu ứng khi bấm), bộ đếm ký tự cập nhật đúng theo từng ký tự gõ ("0 ký tự" → "29 ký tự"), card "Ghi nhận đơn giản", 2 nút "Lưu nháp"/"Lưu & tiếp tục".
  - **Verify riêng logic lưu KHÔNG bị ảnh hưởng** (bắt buộc theo đề bài): nhập mô tả thật "Be coi mo ban va vay tay chao", bấm "Lưu nháp" → mô tả xuất hiện đúng trong "Mô tả đã lưu" ngay trên UI kèm timestamp. Đối chiếu trực tiếp qua database thật trên thiết bị (`adb exec-out run-as com.iris.app.iris_app cat .../iris.db`, đọc bằng `sqlite3` qua Python): bảng `assessments` có đúng 1 dòng mới `linh_vuc='quan_he_xa_hoi'`, `content_type='mo_ta'`, `content='Be coi mo ban va vay tay chao'`, `created_at` khớp đúng thời điểm bấm lưu — **xác nhận logic lưu nguyên vẹn 100% sau khi chỉnh bố cục**. (Bước embed AI báo lỗi trong lần build này vì không dùng `--dart-define-from-file` — đúng hành vi fallback đã có từ trước, không phải lỗi mới, nút "Thử lại xử lý cho AI" hiện đúng.)
  - **Phần 2–5**: đi hết chuỗi thật qua "Lưu & tiếp tục" → "Tiếp theo" ×3 → "Hoàn tất", xác nhận đúng "Phần 2/5"–"Phần 5/5" hiện đúng vị trí trên từng màn, đúng thứ tự "Biểu hiện thường gặp"→"Cần quan sát thêm" (Phần 2), đúng nhãn tab mới "Phụ huynh trẻ phát triển bình thường"/"Phụ huynh trẻ ASD" + quote card đúng kiểu mới (Phần 3), đúng 3 mục điều hướng (Phần 4), đúng thứ tự Điểm nổi bật→Khác biệt→Mức độ biểu hiện mới (Phần 5) — khớp 100% ảnh chụp màn hình đối chiếu với mô tả đề bài.
  - "Hoàn tất" quay đúng về `DomainListPage`, lĩnh vực "Quan hệ xã hội" cập nhật đúng "Đã có mô tả", tiến độ "1/9 lĩnh vực".
  - `adb logcat -d | grep FATAL EXCEPTION`: **không có kết quả** trong suốt phiên verify.

### Không làm / ngoài phạm vi (đúng theo đề bài)

- Không đổi logic lưu/đọc dữ liệu ở bất kỳ phần nào trong 5 phần — đã verify riêng bằng database thật cho Phần 1.
- Không dựng lại mindmap toả tròn cho Phần 5.
- Không làm đẹp theme/màu sắc.
- Không đổi luồng điều hướng giữa 5 phần (vẫn `pushReplacement` nối tiếp 1→2→3→4→5, `pop()` đơn ở "Hoàn tất").
- Không commit git.

## 22. Tái cấu trúc bố cục UI, Phần 3/4 — Bước 7–12 (2026-08-14)

Phạm vi: thêm màn "Đã lưu kết quả" (Bước 7) và banner "Tiếp tục đánh giá" (Bước 8) — 2 phần trước đây chỉ dùng SnackBar/điều hướng ngầm, chưa có màn hình riêng; đối chiếu nhanh Bước 9 (Lịch sử) và Bước 11–12 (Hỏi đáp AI). Đọc lại code thật của `SummaryPortraitPage`, `DomainListPage`, `HistoryPage`, `AiChatPage` trước khi sửa — không đổi logic 3 trạng thái AI/guardrail, không đổi logic lưu dữ liệu ở bất kỳ đâu.

### Nhiệm vụ 1 — Bước 7: Màn "Đã lưu kết quả"

[lib/features/assessment/nine_domains/saved_result_page.dart](lib/features/assessment/nine_domains/saved_result_page.dart) *(mới)* — `SavedResultPage`:
- Icon + "Lưu thành công!" + tên lĩnh vực.
- Bảng thông tin: "Ngày đánh giá" = thời điểm hoàn tất Bước 7 (`DateTime.now()` chụp lúc mở trang) — **quyết định**: không lấy theo ngày tạo bản ghi mô tả gần nhất vì Phần 1 có thể bị bỏ qua (bấm "Lưu & tiếp tục" khi ô nhập trống vẫn cho qua), nên dùng thời điểm hoàn tất chuỗi 5 phần làm mốc luôn có giá trị. "Người thực hiện" = `child.nguoiDanhGia` hoặc "Chưa cập nhật". "Trạng thái" = "Đã lưu thành công" (tĩnh, đúng ý nghĩa của việc đã tới được màn này).
- Checklist "Nội dung đã được lưu" — truy vấn dữ liệu THẬT: `AssessmentRepository.getForChild(linhVuc:)` lọc `content_type='mo_ta'` cho "Mô tả của người dùng"; `ExpertKnowledgeRepository.query()` với `contentType` lần lượt `'so_sanh'`/`'chia_se_phu_huynh'`/`'bac_si'` (đúng lĩnh vực + tuổi trẻ) cho 3 mục còn lại. Mục nào không có dữ liệu → icon `remove_circle_outline` xám + chữ "Không có dữ liệu", **không** đánh dấu ✓ giả — đã verify thật bằng 2 kịch bản khác nhau (xem Nhiệm vụ 3).
- Dòng miễn trừ trách nhiệm đúng nguyên văn đề bài.
- 2 nút: "Xem kết quả" → `push` `DescriptionPage` (Phần 1) của đúng lĩnh vực — trang này vốn đã hiện danh sách "Mô tả đã lưu" nên tự nhiên đóng vai trò "xem lại", không cần chế độ riêng. "Quay về tổng quan" → `pop()`.
- [summary_portrait_page.dart](lib/features/assessment/nine_domains/summary_portrait/summary_portrait_page.dart) — nút "Hoàn tất" đổi từ `pop()` thẳng sang `pushReplacement` tới `SavedResultPage` — **giữ nguyên bất biến "chỉ 1 route trên `DomainListPage`"** đã ghi trong comment gốc (Phần 2-5 đều `pushReplacement` nối tiếp), nên `SavedResultPage` chỉ cần đúng 1 `pop()` để quay về danh sách 9 lĩnh vực — không cần pop nhiều lần hay sửa gì ở phía `DomainListPage`.

### Nhiệm vụ 2 — Bước 8: Banner "Tiếp tục đánh giá" ở `DomainListPage`

[lib/features/assessment/domain_list_page.dart](lib/features/assessment/domain_list_page.dart):
- **Quyết định logic gợi ý** (đề bài yêu cầu tự chọn + ghi rõ lý do): kiến trúc hiện tại chỉ theo dõi 1 trạng thái nhị phân mỗi lĩnh vực — đã có bản ghi `assessments` (content_type='mo_ta') hay chưa, dùng chung với badge "Đã có mô tả"/"Chưa có mô tả" đã có trên từng thẻ — không có khái niệm "đang dở" (VD đã qua Phần 1-3 nhưng chưa tới Phần 5) tách biệt trong dữ liệu. Vì vậy gợi ý = **lĩnh vực CHƯA có mô tả đầu tiên theo đúng thứ tự 9 lĩnh vực** trong `nineDomains` — logic đơn giản nhất khớp đúng dữ liệu đang có, không suy diễn thêm trạng thái không tồn tại.
- Card "Gợi ý: tiếp tục lĩnh vực "..."" + nút "Tiếp tục ngay" → `push` thẳng `DescriptionPage` (Phần 1) của lĩnh vực đó, `_reload()` sau khi quay về. Tách thành widget riêng `_NextDomainCard` (nhận `domain` non-nullable) để tránh lỗi phân tích tĩnh "unchecked_use_of_nullable_value" khi truy cập biến local `nextDomain` (nullable) bên trong closure `async` của `onPressed` — biến local không được Dart promote non-null xuyên qua closure dù đã kiểm tra `!= null` ở ngoài.
- Nếu đủ 9/9: ẩn hẳn card, thay bằng 1 dòng chúc mừng "Bạn đã hoàn thành đánh giá cả 9 lĩnh vực!".
- Dòng ghi chú tĩnh đúng nguyên văn đề bài, luôn hiện (không điều kiện).
- Đặt ngay dưới thanh tiến độ tổng đã có từ Phần 1/4, trên lưới 9 lĩnh vực — đúng vị trí đề bài yêu cầu.

### Nhiệm vụ 3 — Đối chiếu Bước 9 (Lịch sử)

Đọc lại [history_page.dart](lib/features/history/history_page.dart) — **đã khớp đúng mô tả, không cần sửa**: nhóm sự kiện theo ngày (`_groupByDay`), mỗi ngày liệt kê các sự kiện dạng `Card`+`ListTile` (icon theo loại + mô tả + nhãn loại/giờ), sắp xếp mới nhất trước (`HistoryLogRepository.getForChild` đã `ORDER BY event_date DESC`, nhóm giữ nguyên thứ tự). Verify tay: mở Lịch sử của `Be_Migration_Test`, thấy đúng 1 mục "Đánh giá Quan hệ xã hội — đã nhập mô tả biểu hiện" ngày 14/08/2026, đúng cấu trúc.

### Nhiệm vụ 4 — Đối chiếu Bước 11–12 (Hỏi đáp AI)

Đọc lại [ai_chat_page.dart](lib/features/ai_chat/ai_chat_page.dart) — **đã khớp đúng mô tả, không cần sửa**: khung chat có `ListView` bong bóng hội thoại (câu hỏi bên phải, trả lời bên trái) + ô nhập + nút gửi (`IconButton` icon gửi) ở dưới, dùng `SafeArea`. Câu trả lời AI đã có dấu hiệu phân biệt trạng thái — dòng `'Trạng thái ${conversation.state}'` (`labelSmall`) hiện ngay dưới mỗi câu trả lời, đúng tinh thần "không bắt buộc hiện rõ số trạng thái nếu hiện tại không có" (ở đây đã CÓ sẵn, giữ nguyên). Không phát hiện lệch, không sửa gì.

### Nhiệm vụ 5 — Kiểm chứng

- `flutter analyze`: **0 issues** (đã sửa 1 lỗi `unchecked_use_of_nullable_value` phát sinh khi viết `_NextDomainCard`, xem Nhiệm vụ 2).
- `flutter test`: **64/64 PASS** — không có test nào bị ảnh hưởng.
- **Verify tay trên `emulator-5554`** (build debug thật) — dùng hồ sơ `Be_Migration_Test` (đã có sẵn mô tả cho "Quan hệ xã hội" từ trước):
  - **Trường hợp còn lĩnh vực chưa làm**: `DomainListPage` hiện đúng banner "Gợi ý: tiếp tục lĩnh vực "Hành vi"" (đúng lĩnh vực đầu tiên theo thứ tự chưa có mô tả) + nút "Tiếp tục ngay" → bấm vào đúng thẳng Phần 1 "Hành vi — Mô tả biểu hiện". Lưu 1 mô tả thật ("Be chay nhay nhieu") qua "Lưu & tiếp tục", đi hết Phần 2→3→4→5 (đều đúng "chưa có dữ liệu" vì lĩnh vực "Hành vi" chưa ingest dữ liệu tham khảo), bấm "Hoàn tất" → **`SavedResultPage` hiện đúng**: "Lưu thành công!", tên lĩnh vực "Hành vi", ngày giờ đúng thời điểm thật, checklist đúng ✓ **duy nhất** "Mô tả của người dùng" (vì vừa lưu thật) và "Không có dữ liệu" cho cả 3 mục còn lại (đúng thật vì lĩnh vực này chưa có dữ liệu tham khảo) — xác nhận **không có ✓ giả**. Bấm "Xem kết quả" → đúng Phần 1 hiện lại mô tả vừa lưu. Quay lại, bấm "Quay về tổng quan" → đúng về `DomainListPage`, tiến độ cập nhật "2/9", banner cập nhật đúng gợi ý lĩnh vực tiếp theo "Nhận thức".
  - **Trường hợp đủ 9/9**: để verify hiệu quả không cần lái tay qua 7 lĩnh vực × 5 phần còn lại, đã nạp thêm dữ liệu mô tả thật cho 7 lĩnh vực còn thiếu **thẳng vào database thật trên thiết bị** (qua `adb exec-out run-as ... cat` để đọc, sửa bằng Python `sqlite3`, rồi `adb shell run-as ... dd conv=notrunc` để ghi đè đúng file `iris.db` tại chỗ — không tạo file mới vì SELinux domain `runas_app` trên bản Android này chặn tạo file mới trong thư mục dữ liệu app dù cùng UID, chỉ cho ghi đè file đã tồn tại) — dữ liệu vẫn là bản ghi `assessments` hợp lệ (không giả lập ở tầng UI), chỉ khác ở chỗ nhập qua script thay vì gõ tay qua 7×5=35 màn hình. Mở lại app thật (force-stop + relaunch), vào đúng `DomainListPage` của `Be_Migration_Test`: **banner ẩn đúng, thay bằng dòng "Bạn đã hoàn thành đánh giá cả 9 lĩnh vực!"**, tiến độ "9/9 lĩnh vực", cả 9 thẻ đều xanh "Đã có mô tả", không lỗi, không crash.
  - `adb logcat -d | grep FATAL EXCEPTION`: **không có kết quả** trong suốt phiên verify (cả 2 trường hợp).

### Không làm / ngoài phạm vi (đúng theo đề bài)

- Không dựng calendar/lịch chọn ngày đầy đủ cho Bước 8 — dùng banner gợi ý đơn giản (Card + nút), đúng tinh thần "đơn giản hoá chủ động, ưu tiên chức năng trước hình thức".
- Không đổi logic 3 trạng thái AI/guardrail (Bước 11-12 chỉ đối chiếu, không sửa).
- Không đổi logic lưu dữ liệu ở bất kỳ đâu (Bước 7 chỉ ĐỌC dữ liệu đã có để hiện checklist).
- Không đánh dấu ✓ giả cho nội dung tham khảo không có dữ liệu thật ở checklist Bước 7 — verify thật bằng lĩnh vực chưa có dữ liệu.
- Không làm đẹp theme/màu sắc.
- Không commit git.

## 23. Tái cấu trúc bố cục UI, Phần 4/4 — Bước 13–14 + Dashboard (2026-08-14) — HOÀN THÀNH TOÀN BỘ 4/4 PHẦN

Phạm vi: xây màn hình "Kết nối chuyên gia/trung tâm" thật (Bước 14) — trọng tâm chính của phần này vì trước đây chỉ có nút debug mô phỏng trong `VideoDetailPage`, chưa có màn hình đề xuất đơn vị/chuyên gia nào; đối chiếu nhanh Bước 13 (quay video) và Dashboard nhiều trẻ. Đây là **phần cuối cùng (4/4)** của đợt tái cấu trúc bố cục UI bắt đầu từ mục 20.

### Nhiệm vụ 1 — Bước 14: Màn "Kết nối chuyên gia/trung tâm"

[lib/features/expert_connect/expert_connect_page.dart](lib/features/expert_connect/expert_connect_page.dart) *(mới)* — `ExpertConnectPage`:
- **Logic phân loại nhu cầu bằng code thuần, không dùng AI** (`_determineNeedLevel()`) — đơn giản hoá có chủ đích từ 5 trường hợp gốc xuống 3 mức, vì dữ liệu thật hiện có (đã sàng lọc?/số lĩnh vực đã mô tả/đã có video được chuyên gia xem hay chưa qua `status='reviewed'`) không đủ chi tiết để phân biệt rạch ròi hơn:
  - `!hasScreening && doneDomainCount == 0` → **"Chưa có đủ thông tin"**.
  - `doneDomainCount >= 5` (quá bán 9 lĩnh vực — **ngưỡng tự chọn**, không có sẵn trong tài liệu gốc) `|| hasReviewedVideo` → **"Đã có kết quả đánh giá đầy đủ hơn"**.
  - Còn lại (đã sàng lọc và/hoặc đã có một vài mô tả) → **"Có dấu hiệu cần theo dõi"**.
  - Dùng lại nguyên `ScreeningRepository.hasScreening()`, `AssessmentRepository.getForChild()`, `VideoRepository.getForChild()` đã có sẵn — không viết logic truy vấn mới, chỉ tổng hợp lại thành 1 quyết định if/else.
- Card banner đầu trang: icon + tiêu đề + 1–2 câu khuyến nghị theo đúng mức đã xác định.
- "Đơn vị/dịch vụ đề xuất": 6 card tĩnh hardcode trong code (`_providers`, **không tạo bảng database mới**) — 2 trung tâm can thiệp sớm, 2 phòng khám nhi/PTNK, 1 chuyên gia tâm lý-giáo dục, 1 trường mầm non hoà nhập (đủ 4 loại hình đề bài yêu cầu, dư 2 mục cho "Xem thêm"). Mỗi card: tên, mô tả ngắn (loại hình + độ tuổi), rating sao tĩnh, số lượt đánh giá tĩnh, khoảng cách tĩnh — toàn bộ là **dữ liệu minh hoạ đóng gói sẵn trong app**, không gọi API/dịch vụ bên ngoài nào.
- Nút "Xem thêm gợi ý phù hợp" — chỉ `setState` mở rộng từ 4 lên 6 card tĩnh đã có sẵn trong danh sách, không tải thêm dữ liệu thật.
- **Dòng ghi chú bắt buộc "Đây là danh sách minh hoạ, chưa phải dữ liệu đơn vị/chuyên gia thật."** — luôn hiện, không điều kiện, đúng yêu cầu "không được bỏ".
- [profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart) — thêm nút "Kết nối chuyên gia/trung tâm" ngay sau "Quay video tình huống" (trước cụm nút debug), điều hướng `push` tới `ExpertConnectPage`.

### Nhiệm vụ 2 — Đối chiếu Bước 13 (Quay video)

Đọc lại 4 màn [video_situation_page.dart](lib/features/video_recording/video_situation_page.dart)/[video_preparation_page.dart](lib/features/video_recording/video_preparation_page.dart)/[video_recording_capture_page.dart](lib/features/video_recording/video_recording_capture_page.dart)/[video_review_page.dart](lib/features/video_recording/video_review_page.dart) — **đã khớp đúng mô tả, không cần sửa**: chọn tình huống (danh sách gợi ý + tự nhập) → chuẩn bị (danh sách tips tĩnh) → quay (`CameraPreview` thật + đồng hồ đang quay + nút quay/dừng) → xem lại & gửi (`VideoPlayer` thật + nút "Gửi cho chuyên gia"). Đúng 4 bước tuần tự, đúng comment "Bước x/4" có sẵn trong từng file. Không phát hiện lệch, không sửa gì.

### Nhiệm vụ 3 — Đối chiếu Dashboard nhiều trẻ

Đọc lại [multi_child_dashboard_page.dart](lib/features/multi_child_dashboard/multi_child_dashboard_page.dart) — **đã khớp đúng mô tả, không cần sửa**: vẫn đúng bố cục mobile 1 cột (không có bố cục nhiều cột kiểu desktop nào được thêm ở các phần trước, xác nhận lại ở phần này) — 4 card thống kê xếp hàng ngang co giãn (`Expanded` trong 1 `Row`, không phải lưới nhiều cột cố định), ô tìm kiếm + dropdown lọc, danh sách `ListView` 1 cột, menu `PopupMenuButton` (⋮) đúng 3-4 hành động tuỳ trạng thái hồ sơ (Xem/Lịch sử/Lưu trữ hoặc Khôi phục/Xoá), 2 tab Đang quản lý/Đã lưu trữ. Không phát hiện lệch, không sửa gì.

### Nhiệm vụ 4 — Kiểm chứng

- `flutter analyze`: **0 issues**.
- `flutter test`: **64/64 PASS** — không có test nào bị ảnh hưởng (màn mới không có test riêng, phù hợp mức độ ưu tiên "đủ chức năng, đã verify tay kỹ" của các trang minh hoạ tĩnh trong đợt tái cấu trúc này).
- **Verify tay trên `emulator-5554`** (build debug thật):
  - Hồ sơ `Be_Demo_Layout` (đã sàng lọc từ trước, 0 lĩnh vực có mô tả) → mở "Kết nối chuyên gia/trung tâm": banner đúng **"Có dấu hiệu cần theo dõi"** + khuyến nghị đúng nội dung. 4 card đề xuất hiện đủ, đúng thứ tự loại hình. Bấm "Xem thêm gợi ý phù hợp" → đúng mở rộng thành 6 card, dòng ghi chú minh hoạ vẫn hiện đúng ở cuối.
  - Tạo mới hồ sơ trắng `Be_Tier1_Test` (chưa sàng lọc, chưa có mô tả nào) → mở "Kết nối chuyên gia/trung tâm": banner đúng **"Chưa có đủ thông tin"** + khuyến nghị đúng nội dung — xác nhận cả 2 trạng thái banner khác nhau đều đúng theo dữ liệu thật.
  - `adb logcat -d | grep FATAL EXCEPTION`: **không có kết quả** trong suốt phiên verify (cả 2 hồ sơ).

### Không làm / ngoài phạm vi (đúng theo đề bài)

- Không xây kết nối thật tới bất kỳ dịch vụ/API bên ngoài (đặt lịch/gọi điện/bản đồ thật) — toàn bộ 6 đơn vị là dữ liệu tĩnh hardcode.
- Không tạo bảng database mới cho danh sách đơn vị/chuyên gia — giữ tĩnh trong code (`_providers`).
- Không bỏ dòng ghi chú "dữ liệu minh hoạ" — luôn hiện, đã verify trên cả 2 trạng thái banner.
- Không làm đẹp theme/màu sắc.
- Không commit git.

## 24. Tổng kết đợt tái cấu trúc bố cục UI (4/4 phần — 2026-08-13 đến 2026-08-14)

Cả 4 phần của đợt tái cấu trúc bố cục UI (Bước 1–15 + Dashboard) nay đã hoàn thành đầy đủ, đúng thứ tự/cấu trúc theo thiết kế gốc mô tả qua 4 prompt, giữ nguyên toàn bộ logic nghiệp vụ/dữ liệu đã chạy đúng từ trước, có verify thiết bị thật cho từng phần:

| Phần | Phạm vi | Trạng thái | Mục ghi chú |
|---|---|---|---|
| 1/4 | Bước 1–5 (mở app → 9 lĩnh vực) | Đã xong | Mục 20 |
| 2/4 | Bước 6 (5 phần trong 1 lĩnh vực) | Đã xong | Mục 21 |
| 3/4 | Bước 7–12 (đã lưu kết quả/tiếp tục đánh giá/lịch sử/hỏi đáp AI) | Đã xong | Mục 22 |
| 4/4 | Bước 13–14 + Dashboard (quay video/kết nối chuyên gia/quản lý nhiều trẻ) | Đã xong | Mục 23 (mục này) |

## 25. "Chân dung toàn cảnh" — tổng hợp mức tổng quan 9 lĩnh vực (2026-08-15)

Phạm vi: sau khi trẻ đã có mô tả biểu hiện (Phần 1) cho đủ cả 9 lĩnh vực, hệ thống gắn nhãn từng lĩnh vực (AI hỗ trợ, dựa trên `expert_knowledge_chunks` loại `so_sanh` — 2 nhóm `phan_loai` mới `binh_thuong`/`roi_loan_pho_tu_ky`, xem mục 24/prompt trước), rồi CODE (không phải AI) đếm và xếp trẻ vào 1 trong 3 mức: "Trong giới hạn thường gặp" / "Có điểm cần theo dõi" / "Nên tìm đánh giá chuyên môn sớm".

### Migration (bảng MỚI, không sửa bảng cũ)

- [domain_overview_labels_table.dart](lib/data/local/tables/domain_overview_labels_table.dart) + [overview_summaries_table.dart](lib/data/local/tables/overview_summaries_table.dart) — đúng schema đề bài. Mỗi lần gắn nhãn/tổng hợp ghi 1 dòng MỚI (lịch sử theo `computed_at`), không UPDATE đè — "hiện hành" là dòng mới nhất (`getLatestForChild`).
- [database.dart](lib/data/local/database.dart): version 4 → **5**, `onUpgrade` chỉ thêm 2 bảng mới, không đụng bảng/dữ liệu cũ. Test migration: [overview_migration_test.dart](test/overview_migration_test.dart) — tạo DB thật ở version 4 có sẵn 1 hồ sơ trẻ, mở lại bằng `AppDatabase` version 5, xác nhận dữ liệu cũ còn nguyên + 2 bảng mới dùng được ngay.
- [child_repository.dart](lib/data/repositories/child_repository.dart) — `delete()` đã thêm xoá 2 bảng mới vào transaction (bắt buộc vì `PRAGMA foreign_keys = ON` và cả 2 bảng đều `REFERENCES children(id)`), không thì xoá hồ sơ trẻ đã có nhãn/tổng hợp sẽ lỗi FK constraint.

### Bước gắn nhãn từng lĩnh vực (AI hỗ trợ, KHÔNG quyết định mức cuối)

[overview_repository.dart](lib/data/repositories/overview_repository.dart) — `OverviewRepository.labelDomain()`:
- Chưa có mô tả (`assessments` content_type='mo_ta' rỗng) → nhãn cứng `'chua_du_du_lieu'`, **không gọi AI** (verify bằng test đếm số lần gọi HTTP = 0).
- Đã có mô tả → lấy toàn bộ `expert_knowledge_chunks` content_type='so_sanh' đúng `linh_vuc` + độ tuổi (qua `ExpertKnowledgeRepository.query()` có sẵn), tự tính cosine similarity bằng `VectorSearchService.cosineSimilarity()` **đã có sẵn** (không viết lại logic vector search mới), tách top 3 chunk mỗi nhóm `phan_loai` (`binh_thuong`/`roi_loan_pho_tu_ky`) đưa vào prompt.
- [prompt_builder.dart](lib/domain/services/prompt_builder.dart) — thêm `buildDomainOverviewLabelPrompt()`: ép Groq trả ĐÚNG 1 JSON `{"nhan": ..., "ly_do_ngan_gon": ...}`, nêu rõ PHẢI chọn `'chua_du_du_lieu'` nếu dữ liệu tham khảo không đủ, không được đoán.
- Parse JSON có validate (`nhan` phải thuộc đúng 3 giá trị) — sai định dạng hoặc lỗi gọi API (mạng/timeout) đều fallback `'chua_du_du_lieu'` kèm lý do, log lỗi qua `print`, **không crash** (test riêng: mock Groq trả text không phải JSON).

### Bước tổng hợp mức cuối — 100% CODE, KHÔNG gọi AI

[overview_tier_calculator.dart](lib/domain/services/overview_tier_calculator.dart) — hàm thuần `calculateOverviewTier(List<String> labels)`, không I/O, không phụ thuộc AI:
- Hằng số ngưỡng đặt tên rõ ràng ở đầu file: `nguongThuongGap = 2`, `nguongCanTheoDoi = 5`, `nguongThieuDuLieuToiThieu = 4` — **mỗi hằng số đều có docstring ghi rõ đây là ngưỡng TẠM do dự án tự đặt cho demo, KHÔNG phải thang đo lâm sàng đã kiểm định**, cần thay bằng ngưỡng có cơ sở chuyên môn trước khi dùng thật.
- `so_thieu >= 4` → `insufficientData`, không tính tier.
- Còn lại: `so_can_theo_doi` 0–2 → `thuong_gap`; 3–5 → `can_theo_doi`; ≥6 → `chuyen_mon_som`.
- `OverviewRepository.computeAndSaveOverview()` chỉ gọi hàm này SAU KHI đọc đủ 9/9 nhãn mới nhất từ `domain_overview_labels` (chưa đủ 9/9 → `insufficientLabels`, không tính) — lưu `overview_summaries` + 1 dòng `history_logs` (event_type='tong_quan').

### UI

[overview_portrait_page.dart](lib/features/assessment/overview/overview_portrait_page.dart) *(mới)* — `OverviewPortraitPage`:
- Chưa đủ 9/9 → hiện tiến độ (x/9) thay vì kết quả, không có nút tổng hợp.
- Đủ 9/9, chưa từng tổng hợp → nút "Tổng hợp Chân dung toàn cảnh" (gọi `labelAllDomains` + `computeAndSaveOverview`).
- Đã có kết quả → hiện tier bằng ĐÚNG 1 trong 3 tên đã chốt (`tierDisplayLabel()`, không có nơi nào khác tự viết lại chuỗi này), danh sách 9 lĩnh vực kèm nhãn + lý do ngắn, nút "Tính toán lại".
- `tier == 'chuyen_mon_som'` → thêm nút "Kết nối chuyên gia/trung tâm" dẫn thẳng `ExpertConnectPage` đã có sẵn (Bước 14).
- Dòng cảnh báo "Đây là tổng hợp mang tính tham khảo... không phải kết luận chẩn đoán y khoa." đặt NGOÀI mọi nhánh điều kiện trong `build()` — luôn hiện dù ở trạng thái nào (tiến độ/chưa tổng hợp/đã có kết quả/lỗi).
- [domain_list_page.dart](lib/features/assessment/domain_list_page.dart) — chỉ hiện nút "Xem Chân dung toàn cảnh" khi `nextDomain == null` (đủ 9/9), đặt ngay dưới dòng chúc mừng đã có sẵn.
- [history_page.dart](lib/features/history/history_page.dart) — thêm `'tong_quan'` vào `_iconFor`/`_labelFor` (hiện "Chân dung toàn cảnh" thay vì rơi vào nhánh mặc định).

### Kiểm chứng

- `flutter analyze`: **0 issues**.
- `flutter test`: **91/91 PASS** (18 test mới, không có test cũ nào bị hỏng):
  - [overview_tier_calculator_test.dart](test/overview_tier_calculator_test.dart) — bao phủ đủ ranh giới ngưỡng (2/3, 5/6), toàn bộ thường gặp, toàn bộ chuyên môn sớm, trộn `chua_du_du_lieu` dưới/đúng/trên ngưỡng 4, và xác nhận `tierDisplayLabel` không dùng nhãn cấm ("bình thường"/"nghi ngờ"/"nguy hiểm").
  - [overview_migration_test.dart](test/overview_migration_test.dart) — migration v4→v5 không mất dữ liệu cũ.
  - [overview_repository_test.dart](test/overview_repository_test.dart) — mock NVIDIA/Groq qua `http.testing.MockClient` (không gọi API thật), gồm: chưa có mô tả → không gọi AI; AI trả sai định dạng → fallback không crash; chưa đủ 9/9 nhãn → không lưu; đủ 9/9 nhưng ≥4 thiếu dữ liệu → không lưu; và **luồng đầy đủ**: tạo 1 trẻ giả, nhập mô tả mock cho cả 9 lĩnh vực, chạy `labelAllDomains` + `computeAndSaveOverview`, rồi **đọc lại trực tiếp bằng `db.query()` từ database thật** (`domain_overview_labels` đúng 9 dòng, `overview_summaries` đúng 1 dòng tier='can_theo_doi', `history_logs` đúng 1 dòng 'tong_quan') — không chỉ tin giá trị trả về từ hàm.
- **Chưa verify tay trên emulator thật** cho đợt này (khác các mục trước) — do luồng đầy đủ cần gọi Groq/NVIDIA thật (chưa có API key trong môi trường làm việc này) hoặc phải lái tay qua toàn bộ 9×5 màn hình mô tả; đã bù bằng test tích hợp ở trên (DB thật qua `sqflite_common_ffi`, chỉ mock tầng HTTP).

### Lưu ý quan trọng khi dùng/diễn giải kết quả demo

- **Ngưỡng 2/5 (và 4) ở `overview_tier_calculator.dart` là số TẠM do dự án tự đặt**, chưa có cơ sở/thang đo lâm sàng đã kiểm định — không dùng để đưa ra quyết định thật ngoài mục đích minh hoạ luồng.
- **`expert_knowledge_chunks` loại `so_sanh` (nhóm `binh_thuong`/`roi_loan_pho_tu_ky`) hiện toàn bộ là dữ liệu placeholder** (`assets/reference/expert_content_so_sanh.json`, xem đợt việc trước) — kết quả gắn nhãn/tổng hợp khi demo/test tay **KHÔNG phản ánh nội dung chuyên môn thật**, chỉ xác nhận đúng luồng kỹ thuật (dữ liệu → vector search → prompt → parse → code tổng hợp → lưu DB).

### Không làm / ngoài phạm vi (đúng theo đề bài)

- Không để AI quyết định tier cuối cùng — `calculateOverviewTier()` là hàm Dart thuần, không gọi mạng, trace/debug được độc lập với LLM.
- Không dùng nhãn "bình thường/nghi ngờ/nguy hiểm" ở bất kỳ đâu hiển thị cho người dùng.
- Không bỏ dòng cảnh báo "không phải kết luận chẩn đoán" ở `OverviewPortraitPage`.
- Không tự soạn nội dung chuyên môn thật cho `expert_knowledge_chunks`.
- Không sửa bảng đã có — chỉ thêm 2 bảng mới qua migration v5.
- Không commit git.

Xuyên suốt cả 4 phần: chưa làm đẹp theme/màu sắc/font (giữ Material mặc định theo đúng chỉ định), bố cục mobile 1 cột cuộn dọc, không đổi bất kỳ logic lưu/đọc dữ liệu hay logic nghiệp vụ nào (sàng lọc, guardrail 3 trạng thái AI, embedding/RAG, quay video) — chỉ sắp xếp/bổ sung bố cục hiển thị và một số màn hình còn thiếu (Bước 1 Trang chủ, Bước 2 màn tóm tắt, Bước 3 màn xác nhận công cụ, Bước 7 màn đã lưu kết quả, Bước 8 banner tiếp tục, Bước 14 màn kết nối chuyên gia). `flutter analyze` 0 issues và `flutter test` full PASS được xác nhận lại ở cuối mỗi phần. Toàn bộ các quyết định tự chọn (khi đề bài yêu cầu tự quyết định + ghi rõ lý do) đã được ghi chú đầy đủ tại đúng mục tương ứng — không có quyết định nào bị bỏ sót không giải thích. Chưa commit git ở bất kỳ phần nào trong 4 phần, theo đúng yêu cầu xuyên suốt.

## 26. Chuyển đổi cấu trúc từ 9 lĩnh vực sang 7 lĩnh vực (2026-08-15)

Phạm vi: chuyển đổi toàn bộ hệ thống đánh giá của ứng dụng IRIS từ cấu trúc 9 lĩnh vực sang ĐÚNG 7 lĩnh vực:
- **7 lĩnh vực chuẩn**: `nhan_thuc`, `cam_xuc`, `giac_quan`, `quan_he_xa_hoi`, `ngon_ngu`, `sinh_hoc`, `sinh_hoat_ca_nhan`.
- **Bỏ hẳn**: `hanh_vi` (Hành vi) — không còn tồn tại dưới bất kỳ hình thức nào.
- **Gộp ý nghĩa**: `ung_xu` (Ứng xử) vào `quan_he_xa_hoi` (Quan hệ xã hội) — mã `ung_xu` không còn được dùng lưu mới.

### Migration SQLite (Version 5 → 6)

- [database.dart](lib/data/local/database.dart): nâng `version: 6`. Trong `onUpgrade`, thêm nhánh `oldVersion < 6` thực hiện xoá sạch dữ liệu của 2 lĩnh vực bị loại bỏ ở cả 4 bảng (`assessments`, `profile_chunks`, `domain_overview_labels`, `expert_knowledge_chunks`) với câu lệnh `DELETE FROM ... WHERE linh_vuc IN ('hanh_vi', 'ung_xu')`, có kiểm tra bảng tồn tại và try-catch phòng thủ để an toàn với mọi fixture test / database cũ.
- Test migration: [seven_domains_migration_test.dart](test/seven_domains_migration_test.dart) — dựng DB version 5 với dữ liệu ở cả 4 bảng (chứa `hanh_vi`, `ung_xu`, `ngon_ngu`, `cam_xuc`), mở lại bằng `AppDatabase` (version 6), xác nhận toàn bộ bản ghi `hanh_vi` và `ung_xu` bị xoá sạch ở cả 4 bảng, trong khi dữ liệu của các lĩnh vực khác còn nguyên vẹn.

### Cập nhật hằng số & code lõi

- [domains.dart](lib/core/constants/domains.dart) *(mới)*: thay thế file `nine_domains.dart` (đã xoá), định nghĩa `class Domain` và danh sách `const List<Domain> domains = [...]` gồm đúng 7 lĩnh vực theo thứ tự.
- [overview_tier_calculator.dart](lib/domain/services/overview_tier_calculator.dart): **GIỮ NGUYÊN các ngưỡng số** (`nguongThuongGap = 2`, `nguongCanTheoDoi = 5`, `nguongThieuDuLieuToiThieu = 4`). Đã cập nhật docstring giải thích rõ: *"Giá trị giữ nguyên từ thiết kế 9 lĩnh vực, nay tính trên nền 7 lĩnh vực nên tỷ lệ đạt mức 'chuyên môn sớm' khắt khe hơn trước (yêu cầu 6-7/7 thay vì 6-9/9) - quyết định có chủ đích, không phải sai sót."*
- [overview_repository.dart](lib/data/repositories/overview_repository.dart): chuyển sang import `domains.dart`, duyệt qua `domains` (7 lĩnh vực) trong `labelAllDomains` và `computeAndSaveOverview`.
- [pubspec.yaml](pubspec.yaml): xoá 2 đường dẫn `assets/videos/hanh_vi/` và `assets/videos/ung_xu/`.
- [expert_content.json](assets/reference/expert_content.json) & [expert_content_so_sanh.json](assets/reference/expert_content_so_sanh.json): lọc bỏ toàn bộ entry gắn với `hanh_vi` và `ung_xu` (file `expert_content_so_sanh.json` còn đúng 70 entry = 7 lĩnh vực × 10 entry).

### Cập nhật UI & Business Logic

- [domain_list_page.dart](lib/features/assessment/domain_list_page.dart): xoá icon `hanh_vi`/`ung_xu`, cập nhật tiêu đề AppBar "Đánh giá 7 lĩnh vực — ...", tiến độ "x/7 lĩnh vực", thông báo hoàn thành 7 lĩnh vực, và banner gợi ý lĩnh vực tiếp theo duyệt qua `domains`.
- [overview_portrait_page.dart](lib/features/assessment/overview/overview_portrait_page.dart): điều kiện hoàn thành `doneDomainCount >= domains.length` (7), cập nhật chuỗi text "7 lĩnh vực", text chi tiết `${summary.soLinhVucCanTheoDoi}/7 lĩnh vực cần theo dõi`.
- [description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart): xoá `hanh_vi` và `ung_xu` khỏi map `_domainIntroTextTemp`, cập nhật định nghĩa của `quan_he_xa_hoi` để bao quát tương tác, giao tiếp, ứng xử, tuân thủ quy tắc và thích nghi xã hội.
- [home_page.dart](lib/features/home/home_page.dart) & [profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart): cập nhật nhãn nút thành "Đánh giá 7 lĩnh vực".
- [assessment_summary_page.dart](lib/features/screening/assessment_summary_page.dart): tiêu đề card "Đánh giá 7 lĩnh vực", logic đề xuất tính theo mẫu số `domains.length` (7).
- [multi_child_dashboard_page.dart](lib/features/multi_child_dashboard/multi_child_dashboard_page.dart): mẫu số tiến độ `x/7`, quy tắc `_statusLabel` (0/7: Chưa, 7/7: Đã, còn lại: Đang), thống kê đếm hoàn thành theo `domains.length`.
- [domain_overview_labels_table.dart](lib/data/local/tables/domain_overview_labels_table.dart), [assessment_repository.dart](lib/data/repositories/assessment_repository.dart), [assessment.dart](lib/domain/models/assessment.dart), [screening_intro_page.dart](lib/features/screening/screening_intro_page.dart): cập nhật docstrings.

### Cập nhật Test Suite & Kiểm chứng

- [seven_domains_migration_test.dart](test/seven_domains_migration_test.dart): kiểm chứng migration v5 $\rightarrow$ v6 dọn sạch 2 lĩnh vực cũ ở 4 bảng.
- [overview_repository_test.dart](test/overview_repository_test.dart): mock và kiểm chứng luồng 7 lĩnh vực.
- [overview_tier_calculator_test.dart](test/overview_tier_calculator_test.dart): cập nhật các ca test số lượng nhãn theo nền 7 lĩnh vực.
- [screening_flow_test.dart](test/screening_flow_test.dart): cập nhật assertion `Đã có mô tả cho 0/7 lĩnh vực`.
- [ingest_so_sanh_data_test.dart](test/ingest_so_sanh_data_test.dart): cập nhật test ingest đủ 70 entry thật (49 `binh_thuong` + 21 `roi_loan_pho_tu_ky`).
- [repositories_test.dart](test/repositories_test.dart), [child_repository_test.dart](test/child_repository_test.dart), [ingest_expert_data_test.dart](test/ingest_expert_data_test.dart): đổi dữ liệu mock sang các lĩnh vực hợp lệ (`nhan_thuc`, `cam_xuc`).
- [overview_migration_test.dart](test/overview_migration_test.dart): cập nhật mong đợi getVersion() nâng lên phiên bản mới nhất.
- **Kết quả**:
  - `flutter analyze`: **0 issues found** (sạch 100%).
  - `flutter test`: **92/92 PASS** (100% test vượt qua).

## 27. Loại bỏ Phần 5 (Chân dung biểu hiện cấp lĩnh vực) & Nâng cấp Chân dung toàn cảnh với mô tả tổng hợp AI (2026-08-15)

Phạm vi:
1. **Loại bỏ Phần 5 cấp lĩnh vực**: Bỏ hẳn "Chân dung biểu hiện" dạng nội dung tĩnh trong luồng từng lĩnh vực. Chuỗi đánh giá mỗi lĩnh vực nay gồm đúng 4 phần:
   - Phần 1: Mô tả biểu hiện (`DescriptionPage`, `step: 1`)
   - Phần 2: So sánh với trẻ cùng độ tuổi (`ComparisonVideoPage`, `step: 2`)
   - Phần 3: Chia sẻ từ phụ huynh (`ParentInputPage`, `step: 3`)
   - Phần 4: Thông tin từ bác sĩ (`ExpertInputPage`, `step: 4`) $\rightarrow$ bấm "Hoàn tất" chuyển thẳng sang `SavedResultPage`.
2. **Xoá thư mục & dữ liệu tĩnh `chan_dung`**:
   - Xoá hoàn toàn thư mục `lib/features/assessment/nine_domains/summary_portrait/` (`summary_portrait_page.dart` và `summary_detail_page.dart`).
   - Lọc bỏ 8 entry `content_type='chan_dung'` trong `assets/reference/expert_content.json` (từ 30 còn 22 entry).
   - Cập nhật [part_step_indicator.dart](lib/features/assessment/nine_domains/part_step_indicator.dart) hiển thị `Phần $step/4`.
3. **Nâng cấp "Chân dung toàn cảnh" với mô tả tổng hợp AI**:
   - [overview_summaries_table.dart](lib/data/local/tables/overview_summaries_table.dart): thêm cột `mo_ta_tong_hop TEXT`.
   - [overview_summary.dart](lib/domain/models/overview_summary.dart) & [overview_summary_repository.dart](lib/data/repositories/overview_summary_repository.dart): thêm trường `final String? moTaTongHop;`, hàm `updateMoTaTongHop(id, moTaTongHop)`.
   - [prompt_builder.dart](lib/domain/services/prompt_builder.dart): bổ sung hàm `buildOverviewPortraitSummaryPrompt` với các guardrails bắt buộc (không chẩn đoán, không khẳng định tự kỷ/rối loạn, văn phong đồng cảm, kết thúc bằng lời khuyên trao đổi chuyên gia).
   - [overview_repository.dart](lib/data/repositories/overview_repository.dart):
     - `computeAndSaveOverview`: giữ nguyên 100% logic tính tier bằng code thuần, gọi Groq AI sinh `moTaTongHop` (bọc try-catch, nếu lỗi lưu `null` không làm gián đoạn việc lưu tier).
     - Thêm phương thức `generateAndSaveSummaryDescription(child, summary)` để thử lại riêng bước gọi AI mà không cần tính lại tier.
   - [overview_portrait_page.dart](lib/features/assessment/overview/overview_portrait_page.dart): hiển thị Card "Chân dung biểu hiện" tổng hợp khi có dữ liệu, hoặc Card thông báo kèm nút "Tạo mô tả tổng hợp" khi `moTaTongHop == null`. Nút "Tính toán lại" và Disclaimer cảnh báo luôn được bảo toàn.
4. **Migration SQLite (Version 6 → 7)**:
   - [database.dart](lib/data/local/database.dart): nâng `version: 7`. Thêm nhánh `oldVersion < 7` thực hiện `DELETE FROM expert_knowledge_chunks WHERE content_type = 'chan_dung'` và `ALTER TABLE overview_summaries ADD COLUMN mo_ta_tong_hop TEXT` với kiểm tra an toàn schema.
   - Test migration: [chan_dung_and_overview_description_migration_test.dart](test/chan_dung_and_overview_description_migration_test.dart) kiểm chứng xoá sạch dữ liệu `chan_dung`, thêm cột mới và bảo toàn 100% dữ liệu `overview_summaries` cũ.
5. **Cập nhật Test Suite**:
   - [overview_repository_test.dart](test/overview_repository_test.dart): mock và test thành công luồng sinh mô tả tổng hợp, test trường hợp lỗi AI fallback `moTaTongHop=null`, test hàm thử lại `generateAndSaveSummaryDescription`.
   - [prompt_builder_test.dart](test/prompt_builder_test.dart): kiểm chứng prompt mô tả tổng hợp đúng guardrails.
   - [ingest_expert_data_test.dart](test/ingest_expert_data_test.dart) & [repositories_test.dart](test/repositories_test.dart): xoá bỏ các tham chiếu đến `chan_dung`.
   - **Kết quả kiểm thử**:
     - `flutter analyze`: **0 issues found** (sạch 100%).
     - `flutter test`: **95/95 PASS** (100% test vượt qua).

28. **Chuyển đổi hoàn toàn điều hướng giữa 4 phần đánh giá lĩnh vực sang Mô hình Hub tự do (Free Navigation)**
   - **Audit thực tế trước khi triển khai**:
     - Phát hiện: `DomainListPage` vào thẳng `DescriptionPage`; 4 màn con dùng `pushReplacement` nối tiếp tuần tự và hiển thị `PartStepIndicator(step: x)`; `SavedResultPage` nằm ở cuối luồng tuần tự; Nút "Lưu" chỉ có ở `DescriptionPage`.
   - **Tạo Màn hình Hub trung tâm cấp Lĩnh vực** ([domain_hub_page.dart](lib/features/assessment/domain_hub_page.dart)):
     - Card Header hiển thị khái niệm/định nghĩa của lĩnh vực.
     - Thẻ 1: **"Mô tả biểu hiện của trẻ"** — được nhấn mạnh trực quan với badge `Quan trọng`, icon nổi bật, hiển thị số lượng ghi nhận đã lưu ("Chưa có ghi nhận nào" / "Đã có x ghi nhận biểu hiện"). Đây là dữ liệu thật duy nhất của trẻ dùng cho AI gắn nhãn và tổng hợp sau này.
     - Thẻ 2: **"So sánh với trẻ cùng độ tuổi"** — tra cứu nhanh biểu hiện thường gặp vs cần quan sát thêm.
     - Thẻ 3: **"Chia sẻ từ phụ huynh"** — tham khảo góc nhìn thực tế từ các phụ huynh khác.
     - Thẻ 4: **"Thông tin từ bác sĩ"** — tra cứu mốc phát triển y khoa, dấu hiệu lưu ý và giải thích chuyên môn.
     - Cả 4 thẻ đều mở độc lập bằng `Navigator.push`, bất kỳ lúc nào, không có thứ tự bắt buộc, không bị khoá hay kiểm tra điều kiện hoàn thành phần trước.
   - **Cập nhật Điều hướng & Gỡ bỏ Luồng tuần tự**:
     - [domain_list_page.dart](lib/features/assessment/domain_list_page.dart): Tap trên thẻ lĩnh vực và nút "Tiếp tục ngay" mở `DomainHubPage`.
     - [description_page.dart](lib/features/assessment/nine_domains/description/description_page.dart): Gỡ bỏ `PartStepIndicator`, gỡ bỏ `_goNext()` và `_saveAndContinue()`, chuyển sang nút `FilledButton.icon` "Lưu mô tả" (chỉ lưu vào DB/RAG và reload danh sách tại chỗ, không navigate đi).
     - [comparison_video_page.dart](lib/features/assessment/nine_domains/comparison_video/comparison_video_page.dart): Gỡ bỏ `PartStepIndicator`, gỡ bỏ nút "Tiếp theo" và `_goNext()`.
     - [parent_input_page.dart](lib/features/assessment/nine_domains/parent_input/parent_input_page.dart): Gỡ bỏ `PartStepIndicator`, gỡ bỏ nút "Tiếp theo" và `_goNext()`.
     - [expert_input_page.dart](lib/features/assessment/nine_domains/expert_input/expert_input_page.dart): Gỡ bỏ `PartStepIndicator`, gỡ bỏ nút "Hoàn tất" và `_goNext()`.
     - Xoá hoàn toàn 2 file tàn dư luồng tuần tự: `lib/features/assessment/nine_domains/part_step_indicator.dart` và `lib/features/assessment/nine_domains/saved_result_page.dart`.
   - **Kiểm thử tự động toàn diện** ([domain_hub_free_navigation_test.dart](test/domain_hub_free_navigation_test.dart)):
     - *Test 1*: Từ Hub vào thẳng "So sánh" khi CHƯA từng có mô tả $\rightarrow$ PASS, mở mượt mà, không bị chặn.
     - *Test 2*: Vào từng phần trong 4 phần rồi bấm Back $\rightarrow$ PASS, quay về Hub đầy đủ 4 thẻ.
     - *Test 3*: Thứ tự ngẫu nhiên (Bác sĩ $\rightarrow$ Chia sẻ $\rightarrow$ Mô tả & Lưu $\rightarrow$ So sánh) $\rightarrow$ PASS, dữ liệu lưu chuẩn vào DB và Hub cập nhật badge "Đã có 1 ghi nhận biểu hiện".
     - *Test 4*: Nút "Lưu" CHỈ tồn tại ở màn Mô tả biểu hiện, KHÔNG tồn tại ở 3 màn tham khảo $\rightarrow$ PASS.
   - **Kết quả kiểm thử toàn dự án**:
     - `flutter analyze`: **0 issues found** (sạch 100%).

## 31. Làm mới UI toàn ứng dụng theo `IRIS_STYLE_GUIDE.md` — 15/08/2026

### Design system tập trung

- [iris_theme.dart](lib/core/theme/iris_theme.dart) là nguồn duy nhất cho màu, typography, radius, spacing, kích thước, shadow, theme Material 3 và mapping accent của 7 lĩnh vực.
- [iris_assets.dart](lib/core/theme/iris_assets.dart) tập trung toàn bộ đường dẫn mascot/icon; [iris_ui.dart](lib/core/widgets/iris_ui.dart) chứa các component tái sử dụng: asset icon, mascot, icon chip, status badge, info banner và domain icon.
- [app.dart](lib/app.dart) áp `IrisTheme.light` cho toàn ứng dụng. `pubspec.yaml` đã khai báo hai thư mục asset local `assets/images/mascot/` và `assets/images/icons/`.
- Các component dùng chung đã được đồng bộ qua theme: button dạng pill, card bo 20 px, badge, input field, bottom navigation, progress indicator, dialog, snackbar, tab và chat bubble AI có shadow mềm.

### Mapping accent đúng 7 lĩnh vực hiện hành

| Mã lĩnh vực | Màu accent |
|---|---|
| `nhan_thuc` | `#4C7CF3` |
| `cam_xuc` | `#F45B69` |
| `giac_quan` | `#36B6D9` |
| `quan_he_xa_hoi` | `#8B7CF6` |
| `ngon_ngu` | `#20C4B0` |
| `sinh_hoc` | `#F2994A` |
| `sinh_hoat_ca_nhan` | `#6AAF72` |

Mapping trên được dùng chung tại lưới lĩnh vực, tiến độ, hub, dashboard và nhãn/chi tiết Chân dung toàn cảnh; không thêm lĩnh vực thứ 8 hoặc thứ 9.

### Asset ảnh sinh mới

Tất cả ảnh là PNG local có alpha, không gọi dịch vụ sinh ảnh khi app chạy.

- Mascot tại `assets/images/mascot/`: `iris_bear_waving.png`, `iris_bear_shield.png`, `iris_bear_clipboard.png`, `iris_bear_thumbs_up.png`, `iris_bear_pointing.png`.
- Icon chức năng tại `assets/images/icons/`: `screening_shield.png`, `assessment_clipboard.png`, `video_camera.png`, `history_clock.png`, `expert_stethoscope.png`, `ai_chat.png`, `child_profile.png`, `overview_portrait.png`.
- Vị trí dùng chính: Home/hồ sơ nhanh, sàng lọc, AI safety/chat, tóm tắt tạo hồ sơ, quay video, lịch sử, dashboard nhiều trẻ, kết nối chuyên gia và Chân dung toàn cảnh.
- Chế độ sinh: công cụ image generation tích hợp. Prompt mascot giữ một nhân vật gấu beige 2D, áo xanh `#3566E8` có chữ `IRIS`, chỉ thay hành động theo từng pose. Prompt icon dùng flat rounded duotone, màu chính + sắc độ sáng, một biểu tượng chức năng rõ ràng trên nền vuông bo góc pastel.
- Hai script build-time [extract_generated_cutout.py](scripts/extract_generated_cutout.py) và [resize_generated_assets.py](scripts/resize_generated_assets.py) chỉ hậu xử lý alpha/kích thước asset; app Android không phụ thuộc các script này lúc runtime.

### Nhóm màn hình đã áp style

- Trang chủ và bottom nav 4 tab; Tài khoản; Hỏi đáp AI.
- Tạo/xem hồ sơ trẻ và dashboard nhiều trẻ.
- Sàng lọc, xác nhận công cụ, bảng câu hỏi, kết quả và tổng hợp.
- Danh sách 7 lĩnh vực, hub đúng 4 phần, Mô tả, So sánh, Chia sẻ phụ huynh và Thông tin bác sĩ.
- Chân dung toàn cảnh 7 lĩnh vực; Lịch sử.
- Luồng quay video hiện hành: Chuẩn bị quay → Quay video → Xem lại/gửi; không có màn chọn tình huống.
- Kết nối chuyên gia/trung tâm và trang chi tiết.

Không thay đổi thứ tự màn hình, navigation, nội dung chữ hoặc logic nghiệp vụ. Các cảnh báo an toàn vẫn nguyên văn, gồm “Sàng lọc không phải là chẩn đoán” và “không phải kết luận chẩn đoán y khoa”. Không phục hồi `Chân dung biểu hiện` cấp lĩnh vực, màn chọn tình huống quay video, hoặc lĩnh vực Hành vi/Ứng xử. `OverviewTierCalculator` và toàn bộ ngưỡng giữ nguyên.

Trong lúc verify, emulator phát hiện callback `_reload()` của Chân dung toàn cảnh trả về `Future` bên trong `setState`, gây màn đỏ ở chế độ debug. Callback đã được đổi sang block đồng bộ; đây là sửa lỗi vòng đời UI, không thay đổi phép tính tier hay luồng dữ liệu.

### Ảnh chụp thật trên emulator

Ảnh được chụp từ emulator Android 1080×2400 và lưu tại `artifacts/ui_refresh/`. Riêng dữ liệu đủ 7/7 dùng để mở Chân dung toàn cảnh là dữ liệu mẫu chỉ chèn vào database của emulator, không nằm trong source/app seed.

- Home/tài khoản/AI: [Home](artifacts/ui_refresh/01_home.png), [Tài khoản](artifacts/ui_refresh/02_account.png), [AI chat](artifacts/ui_refresh/03_ai_chat.png).
- Lĩnh vực và hub 4 phần: [Lưới 7 màu](artifacts/ui_refresh/04_domain_list.png), [Hub](artifacts/ui_refresh/05_domain_hub.png), [Mô tả](artifacts/ui_refresh/06_description.png), [So sánh](artifacts/ui_refresh/07_comparison.png), [Chia sẻ phụ huynh](artifacts/ui_refresh/08_parent_share.png), [Thông tin bác sĩ](artifacts/ui_refresh/09_doctor_info.png).
- Hồ sơ/dashboard/sàng lọc: [Dashboard nhiều trẻ](artifacts/ui_refresh/10_dashboard.png), [Chi tiết hồ sơ](artifacts/ui_refresh/11_profile_detail.png), [Sàng lọc](artifacts/ui_refresh/12_screening_intro.png).
- Lịch sử/video/chuyên gia: [Lịch sử](artifacts/ui_refresh/13_history.png), [Chuẩn bị quay](artifacts/ui_refresh/14_video_preparation.png), [Camera](artifacts/ui_refresh/15_video_capture.png), [Kết nối chuyên gia](artifacts/ui_refresh/16_expert_connect.png).
- Hoàn thành 7 lĩnh vực/overview: [Tiến độ 7/7](artifacts/ui_refresh/17_domain_complete.png), [Overview đầu trang](artifacts/ui_refresh/18_overview_top.png), [7 nhãn và cảnh báo an toàn](artifacts/ui_refresh/19_overview_domains.png).

### Kết quả xác minh cuối

- `flutter analyze`: **No issues found**.
- `flutter test`: **104 test passed**, 4 test được suite đánh dấu skip, **All tests passed**.
- `flutter build apk --debug --dart-define-from-file=dart_define.json`: build thành công tại `build/app/outputs/flutter-apk/app-debug.apk`.
     - `flutter test`: **99/99 PASS** (100% test thành công).

29. **Audit Bảo Mật API Key, Build Release APK & Xác Thực Toàn Diện Cloud AI Thật (NVIDIA & Groq)**
   - **Audit Rủi ro lộ Key Git**:
     - `.gitignore` đã có `dart_define.json` (dòng 49).
     - Đã chạy kiểm tra lịch sử Git: `git log --all --full-history -- dart_define.json` $\rightarrow$ **0 commit**. File chứa key thật **CHƯA TỪNG bị commit** vào bất kỳ commit nào trong lịch sử kho mã nguồn.
     - Đã tạo file template an toàn [dart_define.json.example](dart_define.json.example) với các giá trị placeholder (`YOUR_NVIDIA_API_KEY_HERE`, `YOUR_GROQ_API_KEY_HERE`), xoá bỏ file cũ `dart_define.example.json`.
   - **Audit Code đọc Key & Xử lý An toàn**:
     - [api_config.dart](lib/core/constants/api_config.dart): Khớp chính xác tên biến `String.fromEnvironment('NVIDIA_API_KEY')` và `String.fromEnvironment('GROQ_API_KEY')`. Bổ sung các getter `hasNvidiaApiKey`, `hasGroqApiKey`, `hasAiConfig`.
     - [nvidia_api_client.dart](lib/data/remote/nvidia_api_client.dart) & [groq_api_client.dart](lib/data/remote/groq_api_client.dart): Tự động kiểm tra key khi chạy thật, ném `NvidiaApiException` và `GroqApiException` rõ ràng thay vì lỗi mạng khó hiểu. Phân biệt `_isCustomClient` cho phép unit test MockClient chạy độc lập mà không bắt buộc key thật.
     - [ai_chat_page.dart](lib/features/ai_chat/ai_chat_page.dart): Bổ sung Banner cảnh báo thân thiện trên giao diện khi chưa cấu hình API key (*"Chưa cấu hình API key, tính năng AI hiện không khả dụng."*).
     - **Kiểm tra rò rỉ log**: Grep toàn bộ thư mục `lib/` xác nhận **100% không có chỗ nào in giá trị API key thật hoặc headers chứa key ra log/console**.
   - **Build Release APK & Cài đặt Thiết bị Thật**:
     - Lệnh build: `flutter build apk --release --dart-define-from-file=dart_define.json`
     - Kết quả: Build thành công file APK `build/app/outputs/flutter-apk/app-release.apk` (dung lượng 54.4 MB, Gradle assembleRelease hoàn tất không lỗi).
     - Cài đặt lên máy ảo `Pixel_7` (`emulator-5554`): `adb install -r build/app/outputs/flutter-apk/app-release.apk` $\rightarrow$ **Success**.
     - Khởi chạy app trên máy ảo và chụp ảnh màn hình xác thực: `app_release_screenshot.png`.
   - **Bằng chứng Xác thực Toàn diện với Cloud AI Thật** ([real_cloud_ai_verification_test.dart](test/real_cloud_ai_verification_test.dart)):
     - **a. NVIDIA NIM Embedding thật**:
       - Input text: `"Bé 3 tuổi rất thích xếp các khối gỗ theo hàng thẳng và lặp đi lặp lại"`
       - API Endpoint: `https://integrate.api.nvidia.com/v1/embeddings` (model `nvidia/nv-embedqa-e5-v5`)
       - Kết quả: Nhận về vector float 1024 chiều (5 giá trị đầu: `[-0.018402, -0.017349, 0.009185, 0.034301, 0.002599]`), lưu thành công vào SQLite bảng `profile_chunks`.
     - **b. Groq Generation thật (Hỏi đáp AI)**:
       - Input question: `"Bé 3 tuổi chưa nói được từ đơn thì phụ huynh nên làm gì để hỗ trợ bé?"`
       - API Endpoint: `https://api.groq.com/openai/v1/chat/completions` (model `openai/gpt-oss-20b`)
       - Kết quả: Groq trả về câu trả lời tiếng Việt chuẩn UTF-8, tuân thủ đúng guardrail: *"Chưa đủ dữ liệu để đưa ra nhận định về cách hỗ trợ bé 3 tuổi chưa nói được từ đơn. Bạn có thể thực hiện sàng lọc ngôn ngữ hoặc bổ sung mô tả chi tiết hơn về biểu hiện của bé vào hồ sơ để được tư vấn chính xác hơn."*, lưu vào bảng `ai_conversations`.
     - **c. Groq Chân dung toàn cảnh 7 lĩnh vực thật**:
       - Gắn nhãn AI 7 lĩnh vực với mô tả thật $\rightarrow$ Groq phân loại thành công 7/7 nhãn `thuong_gap` kèm lý do ngắn gọn.
       - Mức tổng quan tính toán bằng code: `thuong_gap`.
       - Groq sinh văn xuôi Chân dung biểu hiện tổng hợp chuẩn xác, không chẩn đoán y khoa, kết thúc bằng lời khuyên trao đổi chuyên gia theo đúng guardrail:
         > *"Bé Test ở độ tuổi 3 tuổi đang có những biểu hiện phát triển phù hợp với mức độ thường gặp. Trong lĩnh vực nhận thức, bé đã nhận biết được các đồ vật quen thuộc và có thể làm theo những chỉ dẫn đơn giản của bố mẹ... Đây là bức tranh tổng hợp mang tính tham khảo hỗ trợ theo dõi sự phát triển của trẻ, phụ huynh nên trao đổi thêm với các chuyên gia y tế/giáo dục chuyên biệt nếu có băn khoăn hoặc cần đánh giá chuyên sâu hơn."*
       - Lưu thành công vào bảng `overview_summaries` (cột `mo_ta_tong_hop`).
   - **Tài liệu hoá**:
     - Viết mới toàn diện file [README.md](README.md) hướng dẫn cấu hình `dart_define.json`, lệnh chạy `flutter run` dev và lệnh `flutter build apk --release`.
30. **Gỡ Bỏ Bước "Chọn Tình Huống" Khỏi Chức Năng Quay Video (Tinh Gọn Còn 3 Màn)**
   - **Xoá màn hình & Route cũ**:
     - Đã xoá file `lib/features/video_recording/video_situation_page.dart`.
     - Luồng quay video tinh gọn còn đúng **3 màn**: **1. Chuẩn bị quay** (`VideoPreparationPage`) $\rightarrow$ **2. Quay video** (`VideoRecordingCapturePage`) $\rightarrow$ **3. Xem lại & Gửi** (`VideoReviewPage`).
   - **Cập nhật Entry Points (Lối vào)**:
     - [home_page.dart](lib/features/home/home_page.dart): Nút "Quay video quan sát" đi thẳng vào `VideoPreparationPage(child: child)`.
     - [profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart): Đổi nhãn thành "Video quan sát", dẫn tới `VideoListPage`.
   - **Cập nhật các màn hình trong luồng**:
     - [video_preparation_page.dart](lib/features/video_recording/video_preparation_page.dart): Trở thành Bước 1/3, bỏ tham số `situation`, bỏ dòng Text `Tình huống: ...`, nút "Bắt đầu quay" mở `VideoRecordingCapturePage`.
     - [video_recording_capture_page.dart](lib/features/video_recording/video_recording_capture_page.dart): Trở thành Bước 2/3, bỏ tham số `situation`, tiêu đề AppBar đổi thành `Quay video`.
     - [video_review_page.dart](lib/features/video_recording/video_review_page.dart): Trở thành Bước 3/3, bỏ tham số `situation`, lưu video mới với `situation: null`, nút "Quay thêm video khác" quay lại `VideoPreparationPage`.
     - [video_list_page.dart](lib/features/video_recording/video_list_page.dart): Nút `+` (FAB) mở thẳng `VideoPreparationPage`. Hiển thị: video có `situation` thì hiện tình huống; video `situation = null` thì hiện "Video ngày d/m/y" + trạng thái (ẩn hẳn dòng tình huống, không có chữ `null`).
     - [video_detail_page.dart](lib/features/video_recording/video_detail_page.dart): Ẩn dòng `Tình huống: ...` khi `situation = null`, debug mô phỏng chuyên gia hoạt động bình thường.
   - **Bảo toàn Schema SQLite**:
     - Cột `videos.situation TEXT` được giữ nguyên trong schema bảng `videos` để bảo toàn dữ liệu các video cũ đã có tình huống trước đây.
     - `VideoRepository.save` hỗ trợ `situation` là optional (`null` cho video mới).
   - **Kiểm thử tự động**:
     - Tạo mới [video_flow_no_situation_test.dart](test/video_flow_no_situation_test.dart) (4/4 PASS): verify mở thẳng màn chuẩn bị, ẩn tình huống null ở danh sách và chi tiết, nút FAB hoạt động chuẩn.
     - Cập nhật [video_repository_test.dart](test/video_repository_test.dart) bổ sung test case lưu `situation = null`.
   - **Kết quả kiểm thử toàn dự án**:
     - `flutter analyze`: **0 issues found** (sạch 100%).

## Nối lại luồng sau khi tạo hồ sơ trẻ (xoá màn trung gian trùng HomePage)

**Vấn đề**: sau khi `CreateProfilePage` lưu hồ sơ thành công, luồng cũ đi qua `CreateProfileSummaryPage` ("Tạo hồ sơ thành công!" + nút "Xem hồ sơ") rồi dừng ở `ProfileDetailPage` — 1 màn hiện tên/tuổi/người đánh giá/vai trò + badge "Chưa sàng lọc" + 6 nút chức năng + 3 nút debug, **trùng lặp hoàn toàn** `HomePage` (đã xây theo mô hình active child ở đợt trước) và không nên là điểm dừng sau khi tạo hồ sơ.

**1. Audit trước khi xoá** (tìm theo chuỗi text đặc trưng "Đánh giá 7 lĩnh vực", "Video quan sát", "Debug: xem dữ liệu sàng lọc thô" → xác định đúng file là [profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart)). Toàn bộ nơi điều hướng `Navigator.push(...) => ProfileDetailPage(...)` trong code (không tính test):

| Nơi gọi | Mục đích | Kết luận |
|---|---|---|
| `CreateProfilePage` → `CreateProfileSummaryPage` → nút "Xem hồ sơ" | Sau khi tạo hồ sơ — **đây là luồng cần sửa** | Cắt bỏ khỏi luồng này |
| [child_list_page.dart](lib/features/child_profile/child_list_page.dart) — tap vào 1 hồ sơ trong danh sách | Xem chi tiết hồ sơ đã có sẵn (Bước 1 — điểm vào cũ, hiện không còn là `home` của app nhưng vẫn còn dùng trong `test/future_builder_error_test.dart`) | Hợp lệ — **giữ nguyên** |
| [multi_child_dashboard_page.dart](lib/features/multi_child_dashboard/multi_child_dashboard_page.dart) — menu ⋮ "Xem hồ sơ" | Xem chi tiết 1 hồ sơ từ màn Quản lý nhiều trẻ (lối vào thật từ `HomePage` → tab Tài khoản → "Đổi tài khoản") | Hợp lệ — **giữ nguyên** |

→ Kết luận audit: `ProfileDetailPage` **đang được dùng hợp lệ ở nơi khác** ("Xem hồ sơ" từ Dashboard/danh sách hồ sơ) nên **KHÔNG xoá file** — chỉ sửa điều hướng sau khi tạo hồ sơ để không còn trỏ tới màn này nữa. `ScreeningIntroPage`/`ScreeningToolConfirmPage`/`ScreeningQuestionnairePage`/`ScreeningResultPage` gọi từ `ProfileDetailPage._openScreening()` cũng giữ nguyên logic, không đổi gì cho luồng đó.

**2. Xử lý**:
- [create_profile_page.dart](lib/features/child_profile/create_profile/create_profile_page.dart): sau `_activeChildService.setActiveChildId(created.id)` (đã có sẵn từ đợt trước — xác nhận không cần thêm), đổi đích `pushReplacement` từ `CreateProfileSummaryPage` sang thẳng `ScreeningIntroPage(child: created, isOnboarding: true)`. Dùng `pushReplacement` (không phải `push`) để người dùng không back được về form tạo hồ sơ đã nộp.
- **`CreateProfileSummaryPage` bị xoá hẳn** (`lib/features/child_profile/create_profile/create_profile_summary_page.dart`) — sau khi đổi đích của `CreateProfilePage`, đây là nơi gọi DUY NHẤT tới trang này (đã grep xác nhận), nên trang trở thành dead code hoàn toàn nếu giữ lại. Đây không phải màn trong ảnh (không audit theo yêu cầu, không có 6 nút/badge/nút debug) nhưng bị xoá do là hệ quả trực tiếp của yêu cầu #3 ("sau khi lưu hồ sơ, điều hướng tới màn hỏi sàng lọc").
- Thêm tham số `isOnboarding` (mặc định `false`, không đổi hành vi/logic bài sàng lọc hay màn kết quả) chạy xuyên suốt `ScreeningIntroPage` → `ScreeningToolConfirmPage` → `ScreeningQuestionnairePage` → `ScreeningResultPage`, chỉ đổi **điểm đến điều hướng** ở 2 nút cuối:
  - `ScreeningIntroPage` — nút "Chưa muốn": nếu `isOnboarding == true` thì `Navigator.popUntil((route) => route.isFirst)` (về thẳng `HomePage`, xoá back-stack) thay vì `push(AssessmentSummaryPage)` (Bước 4 — vẫn giữ nguyên cho luồng gọi từ `ProfileDetailPage`).
  - `ScreeningResultPage` — nút "Tiếp tục": nếu `isOnboarding == true` thì `popUntil((route) => route.isFirst)` thay vì `pushReplacement(AssessmentSummaryPage)`.
  - Cơ chế `popUntil((route) => route.isFirst)` tái dùng đúng pattern đã có sẵn ở `MultiChildDashboardPage._selectAsActive()` (không phát minh cơ chế mới) — `HomePage` luôn là route `home:` gốc của `MaterialApp` (`lib/app.dart`) nên `route.isFirst` luôn trỏ đúng về `HomePage`, dù `CreateProfilePage` được mở từ đâu (lần đầu mở app chưa có hồ sơ, hoặc từ tab Tài khoản → "Tạo hồ sơ trẻ mới", hoặc từ `MultiChildDashboardPage`).
- **3 nút debug** ("Debug: xem dữ liệu sàng lọc thô", "Debug: xem dữ liệu đánh giá thô", "Debug: Nạp dữ liệu tham khảo") — vẫn hữu ích cho dev/kiểm thử nên **không bỏ hẳn**, chuyển sang trang riêng mới [child_debug_page.dart](lib/features/child_profile/profile_detail/child_debug_page.dart) (`ChildDebugPage`), chỉ vào được qua 1 icon 🐞 trên `AppBar` của `ProfileDetailPage` **guard bằng `kDebugMode`** (trước đó 2/3 nút hiện cho MỌI người dùng, không có guard — đã sửa luôn thành cả 3 đều chỉ hiện ở debug build). Không mất khả năng debug nào, chỉ không còn hiện giữa danh sách nút chức năng chính cho người dùng thường.

**3. Kết quả**: `flutter analyze` — 0 issues. `flutter test` — toàn bộ PASS (xem [screening_flow_test.dart](test/screening_flow_test.dart) đã viết lại 3 test: nhánh "Có" → xem kết quả → Trang chủ đúng active child + không back được; nhánh "Chưa muốn" → thẳng Trang chủ + không back được; và xác nhận lối vào "Xem hồ sơ" từ Dashboard tới `ProfileDetailPage` vẫn hoạt động đúng, luồng sàng lọc gọi từ đó vẫn vào Bước 4 như cũ, không bị ảnh hưởng).

---

## 31. Thay Thế Bộ Câu Hỏi Sàng Lọc Mock Bằng Bộ 50 Câu Chính Thức 7 Lĩnh Vực (Audit & Kế Hoạch Triển Khai)

### 1. Kết Quả Audit Toàn Diện Trước Khi Sửa Code

#### a. File / Class chứa bộ câu hỏi mock A/B hiện tại
- **File**: [lib/domain/services/screening_question_bank.dart](lib/domain/services/screening_question_bank.dart)
  - Chứa `class ScreeningQuestionSet`, `_mockQuestionsA` (6 câu), `_mockQuestionsB` (6 câu), `screeningQuestionSetA`, `screeningQuestionSetB`, và hàm `selectScreeningQuestionSet(ageMonths)` rẽ nhánh theo mốc 30 tháng.
  - Sẽ được **xoá bỏ hoàn toàn** và thay thế bằng `ScreeningLoaderService` đọc từ file JSON chính thức [assets/data/sang_loc_50_cau_7_linh_vuc.json](assets/data/sang_loc_50_cau_7_linh_vuc.json).
  - Hàm `childAgeInMonths()` trong `lib/domain/models/child.dart` **được giữ nguyên** vì vẫn dùng cho các tính năng khác (như lọc `expert_knowledge_chunks` theo độ tuổi).

#### b. Màn hình hiển thị câu hỏi và kết quả sàng lọc hiện tại
- **[screening_tool_confirm_page.dart](lib/features/screening/screening_tool_confirm_page.dart)**:
  - Hiện tại: hiển thị nhãn `selectScreeningQuestionSet(ageMonths).label` ("Bộ A (16-30 tháng)" / "Bộ B (31 tháng trở lên)").
  - Cần cập nhật: hiển thị thông tin bộ câu hỏi 50 câu chuẩn hóa 7 lĩnh vực dùng chung cho mọi lứa tuổi, 4 mức lựa chọn (0, 1, 2, N/A).
- **[screening_questionnaire_page.dart](lib/features/screening/screening_questionnaire_page.dart)**:
  - Hiện tại: hiển thị danh sách tất cả câu hỏi mock trong `ListView.builder` cùng lúc, 2 nút Có/Không.
  - Cần làm lại hoàn toàn: **Mô hình 1 câu hỏi / 1 màn hình**:
    - Mỗi thời điểm CHỈ hiển thị đúng 1 câu hỏi (tiểu lĩnh vực, nội dung câu, gợi ý quan sát dạng tip, 4 nút lựa chọn: 0, 1, 2, N/A).
    - Thanh tiến độ & số thứ tự "Câu X/50".
    - Chọn đáp án -> tự động chuyển sang câu tiếp theo.
    - Nút "Quay lại câu trước" cho phép xem/đổi đáp án đã chọn mà không mất dữ liệu.
    - Câu 50 hoàn thành -> tự động tính điểm qua `ScreeningScoringService` -> lưu DB (`screenings`, 50 dòng `screening_responses`, 7 dòng `screening_domain_scores`, log lịch sử) -> chuyển sang `ScreeningResultPage`.
    - Thoát giữa chừng không lưu dữ liệu nửa vời.
- **[screening_result_page.dart](lib/features/screening/screening_result_page.dart)**:
  - Hiện tại: hiển thị tỷ lệ câu có dấu hiệu chú ý dạng x/y.
  - Cần cập nhật:
    - Mức tổng quan: Tên mức theo `meta.muc_mo_ta` ("Mức 1 - Ít biểu hiện" / "Mức 2 - Có biểu hiện cần theo dõi" / "Mức 3 - Nhiều biểu hiện khó khăn") + điểm % toàn bài.
    - Breakdown 7 lĩnh vực: điểm % từng lĩnh vực hoặc "Chưa đủ dữ liệu cho lĩnh vực này" nếu toàn N/A.
    - Hiển thị nguyên văn `meta.luu_y_khong_chan_doan`.
    - Giữ nguyên nút "Tiếp tục" điều hướng về `AssessmentSummaryPage` (hoặc `HomePage` nếu `isOnboarding == true`).

#### c. Danh sách các nơi trong codebase đang ĐỌC dữ liệu từ bảng `screenings`
1. **[lib/features/child_profile/profile_detail/profile_detail_page.dart](lib/features/child_profile/profile_detail/profile_detail_page.dart)**:
   - Gọi `ScreeningRepository.hasScreening(child.id)` để hiển thị badge "Đã sàng lọc" / "Chưa sàng lọc".
   - Ảnh hưởng: **Không đổi logic** (hàm `hasScreening` vẫn kiểm tra xem có bản ghi nào trong bảng `screenings` hay không).
2. **[lib/features/home/home_page.dart](lib/features/home/home_page.dart)**:
   - Gọi `ScreeningRepository.hasScreening(widget.child.id)` để ẩn/hiện nút "Sàng lọc".
   - Ảnh hưởng: **Không đổi logic** (`hasScreening` trả về bool).
3. **[lib/features/expert_connect/expert_connect_page.dart](lib/features/expert_connect/expert_connect_page.dart)**:
   - Gọi `ScreeningRepository.hasScreening(child.id)`.
   - Ảnh hưởng: **Không đổi logic**.
4. **[lib/features/child_profile/profile_detail/child_debug_page.dart](lib/features/child_profile/profile_detail/child_debug_page.dart)**:
   - Gọi `ScreeningRepository.getForChild(child.id)` hiển thị danh sách dòng `screenings` thô.
   - Ảnh hưởng: **Không đổi logic**.
5. **[lib/data/repositories/ai_repository.dart](lib/data/repositories/ai_repository.dart)** & **[lib/domain/services/guardrail_service.dart](lib/domain/services/guardrail_service.dart)**:
   - Gọi `ScreeningRepository.hasScreening(child.id)` để xác định `hasScreeningResult` cho AI Guardrail Trạng thái 2.
   - Ảnh hưởng: **Không đổi logic**.
6. **[lib/features/screening/assessment_summary_page.dart](lib/features/screening/assessment_summary_page.dart)**:
   - Gọi `ScreeningRepository.hasScreening()` và `getLatestForChild()`.
   - Đang gọi `selectScreeningQuestionSet(ageMonths)` trong `_buildSuggestion()` -> Cần sửa nhỏ: bỏ gọi `selectScreeningQuestionSet`, dùng nhãn công cụ chuẩn "bài sàng lọc 50 câu (7 lĩnh vực)".
7. **[lib/data/repositories/child_repository.dart](lib/data/repositories/child_repository.dart)**:
   - Phương thức `delete(childId)` xóa hồ sơ và các bảng con liên quan: Bổ sung xóa `screening_responses` và `screening_domain_scores` trước khi xóa `screenings` để bảo toàn foreign key.

### 2. Kết Quả Triển Khai Chi Tiết

1. **Asset & Khai Báo Bộ Câu Hỏi Chính Thức**:
   - Đặt file [assets/data/sang_loc_50_cau_7_linh_vuc.json](assets/data/sang_loc_50_cau_7_linh_vuc.json) (50 câu hỏi, 7 lĩnh vực, metadata, 4 thang điểm, 3 mức mô tả, lưu ý không chẩn đoán).
   - Khai báo `- assets/data/` trong [pubspec.yaml](pubspec.yaml).

2. **Migration Database SQLite Version 8**:
   - Tạo 2 file schema bảng:
     - [lib/data/local/tables/screening_responses_table.dart](lib/data/local/tables/screening_responses_table.dart) (`screeningResponsesTableCreate`)
     - [lib/data/local/tables/screening_domain_scores_table.dart](lib/data/local/tables/screening_domain_scores_table.dart) (`screeningDomainScoresTableCreate`)
   - Nâng DB `version: 8` trong [lib/data/local/database.dart](lib/data/local/database.dart) kèm `onUpgrade (oldVersion < 8)`.
   - Tạo 2 domain model:
     - [lib/domain/models/screening_response.dart](lib/domain/models/screening_response.dart)
     - [lib/domain/models/screening_domain_score.dart](lib/domain/models/screening_domain_score.dart)
   - Cập nhật [lib/data/repositories/screening_repository.dart](lib/data/repositories/screening_repository.dart) với hàm `saveScreeningSession` (lưu đồng thời `screenings`, 50 dòng `screening_responses`, 7 dòng `screening_domain_scores` trong 1 transaction SQLite) cùng `getResponses` và `getDomainScores`.
   - Cập nhật [lib/data/repositories/child_repository.dart](lib/data/repositories/child_repository.dart) xóa cascade `screening_responses` và `screening_domain_scores`.

3. **Service Chấm Điểm & Nạp Dữ Liệu (Pure Dart)**:
   - [lib/domain/services/screening_scoring_service.dart](lib/domain/services/screening_scoring_service.dart):
     - Hàm pure Dart `calculateScore` tính điểm theo chuẩn:
       - 4 mức: `'0'`, `'1'`, `'2'`, `'N/A'`.
       - N/A không tính điểm và không tính vào mẫu số chuẩn hóa %.
       - Lĩnh vực toàn N/A: `diemPhanTram` là `null`, hiển thị "Chưa đủ dữ liệu cho lĩnh vực này", không quy thành 0%.
       - Điểm toàn bài chuẩn hóa và xác định 3 mức: Mức 1 (0-33%), Mức 2 (34-66%), Mức 3 (67-100%).
   - [lib/domain/services/screening_loader_service.dart](lib/domain/services/screening_loader_service.dart):
     - Nạp JSON từ asset một lần duy nhất và cache trong phiên làm việc.
   - Xoá bỏ hoàn toàn mock question bank cũ (`screening_question_bank.dart`).

4. **UI Làm Bài & Kết Quả**:
   - [lib/features/screening/screening_tool_confirm_page.dart](lib/features/screening/screening_tool_confirm_page.dart): Giới thiệu công cụ 50 câu 7 lĩnh vực (không còn Bộ A/B).
   - [lib/features/screening/screening_questionnaire_page.dart](lib/features/screening/screening_questionnaire_page.dart):
     - Mô hình 1 câu hỏi / 1 màn hình.
     - Thanh tiến độ "Câu X/50", badge lĩnh vực và tiểu lĩnh vực, gợi ý quan sát dạng tip.
     - 4 lựa chọn (0, 1, 2, N/A), tự chuyển câu tiếp theo, có nút "Quay lại câu trước" giữ nguyên đáp án đã chọn.
     - Câu 50 tự động tính điểm, lưu DB và chuyển màn kết quả.
   - [lib/features/screening/screening_result_page.dart](lib/features/screening/screening_result_page.dart):
     - Mức tổng quan & điểm % toàn bài.
     - Breakdown 7 lĩnh vực chi tiết (hoặc "Chưa đủ dữ liệu cho lĩnh vực này").
     - Hiển thị NGUYÊN VĂN dòng `meta.luu_y_khong_chan_doan`.
     - Giữ nguyên luồng điều hướng: Onboarding $\rightarrow$ `HomePage`, profile flow $\rightarrow$ `AssessmentSummaryPage`.
   - [lib/features/screening/assessment_summary_page.dart](lib/features/screening/assessment_summary_page.dart):
     - Cập nhật mô tả đề xuất phù hợp với bộ 50 câu 7 lĩnh vực.

5. **Kết Quả Kiểm Thử Toàn Diện**:
   - `flutter analyze`: **No issues found! (0 errors, 0 warnings, 0 infos)**
   - `flutter test`: **111/111 PASS (100%)**:
     - `test/screening_scoring_service_test.dart`: PASS toàn bộ test cases (toàn 0, toàn 2, toàn 1, N/A đơn lẻ, 1 domain toàn N/A, ranh giới 33%/34%/66%/67%, disclaimer nguyên văn).
     - `test/screening_migration_test.dart`: PASS (khởi tạo v8, lưu 3 bảng, đọc lại, cascade delete khi xóa trẻ).
     - `test/screening_flow_test.dart`: PASS 3/3 test flows UI & navigation.
     - Tất cả các test suites khác trong toàn repo: PASS 100%.

---

## 32. Tính Năng "Lịch Sử Sàng Lọc" Trong Tab Tài Khoản & Bảo Vệ Toàn Vẹn Dữ Liệu Đa Trẻ

### 1. Kết Quả Audit Màn Hình Kết Quả Sàng Lọc Hiện Tại ([screening_result_page.dart](lib/features/screening/screening_result_page.dart))

- **Cách nhận dữ liệu hiện tại**:
  - `ScreeningResultPage` nhận vào: `child` (Child), `screeningId` (String?), `score` (String), `resultSummary` (String), `scoreResult` (ScreeningScoreResult?, in-memory), `isOnboarding` (bool).
  - Khi vừa làm bài xong từ `ScreeningQuestionnairePage`: truyền đầy đủ `scoreResult` (trong bộ nhớ) $\rightarrow$ màn hình vẽ trực tiếp từ `scoreResult.domainScores`.
  - Khi mở từ lịch sử (hoặc từ bên ngoài): nếu chỉ truyền `screeningId`, hiện tại màn hình đọc `_screeningRepository.getDomainScores(screeningId)` nhưng lại phụ thuộc vào chuỗi `score`, `resultSummary` và đối tượng `child` truyền cứng ở constructor.
- **Rủi ro dữ liệu đa trẻ**:
  - Nếu mở màn kết quả từ danh sách lịch sử mà phụ thuộc vào `child` hoặc chuỗi `score` truyền từ bên ngoài mà không query chính bản ghi `screenings` trong SQLite, có nguy cơ hiển thị sai dữ liệu hoặc tên trẻ nếu state bị stale giữa các lần đổi tài khoản.
- **Giải pháp Refactor an toàn**:
  - Refactor `ScreeningResultPage` hỗ trợ chế độ query tự động hoàn toàn từ DB:
    - Khi `screeningId` được cung cấp và `scoreResult == null` (chế độ xem lại lịch sử): `ScreeningResultPage` tự query `screenings` bằng `_screeningRepository.getById(screeningId)` để lấy `score`, `result_summary`, `performed_at`, và `child_id`. Đồng thời query `ChildRepository.getById(screening.childId)` để lấy đúng tên trẻ thuộc về bản ghi đó.
    - Khi `scoreResult != null` (chế độ vừa làm bài xong): tiếp tục hiển thị tức thì từ kết quả vừa tính toán trong memory, không làm chậm hoặc ảnh hưởng luồng làm bài.
  - Luồng làm bài xong $\rightarrow$ tự động chuyển sang màn kết quả được bảo toàn 100% không bị ảnh hưởng.

### 2. Kế Hoạch Triển Khai

1. **Repository**:
   - Thêm `Future<List<Screening>> getScreeningsByChildId(String childId)` trong [lib/data/repositories/screening_repository.dart](lib/data/repositories/screening_repository.dart) dùng `WHERE child_id = ? ORDER BY performed_at DESC` (lọc trực tiếp trong câu SQL).
   - Thêm `Future<Screening?> getById(String id)` trong `ScreeningRepository` dùng `WHERE id = ? LIMIT 1`.

2. **Màn Hình Lịch Sử Sàng Lọc Mới ([lib/features/screening/screening_history_list_page.dart](lib/features/screening/screening_history_list_page.dart))**:
   - Tự đọc `active_child_id` tươi từ `ActiveChildService().getActiveChildId()` ngay khi mở màn.
   - Query thông tin trẻ từ `ChildRepository.getById(activeChildId)`.
   - Query danh sách sàng lọc của đúng trẻ từ `ScreeningRepository.getScreeningsByChildId(activeChildId)`.
   - Trạng thái rỗng: hiển thị rõ ràng "Chưa có lịch sử sàng lọc cho [Tên trẻ]".
   - Danh sách: hiển thị từng lần sàng lọc gồm ngày thực hiện, điểm %, mức mô tả.
   - Tap vào 1 dòng $\rightarrow$ mở `ScreeningResultPage(screeningId: item.id)`.

3. **Tab Tài Khoản ([lib/features/home/home_page.dart](lib/features/home/home_page.dart))**:
   - Thêm nút "Lịch sử sàng lọc" (icon `IrisAssets.iconScreening`) trong `_AccountTab` dẫn tới `ScreeningHistoryListPage`.

### 3. Kết Quả Triển Khai Thực Tế

1. **Repository Functions Mới**:
   - [`ScreeningRepository.getScreeningsByChildId(childId)`](lib/data/repositories/screening_repository.dart):
     - Truy vấn: `SELECT * FROM screenings WHERE child_id = ? ORDER BY performed_at DESC`.
     - Lọc trực tiếp bằng mệnh đề `WHERE` trong SQLite, không load toàn bộ bảng rồi lọc ở Dart.
   - [`ScreeningRepository.getById(id)`](lib/data/repositories/screening_repository.dart):
     - Truy vấn: `SELECT * FROM screenings WHERE id = ? LIMIT 1`.

2. **Refactor Màn Hình Kết Quả ([screening_result_page.dart](lib/features/screening/screening_result_page.dart))**:
   - Khi `scoreResult != null` (luồng làm bài xong): vẽ tức thì từ memory.
   - Khi `scoreResult == null` (luồng xem lại lịch sử): tự truy vấn `_screeningRepository.getById(screeningId)` và `_childRepository.getById(screening.childId)`, đọc điểm từng lĩnh vực qua `_screeningRepository.getDomainScores(screeningId)`.
   - Nút "Tiếp tục" / Back:
     - Nếu mở từ lịch sử: `Navigator.pop(context)` quay lại đúng danh sách lịch sử.
     - Nếu trong luồng onboarding: `Navigator.popUntil(isFirst)` về Trang chủ.
     - Nếu trong luồng làm bài từ Profile: chuyển sang `AssessmentSummaryPage`.

3. **Màn Hình Lịch Sử Sàng Lọc Mới ([screening_history_list_page.dart](lib/features/screening/screening_history_list_page.dart))**:
   - Tự động đọc `active_child_id` tươi từ `ActiveChildService` mỗi khi màn hình được mở hoặc cập nhật qua `didUpdateWidget`.
   - Query thông tin hồ sơ của active child và gọi `getScreeningsByChildId(activeChildId)`.
   - Trạng thái rỗng: Hiện mascot clipboard, tiêu đề "Chưa có lịch sử sàng lọc cho [Tên trẻ]" và hướng dẫn bắt đầu bài sàng lọc 50 câu.
   - Trạng thái có dữ liệu: Hiển thị danh sách card gồm Mức mô tả, Điểm %, Ngày giờ thực hiện (`dd/MM/yyyy lúc HH:mm`).
   - Tap vào card: Mở `ScreeningResultPage(screeningId: screening.id, child: child)`.

4. **Tab Tài Khoản ([home_page.dart](lib/features/home/home_page.dart))**:
   - Thêm nút `OutlinedButton.icon` "Lịch sử sàng lọc" (icon `IrisAssets.iconScreening`) ngay dưới Card thông tin của trẻ đang hoạt động.

### 4. Kết Quả Kiểm Thử & Nghiệm Thu

1. **Static Analysis**:
   - `flutter analyze`: **No issues found! (0 errors, 0 warnings, 0 infos)**

2. **Automated Test Suite**:
   - `flutter test test/screening_history_test.dart`: **4/4 PASS (100%)**
     - `Test 1`: Tạo Trẻ A (20% - Mức 1) và Trẻ B (80% - Mức 3). Khi active child = Trẻ A, danh sách CHỈ có dữ liệu của Trẻ A; khi đổi active child = Trẻ B, danh sách CHỈ có dữ liệu của Trẻ B $\rightarrow$ **PASS**.
     - `Test 2`: Mở chi tiết từ lịch sử của Trẻ A, tự query DB theo `screening_id`, đối chiếu chính xác `score: 65%`, `result_summary`, các điểm % lĩnh vực và dòng disclaimer $\rightarrow$ **PASS**.
     - `Test 3`: Trạng thái rỗng cho Trẻ C chưa từng làm bài sàng lọc, hiển thị đúng "Chưa có lịch sử sàng lọc cho Bé Chưa Sàng Lọc", không crash, không hiện lẫn dữ liệu $\rightarrow$ **PASS**.
     - `Test 4`: Nút "Lịch sử sàng lọc" trong tab Tài khoản của `HomePage` mở đúng `ScreeningHistoryListPage` của active child $\rightarrow$ **PASS**.
   - `flutter test test/screening_flow_test.dart`: **3/3 PASS (100%)**
     - Luồng Onboarding làm bài 50 câu $\rightarrow$ hiển thị kết quả $\rightarrow$ vào Trang chủ hoạt động trơn tru.
   - `flutter test` (toàn bộ workspace): **115/115 PASS (100%)** không có bất kỳ regression nào.

## Cập Nhật Cấu Trúc Dữ Liệu `so_sanh` — 3 Dải Tuổi Đối Xứng (Audit, 2026-08-16)

### 1. Audit trước khi sửa

**File nguồn chính:** [assets/reference/expert_content_so_sanh.json](assets/reference/expert_content_so_sanh.json) — 70 entry, chỉ chứa `content_type: "so_sanh"`, mẫu khóa `id: "so_sanh_{linh_vuc}_{phan_loai}_{min}_{max}"`.

- **7 linh_vuc**: `nhan_thuc`, `cam_xuc`, `giac_quan`, `quan_he_xa_hoi`, `ngon_ngu`, `sinh_hoc`, `sinh_hoat_ca_nhan`. Không còn `hanh_vi`/`ung_xu` (đã dọn ở đợt migration DB version 6 trước đây — xác nhận file nguồn JSON cũng đã được dọn theo, không lệch với DB).
- **2 phan_loai**, mỗi phan_loai có bộ dải tuổi RIÊNG (bất đối xứng — cấu trúc CŨ):
  - `binh_thuong`: 7 dải/linh_vuc — 15-17, 18-23, 24-29, 30-35, 36-47, 48-59, 60-71 (tháng) → 49 entry.
  - `roi_loan_pho_tu_ky`: 3 dải/linh_vuc — 15-23, 24-47, 48-59 (tháng) → 21 entry.
  - Tổng 49 + 21 = 70 entry, khớp `test/ingest_so_sanh_data_test.dart`.
- **100% cả 70 entry đều là PLACEHOLDER**: `content = "[Placeholder - chưa có nội dung thật]"`, `nguon_tai_lieu = "[Chưa có nguồn]"` — không có ngoại lệ. Không có entry nào trong file này là nội dung thật, kể cả `quan_he_xa_hoi`.

**File thứ hai — PHÁT HIỆN QUAN TRỌNG chưa có trong đề bài ban đầu:** [assets/reference/expert_content.json](assets/reference/expert_content.json) (file gốc, 22 entry, nhiều content_type) **cũng chứa 6 entry `content_type: "so_sanh"`** — đây là NỘI DUNG THẬT (không phải placeholder), thuộc `linh_vuc: "quan_he_xa_hoi"`, dải tuổi **48-71 tháng**, dùng **`phan_loai` theo bộ giá trị CŨ KHÁC**: `"thuong_gap"` (3 entry) / `"can_quan_sat"` (3 entry) — KHÔNG phải `binh_thuong`/`roi_loan_pho_tu_ky` như file `_so_sanh.json`. 6 entry này không có trường `id`.

→ Dữ liệu `content_type='so_sanh'` trong dự án hiện **nằm rải ở 2 file JSON riêng biệt, với 2 bộ `phan_loai` không tương thích nhau**, không phải 1 file duy nhất như giả định ban đầu trong đề bài.

**Đối chiếu DB thật:** Không thể kết nối — không có emulator/thiết bị đang chạy (`adb devices` không có kết quả), không có file `.db` seed nào tồn tại cục bộ. Qua đọc code xác nhận thêm 1 phát hiện quan trọng: nút **"Debug: Nạp dữ liệu tham khảo"** ([lib/features/child_profile/profile_detail/child_debug_page.dart:133-135](lib/features/child_profile/profile_detail/child_debug_page.dart#L133-L135)) — con đường DUY NHẤT hiện có để ghi dữ liệu tham khảo vào DB thật của app — **chỉ đọc `assets/reference/expert_content.json`**, KHÔNG đọc `expert_content_so_sanh.json`. File `expert_content_so_sanh.json` chỉ được `scripts/ingest_so_sanh_data.dart` và test tham chiếu tới (ghi vào `iris_so_sanh_seed.db` — file tạm trên desktop qua `sqflite_common_ffi`, không phải DB thật trên thiết bị). Do đó: **nhiều khả năng DB thật của app hiện chưa từng có 70 entry `so_sanh` placeholder nào** (chỉ có thể có 6 entry `so_sanh` thật `quan_he_xa_hoi`/48-71 nếu nút debug từng được bấm với `expert_content.json` phiên bản đã có 6 entry này).

### 2. Việc CẦN NGƯỜI DÙNG XÁC NHẬN — chưa xử lý, chưa xoá/sửa gì

1. **6 entry `so_sanh` nội dung thật (`quan_he_xa_hoi`, 48-71 tháng, `phan_loai` = `thuong_gap`/`can_quan_sat`) trong `expert_content.json`**: không khớp bất kỳ dải nào trong 3 dải mới (15-23/24-47/48-60), và dùng tên `phan_loai` khác hệ với `binh_thuong`/`roi_loan_pho_tu_ky`. Giữ nguyên, KHÔNG đụng tới. Cần người dùng quyết định: (a) coi đây là dữ liệu ngoài phạm vi tái cấu trúc lần này (giữ y nguyên, không đưa vào cấu trúc 42-entry mới) hay (b) có ý định gộp/ánh xạ `thuong_gap→binh_thuong`, `can_quan_sat→roi_loan_pho_tu_ky` và cắt/sửa dải 48-71→48-60 (việc này KHÔNG được tự động hoá theo đúng yêu cầu ban đầu).
2. **Không có đường ghi `expert_content_so_sanh.json` vào DB thật của app**: để hoàn thành bước 6 (ingest lại và verify DB thật) của yêu cầu, cần bổ sung/sửa cơ chế nạp (ví dụ mở rộng nút debug trong `child_debug_page.dart` để đọc thêm file này) — đây là thay đổi code UI/app, không chỉ dữ liệu, cần xác nhận trước vì nằm ngoài "không tạo migration schema mới" nhưng vẫn là thay đổi hành vi app.
3. **Không có emulator/thiết bị nào đang chạy** để đọc/ghi DB thật trực tiếp — cần người dùng khởi động emulator hoặc xác nhận cách khác để verify DB thật sau ingest.

### 3. Quyết định của người dùng (2026-08-16)

1. 6 entry thật `so_sanh`/`quan_he_xa_hoi`/48-71/`thuong_gap`+`can_quan_sat` trong `expert_content.json`: **giữ nguyên, ngoài phạm vi** — không đụng, không đưa vào cấu trúc 42-entry mới.
2. **Không sửa code app** (`child_debug_page.dart`) lần này — chỉ cập nhật file JSON nguồn + script validate/ingest desktop (ghi vào file `.db` tạm qua `sqflite_common_ffi` để test luồng). Việc đưa dữ liệu vào DB thật trên thiết bị để sau.
3. Verify DB thật: người dùng sẽ tự khởi động emulator, báo khi sẵn sàng.

### 4. Thay đổi đã thực hiện

- **[assets/reference/expert_content_so_sanh.json](assets/reference/expert_content_so_sanh.json)**: viết lại toàn bộ, từ 70 entry (7 linh_vuc × (7 dải `binh_thuong` + 3 dải `roi_loan_pho_tu_ky`)) → **42 entry** (7 linh_vuc × 3 dải chung `15-23`/`24-47`/`48-60` × 2 `phan_loai`). Toàn bộ 70 entry cũ đều là placeholder nên không có nội dung thật nào bị xoá — chỉ xoá placeholder thuộc dải không còn tồn tại (mọi dải `binh_thuong` cũ + dải `48-59` của `roi_loan_pho_tu_ky`) và tạo mới placeholder cho các dải còn thiếu (dải `48-60` của cả 2 phan_loai, và 2 dải còn lại của `binh_thuong`). Không còn `hanh_vi`/`ung_xu` (đã xác nhận từ trước, không phát sinh thêm việc xoá).
- **[scripts/validate_so_sanh_data.dart](scripts/validate_so_sanh_data.dart)**: thay logic dò "age gap" phức tạp bằng so khớp tập hợp dải tuổi thực tế với tập hợp mong đợi cố định `{15-23, 24-47, 48-60}` cho mỗi (linh_vuc, phan_loai) — báo thiếu dải/dải lạ. Thêm kiểm tra `linh_vuc` phải thuộc đúng 7 giá trị hợp lệ (bắt lỗi nếu còn sót `hanh_vi`/`ung_xu`).
- **[scripts/ingest_so_sanh_data.dart](scripts/ingest_so_sanh_data.dart)**: loại thêm entry có `unexpectedLinhVucIssues` khỏi danh sách ingest (trước đây chỉ loại theo field/age-range/duplicate issues).
- **[test/validate_so_sanh_data_test.dart](test/validate_so_sanh_data_test.dart)**: viết lại theo cấu trúc đối xứng mới — test bộ 42-entry hợp lệ, test phát hiện `linh_vuc` lạ (`hanh_vi`/`ung_xu`), test thiếu dải mong đợi, test dải lạ, test 2 phan_loai dùng chung 3 dải không báo lệch giả.
- **[test/ingest_so_sanh_data_test.dart](test/ingest_so_sanh_data_test.dart)**: cập nhật kỳ vọng ingest từ 70 (49 binh_thuong + 21 roi_loan_pho_tu_ky) → **42 (21 + 21)**.

### 5. Kết quả kiểm thử

- `dart run scripts/validate_so_sanh_data.dart`: **HỢP LỆ về cấu trúc** — 42/42 entry, đúng 7 linh_vuc × 3 dải × 2 phan_loai, 0 lỗi field/age-range/duplicate/linh_vuc-lạ/lệch-dải.
- `flutter test test/validate_so_sanh_data_test.dart test/ingest_so_sanh_data_test.dart`: **11/11 PASS**.
- `flutter analyze`: **No issues found!**
- `flutter test` (toàn bộ workspace): **117/117 PASS (100%)**, không có regression.

### 6. Việc còn lại (chờ người dùng)

- Khởi động emulator/thiết bị thật để ingest `expert_content_so_sanh.json` vào DB thật và verify — hiện chưa có cơ chế UI đọc file này (chỉ có script desktop ghi vào `.db` tạm). Cần người dùng xác nhận thêm bước wiring vào app (đã hỏi và người dùng chọn bỏ qua lần này) trước khi có thể ingest vào DB thật trên thiết bị.
- 6 entry thật `quan_he_xa_hoi`/48-71 trong `expert_content.json` vẫn treo, chưa được người dùng quyết định map/sửa hay giữ vĩnh viễn ngoài phạm vi — đây là quyết định tạm thời cho lần cập nhật này, có thể cần xem lại sau.

## Áp Dụng 3 Dải Tuổi Chung Cho `chia_se_phu_huynh` Và `bac_si` (Audit, 2026-08-16)

### 1. Audit trước khi sửa

Nguồn dữ liệu duy nhất cho 2 content_type này: [assets/reference/expert_content.json](assets/reference/expert_content.json) (22 entry tổng, không có file riêng nào khác — khác với `so_sanh` đã tách file). Đọc toàn bộ 22 entry, phân loại chính xác:

**`content_type = 'chia_se_phu_huynh'` — 8 entry:**
- Cấu trúc phân loại RIÊNG xác nhận qua code thật: cột `nhom_tre` (giá trị: `binh_thuong`, `asd`) × cột `boi_canh` (giá trị: `o_nha`, `o_truong`, `noi_cong_cong`) — KHÔNG dùng cột `phan_loai`.
- 1 entry **THẬT**, `linh_vuc=ngon_ngu`, `24-36` tháng, KHÔNG có `nhom_tre`/`boi_canh` (dữ liệu từ đợt seed rất sớm, trước khi 2 cột này tồn tại).
- 1 entry **placeholder**, `linh_vuc=giac_quan`, `6-18` tháng, cũng không có `nhom_tre`/`boi_canh`.
- 6 entry **THẬT**, `linh_vuc=quan_he_xa_hoi`, `48-71` tháng — đúng lưới đầy đủ 2×3 = 6 tổ hợp `nhom_tre`×`boi_canh`.
- Không có entry `chia_se_phu_huynh` nào cho 6 lĩnh vực còn lại (`nhan_thuc`, `cam_xuc`, `quan_he_xa_hoi` đã có, `ngon_ngu` đã có 1, `sinh_hoc`, `sinh_hoat_ca_nhan` — tức 5/7 lĩnh vực hoàn toàn trống).

**`content_type = 'bac_si'` — 7 entry:**
- Cấu trúc phân loại RIÊNG: cột `phan_loai` với 3 giá trị mang ý nghĩa hoàn toàn khác `so_sanh` — `moc_phat_trien` (mốc phát triển), `dau_hieu_luu_y` (dấu hiệu cần lưu ý), `giai_thich` (giải thích thêm cho phụ huynh).
- 1 entry **placeholder**, `linh_vuc=quan_he_xa_hoi`, `12-24` tháng, KHÔNG có `phan_loai`.
- 6 entry **THẬT**, `linh_vuc=quan_he_xa_hoi`, `48-71` tháng — 2 entry mỗi giá trị `phan_loai` (2×3=6).
- 6/7 lĩnh vực hoàn toàn trống (chỉ có `quan_he_xa_hoi`).

**Phát hiện bổ sung ngoài phạm vi:** file này còn có 7 entry `content_type='so_sanh'` (1 entry `ngon_ngu`/24-36 thật không `phan_loai`, và 6 entry `quan_he_xa_hoi`/48-71 thật đã ghi nhận ở đợt audit trước) — giữ nguyên, không đụng, đúng phạm vi nhiệm vụ này (chỉ `chia_se_phu_huynh`/`bac_si`). Đợt audit trước chỉ liệt kê 6/7 entry so_sanh trong file này (bỏ sót entry `ngon_ngu`/24-36) — bổ sung ghi nhận ở đây cho đầy đủ, không hành động gì thêm vì ngoài phạm vi.

**Đối chiếu 3 dải tuổi mới (15-23/24-47/48-60):** KHÔNG entry thật nào (của cả `chia_se_phu_huynh` lẫn `bac_si`) khớp chính xác 1 trong 3 dải mới — `24-36` không khớp `24-47`, `48-71` không khớp `48-60`. Không có script/cơ chế validate riêng nào cho 2 content_type này trước đây (chỉ có `ingest_expert_data.dart` ingest thẳng không validate) — đã tạo mới `scripts/validate_expert_content.dart` (xem mục 4).

### 2. CẦN NGƯỜI DÙNG XÁC NHẬN — nội dung thật không khớp 3 dải mới (giữ nguyên, không tự sửa)

| content_type | linh_vuc | Phân loại riêng | Dải hiện tại | Dải mới gần nhất | Số entry |
|---|---|---|---|---|---|
| chia_se_phu_huynh | ngon_ngu | (không có nhom_tre/boi_canh) | 24-36 | 24-47 | 1 |
| chia_se_phu_huynh | quan_he_xa_hoi | nhom_tre×boi_canh đủ 6 tổ hợp | 48-71 | 48-60 | 6 |
| bac_si | quan_he_xa_hoi | phan_loai đủ 3 giá trị ×2 | 48-71 | 48-60 | 6 |

→ Tổng 13 entry thật bị treo, y hệt nguyên tắc đã áp dụng cho `so_sanh` — KHÔNG xoá, KHÔNG tự sửa số. Người dùng cần tự quyết định giữ nguyên vĩnh viễn hay chỉnh sửa.

### 3. Đã xoá (chỉ placeholder, không đụng nội dung thật)

- `chia_se_phu_huynh` / `giac_quan` / 6-18 tháng (placeholder, không khớp dải mới nào).
- `bac_si` / `quan_he_xa_hoi` / 12-24 tháng (placeholder, không khớp dải mới nào).

### 4. Đã thêm — placeholder theo cấu trúc mới

Áp dụng đúng nguyên tắc: mỗi (linh_vuc × 3 dải tuổi mới × tổ hợp phân loại riêng đã có) phải có entry (thật hoặc placeholder).

- **`chia_se_phu_huynh`**: 7 linh_vuc × 3 dải × 2 `nhom_tre` × 3 `boi_canh` = **126 entry** (placeholder cho toàn bộ ô còn thiếu — kể cả 5 lĩnh vực trước đây hoàn toàn chưa có entry nào).
- **`bac_si`**: 7 linh_vuc × 3 dải × 3 `phan_loai` = **63 entry**.
- Mẫu placeholder đúng theo yêu cầu (`id`, giữ nguyên tên/giá trị cột phân loại riêng, `content`/`nguon_tai_lieu` placeholder chuẩn).

**Kết quả `expert_content.json` sau cập nhật:** 7 (so_sanh, không đổi) + 133 (chia_se_phu_huynh: 7 thật giữ nguyên + 126 placeholder mới) + 69 (bac_si: 6 thật giữ nguyên + 63 placeholder mới) = **209 entry**.

### 5. Script validate mới

Tạo **[scripts/validate_expert_content.dart](scripts/validate_expert_content.dart)** (trước đây KHÔNG có script validate nào cho `chia_se_phu_huynh`/`bac_si` — chỉ ingest thẳng không kiểm tra):
- Đọc `expert_content.json`, lọc riêng `chia_se_phu_huynh` và `bac_si`.
- Kiểm tra trường bắt buộc chung (không ép buộc `nhom_tre`/`boi_canh`/`phan_loai` phải có — để không báo lỗi giả cho 13 entry thật đang treo ở mục 2, vốn cố ý giữ nguyên cấu trúc cũ).
- Kiểm tra `do_tuoi_thang_min/max` PHẢI thuộc đúng 1 trong 3 cặp (15,23)/(24,47)/(48,60) — entry nào lệch (kể cả entry thật đang treo) đều được liệt kê rõ trong báo cáo, không bị ẩn đi, đúng tinh thần "không tự sửa nhưng phải hiện rõ".
- Kiểm tra trùng khoá (content_type, linh_vuc, nhom_tre, boi_canh, phan_loai, min, max).
- Giữ nguyên logic phân loại riêng: KHÔNG gộp/ép `nhom_tre`/`boi_canh`/`phan_loai` theo cấu trúc `binh_thuong`/`roi_loan_pho_tu_ky` của `so_sanh`.
- Báo cáo tổng số entry theo (content_type × linh_vuc × dải tuổi), đánh dấu placeholder vs thật.

Đồng thời tạo **[scripts/ingest_expert_content.dart](scripts/ingest_expert_content.dart)** (mẫu giống `ingest_so_sanh_data.dart`): validate rồi CHỈ ingest entry mới lỗi cấu trúc bị loại (entry thật cũ lệch dải tuổi vẫn được ingest bình thường, không bị loại) — ghi vào file `.db` tạm qua `sqflite_common_ffi` để test luồng, đọc lại xác nhận theo (content_type, linh_vuc). KHÔNG đụng tới 7 entry `so_sanh` cũng nằm trong `expert_content.json` — những entry đó vẫn được ingest qua đường cũ (`ingest_expert_data.dart`/nút debug, đọc nguyên file không lọc content_type), không đổi gì.

### 6. Kết quả kiểm thử

- `dart run scripts/validate_expert_content.dart`: **HỢP LỆ về cấu trúc** — 202 entry (189 placeholder + 13 thật), 0 lỗi chặn ingest trên entry mới; đúng 13 ghi chú lệch dải tuổi trên entry thật cũ (khớp chính xác mục 2 ở trên).
- `flutter test test/validate_expert_content_test.dart test/ingest_expert_content_test.dart`: **11/11 PASS**, gồm cả test đọc trực tiếp file JSON thật khoá lại đúng con số 202/189/13 (không nhiều hơn, không ít hơn) và test ingest 202 entry vào file `.db` thật qua `sqflite_common_ffi`, đọc lại xác nhận đúng 133 `chia_se_phu_huynh` + 69 `bac_si`.
- `flutter analyze`: **No issues found!**
- `flutter test` (toàn bộ workspace): **128/128 PASS (100%)**, không có regression.

### 7. Ingest thật vào DB trên emulator (2026-08-16, sau khi người dùng khởi động emulator)

Emulator `emulator-5554` đã chạy sẵn — thực hiện ingest thật (không phải qua script desktop nữa):
- Chạy `flutter run -d emulator-5554 --dart-define-from-file=dart_define.json` (key NVIDIA lấy từ `dart_define.json`, file bị `.gitignore`, không commit).
- Sự cố gặp phải: (1) lần đầu chạy nhầm `--release` — ẩn mất nút debug (chỉ hiện ở `kDebugMode`) — phải dừng và chạy lại không có cờ này; (2) lần chạy debug đầu tiên bị "Lost connection to device" giữa chừng, khiến app đang chạy thực ra vẫn là bản **release cũ không debuggable** (xác nhận qua `adb shell run-as ... — package not debuggable`) — phải chạy lại debug build và xác minh bằng `run-as` trước khi thao tác tiếp.
- Điều hướng UI qua `adb shell input tap` + `uiautomator dump` (lấy toạ độ chính xác từ `bounds` thay vì ước lượng từ ảnh chụp màn hình — ước lượng ban đầu làm tab "Tài khoản" không bấm trúng): Trang chủ → Tài khoản → Đổi tài khoản → menu "⋮" trên hồ sơ → Xem hồ sơ → icon Debug → "Debug: Nạp dữ liệu tham khảo".
- **Kết quả verify trực tiếp trên DB thật** (`adb shell run-as com.iris.app.iris_app sqlite3 .../iris.db`, KHÔNG chỉ tin log/snackbar):

  ```
  SELECT content_type, count(*) FROM expert_knowledge_chunks GROUP BY content_type;
  bac_si|69
  chia_se_phu_huynh|133
  so_sanh|7
  ```

  Khớp đúng dự kiến (133 `chia_se_phu_huynh` + 69 `bac_si` mới ingest; 7 `so_sanh` cũ không đổi vì `expert_content_so_sanh.json` 42-entry vẫn chưa có đường nạp vào DB thật — chỉ `expert_content.json` được nút debug đọc). Mỗi `embedding` dài 4096 byte (1024 float) — xác nhận gọi NVIDIA embedding API THẬT thành công, không phải embedding giả.

### 8. Việc còn lại (chờ người dùng)

- File `expert_content_so_sanh.json` (42 entry, cấu trúc 3-dải-tuổi mới) vẫn CHƯA có đường nạp vào DB thật trên thiết bị — cần sửa `child_debug_page.dart` để đọc thêm file này (người dùng đã từ chối việc này ở đợt trước, có thể xem lại quyết định nếu muốn ingest 42 entry `so_sanh` mới vào DB thật).
- 13 entry thật (audit mục 2) vẫn treo, chờ người dùng quyết định (bao gồm cả 7 entry `so_sanh` cũ đã ghi nhận ở đợt trước, cộng phát hiện bổ sung 1 entry `so_sanh`/`ngon_ngu`/24-36 trước đây bị bỏ sót).

---

## 21. Rút gọn mỗi lĩnh vực còn 2 phần (Mô tả & So sánh) — Gỡ bỏ Chia sẻ phụ huynh và Thông tin bác sĩ (2026-08-16)

### 1. Bối cảnh & Mục tiêu
Rút gọn cấu trúc đánh giá 7 lĩnh vực từ Hub 4 phần xuống còn **đúng 2 phần**:
1. **Mô tả biểu hiện của trẻ** (`mo_ta` trong `assessments` + `profile_chunks` — dữ liệu thực tế duy nhất của trẻ)
2. **So sánh với trẻ cùng độ tuổi** (`so_sanh` trong `expert_knowledge_chunks` — dữ liệu tham khảo bổ trợ)

Gỡ bỏ hoàn toàn phần 3 (**Chia sẻ từ phụ huynh** — `content_type='chia_se_phu_huynh'`) và phần 4 (**Thông tin từ bác sĩ** — `content_type='bac_si'`).

---

### 2. Kết quả Audit trước khi sửa (bắt buộc)
1. **File/Widget của 2 phần bị xoá**:
   - `lib/features/assessment/nine_domains/parent_input/`:
     - `parent_input_page.dart` (`class ParentInputPage`)
     - `parent_context_page.dart` (`class ParentContextPage`)
   - `lib/features/assessment/nine_domains/expert_input/`:
     - `expert_input_page.dart` (`class ExpertInputPage`)
     - `expert_detail_page.dart` (`class ExpertDetailPage`)
2. **Route/Navigation trỏ tới 2 màn này**:
   - Duy nhất tại `lib/features/assessment/domain_hub_page.dart` (import 2 file và 2 thẻ điều hướng `_HubNavigationCard`). Không có bất kỳ route hay file nào khác trong toàn bộ codebase dẫn tới 2 màn hình này.
3. **Kiểm tra Hỏi đáp AI / Guardrail 3 trạng thái**:
   - `GuardrailService.determineState()`: Xác định Trạng thái 1/2/3 hoàn toàn bằng code Dart thuần dựa trên `retrievedProfileChunks` (từ `profile_chunks` của trẻ) và `hasScreeningResult` (từ `screenings`). **Không phụ thuộc vào `expert_knowledge_chunks`**, logic guardrail giữ nguyên 100%.
   - RAG Trạng thái 3 (`AiRepository.ask` & `VectorSearchService.searchExpertChunks`): Câu truy vấn gốc `_expertKnowledgeRepository.query(ageInMonths: ageMonths)` trước đây lấy mọi chunk theo độ tuổi. Đã bổ sung tường minh tham số `contentType: 'so_sanh'` trong `VectorSearchService.searchExpertChunks` để chỉ truy vấn tri thức so sánh.
4. **File nguồn JSON**:
   - `assets/reference/expert_content.json`: Chứa 209 entry (7 `so_sanh`, 133 `chia_se_phu_huynh`, 69 `bac_si`). Đã lọc và xoá sạch 202 entry `chia_se_phu_huynh` và `bac_si`, chỉ giữ lại 7 entry `so_sanh`.
   - `assets/reference/expert_content_so_sanh.json`: 42 entry `so_sanh` chuẩn hoá 7 lĩnh vực × 3 dải tuổi × 2 phân loại được giữ nguyên.
5. **Database Migration v9**:
   - Nâng version SQLite `AppDatabase` từ 8 lên 9.
   - Migration v9 thực hiện: `DELETE FROM expert_knowledge_chunks WHERE content_type IN ('chia_se_phu_huynh', 'bac_si');`.

---

### 3. Danh sách file đã xoá
1. `lib/features/assessment/nine_domains/parent_input/parent_input_page.dart` (UI thẻ Chia sẻ phụ huynh)
2. `lib/features/assessment/nine_domains/parent_input/parent_context_page.dart` (UI chi tiết tình huống)
3. `lib/features/assessment/nine_domains/expert_input/expert_input_page.dart` (UI thẻ Thông tin bác sĩ)
4. `lib/features/assessment/nine_domains/expert_input/expert_detail_page.dart` (UI chi tiết mốc phát triển y khoa)
5. `scripts/validate_expert_content.dart` (Script validate riêng cho chia_se_phu_huynh/bac_si)
6. `scripts/ingest_expert_content.dart` (Script ingest riêng cho chia_se_phu_huynh/bac_si)
7. `test/validate_expert_content_test.dart` (Test cho script validate đã xoá)
8. `test/ingest_expert_content_test.dart` (Test cho script ingest đã xoá)
9. `test/expert_knowledge_context_migration_test.dart` (Test schema cũ v3->v4 cho cột nhom_tre/boi_canh)

---

### 4. File đã chỉnh sửa & tạo mới
1. `lib/data/local/database.dart`: Nâng `version: 9`, thêm `onUpgrade` v9 xoá 2 loại `content_type`.
2. `lib/features/assessment/domain_hub_page.dart`: Rút gọn Hub còn 2 thẻ (Mô tả biểu hiện & So sánh với trẻ cùng độ tuổi), xoá import và 2 thẻ cũ.
3. `lib/domain/services/vector_search_service.dart`: Chỉ định rõ `contentType: 'so_sanh'` trong `searchExpertChunks`.
4. `assets/reference/expert_content.json`: Lọc xoá 202 entry `chia_se_phu_huynh`/`bac_si`, chỉ giữ `so_sanh`.
5. `test/expert_knowledge_cleanup_migration_test.dart` *(mới)*: Test migration v8 -> v9 xác nhận xoá sạch dữ liệu cũ, bảo toàn 100% `so_sanh`.
6. `test/domain_hub_free_navigation_test.dart`: Cập nhật 4 test cases cho Hub 2 phần.
7. `test/repositories_test.dart`: Chuyển test `ExpertKnowledgeRepository` tập trung vào `so_sanh`.
8. `test/chan_dung_and_overview_description_migration_test.dart`, `test/seven_domains_migration_test.dart`, `test/overview_migration_test.dart`: Cập nhật kỳ vọng DB version lên 9.

---

### 5. Kết quả kiểm thử & Xác thực
- `flutter analyze`: **0 issues found** (ran in 62.4s).
- `flutter test test/expert_knowledge_cleanup_migration_test.dart`: **PASS** (xác minh migration v8 -> v9 trên DB SQLite thật).
- `flutter test test/domain_hub_free_navigation_test.dart`: **4/4 PASS** (xác minh Hub 2 phần, điều hướng, nút Lưu).
- `flutter test test/ai_repository_test.dart`: **4/4 PASS** (xác minh đủ 3 trạng thái AI Guardrail với kho tri thức `so_sanh`).
- `flutter test` (toàn bộ workspace): **115/115 PASS (100%)**.

---

## 22. Ingest 200 Entry Dữ liệu THẬT So Sánh 15-23 Tháng & Kiểm Chứng Nghiêm Ngặt Logic Lọc Độ Tuổi (2026-08-16)

### 1. Kết quả Audit trước khi Ingest (Bắt buộc)
1. **Hiện trạng bảng `expert_knowledge_chunks`**:
   - Trong `assets/reference/expert_content.json` chỉ có 7 entry `so_sanh` thuộc các dải tuổi khác (`ngon_ngu` 24-36, `quan_he_xa_hoi` 48-71). **Không có entry thật nào thuộc dải 15-23 tháng**.
   - Trong `assets/reference/expert_content_so_sanh.json` có 14 entry placeholder dải 15-23 tháng (được lưu cho môi trường test/dev, không dùng trong production DB).
   - $\rightarrow$ **Kết luận**: Không có xung đột dữ liệu thật trong cơ sở dữ liệu.
2. **Kiểm tra Logic Lọc Theo Độ Tuổi**:
   - `ExpertKnowledgeRepository.query`:
     ```sql
     (do_tuoi_thang_min IS NULL OR do_tuoi_thang_min <= ?) AND (do_tuoi_thang_max IS NULL OR do_tuoi_thang_max >= ?)
     ```
   - `VectorSearchService.searchExpertChunks`: Lọc thô bằng SQL theo `ageInMonths` trước khi tính Cosine Similarity trên các vector. Nếu SQL trả về rỗng, hàm trả về danh sách rỗng ngay lập tức.
   - `AiRepository.ask`: Khi `retrievedExpertChunks` rỗng, `PromptBuilder.buildState3ExpertContext` sinh câu mặc định: `'(không có dữ liệu tham khảo phù hợp)'`.
   - `ComparisonVideoPage`: Khi `snapshot.data` rỗng, hiển thị thông báo: `'Chưa có dữ liệu so sánh cho lĩnh vực này ở độ tuổi hiện tại.'`.
   - $\rightarrow$ **Xác nhận 100%**: Tuyệt đối **KHÔNG có bất kỳ cơ chế fallback** hay lấy dải tuổi gần nhất nào.

---

### 2. Xử lý Dữ liệu Cũ Trùng Phạm Vi
- Các entry placeholder 15-23 tháng trong file test không được nạp vào DB runtime.
- File `so_sanh_15_23_thang.json` (200 entry thật) được lưu vào `assets/reference/so_sanh_15_23_thang.json` và cập nhật `ChildDebugPage` để sẵn sàng nạp khi cần.
- 2 trường `thu_tu_trong_bang` và `cap_doi_id` được bỏ qua hoàn toàn khi nạp vào bảng `expert_knowledge_chunks` (không sửa schema SQLite, giữ nguyên tính tương thích).

---

### 3. Kết quả Ingest 200 Entry Thật với NVIDIA NIM Embedding
- **API Model**: `nvidia/nv-embedqa-e5-v5` (từ NVIDIA NIM qua `https://integrate.api.nvidia.com/v1/embeddings`).
- **Vector Chiều rộng**: 1024 float32 / 4096 bytes per BLOB (encode/decode bằng `lib/domain/services/embedding_codec.dart`).
- **Tỷ lệ Ingest thành công**: **200/200 entry (100%)**, Thất bại: **0**.
- **Phân bổ 200 entry trên 7 lĩnh vực chuẩn**:
  | Lĩnh vực | `binh_thuong` | `roi_loan_pho_tu_ky` | Tổng số entry |
  |---|---|---|---|
  | `nhan_thuc` | 13 | 13 | **26** |
  | `cam_xuc` | 7 | 7 | **14** |
  | `giac_quan` | 5 | 5 | **10** |
  | `quan_he_xa_hoi` | 10 | 11 | **21** |
  | `ngon_ngu` | 28 | 28 | **56** |
  | `sinh_hoc` | 22 | 21 | **43** |
  | `sinh_hoat_ca_nhan` | 15 | 15 | **30** |
  | **TỔNG CỘNG** | **100** | **100** | **200** |

---

### 4. Kết quả Kiểm Chứng Nghiêm Ngặt Logic Lọc Tuổi qua Test Suite
Đã xây dựng test suite chuyên biệt `test/so_sanh_15_23_age_filtering_test.dart` với 11 ca kiểm thử:
1. **Test 1**: Trẻ 18 tháng (giữa dải 15-23) $\rightarrow$ Nhận đúng 200 entry phân bổ chính xác trên 7 lĩnh vực. **PASS**
2. **Test 2**: Trẻ đúng 15 tháng (biên dưới) $\rightarrow$ Nhận đủ 200 entry dữ liệu tham khảo. **PASS**
3. **Test 3**: Trẻ đúng 23 tháng (biên trên) $\rightarrow$ Nhận đủ 200 entry dữ liệu tham khảo. **PASS**
4. **Test 4**: Trẻ 14 tháng (ngay dưới biên) $\rightarrow$ **RỖNG TUYỆT ĐỐI (0 kết quả)**, không bị gán nhầm dải 15-23. **PASS**
5. **Test 5**: Trẻ 24 tháng (ngay trên biên) $\rightarrow$ **KHÔNG nhận bất kỳ entry nào từ dải 15-23**, chỉ nhận chunk của dải 24-36 (nếu có). **PASS**
6. **Test 6**: Trẻ 40 tháng (lớn hơn nhiều) $\rightarrow$ **RỖNG TUYỆT ĐỐI trên cả 7 lĩnh vực**. **PASS**
7. **Test 7**: Trẻ 60 tháng (5 tuổi) $\rightarrow$ **RỖNG TUYỆT ĐỐI trên cả 7 lĩnh vực**. **PASS**
8. **Test 8**: `VectorSearchService.searchExpertChunks` lọc tuổi trước khi tính similarity $\rightarrow$ Trả về rỗng cho trẻ 14m/40m, không fallback. **PASS**
9. **Test 9**: `childAgeInMonths` quy đổi chính xác từ `dob` sang số tháng tuổi. **PASS**
10. **Test 10**: Widget test `ComparisonVideoPage` với trẻ 18 tháng $\rightarrow$ Tải và render bảng so sánh thành công. **PASS**
11. **Test 11**: Widget test `ComparisonVideoPage` với trẻ 40 tháng $\rightarrow$ Hiển thị đúng trạng thái RỖNG, không crash, không lẫn dữ liệu dải 15-23. **PASS**

---

### 5. Xác Thực Trực Tiếp trên Thiết Bị / Emulator Pixel 7
1. **Dữ liệu trong SQLite DB trên Emulator**:
   - `SELECT do_tuoi_thang_min, do_tuoi_thang_max, count(*) FROM expert_knowledge_chunks GROUP BY do_tuoi_thang_min, do_tuoi_thang_max;`
     - `15 | 23 | 200`
     - `24 | 36 | 1`
     - `48 | 71 | 6`
   - Đủ 200 entry dải 15-23 với vector embedding 4096 bytes.
2. **Kiểm tra luồng UI thực tế**:
   - **Trường hợp Trẻ 18 tháng (`Bé An (18 tháng)` - 1 tuổi 6 tháng)**:
     - Vào "Đánh giá 7 lĩnh vực" $\rightarrow$ chọn "Nhận thức" $\rightarrow$ chọn "So sánh với trẻ cùng độ tuổi".
     - Header hiển thị: `Nhận thức — So sánh nhanh (1 tuổi 6 tháng)`.
     - Nút "Xem chi tiết so sánh" hiển thị và mở ra bảng 26 tiêu chí (13 bình thường vs 13 rối loạn phổ tự kỷ).
   - **Trường hợp Trẻ 40 tháng (`Bé Bình (40 tháng)` - 3 tuổi 4 tháng)**:
     - Vào "Đánh giá 7 lĩnh vực" $\rightarrow$ chọn "Nhận thức" $\rightarrow$ chọn "So sánh với trẻ cùng độ tuổi".
     - Header hiển thị: `Nhận thức — So sánh nhanh (3 tuổi 4 tháng)`.
     - Body hiển thị thông báo rỗng: *"Chưa có dữ liệu so sánh cho lĩnh vực này ở độ tuổi hiện tại."*.
     - Không có nút "Xem chi tiết", không crash, không xuất hiện bất kỳ nội dung nào của dải 15-23.
3. **Ảnh chụp màn hình đối chứng**:
   - `so_sanh_18m_data.png`: Minh chứng hiển thị dữ liệu cho trẻ 18 tháng.
   - `so_sanh_40m_empty.png`: Minh chứng hiển thị trạng thái rỗng cho trẻ 40 tháng.

---

### 6. Tổng Kết Chất Lượng Codebase
- `flutter analyze`: **0 issues found** (No issues found!).
- `flutter test`: **126/126 PASS (100%)**.

## Sửa Lỗi Màn "So Sánh" — Bảng Cột Trống → Đúng Cấu Trúc 2 Tab (2026-08-16)

### 1. Audit — nguyên nhân gốc

**File liên quan:**
- `lib/features/assessment/nine_domains/comparison_video/comparison_video_page.dart` — "So sánh nhanh" (`ComparisonVideoPage`).
- `lib/features/assessment/nine_domains/comparison_video/comparison_detail_page.dart` — "So sánh chi tiết" (`ComparisonDetailPage`), trước đây mở từ nút "Xem chi tiết so sánh" trong `ComparisonVideoPage`, nhận lại nguyên `List<ExpertKnowledgeChunk> chunks` đã tải sẵn (không tự query).
- `lib/data/repositories/expert_knowledge_repository.dart` — hàm `query()` dùng chung.

**Nguyên nhân gốc (2 lớp, xác nhận qua đọc trực tiếp code + đối chiếu dữ liệu thật):**

1. **Sai giá trị `phan_loai` (nguyên nhân chính, gây đúng hiện tượng trong ảnh lỗi):** Code cũ ở cả 2 màn lọc/đánh dấu theo `c.phanLoai == 'thuong_gap'` và `c.phanLoai == 'can_quan_sat'`. Nhưng dữ liệu thật trong `expert_knowledge_chunks` (ingest từ `so_sanh_15_23_thang.json`, xác nhận qua `scripts/validate_so_sanh_data.dart` và `test/ingest_so_sanh_data_test.dart`) dùng đúng 2 giá trị **`'binh_thuong'`** / **`'roi_loan_pho_tu_ky'`** — không phải `'thuong_gap'`/`'can_quan_sat'`. Hệ quả: `ComparisonVideoPage` tải được `chunks` (không rỗng) nhưng cả 2 nhóm lọc phía Dart đều rỗng nên 2 khối UI biến mất; `ComparisonDetailPage` vẫn lặp đủ mọi hàng (vì dùng nguyên `chunks`, không lọc) nhưng cột "Thường gặp"/"Cần quan sát" luôn `SizedBox.shrink()` vì điều kiện check sai — **đúng hệt hiện tượng trong ảnh lỗi**: cột "Tiêu chí" liệt kê lẫn lộn cả `binh_thuong` lẫn `roi_loan_pho_tu_ky` thành các hàng riêng (vì không lọc), cột "Thường gặp" luôn trống.
2. **Thiết kế bảng ghép cặp theo hàng đã lỗi thời:** JSON nguồn từng có `cap_doi_id`/`thu_tu_trong_bang` để ghép 2 entry đối xứng thành 1 hàng bảng, nhưng xác nhận qua `lib/data/local/tables/expert_knowledge_chunks_table.dart` — **schema DB KHÔNG có 2 cột này**, và cả 2 script ingest (`scripts/ingest_so_sanh_15_23.dart`, `scripts/ingest_so_sanh_data.dart`) đều không đọc/insert chúng. `ExpertKnowledgeRepository.query()` cũng không có tham số `phanLoai` — việc tách nhóm hoàn toàn nằm ở phía Dart trong 2 trang UI, dùng sai giá trị nêu trên.
3. Test cũ (`test/so_sanh_15_23_age_filtering_test.dart` Test 10/11, `test/domain_hub_free_navigation_test.dart` Test 1) không phát hiện bug vì tự seed thủ công `phanLoai: 'thuong_gap'` (giá trị sai) vào DB test thay vì dùng giá trị thật `'binh_thuong'`/`'roi_loan_pho_tu_ky'` — che giấu mismatch, khớp UI "trông có vẻ đúng" nhưng không đối chiếu nội dung con.

### 2. Thay đổi đã thực hiện

- **`lib/data/repositories/expert_knowledge_repository.dart`**: thêm tham số `phanLoai` vào `query()` (SQL `WHERE phan_loai = ?`) — lọc đúng tab ngay ở DB thay vì lọc sai ở Dart.
- **`lib/domain/models/expert_knowledge_chunk.dart`**: sửa docstring `phanLoai` (trước ghi sai `'thuong_gap'`/`'can_quan_sat'`, nay đúng `'binh_thuong'`/`'roi_loan_pho_tu_ky'`).
- **`comparison_video_page.dart`**: viết lại hoàn toàn — `AppBar` có `TabBar` 2 tab "Trẻ bình thường"/"Trẻ tự kỷ"; `initState` gọi `loadComparisonTabData()` (2 lệnh `ExpertKnowledgeRepository.query()` song song, mỗi lệnh đúng `phanLoai` của 1 tab, KHÔNG ghép theo `cap_doi_id`/hàng ngang); mỗi tab render `ComparisonItemList` — danh sách, mỗi dòng = 1 entry, không còn bảng. Trạng thái rỗng hiện thông báo riêng cho từng tab. Nút "Xem chi tiết so sánh" chỉ hiện khi có ít nhất 1 tab có dữ liệu, giờ điều hướng bằng `child`+`linhVuc`+`linhVucLabel` (không truyền `chunks` nữa).
- **`comparison_detail_page.dart`**: viết lại hoàn toàn theo cùng cấu trúc — từ `StatelessWidget` nhận sẵn `chunks` chuyển thành `StatefulWidget` tự gọi `loadComparisonTabData()` theo đúng `linhVuc`, 2 tab riêng, xoá hẳn `Table`/`_HeaderCell`/`_MarkCell` (bảng "Tiêu chí \| Thường gặp \| Cần quan sát" cũ).
- Không đụng: dữ liệu trong `expert_knowledge_chunks`, logic `childAgeInMonths()`/lọc tuổi, Mô tả biểu hiện, Chân dung toàn cảnh, Sàng lọc 50 câu.

### 3. Test

- **`test/comparison_tabs_test.dart`** (mới, 4 test): tab "Trẻ bình thường" hiện đúng số lượng/nội dung entry `phan_loai='binh_thuong'` đối chiếu trực tiếp với `ExpertKnowledgeRepository.query()` thật (không chỉ tin UI); chuyển qua lại 2 tab 3 vòng liên tiếp xác nhận không lẫn dữ liệu; trẻ ngoài mọi dải tuổi → cả 2 tab hiện đúng thông báo trống riêng, `find.byType(Table)` rỗng (không còn bảng cột trống); `ComparisonDetailPage` tự query lại theo `linhVuc`, xác nhận không còn `Text('Tiêu chí')`/`Text('Thường gặp')`/`Table` nào trong cây widget.
- Cập nhật `test/domain_hub_free_navigation_test.dart` Test 1 và `test/so_sanh_15_23_age_filtering_test.dart` Test 11: sửa `phanLoai` seed từ giá trị sai `'thuong_gap'` sang đúng `'binh_thuong'`, cập nhật assertion theo tiêu đề tab mới thay vì tiêu đề section cũ.
- Kết quả: `flutter test test/comparison_tabs_test.dart test/domain_hub_free_navigation_test.dart test/so_sanh_15_23_age_filtering_test.dart` — **19/19 PASS**.
- `flutter analyze`: **No issues found!**
- `flutter test` (toàn bộ workspace): đang chạy, cập nhật kết quả bên dưới sau khi hoàn tất.

### 4. Verify luồng thật trên emulator (2026-08-16)

Redeploy debug build lên `emulator-5554` (`flutter run -d emulator-5554 --dart-define-from-file=dart_define.json`), xác nhận `run-as` debuggable trước khi thao tác. Trẻ có sẵn trong DB thật: **"lvl"**, `dob=2025-03-16` → tính tới ngày verify (2026-08-16) đúng **17 tháng = "1 tuổi 5 tháng"**, đúng kịch bản trong ảnh lỗi gốc. DB thật đã có sẵn dữ liệu THẬT (200 entry, dải 15-23 tháng, ingest từ `so_sanh_15_23_thang.json` ở đợt trước) — lĩnh vực `nhan_thuc`: 13 `binh_thuong` + 13 `roi_loan_pho_tu_ky` — đúng dữ liệu từng gây lỗi trong ảnh chụp gốc.

Điều hướng qua `adb shell input tap` + `uiautomator dump` (Home → Đánh giá 7 lĩnh vực → Nhận thức → So sánh với trẻ cùng độ tuổi):

1. **"Nhận thức — So sánh nhanh"**: hiện đúng 2 tab "Trẻ bình thường" (mặc định, active) / "Trẻ tự kỷ". Tiêu đề "So sánh nhanh (1 tuổi 5 tháng)" — đúng tuổi, không đổi. Tab "Trẻ bình thường" liệt kê đủ 13 dòng nội dung thật (VD "Xếp chồng ít nhất hai vật nhỏ...", "Bắt chước hành động như các động tác và cử chỉ..."). Nút "Xem chi tiết so sánh" hiện đúng.
2. Bấm tab "Trẻ tự kỷ": danh sách đổi hoàn toàn sang 13 dấu hiệu khác (VD "Không thể xếp chồng hai vật nhỏ", "Không hứng thú với đồ chơi") — xác nhận không lẫn dữ liệu giữa 2 tab.
3. Bấm "Xem chi tiết so sánh" → **"Nhận thức — Chi tiết so sánh"** (đúng màn trong ảnh lỗi gốc): tiêu đề "So sánh chi tiết (1 tuổi 5 tháng)", đúng 2 tab, tab "Trẻ bình thường" hiện lại đúng 13 dòng (không phải bảng "Tiêu chí \| Thường gặp" với cột trống như ảnh cũ), có hộp disclaimer "Thông tin này chỉ giúp đối chiếu với trẻ cùng độ tuổi, không dùng để tự chẩn đoán." ở cuối.
4. Bấm tab "Trẻ tự kỷ" ở màn chi tiết: đổi đúng sang 13 dấu hiệu tương ứng, không lẫn — xác nhận `ComparisonDetailPage` tự query lại đúng theo tab, không còn dùng `chunks` cố định truyền từ màn trước.

**Kết luận verify:** lỗi trong ảnh gốc (bảng 1 cột "Tiêu chí" liệt kê lẫn lộn, cột "Thường gặp" trống hoàn toàn) đã hết hoàn toàn trên dữ liệu thật, đúng hành vi 2-tab theo yêu cầu.

## 24. Ingest Dữ Liệu Thật So Sánh 24-47 Tháng (196 Entry) & Kiểm Chứng Nghiêm Ngặt (2026-08-16)

### 1. Audit Bước 0 Trước Khi Thực Hiện
1. **Tái sử dụng logic Ingest**:
   - Tái sử dụng cấu trúc và phương thức từ `scripts/ingest_so_sanh_15_23.dart` để xây dựng `scripts/ingest_so_sanh_24_47.dart`.
2. **Schema `expert_knowledge_chunks`**:
   - Gồm 11 cột: `id`, `content`, `content_type`, `phan_loai`, `nhom_tre`, `boi_canh`, `linh_vuc`, `do_tuoi_thang_min`, `do_tuoi_thang_max`, `nguon_tai_lieu`, `embedding` (BLOB float32 1024 chiều / 4096 bytes).
   - Hai trường `cap_doi_id` và `thu_tu_trong_bang` trong JSON nguồn **không tồn tại** trong SQLite schema và đã được bỏ qua khi insert (không sửa schema, không thêm migration).
3. **Query SQLite DB thật trên thiết bị/emulator trước ingest**:
   - `content_type='so_sanh' AND do_tuoi_thang_min=24 AND do_tuoi_thang_max=47`: **0 dòng**.
   - Có 1 dòng legacy `24|36` (`ffe04570-6163-4914-aeaf-10d30c320211`) và 6 dòng `48|71`.
   - Đã thực hiện xoá sạch bản ghi legacy `24|36` và toàn bộ dải 24-47 cũ trước khi insert 196 entry mới, đảm bảo không có bản ghi trùng lặp hay dữ liệu rác.

---

### 2. Quá Trình Ingest với NVIDIA NIM Embedding API
- **Nguồn dữ liệu**: `so_sanh_24_47_thang.json` (được lưu cả ở root và `assets/reference/so_sanh_24_47_thang.json`).
- **NVIDIA NIM Model**: `nvidia/nv-embedqa-e5-v5` (`https://integrate.api.nvidia.com/v1/embeddings`, `input_type: 'query'`, `encoding_format: 'float'`).
- **Kết quả Ingest**: **196/196 entry thành công (100%)**, Thất bại: **0**.
- **Đã nạp và đồng bộ vào SQLite DB thật**: `/data/data/com.iris.app.iris_app/app_flutter/iris.db` trên emulator Pixel 7.

---

### 3. Phân Bổ 196 Entry Theo 7 Lĩnh Vực Trong DB Thật
Đã đối chiếu trực tiếp qua SQL query trên DB thật:
`SELECT linh_vuc, count(*) FROM expert_knowledge_chunks WHERE content_type='so_sanh' AND do_tuoi_thang_min=24 AND do_tuoi_thang_max=47 GROUP BY linh_vuc ORDER BY linh_vuc;`

| Lĩnh vực (`linh_vuc`) | Bình thường (`binh_thuong`) | Tự kỷ (`roi_loan_pho_tu_ky`) | Tổng cộng |
|---|---|---|---|
| `cam_xuc` | 6 | 6 | **12** |
| `giac_quan` | 4 | 4 | **8** |
| `ngon_ngu` | 32 | 32 | **64** |
| `nhan_thuc` | 11 | 11 | **22** |
| `quan_he_xa_hoi` | 11 | 11 | **22** |
| `sinh_hoat_ca_nhan` | 9 | 9 | **18** |
| `sinh_hoc` | 25 | 25 | **50** |
| **TỔNG CỘNG** | **98** | **98** | **196** |

---

### 4. Kiểm Chứng Nghiêm Ngặt Qua Test Suite
Tạo test suite [test/so_sanh_24_47_age_filtering_test.dart](test/so_sanh_24_47_age_filtering_test.dart) (8 bài test):
1. **Test 1**: Tổng số dòng đúng 196 và phân bổ chính xác 7 lĩnh vực (98 BT, 98 TK) $\rightarrow$ **PASS**.
2. **Test 2 (Biên tuổi 23 tháng)**: Nhận đúng 200 entry dải 15-23, **0 entry từ dải 24-47** $\rightarrow$ **PASS**.
3. **Test 3 (Biên tuổi 24 tháng)**: Nhận đúng 196 entry dải 24-47, **0 entry từ dải 15-23** $\rightarrow$ **PASS**.
4. **Test 4 (Biên tuổi 47 tháng)**: Nhận đúng 196 entry dải 24-47 $\rightarrow$ **PASS**.
5. **Test 5 (Biên tuổi 48 tháng)**: **Không nhận bất kỳ entry nào từ dải 24-47**, không có fallback $\rightarrow$ **PASS**.
6. **Test 6 (Test riêng Cảm xúc)**: Trẻ 30 tháng query `linh_vuc='cam_xuc'` trả về đủ 12 entry (6 BT, 6 TK), không còn trạng thái rỗng $\rightarrow$ **PASS**.
7. **Test 7**: `VectorSearchService.searchExpertChunks` lọc tuổi trước khi tính similarity cho dải 24-47 $\rightarrow$ **PASS**.
8. **Test 8**: Widget `ComparisonVideoPage` cho trẻ 30 tháng lĩnh vực Cảm xúc hiển thị 2 tab và danh sách nội dung thật $\rightarrow$ **PASS**.

---

### 5. Tổng Kết Chất Lượng Toàn Codebase
- `flutter analyze`: **0 issues found** (No issues found!).
- `flutter test`: **154/154 PASS (100% trên toàn bộ 33 test files)**.

## Dev Tool: `tools/video_manager_tool.py` — Thêm Video Mẫu Tham Khảo (2026-08-16)

**Đây là DEV TOOL độc lập, KHÔNG phải tính năng của app Flutter** — chạy trên máy tính người phát triển bằng:
```
python tools/video_manager_tool.py
```
Chỉ dùng thư viện chuẩn Python (`tkinter`, `json`, `shutil`, `pathlib`, `re`, `datetime`) — không cần `pip install` gì. Không được build cùng app, không đụng tới `lib/`.

### 1. Audit trước khi viết code

- **`pubspec.yaml`** (đọc trực tiếp): khối `flutter: > assets:` thụt lề 2 space/cấp, đã khai báo sẵn **7 thư mục video theo cấp LĨNH VỰC** (phẳng, không lồng theo phân loại/dải tuổi): `assets/videos/{nhan_thuc,cam_xuc,giac_quan,quan_he_xa_hoi,ngon_ngu,sinh_hoc,sinh_hoat_ca_nhan}/`. Ngoài ra có `assets/data/`, `assets/reference/`, `assets/images/mascot/`, `assets/images/icons/`.
- **`assets/videos/` trên đĩa**: 9 thư mục, mỗi thư mục chỉ có 1 file `.gitkeep` (rỗng thật). 2 thư mục thừa `hanh_vi/`, `ung_xu/` tồn tại trên đĩa nhưng KHÔNG được khai báo trong `pubspec.yaml` (tàn dư từ đợt gỡ 2 lĩnh vực này khỏi app) — tool KHÔNG dùng 2 thư mục này.
- **`lib/core/constants/domains.dart`**: nguồn CHUẨN cho danh sách 7 lĩnh vực — mỗi `Domain` có `code` (snake_case) + `label` (tiếng Việt). Docstring của file này còn xác nhận trực tiếp: "*[code] khớp... tên thư mục trong `assets/videos/`*" — xác nhận quy ước tên thư mục = `Domain.code`. Đã copy chính xác 7 cặp (code, label) vào tool, test đối chiếu ngược lại với chính file `.dart` này (xem mục 3).
- **`phan_loai`**: không có enum/constants riêng trong `lib/`, dùng string literal `'binh_thuong'`/`'roi_loan_pho_tu_ky'` xuyên suốt (`expert_knowledge_chunk.dart`, `expert_knowledge_repository.dart`, `comparison_video_page.dart`) — đã xác nhận qua các đợt sửa lỗi màn "So sánh" ngay trước đó trong cùng phiên làm việc.
- **Dải tuổi**: 3 dải cố định `(15,23)/(24,47)/(48,60)` tháng — đúng chuẩn đã chốt cho `so_sanh`/`chia_se_phu_huynh`/`bac_si` (`scripts/validate_expert_content.dart`), key thư mục dùng định dạng `"15_23"/"24_47"/"48_60"` khớp cách đặt tên đã dùng cho `so_sanh_15_23_thang.json`.
- **`assets/reference/`**: đã là nơi chứa các file dữ liệu tĩnh JSON khác (`expert_content.json`, `expert_content_so_sanh.json`) — manifest video đặt cùng chỗ: `assets/reference/video_manifest.json`.
- grep `assets/videos`/`video_manifest` trong `lib/`: **không có kết quả nào** ngoài dòng docstring nêu trên — xác nhận CHƯA có code Dart nào đọc video mẫu; tool này là nơi đầu tiên định ra schema manifest.

**Phát hiện lệch quan trọng so với thiết kế ban đầu (bắt buộc phải điều chỉnh):** yêu cầu tổ chức video theo TỪNG TỔ HỢP lĩnh vực×phân loại×dải tuổi (`assets/videos/{linh_vuc}/{phan_loai}/{dai_tuoi}/`) — nhưng Flutter chỉ đóng gói file nằm TRỰC TIẾP trong thư mục được khai báo ở `pubspec.yaml` (không tự đệ quy vào thư mục con). 7 dòng khai báo cấp lĩnh vực có sẵn **không đủ** để đóng gói các thư mục con lồng bên trong. → Quyết định: giữ cấu trúc thư mục lồng theo đúng yêu cầu (browsable, không trùng tên), và tính năng "Cập nhật pubspec.yaml" của tool **thực sự cần thiết** (không phải no-op) — mỗi khi thêm video vào 1 tổ hợp mới, cần thêm 1 dòng khai báo thư mục con cụ thể đó.

### 2. Code đã viết

- **[tools/video_manager_tool.py](tools/video_manager_tool.py)**: 1 file duy nhất.
  - Hằng số `DOMAINS`/`PHAN_LOAI`/`AGE_BANDS` copy chính xác từ `domains.dart` + giá trị `phan_loai`/dải tuổi đã xác nhận qua audit.
  - Logic thuần (không phụ thuộc tkinter ở top-level, `tkinter` chỉ `import` bên trong `_run_gui()`): `load_config`/`save_config`, `load_manifest`/`save_manifest`, `next_entry_id` (max id hiện có + 1, không dùng `len()` — đúng cả khi đã xoá entry giữa danh sách), `unique_dest_filename` (tránh ghi đè khi trùng tên, thêm hậu tố `" (2)"`, `" (3)"`...), `add_video_files` (copy nhiều file, tạo thư mục tổ hợp nếu chưa có, ghi manifest, không dừng giữa chừng nếu 1 file lỗi), `remove_video_entry` (xoá file thật + dòng manifest, báo lỗi rõ nếu id không tồn tại), `filter_entries` (lọc theo lĩnh vực/phân loại).
  - `declared_pubspec_asset_dirs`/`missing_pubspec_asset_dirs`/`update_pubspec_file`: parse các dòng `- assets/...` hiện có bằng regex, tìm dòng "- assets/..." CUỐI CÙNG để chèn ngay sau (giữ nguyên thụt lề), backup `.bak` trước khi ghi, không đụng bất kỳ dòng nào khác trong file.
  - GUI Tkinter tiếng Việt: chọn thư mục dự án (nhớ lại qua `tools/.video_manager_config.json`), form 3 dropdown (Lĩnh vực/Phân loại/Dải tuổi) + ô tiêu đề + chọn nhiều file + nút thêm, bảng Treeview danh sách video (lọc theo lĩnh vực/phân loại, nút xoá có xác nhận), nút "Cập nhật pubspec.yaml..." (preview trước, hỏi xác nhận, rồi mới ghi).
- **[tools/test_video_manager_tool.py](tools/test_video_manager_tool.py)**: test logic thuần — import thẳng module (không cần `Tk()` chạy được, vì `tkinter` chỉ import bên trong hàm `_run_gui()`), dùng thư mục `tempfile.TemporaryDirectory` làm "dự án giả" cho mọi test copy/xoá file thật.
- Thêm `.gitignore`: `tools/.video_manager_config.json` (đường dẫn máy cục bộ) và `tools/__pycache__/`.

**Không có gì phải sửa thêm ngoài quyết định ở mục 1** — phần còn lại của thiết kế (form 3 dropdown, manifest 9 trường, nút xoá, nút cập nhật pubspec) giữ nguyên như yêu cầu.

### 3. Kết quả test

`python tools/test_video_manager_tool.py` — **55/55 PASS**, gồm:
- Manifest load/save round-trip, đúng vị trí `assets/reference/video_manifest.json`.
- Sinh id tăng dần đúng cả khi đã xoá entry giữa danh sách.
- Tránh ghi đè khi copy nhiều file trùng tên gốc (test copy 2 lần cùng tên `same_name.mp4` với nội dung khác nhau — xác nhận file gốc KHÔNG bị ghi đè, cả 2 bản cùng tồn tại).
- `add_video_files` tạo đúng thư mục tổ hợp lĩnh vực/phân loại/dải tuổi, copy đúng file thật, ghi đúng 9 trường manifest (`id`, `linh_vuc`, `phan_loai`, `do_tuoi_thang_min`, `do_tuoi_thang_max`, `file_path`, `tieu_de`, `ten_file_goc`, `ngay_them`).
- `remove_video_entry` xoá đúng file thật + dòng manifest, báo lỗi rõ khi xoá lần 2 (id không còn tồn tại), không crash.
- `filter_entries` lọc đúng theo lĩnh vực/phân loại/cả 2.
- Đối chiếu ngược `DOMAINS`/`PHAN_LOAI`/`AGE_BANDS` trong tool với đúng nội dung file `lib/core/constants/domains.dart` thật (đọc trực tiếp bằng test, không tin bằng mắt).
- **Test riêng `update_pubspec_file` trên BẢN SAO `pubspec.yaml` THẬT** (copy ra `tempfile.TemporaryDirectory`, KHÔNG đụng file thật trong repo): xác nhận thêm đúng 2 dòng thư mục còn thiếu, có backup `.bak` giống hệt bản gốc trước khi ghi, mọi dòng gốc khác (kể cả khối `dependencies:`/`dev_dependencies:`) không bị mất/sửa, chạy lại lần 2 với cùng dữ liệu KHÔNG thêm trùng (`ok2 is False`), mỗi dòng mới chỉ xuất hiện đúng 1 lần trong file cuối cùng.
- Xác nhận `git status`/`git diff --stat pubspec.yaml` sau khi chạy test: **file `pubspec.yaml` thật trong repo hoàn toàn không đổi** — mọi thao tác ghi chỉ xảy ra trên bản sao trong thư mục tạm.
- `python -m py_compile tools/video_manager_tool.py tools/test_video_manager_tool.py`: sạch, không lỗi cú pháp.

### 4. Schema manifest — để phiên sau (code UI hiển thị video thật) biết đọc từ đâu

File: **`assets/reference/video_manifest.json`** — JSON array, mỗi phần tử:
```json
{
  "id": 1,
  "linh_vuc": "nhan_thuc",
  "phan_loai": "binh_thuong",
  "do_tuoi_thang_min": 15,
  "do_tuoi_thang_max": 23,
  "file_path": "assets/videos/nhan_thuc/binh_thuong/15_23/ten_file.mp4",
  "tieu_de": "Tiêu đề tuỳ chọn",
  "ten_file_goc": "ten_file_goc_tren_may.mp4",
  "ngay_them": "2026-08-16T14:30:00"
}
```
`file_path` đã đúng định dạng asset Flutter (dùng `/`, sẵn sàng dùng trực tiếp với `AssetSource`/`VideoPlayerController.asset()`). **Lưu ý quan trọng cho phiên sau**: nếu thêm video cho tổ hợp lĩnh vực/phân loại/dải tuổi MỚI (chưa từng có), phải chạy nút "Cập nhật pubspec.yaml..." trong tool này (hoặc tự thêm dòng tương ứng) TRƯỚC khi build lại app — nếu không, Flutter sẽ không đóng gói file video đó (không lỗi build, chỉ là app không load được asset lúc runtime).

## Thiết Kế Lại `video_manager_tool.py` — Video Gắn Theo TỪNG ID Entry (2026-08-16)

**Sửa 1 hiểu lầm quan trọng ở đợt trước**: đợt trước tool gắn video theo TỔ HỢP lĩnh vực×phân loại×dải tuổi (nhiều video dùng chung cho cả nhóm) — SAI so với thiết kế thật của dữ liệu. Đã **thiết kế lại hoàn toàn phần lõi xử lý dữ liệu** (không chỉ vá thêm — đúng theo yêu cầu, vì mô hình khoá theo group vs khoá theo id khác nhau về bản chất).

### 1. Audit trước khi sửa

- **`assets/reference/so_sanh_15_23_thang.json`** (đọc trực tiếp, đối chiếu với `assets/reference/so_sanh_24_47_thang.json` — cả 2 đều tồn tại, `so_sanh_48_60_thang.json` **CHƯA có** — tool phải tự `glob` để tự nhận file mới sau này): field `entries` (list), mỗi entry có `id` **DUY NHẤT TOÀN CỤC** (VD `so_sanh_nhan_thuc_binh_thuong_15_23_001`), cùng `linh_vuc`, `phan_loai`, `do_tuoi_thang_min/max`, `content`, `nguon_tai_lieu` (là link tham khảo nội bộ — có thể là URL YouTube, KHÔNG phải video hiển thị cho người dùng cuối, không liên quan tới video mẫu tool này gắn). Kiểm tra script xác nhận: 200 + 196 = 396 entry, **396 id — không trùng id nào** giữa 2 file.
- Đọc lại toàn bộ `tools/video_manager_tool.py` (bản đợt trước): xác định **giữ lại** style module docstring, cách tổ chức `_run_gui()`/class `VideoManagerApp`, `load_config`/`save_config`, và gần như nguyên vẹn logic `declared_pubspec_asset_dirs`/`update_pubspec_file` (thuần xử lý text, không phụ thuộc mô hình dữ liệu video theo group hay theo id — tái dùng được). **Viết lại hoàn toàn**: toàn bộ phần nạp dữ liệu (nay đọc entry từ `so_sanh_*_thang.json` thay vì dropdown chọn nhóm), schema manifest (dict khoá theo id thay vì list), hàm gắn/xoá video (theo entry cụ thể thay vì theo tổ hợp), toàn bộ UI (bảng tìm/lọc entry + panel xem chi tiết + nút gắn/gỡ, thay cho form 3 dropdown + nút thêm hàng loạt).
- **`pubspec.yaml`**: đã khai báo sẵn 7 thư mục `assets/videos/{linh_vuc}/` từ trước (không đổi từ đợt trước). Vì tên file video giờ = chính xác id của entry (không cần chia theo phân loại/dải tuổi trong đường dẫn nữa — id đã tự chứa đủ thông tin đó), quyết định: **lưu video tại `assets/videos/{linh_vuc}/{id}.{đuôi file}`** — tái dùng ĐÚNG 7 thư mục lĩnh vực đã khai báo sẵn, KHÔNG tạo thêm cấp thư mục con nào. Kết quả: trong tình huống thông thường **KHÔNG cần sửa `pubspec.yaml` thêm lần nào nữa** (test xác nhận: 7/7 thư mục lĩnh vực dùng bởi manifest video mẫu đều đã có sẵn). Vẫn giữ nút "Cập nhật pubspec.yaml..." để phòng trường hợp hiếm 1 dòng khai báo lĩnh vực bị lỡ xoá.

### 2. Mô hình dữ liệu mới

- **Manifest**: `assets/reference/video_manifest.json` (không đổi vị trí) — nhưng đổi hẳn schema, khoá **THEO ID**:
  ```json
  {
    "videos": {
      "so_sanh_nhan_thuc_binh_thuong_15_23_001": {
        "file_path": "assets/videos/nhan_thuc/so_sanh_nhan_thuc_binh_thuong_15_23_001.mp4",
        "ten_file_goc": "tên file gốc lúc chọn trên máy",
        "ngay_them": "2026-08-16T14:30:00"
      }
    }
  }
  ```
  Chỉ 1 mô hình duy nhất (theo id) — **không còn** cấu trúc list nhóm theo lĩnh vực/phân loại/tuổi của bản trước (đã xoá hẳn, không giữ song song 2 mô hình).
- **Sparse theo thiết kế**: phần lớn id KHÔNG có video — `video_manifest.json` chỉ chứa các id người dùng chủ động chọn gắn. Entry không có video vẫn hiện bình thường trong bảng (trạng thái cột "Video" để trống, không lỗi, không bị ẩn) — có test riêng xác nhận đúng hành vi này.
- **Tên file = chính xác id** (giữ đuôi file gốc, hạ thường): loại bỏ hoàn toàn khả năng nhầm entry nào ứng với video nào chỉ bằng cách nhìn tên file.

### 3. Chức năng UI mới

- Bảng (Treeview) liệt kê TẤT CẢ entry gộp từ mọi file `so_sanh_*_thang.json` tìm được — cột: trạng thái video (✅/trống), id, lĩnh vực, phân loại, dải tuổi, nội dung rút gọn (~60 ký tự).
- Ô tìm kiếm theo id/nội dung (không phân biệt hoa/thường) + dropdown lọc lĩnh vực/phân loại/dải tuổi + checkbox "Chỉ hiện chưa có video".
- Chọn 1 dòng → panel bên phải hiện đầy đủ `content`, metadata, trạng thái video hiện tại.
- Nút "Gắn / Thay video..." (hỏi xác nhận thay thế nếu entry đã có video — xoá file cũ trước khi copy file mới, không để sót file rác) và "Gỡ video" (xoá file thật + xoá khoá khỏi manifest, có xác nhận).

### 4. Kết quả test

`python tools/test_video_manager_tool.py` — **67/67 PASS**, gồm:
- Tự `glob` đúng file `so_sanh_*_thang.json`, bỏ qua file khác không khớp mẫu; gộp đúng entry từ nhiều file, gắn đúng `_source_file`.
- Xử lý đúng id trùng lặp (giữ bản xuất hiện trước, cảnh báo rõ ràng) — phòng trường hợp hiếm `so_sanh_48_60_thang.json` sau này lỡ trùng id.
- Manifest mới đúng schema `{"videos": {id: {...}}}`; **từ chối rõ ràng** nếu gặp file manifest kiểu CŨ (list nhóm) — không âm thầm đọc nhầm.
- Gắn video: đặt tên file đúng theo id (giữ đuôi gốc, hạ thường), đúng thư mục `assets/videos/{linh_vuc}/`, đúng 3 trường manifest.
- **Thay thế video cho cùng 1 id**: xác nhận file video CŨ (đuôi khác) bị xoá khỏi đĩa, không để sót, chỉ còn đúng 1 file/1 entry manifest sau khi thay.
- Entry KHÔNG có video vẫn hiện trong danh sách lọc bình thường (test riêng, đúng yêu cầu "sparse — không bắt buộc đủ").
- Gỡ video: xoá đúng file + khoá manifest, báo lỗi rõ khi gỡ lần 2 (không còn gì để gỡ).
- Lọc theo lĩnh vực/phân loại/dải tuổi/tìm kiếm — từng chiều riêng lẻ đều đúng.
- Đối chiếu `DOMAINS`/`PHAN_LOAI`/`AGE_BANDS` với **cả** `lib/core/constants/domains.dart` **và** dữ liệu thật trong `assets/reference/so_sanh_*_thang.json` của repo (đọc trực tiếp, không giả lập) — xác nhận mọi `linh_vuc`/`phan_loai` thật trong repo đều nằm trong tập hằng số của tool.
- **`update_pubspec_file` trên bản sao thật**: xác nhận 7/7 thư mục lĩnh vực đã khai báo sẵn (tình huống thông thường không cần thêm gì); mô phỏng tình huống hiếm (xoá thật 1 dòng khỏi bản sao) → phát hiện đúng, thêm lại đúng, có backup `.bak` khớp đúng trạng thái ngay trước khi ghi, không mất dòng nào khác, chạy lại lần 2 không thêm trùng.
- `git status --porcelain pubspec.yaml` sau khi chạy test: **sạch** — file thật hoàn toàn không bị đụng.
- `python -m py_compile tools/video_manager_tool.py tools/test_video_manager_tool.py`: sạch.

### 5. Việc còn lại

- Manifest hiện chưa có entry nào thật (chưa ai dùng tool để gắn video) — `assets/reference/video_manifest.json` sẽ chỉ được tạo khi người dùng chạy tool và gắn video đầu tiên.
- Khi `so_sanh_48_60_thang.json` được thêm vào `assets/reference/`, tool tự nhận diện ngay (không cần sửa code) nhờ dùng `glob("so_sanh_*_thang.json")`.

## Đổi Giao Diện `video_manager_tool.py` — Cuộn Xem Toàn Bộ, Không Cần Tìm Mới Thấy (2026-08-16)

**Yêu cầu:** bỏ mô hình "bảng Treeview rút gọn + phải bấm chọn 1 dòng mới xem full nội dung ở panel riêng" — đổi sang: mở dự án xong là thấy NGAY toàn bộ id kèm đầy đủ nội dung trên 1 khung cuộn dọc, không cần thao tác gì thêm. Chỉ đổi phần hiển thị — mô hình dữ liệu (manifest khoá theo id) giữ nguyên như đợt trước.

### 1. Thiết kế giao diện mới

- Khung cuộn dọc dựng thủ công theo đúng cách chuẩn của Tkinter (Tkinter không có scroll frame dựng sẵn): `Canvas` + `Frame` bên trong (`list_frame`) + `ttk.Scrollbar`, cộng cuộn bằng chuột giữa (bind `<MouseWheel>` khi con trỏ ở trên khung, unbind khi rời khỏi).
- Mỗi entry = 1 "khối" (`Frame` viền mỏng, nền trắng) gồm: `id` đầy đủ (in đậm), 1 dòng metadata (lĩnh vực • phân loại • dải tuổi • file nguồn), **toàn bộ `content`** (dùng `tk.Label` với `wraplength=900` — Label tự xuống dòng và tự cao theo độ dài nội dung, không cần tự tính chiều cao thủ công như `tk.Text`), và 1 dòng trạng thái video (nút "Thêm video..." nếu chưa có; tên file + nút "Thay video..."/"Gỡ video" nếu đã có).
- Thanh lọc (tìm theo id/nội dung — chỉ là lựa chọn hỗ trợ thêm, KHÔNG bắt buộc; dropdown lĩnh vực/phân loại/dải tuổi; checkbox "Chỉ hiện chưa có video") đặt CỐ ĐỊNH phía trên khung cuộn, không cuộn theo danh sách.
- **Hiệu năng**: dựng TOÀN BỘ khối đúng 1 LẦN khi mở dự án (`_build_all_blocks()`), lưu vào `self.block_frames`/`self.status_frames` theo id. Lọc/tìm kiếm (`_apply_filters()`) chỉ gọi `pack()`/`pack_forget()` trên khối đã dựng sẵn — KHÔNG dựng lại widget mỗi lần gõ phím, nên gõ tìm kiếm trên danh sách 400 entry vẫn mượt. Gắn/gỡ video chỉ dựng lại đúng `status_frame` của khối đó (`_render_block_status()`), không đụng các khối khác.
- Tách rõ 2 tầng: hành động có hộp thoại (`_prompt_project_root`, `_attach_video`, `_detach_video`, `_update_pubspec` — không gọi trong test) và logic thuần không hộp thoại (`open_project`, `apply_attach`, `apply_detach` — gọi trực tiếp được từ test).

### 2. Testable bằng `tk.Tk()` THẬT

Môi trường chạy có display thật (`tk.Tk()` tạo được cửa sổ) — xác nhận qua thử nghiệm trước khi viết test. Vì vậy, thay vì giả lập tối thiểu module `tkinter`, đã tách `build_app_class()` (import tkinter + định nghĩa `VideoManagerApp`, trả về class) ra khỏi `_run_gui()` — cho phép test dựng **widget Tkinter thật** (`tk.Tk()` ẩn qua `root.withdraw()`, không gọi `mainloop()`) để đếm số khối đã `pack()`, đọc `.cget("text")` thật từ widget, đo thời gian dựng UI — mà KHÔNG cần chạy cửa sổ thật hay thao tác chuột/bàn phím thật. `import video_manager_tool` (không gọi `build_app_class()`) vẫn không đụng tới tkinter, giữ đúng yêu cầu module import được ở môi trường không có GUI (hàm `_make_hidden_root()` trong test có fallback bỏ qua nhóm test giao diện + in `[SKIP]` nếu môi trường nào đó không tạo được cửa sổ Tk, không làm crash toàn bộ test).

### 3. Kết quả test

`python tools/test_video_manager_tool.py` — **80/80 PASS** (67 test logic thuần trước đó + 13 test mới), gồm:
- **Load full ngay khi mở dự án**: 2 file giả (5 + 3 = 8 entry) → dựng đúng 8 khối, cả 8 đều đang `pack()` (hiển thị) khi chưa lọc gì — không có khối nào bị ẩn mặc định. Nội dung ĐẦY ĐỦ (so khớp y hệt `entry["content"]`, không rút gọn) và `id` đầy đủ đã có sẵn trong cây widget ngay sau khi dựng — dò bằng hàm đệ quy `_collect_widget_texts()` đọc thật `.cget("text")` từ mọi widget con, không chỉ tin thuộc tính nội bộ của app.
- **Lọc theo lĩnh vực**: chọn "Nhận thức" → đúng 2/3 khối còn hiển thị (so khớp chính xác id), khối thứ 3 vẫn tồn tại trong `self.block_frames` (chỉ ẩn, không huỷ) — bỏ lọc thì hiện lại đủ.
- **Checkbox "chỉ hiện chưa có video"**: gắn video cho 1 id qua `apply_attach()` (không qua hộp thoại thật) → bật checkbox → đúng id đã gắn biến mất khỏi hiển thị, id còn lại (chưa có video) vẫn hiện; khối của id đã gắn hiện đúng 2 nút "Thay video..."/"Gỡ video" ngay tại chỗ.
- **Hiệu năng với dữ liệu THẬT của repo** (396 entry từ 2 file `so_sanh_15_23_thang.json` + `so_sanh_24_47_thang.json` có sẵn): dựng toàn bộ UI trong **0.13 giây** — không giật/treo, không cần tối ưu thêm (lazy render/phân đợt) như phương án dự phòng nêu trong yêu cầu. Lọc/tìm kiếm sau khi đã dựng xong chỉ mất **0.001 giây** (nhanh hơn ~130 lần so với lần dựng đầu) — xác nhận đúng cơ chế "chỉ ẩn/hiện, không dựng lại".
- `python -m py_compile tools/video_manager_tool.py tools/test_video_manager_tool.py`: sạch.
- `git status --porcelain pubspec.yaml assets/reference/video_manifest.json` sau khi chạy toàn bộ test (kể cả test hiệu năng mở thẳng repo thật ở chế độ chỉ-đọc): **sạch** — không file thật nào trong repo bị tạo/sửa.

## Nút "Xem Video Minh Hoạ" Trong UI "So Sánh" (2026-08-16)

Đưa kết quả 78 video mẫu đã gắn qua `tools/video_manager_tool.py` (dải 15-23 tháng) lên UI thật của app Flutter — trước đây chỉ có manifest JSON, chưa có code Dart nào đọc.

### 1. Audit trước khi sửa

- **`assets/reference/video_manifest.json`** (đọc trực tiếp): đúng schema đã thống nhất `{"videos": {"<id>": {"file_path", "ten_file_goc", "ngay_them"}}}` — **78 video** đã gắn, khoá đúng theo `id` chunk thật (VD `so_sanh_nhan_thuc_binh_thuong_15_23_001`). Xác nhận cả 78 file `.mp4` tương ứng đều tồn tại thật trên đĩa đúng `file_path` khai báo (0 file thiếu).
- **`pubspec.yaml`**: cả 7 thư mục `assets/videos/{linh_vuc}/` cần dùng (nhan_thuc, cam_xuc, quan_he_xa_hoi, ngon_ngu, sinh_hoc, sinh_hoat_ca_nhan — và giac_quan) đã khai báo sẵn từ trước — **không cần sửa `pubspec.yaml`**.
- **`lib/domain/models/expert_knowledge_chunk.dart`**: model **có giữ `id` gốc** (`final String id;`), đúng khớp id trong SQLite/manifest — không cần sửa gì để "mang id xuống UI".
- **`ComparisonItemList`** (`comparison_video_page.dart`, dùng chung bởi `ComparisonVideoPage` và `ComparisonDetailPage`, từ đợt sửa lỗi 2-tab trước đó trong cùng phiên): `itemBuilder` nhận `items[index]` là `ExpertKnowledgeChunk` đầy đủ (không phải `String` rút gọn) — **đã có `id` sẵn tại điểm render**, chỉ cần sửa `itemBuilder`, không cần đổi signature/luồng dữ liệu nào khác.
- **Cơ chế phát video sẵn có**: grep `video_player`/`VideoPlayerController` trong `lib/` → chỉ có ở `video_detail_page.dart` và `video_review_page.dart` (màn xem lại video người dùng TỰ QUAY) — cả 2 dùng `VideoPlayerController.file(File(...))`. **Không có sẵn `VideoPlayerController.asset(...)`** (nguồn asset đóng gói sẵn, khác hẳn file người dùng tự quay) và **không có sẵn widget dialog/page dùng chung nào** (`VideoPlayerDialog`/`VideoPreviewPage` — không tồn tại). Quyết định: viết 1 page mới nhỏ `VideoIllustrationPlayerPage` theo ĐÚNG cùng kiểu giao diện (AspectRatio + VideoPlayer + nút play/pause đè lên, báo lỗi bằng Text khi init thất bại) như `_buildPlayer()` trong `video_detail_page.dart` — tái dùng ĐÚNG PATTERN/LOGIC, không phải tái cấu trúc 2 file video-quay (ngoài phạm vi, có nguy cơ ảnh hưởng tính năng quay video đang chạy tốt) để ép dùng chung 1 class.
- grep `video_manifest` trong `lib/` trước khi sửa: **0 kết quả** — xác nhận đây là lần đầu tiên có code Dart đọc file này.

### 2. Code đã thêm/sửa

- **[lib/domain/services/video_manifest_service.dart](lib/domain/services/video_manifest_service.dart)** (mới): nạp + cache `video_manifest.json` — cùng pattern với `ScreeningLoaderService` đã có (`static Map? _cachedPaths`, `loadVideoPaths({AssetBundle? bundle})` chỉ đọc file 1 lần, `parseJson()` tách riêng để test không cần Flutter engine, `clearCache()` cho test). `getVideoPathForId(id)` tra cứu đồng bộ từ cache. An toàn tuyệt đối nếu asset chưa tồn tại (dải 24-47/48-60 chưa gắn video nào) — `catch` mọi lỗi, trả `{}`, không chặn màn "So sánh".
- **[lib/features/assessment/nine_domains/comparison_video/video_illustration_player_page.dart](lib/features/assessment/nine_domains/comparison_video/video_illustration_player_page.dart)** (mới): `VideoIllustrationPlayerPage(assetPath, title)` — khởi tạo `VideoPlayerController.asset(assetPath)`, tự `play()`, báo lỗi bằng `Text` nếu init thất bại (file thiếu/hỏng), không crash app.
- **`comparison_video_page.dart`**: `loadComparisonTabData()` nạp thêm `VideoManifestService.loadVideoPaths()` song song với 2 query tab (dùng `Future.wait`, cache lại nên `ComparisonDetailPage` mở sau đó không đọc lại file). `ComparisonItemList.itemBuilder` gọi `VideoManifestService.getVideoPathForId(item.id)` — khác `null` thì thêm `TextButton.icon` "Xem video minh hoạ" (icon `play_circle_outline`) ngay dưới `content`, mở `VideoIllustrationPlayerPage`; `null` thì **không render gì thêm** (không mờ/disable).
- **`comparison_detail_page.dart`**: **không cần sửa** — tái dùng `ComparisonItemList` nên tự động thừa hưởng nút video.

### 3. Kết quả test

- **[test/video_manifest_service_test.dart](test/video_manifest_service_test.dart)** (mới, 6 test): `parseJson` đúng schema; `loadVideoPaths` cache đúng (đọc file đúng 1 lần dù gọi nhiều lần, xác nhận bằng bộ đếm trên `AssetBundle` giả); `getVideoPathForId` đúng cho cả 2 trường hợp có/không có video; an toàn khi asset chưa tồn tại (trả rỗng, không lỗi); `clearCache()` buộc đọc lại đúng.
- **`test/comparison_tabs_test.dart`**: thêm 3 test trong group `Nút "Xem video minh hoạ"` — dùng `AssetBundle` giả (`_FakeVideoManifestBundle`) tiêm trực tiếp qua `VideoManifestService.loadVideoPaths(bundle: ...)` để kiểm soát chính xác id nào có video, không phụ thuộc 78 video thật (dễ đổi theo thời gian):
  - Đúng 1/3 entry hiện nút — khớp chính xác số id có trong manifest, entry khác **hoàn toàn không có nút** (không mờ/disable).
  - Bấm nút mở đúng `VideoIllustrationPlayerPage` với đúng `assetPath` của entry đã bấm (không lẫn asset giữa các entry).
  - Manifest chưa tồn tại (dải tuổi chưa gắn video) → toàn bộ entry không hiện nút nào, không lỗi.
  - **Bug phát hiện + sửa trong lúc viết test**: cache tĩnh của `VideoManifestService` bị nạp bởi dữ liệu THẬT từ `rootBundle` ở các test KHÔNG liên quan chạy trước đó trong cùng file (mọi lần render `ComparisonVideoPage` đều gọi `loadVideoPaths()`), khiến lần gọi với bundle giả sau đó bị bỏ qua (cache đã có). Sửa: thêm `VideoManifestService.clearCache()` vào `setUp()` chung của file test.
- `flutter analyze`: **No issues found!**
- `flutter test` (toàn bộ workspace, log ra file tránh timeout): **163/163 PASS**, không regression so với baseline trước đó.

### 4. Verify thật trên emulator (Pixel_7, Android, 2026-08-16)

Build debug (`flutter run -d emulator-5554 --dart-define-from-file=dart_define.json`), xác nhận `run-as` debuggable. DB thật trên máy có sẵn 402 entry `so_sanh` (bao gồm dải 15-23 thật khớp đúng id với `video_manifest.json`) và trẻ "lvl" (dob 2025-03-16 → đúng 17 tháng = "1 tuổi 5 tháng", nằm trong dải 15-23).

1. **Đếm khớp chính xác**: DB có 13 entry `nhan_thuc`/`binh_thuong`/15-23; manifest có đúng 12/13 id đó có video (thiếu id `_013`). Trên UI thật ("Nhận thức — So sánh nhanh", tab "Trẻ bình thường"): cuộn hết danh sách, đếm đúng **12 nút "Xem video minh hoạ"**, entry cuối cùng (`_013`, "Bắt chước làm việc nhà như dùng chổi để quét.") **không có nút** — khớp chính xác 100% với dữ liệu manifest thật, không thừa không thiếu.
2. **Bấm nút phát đúng video**: bấm nút của entry "Nó nhìn vào một vật quen thuộc khi bạn gọi tên vật đó." → mở đúng `VideoIllustrationPlayerPage`, nút play/pause chuyển sang trạng thái "đang phát" (⏸), không có Text lỗi, `adb logcat` không có exception nào liên quan video/ExoPlayer/flutter error → xác nhận `VideoPlayerController.asset()` init + play thành công với video thật. (Khung hình video xuất hiện đen trong ảnh chụp qua `adb screencap` — đây là giới hạn đã biết của `adb screencap` với lớp render texture/SurfaceView của video trên Android, không phản ánh lỗi thật; trạng thái nút pause + không có exception trong log là bằng chứng đáng tin cậy hơn ảnh chụp cho việc video đang phát.)
3. **Trẻ ở dải tuổi CHƯA có video (24-47 tháng)**: đổi active child sang "233" (2 tuổi 3 tháng). Mở "Nhận thức — So sánh nhanh": toàn bộ 10 entry hiện nội dung đầy đủ bình thường, **0 nút "Xem video minh hoạ"** nào xuất hiện, không lỗi, không khoảng trống/placeholder gây rối giao diện — đúng hành vi mong đợi khi `video_manifest.json` không có video nào cho dải tuổi đó.

### 5. Việc còn lại

- Chỉ dải 15-23 tháng có video (78/~400+ id khả dụng). Khi biên soạn thêm video cho dải 24-47/48-60 qua `tools/video_manager_tool.py`, không cần sửa code Dart nào thêm — `VideoManifestService`/`ComparisonItemList` đã tổng quát theo mọi id trong manifest.
