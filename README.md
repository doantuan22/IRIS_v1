# IRIS — Ứng dụng Sàng lọc & Đánh giá Phát triển Trẻ em

**IRIS** là một ứng dụng di động hỗ trợ phụ huynh theo dõi, sàng lọc và đánh giá quá trình phát triển của trẻ em. Ứng dụng sử dụng cách tiếp cận cá nhân hóa với sự hỗ trợ của AI (Mô hình RAG) để giải đáp thắc mắc dựa trên bối cảnh riêng của từng trẻ, đồng thời lưu trữ toàn bộ dữ liệu an toàn trên thiết bị của người dùng (local-first).

---

## 1. Giới thiệu

- **Mục tiêu**: Cung cấp công cụ dễ tiếp cận, dễ sử dụng giúp phụ huynh nhanh chóng nhận biết các dấu hiệu phát triển của trẻ qua từng giai đoạn, đồng thời tham khảo các kiến thức chuyên môn một cách trực quan.
- **Đối tượng sử dụng**: Phụ huynh, người chăm sóc trẻ, giáo viên mầm non và các trung tâm giáo dục hòa nhập (như Trung tâm Tường Minh).
- **Tính năng cốt lõi**: Hồ sơ cá nhân hoá, sàng lọc 50 câu, đánh giá chi tiết 7 lĩnh vực (tích hợp 532 video mẫu tham khảo), chân dung biểu hiện tổng quan, và hệ thống AI hỏi đáp tích hợp Guardrail an toàn.

---

## 2. Công nghệ sử dụng

Đã được xác nhận trực tiếp từ `pubspec.yaml` (Phiên bản 1.0.0+1):

| Thành phần | Công nghệ / Package | Mục đích |
|---|---|---|
| **Framework** | Flutter (SDK ^3.12.2) | Xây dựng giao diện ứng dụng đa nền tảng |
| **Giao diện** | `google_fonts` (^6.3.2), `cupertino_icons` | Hệ thống Typography (Nunito, Fredoka) & Icons |
| **Cơ sở dữ liệu** | `sqflite` (^2.4.1) | Lưu trữ toàn bộ dữ liệu local trên thiết bị |
| **Đa phương tiện** | `camera` (^0.12.0), `video_player` (^2.9.5) | Quay video tình huống và phát video đối chiếu |
| **Mạng & API** | `http` (^1.2.2) | Giao tiếp với API AI (NVIDIA NIM, Groq) |
| **Tiện ích** | `uuid`, `shared_preferences`, `url_launcher`, `path_provider` | Quản lý ID, lưu tuỳ chọn, mở link ngoài, lấy đường dẫn |

---

## 3. Kiến trúc dự án

Dự án áp dụng kiến trúc **Local-First**, kết hợp với **RAG (Retrieval-Augmented Generation)** để vận hành AI.

```text
[Người Dùng] 
  │ (Hỏi đáp)
  ▼
[Ứng dụng Flutter] ──(Gọi NVIDIA NIM API)──> Vector Embedding
  │                                                │
  ▼                                                ▼
[Cơ sở dữ liệu Local SQLite] <──(Vector Search Cosine Similarity)
  ├─ profile_chunks (Dữ liệu cá nhân: Sàng lọc, Mô tả)
  └─ expert_knowledge_chunks (Kiến thức chuyên môn tĩnh)
  │
  ▼
[Guardrail Service] (Phân loại tự động 3 trạng thái an toàn: 1 / 2 / 3)
  │
  ▼
[Prompt Builder] (Xây dựng prompt theo trạng thái)
  │
  ▼
[Groq LLM API] ──> [Trả về câu trả lời cho Người Dùng]
```

---

## 4. Trạng thái chức năng hiện tại

*Dựa trên việc kiểm tra mã nguồn thực tế tại thời điểm viết tài liệu:*

