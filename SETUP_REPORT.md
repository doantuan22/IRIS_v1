# SETUP_REPORT — Khởi tạo repo dự án IRIS

## 1. Kiểm tra môi trường

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| Flutter | PASS | 3.44.8 (stable channel) — có bản mới hơn, chưa cần upgrade |
| Dart | PASS | 3.12.2 |
| Git | PASS | 2.54.0 — thư mục chưa phải git repo, đã chạy `git init` |
| Hệ điều hành | Windows 11 (25H2) | Chỉ build được Windows/Android/Web trên máy này — **không build được iOS/macOS** (cần máy macOS) |
| Android toolchain | PASS | SDK 36.0.0, build-tools 36.0.0, license đã accept |
| Visual Studio Build Tools (Windows desktop) | PASS | 2022 17.14, Windows 10 SDK 10.0.26100.0 |
| Chrome (web) | PASS | 151.0.7922.76 |
| `flutter doctor -v` | PASS — "No issues found!" | |
| Thiết bị/emulator | 3 thiết bị kết nối: Windows desktop, Chrome, Edge | Chưa có emulator Android **đang chạy**, nhưng đã có 1 AVD cấu hình sẵn: `Pixel_7` (chạy bằng `flutter emulators --launch Pixel_7`) |

Không thiếu thành phần nào cần thiết để chạy app trên Windows/Web/Android (qua emulator có sẵn).

## 2. Đã tạo

- Khởi tạo Flutter project **tại chính `IRIS_v1`** bằng `flutter create .` (không tạo thư mục con lồng bên trong), package name `iris_app`, org `com.iris.app`. `ROADMAP_DU_AN_IRIS.md` được giữ nguyên.
- Khởi tạo git repo (`git init`).
- Dựng đầy đủ cây thư mục `lib/`, `assets/`, `scripts/`, `test/` theo đúng mục 5 roadmap (bỏ lớp `iris_app/` ngoài cùng). Danh sách file chính:
  - `lib/main.dart`, `lib/app.dart`
  - `lib/core/constants/api_config.dart` (+ thư mục rỗng `core/theme/`, `core/utils/`)
  - `lib/data/local/database.dart` + 8 file trong `data/local/tables/` (mỗi file 1 hằng `CREATE TABLE` khớp schema mục 4)
  - `lib/data/remote/nvidia_api_client.dart`, `groq_api_client.dart`
  - `lib/data/repositories/` — 5 file (child, screening, assessment, video, ai)
  - `lib/domain/models/` — 4 file (child, screening, assessment, ai_chunk)
  - `lib/domain/services/` — embedding_service, vector_search_service, guardrail_service (enum 3 trạng thái)
  - `lib/features/` — 13 trang skeleton (`Placeholder()`) theo đúng cấu trúc feature/nine_domains trong roadmap
  - `lib/widgets/.gitkeep`
  - `scripts/ingest_expert_data.dart` (skeleton)
  - `assets/reference/expert_content.json` — 2 entry mẫu (`so_sanh`, `chia_se_phu_huynh`, lĩnh vực `ngon_ngu`)
  - `assets/videos/<9 lĩnh vực>/.gitkeep`
- Cấu hình `pubspec.yaml`:
  - Dependencies: `sqflite` + `path` (đã chọn **sqflite thay vì drift** — roadmap đã viết sẵn schema SQL thuần, sqflite bám sát đúng schema đó và không cần bước code-gen `build_runner`, phù hợp ưu tiên tốc độ phát triển cho dự án thi), `path_provider`, `camera`, `video_player`, `http`, `uuid`.
  - Khối `flutter: assets:` trỏ tới `assets/reference/` và từng thư mục con của `assets/videos/`.
- `flutter pub get`: **chạy sạch**, 52 dependency mới, không lỗi.
- `flutter analyze`: **0 lỗi**. Còn 14 warning/info mức style (`unused_field` trên các repository — do constructor đã inject dependency nhưng thân hàm còn `UnimplementedError`, sẽ hết khi cài logic thật; 1 vài gợi ý `prefer_initializing_formals`). Không ảnh hưởng khả năng build/run.

## 3. Việc cần tự làm thủ công

- **API key**: xin key NVIDIA NIM và Groq, truyền lúc chạy — KHÔNG hardcode vào `api_config.dart`:
  ```
  flutter run --dart-define=NVIDIA_API_KEY=xxx --dart-define=GROQ_API_KEY=yyy
  ```
- **Quyền camera/microphone** cho chức năng quay video (#9):
  - Android: thêm `<uses-permission android:name="android.permission.CAMERA"/>` (và `RECORD_AUDIO` nếu quay có tiếng) vào `android/app/src/main/AndroidManifest.xml`.
  - iOS (nếu sau này build trên macOS): thêm `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` vào `ios/Runner/Info.plist`.
- **Emulator Android**: đã có sẵn `Pixel_7`, chạy `flutter emulators --launch Pixel_7` trước khi `flutter run` nếu muốn test trên Android.
- **iOS/macOS build**: cần một máy macOS có Xcode — máy Windows hiện tại không build được.
- Nạp thêm dữ liệu tham khảo thật vào `assets/reference/expert_content.json` (hiện chỉ có 2 entry mẫu) rồi chạy `scripts/ingest_expert_data.dart` sau khi cài logic ingest thật (script hiện là skeleton, ném `UnimplementedError`).
- Toàn bộ file `.dart` trong `data/`, `domain/`, `features/` mới là **khung sườn** (nhiều nơi `throw UnimplementedError`) — cần cài logic thật theo thứ tự triển khai ở mục 6 roadmap.
