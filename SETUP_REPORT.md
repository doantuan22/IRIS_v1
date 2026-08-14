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
