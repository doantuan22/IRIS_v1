# Roadmap dự án IRIS — Ứng dụng sàng lọc & đánh giá phát triển trẻ

> Tài liệu tổng hợp toàn bộ quyết định thiết kế đã chốt: chức năng, công nghệ, kiến trúc AI, schema dữ liệu và cấu trúc repo. Dùng làm tài liệu tham chiếu khi phát triển và khi trình bày trước ban giám khảo.

**Bối cảnh dự án**: dự án đi thi, ưu tiên chạy đúng chức năng, thời gian phát triển có hạn. Toàn bộ dữ liệu lưu **local trên thiết bị**, không dùng backend riêng; AI gọi thẳng API cloud (NVIDIA + Groq) từ app.

> **Cập nhật gần nhất**: theo bản mô tả chức năng chỉnh sửa — làm rõ bản chất dữ liệu trong Bước 6 (chỉ mục "Mô tả biểu hiện" là dữ liệu riêng của trẻ; các mục So sánh/Chia sẻ từ phụ huynh/Thông tin từ bác sĩ/Chân dung biểu hiện là nội dung tham khảo dùng chung). Đã cập nhật kiến trúc AI và schema SQL tương ứng ở mục 3 và 4.

---

## 1. Chức năng

Theo đúng luồng đã thiết kế trong tài liệu *"Luồng chi tiết ứng dụng sàng lọc và đánh giá trẻ"*:

| # | Chức năng | Ghi chú triển khai |
|---|---|---|
| 1 | Tạo/chọn hồ sơ trẻ | Tên, ngày sinh/tuổi, giới tính — lưu local |
| 2 | Lựa chọn thực hiện bài sàng lọc | 2 lựa chọn sau khi tạo hồ sơ: **Có** → đề xuất công cụ theo độ tuổi, thực hiện trực tiếp trên app, lưu kết quả (là *kết quả sàng lọc*, không phải kết luận chẩn đoán) / **Chưa muốn** → không ép buộc, vẫn dùng app bình thường, có thể quay lại làm sau |
| 3 | Xác định hướng đánh giá theo độ tuổi | Logic thuần Dart, không cần AI |
| 4 | Đánh giá 9 lĩnh vực | Hành vi, Nhận thức, Cảm xúc, Giác quan, Quan hệ xã hội, Ngôn ngữ, Ứng xử, Sinh học, Sinh hoạt cá nhân |
| 5 | Mỗi lĩnh vực: 5 phần (theo đúng thứ tự UI — xem "Luồng tổng quan Mục 6") | 1. Mô tả biểu hiện *(dữ liệu riêng của trẻ)* → 2. So sánh với trẻ cùng tuổi + video mẫu → 3. Chia sẻ từ phụ huynh (cộng đồng) → 4. Thông tin từ bác sĩ → 5. Chân dung biểu hiện |
| 6 | Lưu tiến độ & tiếp tục sau | Không bắt buộc hoàn thành 9 lĩnh vực 1 lần |
| 7 | Lịch sử | Toàn bộ mốc thời gian: sàng lọc, đánh giá, video |
| 8 | Hỏi đáp AI | RAG trên dữ liệu hồ sơ trẻ + dữ liệu tham khảo chuyên môn |
| 9 | Quay video tình huống | Quay & lưu local, gửi chuyên gia theo yêu cầu |
| 10 | Kết nối chuyên gia/trung tâm | Đề xuất hướng hỗ trợ dựa trên dữ liệu tổng hợp |
| 11 | Quản lý nhiều trẻ (Phụ lục 1) | Dành cho phụ huynh nhiều con / giáo viên / trung tâm |

> **Nguyên tắc quan trọng ở Bước 3 (Lựa chọn thực hiện sàng lọc)**: nếu người dùng chọn "Chưa muốn", ứng dụng **không được xem đây là một kết quả đánh giá hay kết luận** về tình trạng phát triển của trẻ — chỉ đơn giản là chưa có dữ liệu, hoàn toàn trung lập. Đây là điều kiện đầu vào trực tiếp cho **Trạng thái 1** trong guardrail AI (mục 3 bên dưới): chưa sàng lọc = chưa có dữ liệu, không phải "kết quả âm tính" hay bất kỳ hàm ý nào khác.

