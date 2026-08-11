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