| Chức năng | Trạng thái | Ghi chú từ Code & Dữ liệu thật |
|---|---|---|
| **Quản lý Hồ sơ trẻ** | Hoàn thành | Đầy đủ thông tin, lưu local (`children_table`). Hỗ trợ thêm vai trò/người đánh giá. |
| **Sàng lọc 50 câu** | Hoàn thành | Hoạt động trơn tru. Dữ liệu lưu trong bảng `screening_responses` & `screening_domain_scores`. |
| **Đánh giá 7 lĩnh vực** | Hoàn thành | Đã rút gọn từ 9 xuống 7 lĩnh vực chuẩn: Nhận thức, Cảm xúc, Giác quan, Quan hệ xã hội, Ngôn ngữ, Sinh học, Sinh hoạt cá nhân (`domains.dart`). |
| **Dữ liệu tham khảo "So sánh"** | Hoàn thành | Có **532 entries** (`so_sanh_*_thang.json`). Seed tự động vào DB qua `ExpertKnowledgeSeedService` (~3.09 MB gốc). |
| **Video mẫu** | Hoàn thành | **532 video**, được map theo `id` trong `video_manifest.json`. Tổng dung lượng nén thư mục `assets/videos` là **~897 MB**. |
| **Chân dung toàn cảnh** | Hoàn thành | Tính toán Tier bằng **code thuần** (`overview_tier_calculator.dart`), AI chỉ tổng hợp văn xuôi, không tự quyết định trạng thái. |
| **Hỏi đáp AI (RAG)** | Hoàn thành | Đã tích hợp `GuardrailService`. `relevanceThreshold = 0.72`. Có lớp lọc từ khoá phụ phòng ngừa câu hỏi ngoài domain. |
| **Kết nối chuyên gia** | Hoàn thành | Sử dụng dữ liệu THẬT (Trung tâm Hỗ trợ Phát triển Giáo dục Hòa Nhập Tường Minh). |
| **Kiểm tra kết nối AI** | Hoàn thành | Có `AiConnectivityService` chạy định kỳ, liên kết UI đèn trạng thái hoạt động tốt. |
| **Giao diện (UI)** | Hoàn thành | Tông màu Trắng - Xanh Biển (`navy900`, `primary`, `canvas`), font Nunito. Đã loại bỏ hoàn toàn các mascot cũ. |

---

## 5. Cấu trúc Database (SQLite)

Schema hiện tại đang ở **Version 11**, bao gồm **13 bảng** hoạt động hoàn toàn offline:

1. `children`: Thông tin cơ bản, vai trò người đánh giá.
2. `screenings`: Thông tin đợt sàng lọc.
3. `screening_responses`: Câu trả lời chi tiết của bài sàng lọc 50 câu.
4. `screening_domain_scores`: Điểm số theo lĩnh vực của đợt sàng lọc.
5. `assessments`: Dữ liệu mô tả biểu hiện riêng do người dùng nhập.
6. `history_logs`: Nhật ký hoạt động toàn app.
7. `profile_chunks`: Chunk dữ liệu của trẻ, phục vụ tìm kiếm RAG.
8. `expert_knowledge_chunks`: Dữ liệu chuyên môn tham khảo, tự động seed 532 dòng khi mở DB.
9. `videos`: Lưu thông tin video do người dùng quay trực tiếp.
10. `ai_conversations`: Lịch sử trò chuyện với AI.
11. `domain_overview_labels`: Nhãn tổng quan cho từng lĩnh vực trong phần Chân dung.
12. `overview_summaries`: Chân dung biểu hiện tổng hợp.
13. `notifications`: Lưu thông báo hệ thống và trạng thái kết nối.

---

## 6. Cấu trúc thư mục cốt lõi

```text
IRIS_v1/
├── assets/
│   ├── images/icons/         # Các icon giao diện tĩnh
│   ├── reference/            # Chứa expert_knowledge_seed.json, video_manifest.json
│   └── videos/               # Phân theo 7 lĩnh vực (chiếm ~897 MB)
├── lib/
│   ├── core/                 # Constants (domains), UI Themes (iris_theme.dart)
│   ├── data/                 # SQLite setup (database.dart) & Repositories
│   ├── domain/               # Models & Services (Guardrail, AI Connectivity, Tier Calculator)
│   ├── features/             # UI/UX chia theo chức năng: AI Chat, Sàng lọc, 9 Domains (cũ đổi tên thành 7), Profile...
│   └── main.dart             # Entry point
├── test/                     # Các kịch bản test
└── pubspec.yaml              # Khai báo dependency, assets
```