> **Quan trọng — bản chất dữ liệu trong 5 phần trên (theo bản chỉnh sửa)**: chỉ **mục 1 (Mô tả biểu hiện)** là dữ liệu do người dùng nhập riêng cho từng trẻ. Các **mục 2-3-4-5 đều là nội dung tham khảo do nhóm phát triển biên soạn/thu thập sẵn**, đóng gói tĩnh trong app — mục 3 ("Chia sẻ từ phụ huynh") và mục 4 ("Thông tin từ bác sĩ") **chỉ là tên gọi/góc nhìn trình bày nội dung**, không phải tính năng cho phép phụ huynh hay bác sĩ thật đăng bài, chia sẻ hay tương tác trực tiếp trong app. Về mặt kỹ thuật, cả 4 mục (2-3-4-5) xử lý **giống hệt nhau**: nội dung được biên soạn trước, ingest 1 lần vào `expert_knowledge_chunks`, không có cơ chế thu thập nội dung sống. Điều này ảnh hưởng đến việc phân bảng dữ liệu — xem mục 3 và 4 bên dưới.
>
> **Luồng UI trong mỗi lĩnh vực (Luồng tổng quan Mục 6)**: Nhập mô tả theo quan sát → Nhìn nhanh sự khác biệt → Xem trải nghiệm thực tế (chia sẻ phụ huynh) → Xem giải thích chuyên môn từ bác sĩ → Xem chân dung biểu hiện. Giao diện nên tuân theo đúng thứ tự tuần tự này.

**Lưu ý phạm vi cho bản demo thi**: chức năng #10 (gửi video cho chuyên gia thật) và #11 (nhiều người dùng cùng xem 1 hồ sơ) về bản chất cần một kênh chia sẻ dữ liệu ra khỏi máy — vì kiến trúc chọn là local-first, 2 chức năng này nên làm ở mức **mô phỏng trong phạm vi 1 thiết bị** cho bản demo (không cần đồng bộ nhiều máy thật), trừ khi có thời gian làm thêm lớp chia sẻ tối thiểu.

---

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ | Package Flutter |
|---|---|---|
| Framework | Flutter | — |
| Database local | SQLite | `sqflite` hoặc `drift` |
| Lưu video quay | File hệ thống local | `path_provider`, `camera` |
| Phát video (mẫu + đã quay) | — | `video_player` |
| Video mẫu tham khảo | Flutter assets (đóng gói theo app) | khai báo trong `pubspec.yaml` |
| Gọi API AI | HTTP thuần | `http` hoặc `dio` |
| Embedding | NVIDIA NIM API | gọi trực tiếp qua `http` |
| Sinh câu trả lời | Groq API | gọi trực tiếp qua `http` |
| Vector search | Cosine similarity thuần Dart | không cần thư viện riêng (quy mô nhỏ) |

**Vì sao không dùng backend riêng / không dùng LLM local**: đã thống nhất — dự án thi không cần tối ưu bảo mật key, ưu tiên tốc độ phát triển và chất lượng câu trả lời tiếng Việt cao hơn so với model chạy trên máy.

---

## 3. Kiến trúc AI

