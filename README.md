# IRIS — Ứng Dụng Hỗ Trợ Theo Dõi Phát Triển & Sàng Lọc Trẻ Em

IRIS là ứng dụng di động Flutter hỗ trợ cha mẹ và người chăm sóc theo dõi biểu hiện phát triển của trẻ qua 7 lĩnh vực cốt lõi, kết hợp sàng lọc sớm và trợ lý AI (RAG trên dữ liệu chuyên môn) để phác hoạ bức tranh tổng quan ("Chân dung biểu hiện").

---

## 1. Yêu Cầu Môi Trường

- **Flutter SDK**: `^3.12.0` trở lên (Dart SDK `^3.12.0`)
- **Android SDK / Emulator**: Android API 30+ (ví dụ máy ảo `Pixel_7`)
- **API Keys Cloud AI**:
  - **NVIDIA NIM API Key**: Dùng cho tính năng embedding vector RAG (`nvidia/nv-embedqa-e5-v5`).
  - **Groq API Key**: Dùng cho tính năng hỏi đáp thông minh và tổng hợp Chân dung toàn cảnh (`openai/gpt-oss-20b`).

---

## 2. Cấu Hình API Key (Bắt Buộc Trước Khi Chạy)

Dự án sử dụng cơ chế compile-time constants (`String.fromEnvironment`) để nạp API key an toàn lúc build hoặc run, không hardcode key trong mã nguồn.

### Bước 1: Tạo file `dart_define.json` từ template
Copy file mẫu `dart_define.json.example` thành `dart_define.json` tại thư mục gốc của dự án:

```bash
cp dart_define.json.example dart_define.json
```

*(Trên Windows PowerShell: `Copy-Item dart_define.json.example dart_define.json`)*

### Bước 2: Điền API Keys thật vào `dart_define.json`
Mở file `dart_define.json` và thay thế giá trị placeholder bằng key thật của bạn:

```json
{
  "NVIDIA_API_KEY": "nvapi-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "GROQ_API_KEY": "gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

> [!CAUTION]
> **BẢO MẬT API KEY:**
> File `dart_define.json` chứa key thật đã được khai báo trong `.gitignore`. **TUYỆT ĐỐI KHÔNG** commit file này lên Git repository. Chỉ commit file mẫu `dart_define.json.example`.

---

## 3. Lệnh Chạy Ứng Dụng (Development)

### Chạy ứng dụng (kèm nạp API key):
```bash
flutter run --dart-define-from-file=dart_define.json
```

### Chạy trên thiết bị / máy ảo cụ thể:
```bash
# Khởi động máy ảo Pixel_7 (nếu máy ảo chưa mở)
flutter emulators --launch Pixel_7

# Chạy app trên máy ảo đang mở (mã thiết bị emulator-5554)
flutter run -d emulator-5554 --dart-define-from-file=dart_define.json
```

---

## 4. Lệnh Build Release APK (Production)

Để đóng gói file cài đặt Android APK bản Release có đầy đủ tính năng AI:

```bash
flutter build apk --release --dart-define-from-file=dart_define.json
```

File APK sau khi build thành công sẽ nằm tại:
`build/app/outputs/flutter-apk/app-release.apk`

### Cài đặt APK lên thiết bị qua ADB:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. Kiểm Thử & Đảm Bảo Chất Lượng

### Chạy toàn bộ Unit & Widget Tests:
```bash
flutter test
```

### Chạy Test Xác Thực Trực Tiếp Với Cloud AI Thật (NVIDIA & Groq):
```bash
flutter test test/real_cloud_ai_verification_test.dart --dart-define-from-file=dart_define.json
```

### Kiểm tra phân tích mã nguồn (Static Analysis):
```bash
flutter analyze
```

---

## 6. Cấu Trúc Dự Án Chính

- `lib/core/`: Hằng số, định nghĩa 7 lĩnh vực (`domains.dart`), cấu hình endpoint API (`api_config.dart`).
- `lib/data/`:
  - `local/`: SQLite database schema, bảng dữ liệu và migrations (`database.dart`).
  - `remote/`: HTTP clients gọi NVIDIA NIM (`nvidia_api_client.dart`) và Groq (`groq_api_client.dart`).
  - `repositories/`: Các repository tầng dữ liệu (Hồ sơ trẻ, Đánh giá, Sàng lọc, RAG Chunk, Overview...).
- `lib/domain/`: Business logic, Guardrails (`guardrail_service.dart`), Vector Search (`vector_search_service.dart`), Tính toán mức tổng quan (`overview_tier_calculator.dart`), Xây dựng Prompt (`prompt_builder.dart`).
- `lib/features/`: Các màn hình giao diện người dùng:
  - `assessment/`: Danh sách 7 lĩnh vực (`DomainListPage`), Domain Hub trung tâm (`DomainHubPage`), 4 phần đánh giá, và Chân dung toàn cảnh (`OverviewPortraitPage`).
  - `child_profile/`: Quản lý hồ sơ trẻ và nạp dữ liệu tham khảo chuyên môn.
  - `ai_chat/`: Hỏi đáp AI thông minh với bảo vệ Guardrails 3 trạng thái.
  - `screening/`: Sàng lọc phát triển.