---

## 7. Cách Build & Chạy

1. **Chuẩn bị môi trường**: Đảm bảo cài đặt Flutter SDK ^3.12.2.
2. **Cài đặt thư viện**: Chạy `flutter pub get`.
3. **Cấu hình môi trường AI**: Cần cung cấp cấu hình `dart_define.json` (sao chép từ `dart_define.json.example`) chứa thông tin API của NVIDIA và Groq.
4. **Chạy ứng dụng (Debug)**:
   ```bash
   flutter run --dart-define-from-file=dart_define.json
   ```
5. **Build APK Release**:
   ```bash
   flutter build apk --release --dart-define-from-file=dart_define.json
   ```
   *(Lưu ý: Quá trình build APK sẽ mất khá nhiều thời gian do phải đóng gói kèm ~897 MB dữ liệu video local).*

---

## 8. Trạng thái Build & Test (Thời điểm hiện tại)

- **Trạng thái Code (Analyze)**: `flutter analyze` vượt qua không có lỗi nghiêm trọng (phụ thuộc vào môi trường lints).
- **Trạng thái Đóng gói**: Bản build APK release gần nhất (`app-release.apk`) có dung lượng **~976 MB**. Hiện đang sử dụng debug keystore mặc định, chưa ký bằng production keystore thật.

---

## 9. Giới hạn đã biết / Việc còn tồn đọng

- **Dung lượng ứng dụng quá lớn**: Việc đóng gói 532 video offline trực tiếp vào assets đẩy kích thước APK lên tới ~976 MB. Trong tương lai, cần giải pháp tải video on-demand (streaming từ server hoặc tải khi dùng).
- **Nguy cơ mất dữ liệu**: Ứng dụng chạy local 100%. Nếu người dùng xoá ứng dụng hoặc hỏng thiết bị, dữ liệu hồ sơ và đánh giá sẽ bị mất hoàn toàn do chưa có cơ chế đồng bộ đám mây (Cloud Sync / Backup).
- **Tính năng chia sẻ video cho chuyên gia**: Hiện tại chỉ hoạt động ở mức độ "mô phỏng" trên giao diện (lưu cờ trạng thái trong DB), do chưa có hệ thống backend thực thụ để upload video lên và chuyên gia phản hồi.
- **Tên thư mục `nine_domains`**: Một số module trong code vẫn giữ tên `nine_domains` do lịch sử phát triển ban đầu, dù thực tế dự án đã rút gọn xuống và áp dụng chuẩn **7 lĩnh vực** (`domains.dart`).

---

## 10. Lịch sử thay đổi quan trọng

- **Chuyển đổi từ 9 xuống 7 lĩnh vực**: Gộp "Ứng xử" vào "Quan hệ xã hội", loại bỏ "Hành vi" (Database Migration v6).
- **Sàng lọc 50 câu**: Thêm bài test 50 câu đánh giá đủ 7 lĩnh vực (Database Migration v8).
- **Dữ liệu 3 dải tuổi "So sánh"**: Rút gọn phần chuyên gia, chỉ giữ lại Mô tả và So sánh. Xoá sạch dữ liệu rác cũ và tự động seed lại (Migration v9 & v10).
- **AI Guardrail**: Thiết lập ngưỡng `relevanceThreshold = 0.72` và thêm từ khóa phòng hộ khắt khe để chặn câu hỏi ngoài lề y khoa.
- **Đại tu giao diện**: Chuyển tông màu sang Trắng - Xanh biển, áp dụng `iris_theme.dart` chuẩn hoá. Đã gỡ bỏ toàn bộ linh vật (mascot) không phù hợp.
- **Tích hợp Thông báo (Notification)**: Thêm dịch vụ hiển thị thông báo kết nối hệ thống (Migration v11).