```
App (Flutter)
  │  1. Người dùng đặt câu hỏi cho hồ sơ trẻ X
  ▼
Gọi NVIDIA API — embed câu hỏi thành vector
  ▼
Vector search LOCAL (Dart, cosine similarity) trên 2 bảng SQLite:
  ├── profile_chunks           (lọc theo child_id)      → CHỈ mục "1. Mô tả biểu hiện" do người dùng
  │                                                         nhập riêng cho trẻ này (+ nhận xét case-specific
  │                                                         từ chuyên gia nếu có, VD sau khi xem video)
  └── expert_knowledge_chunks  (lọc theo tuổi/lĩnh vực,
                                 và content_type)          → nội dung tham khảo do nhóm biên soạn sẵn, gồm 4 loại:
                                                              so_sanh · chia_se_phu_huynh · bac_si · chan_dung
                                                              (2 loại sau chỉ khác tên gọi/văn phong trình bày,
                                                              không phải nội dung sống từ phụ huynh/bác sĩ thật)
  ▼
Guardrail (hàm Dart) — xác định Trạng thái 1 / 2 / 3
  dựa trên: có chunk profile liên quan? có kết quả sàng lọc? có chunk expert liên quan?
  ▼
Build system prompt theo đúng trạng thái
  ▼
Gọi Groq API (model openai/gpt-oss-20b hoặc gpt-oss-120b) — sinh câu trả lời (streaming)
  ▼
Hiển thị câu trả lời, lưu vào ai_conversations (local)
```

### 3 trạng thái (theo đúng Bước 12 trong luồng gốc)

| Trạng thái | Điều kiện | Yêu cầu nội dung trả lời |
|---|---|---|
| 1 — Chưa đủ thông tin | Không có chunk profile liên quan + chưa có sàng lọc | "Chưa đủ dữ liệu để đưa ra nhận định", gợi ý sàng lọc |
| 2 — Có sàng lọc | Có kết quả sàng lọc nhưng không có mô tả liên quan trực tiếp câu hỏi | Giải thích khái quát, không kết luận, trả lời trung lập |
| 3 — Có đánh giá chuyên môn | Có mô tả/nhận xét liên quan trực tiếp từ phụ huynh/giáo viên/chuyên gia | Trả lời theo đúng bối cảnh, có thể đối chiếu dữ liệu tham khảo chuyên môn |

Nguyên tắc bắt buộc: **trạng thái được xác định bằng code**, dựa trên kết quả retrieval — không giao cho LLM tự quyết định. AI không bao giờ tự chẩn đoán, chỉ mô tả/giải thích trong phạm vi dữ liệu đã truy xuất.

### Cấu hình API tham khảo

```
NVIDIA embedding: nvidia/nv-embedqa-e5-v5
  endpoint: https://integrate.api.nvidia.com/v1/embeddings

Groq generation: openai/gpt-oss-20b (ưu tiên tốc độ) hoặc openai/gpt-oss-120b (ưu tiên chất lượng)
  endpoint: https://api.groq.com/openai/v1/chat/completions
```

---

## 4. SQL — Schema database local (SQLite)

```sql
-- Hồ sơ trẻ
CREATE TABLE children (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  dob TEXT,                      -- ngày sinh, dạng ISO8601
  age_years INTEGER,             -- ĐƠN VỊ: NĂM — chỉ dùng khi không có ngày sinh chính xác
  gender TEXT,
  status TEXT DEFAULT 'active',  -- active / archived
  created_at TEXT NOT NULL
);

-- Kết quả sàng lọc — chỉ có bản ghi khi người dùng THỰC SỰ chọn "Có" ở Bước 3 và hoàn thành.
-- Nếu người dùng chọn "Chưa muốn", KHÔNG tạo bản ghi nào ở đây — việc không có dòng nào
-- cho child_id tương ứng chính là tín hiệu "chưa sàng lọc" (không cần cột trạng thái riêng).
CREATE TABLE screenings (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  tool_name TEXT,                 -- công cụ được đề xuất theo độ tuổi và người dùng đã thực hiện
  score TEXT,
  result_summary TEXT,            -- giải thích ý nghĩa kết quả ở mức tham khảo, không phải chẩn đoán
  performed_at TEXT,
  created_at TEXT NOT NULL
);

-- Dữ liệu đánh giá 9 lĩnh vực — CHỈ dữ liệu riêng của trẻ (mục 1: Mô tả biểu hiện,
-- và về sau có thể mở rộng cho nhận xét case-specific từ chuyên gia, VD sau khi xem video)
-- KHÔNG chứa nội dung tham khảo chung (so sánh/chia sẻ phụ huynh cộng đồng/bác sĩ/chân dung)
-- — các nội dung đó nằm ở bảng expert_knowledge_chunks bên dưới.
CREATE TABLE assessments (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  linh_vuc TEXT NOT NULL,         -- 1 trong 9 lĩnh vực
  content_type TEXT NOT NULL,     -- 'mo_ta' (mặc định) / 'ghi_chu_chuyen_gia' (case-specific, VD từ video)
  content TEXT NOT NULL,
  nguon TEXT,                     -- 'phu_huynh' / 'giao_vien' / 'chuyen_gia'
  performed_by TEXT,
  created_at TEXT NOT NULL
);

-- Lịch sử tổng hợp (mốc thời gian toàn bộ quá trình)
CREATE TABLE history_logs (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  event_type TEXT NOT NULL,       -- 'sang_loc' / 'danh_gia' / 'video' / 'ho_so'
  description TEXT,
  event_date TEXT NOT NULL
);

-- Chunk dữ liệu hồ sơ trẻ dùng cho RAG (embedding tính qua NVIDIA, lưu local)
CREATE TABLE profile_chunks (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  content TEXT NOT NULL,
  linh_vuc TEXT,
  nguon TEXT,
  embedding BLOB NOT NULL,        -- vector dạng Float32List đã serialize
  created_at TEXT NOT NULL
);

-- Chunk dữ liệu tham khảo, dùng chung cho mọi trẻ (tĩnh, do nhóm phát triển biên soạn/thu thập sẵn)
-- gồm 4 loại nội dung tương ứng mục 2-3-4-5 trong mỗi lĩnh vực (Bước 6)
-- Lưu ý: content_type 'chia_se_phu_huynh' và 'bac_si' chỉ khác nhau về VĂN PHONG trình bày
-- (góc nhìn đời thường vs. góc nhìn y khoa), không phải nội dung do phụ huynh/bác sĩ thật đăng trực tiếp
CREATE TABLE expert_knowledge_chunks (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  content_type TEXT NOT NULL,     -- 'so_sanh' / 'chia_se_phu_huynh' / 'bac_si' / 'chan_dung'
  linh_vuc TEXT,
  do_tuoi_thang_min INTEGER,      -- đơn vị: THÁNG tuổi (không phải năm) — khớp mốc các công cụ sàng lọc thực tế
  do_tuoi_thang_max INTEGER,      -- VD: 16-30 (tháng), không phải 1-3 (năm)
  nguon_tai_lieu TEXT,
  embedding BLOB NOT NULL
);

-- Video quay tình huống
CREATE TABLE videos (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  situation TEXT,
  file_path TEXT NOT NULL,        -- đường dẫn local trên máy
  status TEXT DEFAULT 'not_sent', -- 'not_sent' / 'pending' / 'reviewed'
  expert_note TEXT,
  recorded_at TEXT NOT NULL
);

-- Lịch sử hỏi đáp AI theo từng trẻ
CREATE TABLE ai_conversations (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  state INTEGER NOT NULL,         -- 1 / 2 / 3
  created_at TEXT NOT NULL
);

CREATE INDEX idx_profile_chunks_child ON profile_chunks(child_id);
CREATE INDEX idx_assessments_child ON assessments(child_id, linh_vuc);
CREATE INDEX idx_history_child ON history_logs(child_id, event_date);
```

> `embedding` lưu dạng BLOB (bytes của `Float32List`) — khi cần so sánh, đọc ra và chạy cosine similarity thuần Dart, không cần extension vector cho SQLite ở quy mô dữ liệu này.

> **Quan trọng — đơn vị tuổi không đồng nhất giữa 2 bảng, phải quy đổi khi query**: `children.age_years` tính theo **năm** (đúng UI Bước 2 cho người dùng nhập tự nhiên), nhưng `expert_knowledge_chunks.do_tuoi_thang_min/max` tính theo **tháng** (đúng mốc các công cụ sàng lọc thực tế). Bắt buộc phải có 1 hàm quy đổi dùng chung, VD `int childAgeInMonths(Child child)`: nếu có `dob` thì tính số tháng chính xác từ `dob` đến hiện tại; nếu chỉ có `age_years` thì lấy `age_years * 12`. Mọi nơi query `expert_knowledge_chunks` theo độ tuổi trẻ (đặc biệt tầng RAG ở mục 3) đều phải đi qua hàm này, không được so trực tiếp `age_years` với `do_tuoi_thang_min/max`.

---

## 5. Cây thư mục repo (Flutter)

```
iris_app/
├── android/
├── ios/
├── assets/
│   ├── videos/                        # video mẫu tham khảo — đóng gói theo app
│   │   ├── quan_he_xa_hoi/
│   │   ├── ngon_ngu/
│   │   └── ...
│   └── reference/
│       └── expert_content.json        # nguồn để chạy script ingest 1 lần
│                                       # mỗi entry gồm content_type: so_sanh/chia_se_phu_huynh/bac_si/chan_dung
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_config.dart        # endpoint + model NVIDIA/Groq
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── local/
│   │   │   ├── database.dart          # khởi tạo sqflite/drift
│   │   │   └── tables/
│   │   │       ├── children_table.dart
│   │   │       ├── screenings_table.dart
│   │   │       ├── assessments_table.dart
│   │   │       ├── history_logs_table.dart
│   │   │       ├── profile_chunks_table.dart
│   │   │       ├── expert_knowledge_chunks_table.dart
│   │   │       ├── videos_table.dart
│   │   │       └── ai_conversations_table.dart
│   │   ├── remote/
│   │   │   ├── nvidia_api_client.dart # gọi embedding
│   │   │   └── groq_api_client.dart   # gọi generation
│   │   └── repositories/
│   │       ├── child_repository.dart
│   │       ├── screening_repository.dart
│   │       ├── assessment_repository.dart
│   │       ├── video_repository.dart
│   │       └── ai_repository.dart     # gộp retrieval + guardrail + generate
│   ├── domain/
│   │   ├── models/
│   │   │   ├── child.dart
│   │   │   ├── screening.dart
│   │   │   ├── assessment.dart
│   │   │   └── ai_chunk.dart
│   │   └── services/
│   │       ├── embedding_service.dart
│   │       ├── vector_search_service.dart   # cosine similarity
│   │       └── guardrail_service.dart       # xác định trạng thái 1/2/3
│   ├── features/
│   │   ├── onboarding/
│   │   ├── child_profile/
│   │   │   ├── create_profile/
│   │   │   └── profile_detail/
│   │   ├── screening/
│   │   ├── assessment/
│   │   │   ├── nine_domains/
│   │   │   │   ├── description/
│   │   │   │   ├── comparison_video/
│   │   │   │   ├── parent_input/
│   │   │   │   ├── expert_input/
│   │   │   │   └── summary_portrait/
│   │   ├── history/
│   │   ├── ai_chat/
│   │   ├── video_recording/
│   │   └── multi_child_dashboard/     # Phụ lục 1
│   └── widgets/                        # component dùng chung
├── scripts/
│   └── ingest_expert_data.dart        # chạy 1 lần: embed expert_content.json → expert_knowledge_chunks
├── test/
├── pubspec.yaml
└── README.md
```

---

## 6. Thứ tự triển khai đề xuất

1. Local database + CRUD hồ sơ trẻ (Bước 1-4)
2. Giao diện 9 lĩnh vực + lưu đánh giá (Bước 5-7) — phần xương sống
3. Script ingest dữ liệu chuyên môn (`expert_content.json` → `expert_knowledge_chunks`)
4. Hỏi đáp AI: embedding → vector search local → guardrail → Groq (Bước 8, 11-12)
5. Quay video + lưu local (Bước 9)
6. Lịch sử tổng hợp (Bước 7 phần lịch sử)
7. Dashboard nhiều trẻ (Phụ lục 1) — làm sau cùng, có thể đơn giản hoá

---

*Tài liệu này tổng hợp từ các quyết định thiết kế đã thống nhất qua quá trình trao đổi — dùng làm điểm tham chiếu chung cho cả nhóm khi phát triển.*
