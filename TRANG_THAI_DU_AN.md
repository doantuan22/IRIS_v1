# Trạng thái dự án IRIS — audit mã nguồn

_Ngày audit: 11/08/2026. Phạm vi: đọc `lib/`, `test/`, `scripts/`, `ROADMAP_DU_AN_IRIS.md`, toàn bộ `SETUP_REPORT.md`; không sửa mã nguồn, không build hay chạy emulator._

## 1. Số liệu thực tế tại thời điểm audit

| Hạng mục | Kết quả phiên audit | Diễn giải |
|---|---|---|
| `flutter analyze` | **Chưa có kết quả hoàn tất** | Đã khởi chạy 2 lần tại gốc repo; mỗi lần bị môi trường dừng sau 60 giây và không có stdout/stderr. Vì vậy không thể ghi số error/warning hiện tại. |
| `flutter test` | **Chưa có kết quả hoàn tất** | Đã khởi chạy 1 lần; bị dừng sau 60 giây, không có stdout/stderr. Không khẳng định PASS/FAIL hoặc tổng test từ lần chạy này. |
| Test có trong mã | **42 ca** | Đọc 11 tệp trong `test/`: repository 5, child age 4, screening widget-flow 1, NVIDIA 3, Groq 3, vector search 6, guardrail 5, prompt 4, ingest 2, AI repository 4, video/history repository 5. Đây là số ca được khai báo, **không phải** kết quả chạy hiện tại. |
| Git đầu phiên audit | Sạch | `git status --short` không có thay đổi; `git diff --stat` rỗng. |
| Git history | 2 commit | `60185ca update` (HEAD, `main`, `origin/main`) và `61cb641 first commit`. |
| Git sau khi xuất báo cáo | Có tệp audit mới | Chỉ `TRANG_THAI_DU_AN.md` được tạo bởi audit này; không commit. |

`SETUP_REPORT.md` ghi kết quả cũ 42/42 PASS và analyze 0 warning ở giai đoạn 5–6. Các số đó là bằng chứng lịch sử, không thay thế được kết quả mới vì phiên audit này không hoàn tất được hai lệnh trên.

## 2. Đối chiếu 11 chức năng trong roadmap

Quy ước trạng thái: **Hoàn tất & có verify thật** chỉ dùng khi `SETUP_REPORT.md` có mô tả thao tác emulator/ADB/database cụ thể và mã hiện tại vẫn hiện diện. “Có code” không đồng nghĩa đã verify UI trong phiên này.

| # | Chức năng roadmap | Trạng thái | Bằng chứng mã/test/verify |
|---|---|---|---|
| 1 | Tạo/chọn hồ sơ trẻ | **Hoàn tất & có verify thật** | `ChildListPage`, `CreateProfilePage`, `ProfileDetailPage`; `ChildRepository`. Widget-flow: `test/screening_flow_test.dart`; verify ADB tạo hồ sơ được ghi ở SETUP giai đoạn 3. |
| 2 | Lựa chọn thực hiện bài sàng lọc | **Hoàn tất & có verify thật** | `ScreeningIntroPage` có hai nhánh Có/Chưa muốn; nhánh sau chỉ pop, không ghi DB. Widget-flow kiểm chứng cả hai nhánh; SETUP mô tả verify emulator. |
| 3 | Xác định hướng đánh giá theo độ tuổi | **Chưa bắt đầu** | Có `childAgeInMonths()` trong `domain/models/child.dart`, nhưng không có hàm/route chọn công cụ hay hướng đánh giá theo tuổi. `ScreeningQuestionnairePage` luôn dùng một bộ 6 câu mock. |
| 4 | Đánh giá 9 lĩnh vực | **Có code thật nhưng chưa verify UI đầy đủ** | `nine_domains.dart`, `DomainListPage`, route từ hồ sơ; từng lĩnh vực có trạng thái có/chưa mô tả. Mô tả một lĩnh vực đã được verify lịch sử, nhưng không có test/verify riêng cho đủ 9 lĩnh vực. |
| 5 | Mỗi lĩnh vực gồm 5 phần | **Chỉ có khung sườn** | Phần 1 (`DescriptionPage`) có lưu DB + embedding. Bốn trang còn lại `ComparisonVideoPage`, `ParentInputPage`, `ExpertInputPage`, `SummaryPortraitPage` chỉ hiển thị nội dung “đang cập nhật”, không query dữ liệu tham khảo. |
| 6 | Lưu tiến độ và tiếp tục sau | **Có code thật nhưng chưa đầy đủ** | Dữ liệu mô tả được lưu và `DomainListPage` suy ra trạng thái từ `assessments`; tuy nhiên không có mô hình tiến độ/điểm dừng của toàn bộ chuỗi 5 phần hoặc màn tiếp tục phiên làm việc. |
| 7 | Lịch sử | **Hoàn tất & có verify thật** | `HistoryLogRepository`, `HistoryPage`; các luồng sàng lọc, mô tả và video ghi log. `screening_flow_test.dart` xác nhận log sàng lọc; SETUP giai đoạn 6 mô tả đối chiếu UI và DB thật 3 log. |
| 8 | Hỏi đáp AI/RAG | **Hoàn tất & có verify thật (debug/emulator)** | `AiRepository`, NVIDIA/Groq clients, vector search, guardrail, prompt builder, `AiChatPage`; 4 test tích hợp mock trong `ai_repository_test.dart`, cùng các unit test liên quan. SETUP mục 8 ghi verify cả 3 trạng thái bằng key thật trên emulator. Không có kết quả chạy mới của phiên này. |
| 9 | Quay video tình huống | **Hoàn tất & có verify thật (Android debug/emulator)** | 4 trang trong `features/video_recording/`, `VideoRepository`; 5 test repository/history. SETUP giai đoạn 5 ghi build, quay, phát lại, đối chiếu DB và file video trên emulator. |
| 10 | Kết nối chuyên gia/trung tâm | **Có code thật nhưng chưa đầy đủ** | “Gửi” video chỉ lưu local với `status: pending`; phản hồi chuyên gia là nút **debug** sinh mẫu cố định trong `VideoDetailPage`. Không có kênh gửi/nhận, tài khoản, trung tâm, hay đề xuất dựa trên dữ liệu tổng hợp. |
| 11 | Quản lý nhiều trẻ (Phụ lục 1) | **Chỉ có khung sườn** | `MultiChildDashboardPage` chỉ là `Placeholder`; chưa được gắn route. Danh sách hồ sơ nhiều trẻ có tồn tại, nhưng không phải dashboard theo yêu cầu. |

## 3. Đối chiếu luồng chi tiết gốc 15 bước

### Giới hạn đối chiếu

Tài liệu “Luồng chi tiết ứng dụng sàng lọc và đánh giá trẻ” nguyên gốc (15 bước) **không nằm trong workspace hoặc tệp đính kèm**. `ROADMAP_DU_AN_IRIS.md` chỉ tham chiếu rải rác: bước 3 là lựa chọn sàng lọc, 6 là năm phần lĩnh vực, 7 là lịch sử theo mục 6, 8/11/12 là AI, 9 là video theo mục 6; trong khi `SETUP_REPORT.md` lại gọi lịch sử là bước 9 và video là bước 13. Không thể gán nhãn chính xác cho các bước chưa có nguồn gốc mà không suy đoán.

| Bước | Đối chiếu trung thực từ nguồn hiện có | Trạng thái | Bằng chứng / ghi chú |
|---|---|---|---|
| 1 | Hồ sơ trẻ (suy ra từ nhóm “Bước 1–4” trong roadmap) | Có code thật, có verify lịch sử | `ChildListPage`, `CreateProfilePage`, test widget-flow. Tên bước gốc chưa xác minh. |
| 2 | Không có nhãn gốc trong repo | **Chưa xác minh được** | Không suy đoán. Chỉ biết roadmap gộp bước 1–4 thành database/hồ sơ/sàng lọc. |
| 3 | Lựa chọn thực hiện sàng lọc | Hoàn tất & có verify thật | `ScreeningIntroPage`, nhánh Có/Chưa muốn; test widget-flow và SETUP. |
| 4 | Không có nhãn gốc trong repo | **Chưa xác minh được** | Có mã bảng câu hỏi/kết quả sàng lọc, nhưng không thể khẳng định đó chính là nhãn bước 4 gốc. |
| 5 | Đánh giá 9 lĩnh vực (SETUP giai đoạn 3 gọi phạm vi bước 5–6) | Có code thật, chưa verify đầy đủ | `DomainListPage` và 9 hằng số lĩnh vực. |
| 6 | Chuỗi 5 phần trong từng lĩnh vực | Chỉ một phần thật, bốn phần khung | `DescriptionPage` thực; 4 trang còn lại hiển thị placeholder bằng văn bản. |
| 7 | Lịch sử (roadmap mục 6 tham chiếu bước 7) | Hoàn tất & có verify thật | `HistoryPage`, `HistoryLogRepository`, SETUP giai đoạn 6. |
| 8 | AI (roadmap mục 6 tham chiếu bước 8) | Hoàn tất & có verify thật ở debug/emulator | `AiRepository`, `AiChatPage`, test mock, verify lịch sử. |
| 9 | Mâu thuẫn nguồn: roadmap gọi video là bước 9; SETUP gọi lịch sử là bước 9 | **Không thể xác minh nhãn gốc** | Cả video và lịch sử đều có code; cần tài liệu gốc để kết luận mapping chính xác. |
| 10 | Không có nhãn gốc trong repo | **Chưa xác minh được** | Không suy đoán. |
| 11 | Thành phần AI retrieval (roadmap tham chiếu AI ở bước 11–12) | Có code thật, được test mock | NVIDIA embedding → vector search trong `AiRepository`; mapping tên bước vẫn chưa xác minh. |
| 12 | Guardrail 3 trạng thái AI | Hoàn tất & có verify thật ở debug/emulator | `GuardrailService`, `PromptBuilder`, 5 guardrail tests, 4 integration tests AI, verify lịch sử 3 trạng thái. |
| 13 | Quay video (SETUP giai đoạn 5 ghi rõ bước 13) | Hoàn tất & có verify thật Android debug/emulator | `VideoRecordingCapturePage`, `VideoReviewPage`, `VideoDetailPage`; verify lịch sử. |
| 14 | Kết nối chuyên gia | Có mô phỏng local, chưa hoàn chỉnh | Video `pending` + phản hồi mẫu chỉ trong debug; không có kết nối thật. |
| 15 | Không có nhãn gốc trong repo | **Chưa xác minh được** | Phụ lục dashboard được roadmap tách riêng, không thể khẳng định là bước 15. |

Để hoàn tất bảng này với nhãn chuẩn, cần bổ sung chính tài liệu luồng 15 bước gốc. Khi đó có thể cập nhật mapping mà không cần sửa mã.

## 4. Sai lệch phát hiện được

1. **Số liệu verify cũ không còn là số liệu hiện hành.** `SETUP_REPORT.md` ghi 42/42 PASS và analyze sạch; lần chạy mới của audit không hoàn tất nên các con số này chưa được tái xác nhận.
2. **Roadmap yêu cầu hướng đánh giá/công cụ theo tuổi nhưng mã không có.** Hiện chỉ quy đổi tuổi sang tháng phục vụ lọc expert chunks; sàng lọc luôn là 6 câu mock, không chọn công cụ theo tuổi.
3. **Roadmap mô tả nội dung tĩnh cho phần 2–5 của 9 lĩnh vực, nhưng UI vẫn chưa dùng dữ liệu đó.** `assets/reference/expert_content.json` có 6 entry, trong đó 4 entry tự gắn `[Placeholder minh hoạ]`; bốn trang UI không query bảng expert knowledge. Không có video mẫu thực tế trong `assets/videos/`, chỉ `.gitkeep`.
4. **Streaming được vẽ trong sơ đồ kiến trúc roadmap, còn mã thực tế dùng request/response một lần.** `GroqApiClient.generate()` trả `Future<String>`; mã và comment đều nói chưa streaming.
5. **“Kết nối chuyên gia” không phải kết nối thật.** Tên nút “Gửi cho chuyên gia” chỉ tạo bản ghi local; phản hồi là mô phỏng debug. Đây phù hợp một phần với phạm vi demo local-first, nhưng chưa đạt chức năng #10 theo nghĩa kết nối/trung tâm.
6. **Báo cáo cũ nói tất cả thay đổi chưa commit, nhưng Git hiện tại đã sạch và có commit `60185ca update`.** Đây là sai lệch trạng thái lịch sử của báo cáo, không phải lỗi mã.
7. **Cấu hình release Android thiếu quyền Internet.** Client NVIDIA/Groq gọi HTTP, nhưng `android.permission.INTERNET` chỉ có trong manifest debug/profile, không có trong manifest main. AI/ingest sẽ không gọi mạng trong APK release.

## 5. Tồn đọng đã phân loại

### Chặn demo theo đúng phạm vi chức năng

- Bổ sung phần xác định hướng/công cụ sàng lọc theo tuổi; hiện chức năng #3 chưa có.
- Hoàn thiện dữ liệu tham khảo thật và nạp/hiển thị được ở phần 2–5 của 9 lĩnh vực; hiện đa số dữ liệu mẫu là placeholder và UI không đọc chúng.
- Nếu demo bằng APK release có AI: thêm `INTERNET` vào `android/app/src/main/AndroidManifest.xml`.
- Có kết quả `flutter analyze`/`flutter test` mới, hoàn tất được trong môi trường CI hoặc với timeout cao hơn, trước khi dùng con số kiểm chứng mới.

### Không chặn demo debug nhưng nên xử lý

- Nút mô phỏng phản hồi chuyên gia chưa có verify click-through UI thật; chỉ có unit test repository và đọc mã.
- Android release vẫn ký bằng debug key (`android/app/build.gradle.kts`); cần signing config trước phân phối.
- iOS thiếu `NSCameraUsageDescription` và `NSMicrophoneUsageDescription` trong `ios/Runner/Info.plist`; quay video sẽ chưa sẵn sàng để phát hành iOS.
- API key được đưa trực tiếp vào app qua `--dart-define`, dữ liệu trẻ nằm trong SQLite local không mã hoá, và HTTP client không đặt timeout. Roadmap chấp nhận đánh đổi này cho demo, nhưng không phù hợp phát hành rộng.
- Khi NVIDIA lỗi, mô tả vẫn lưu nhưng không có cơ chế retry/backfill embedding; AI không truy hồi được mô tả đó về sau.
- `VectorSearchService.cosineSimilarity()` không kiểm tra hai vector khác chiều dài; dữ liệu vector không đồng nhất/corrupt có thể gây lỗi runtime.
- Một số `FutureBuilder` chỉ xét `hasData`, không hiển thị trạng thái lỗi truy vấn rõ ràng.

### Có thể để sau demo lõi

- Streaming câu trả lời AI và cải thiện UI chat.
- Dashboard nhiều trẻ, onboarding (hiện `Placeholder`) và kết nối chuyên gia/trung tâm thật.
- Video mẫu thực tế theo 9 lĩnh vực.
- Xoá file video vật lý khi xoá metadata video; `VideoRepository.delete()` hiện chỉ xoá hàng SQLite.
- Hoàn chỉnh README (hiện là template Flutter) và đưa tài liệu luồng 15 bước gốc vào repo để truy vết yêu cầu.

## 6. Nhận định tổng quan

Phần xương sống local database, hồ sơ, sàng lọc demo, mô tả quan sát, RAG guardrail, quay video local và lịch sử đã có mã thật; nhiều phần đã có unit/widget test và bằng chứng verify emulator được ghi chi tiết trong báo cáo cũ. Theo thứ tự triển khai roadmap mục 6, dự án đã đi qua các giai đoạn 1–6 ở mức **MVP debug có thể demo các luồng lõi**.

Tuy nhiên đây chưa phải trạng thái “hoàn tất 11 chức năng”: thiếu logic theo tuổi, bốn phần tham khảo của 9 lĩnh vực vẫn là khung, dữ liệu chuyên môn chưa sẵn sàng, dashboard và kết nối chuyên gia chưa hoàn thành. Ngoài ra, do analyze/test không hoàn tất trong chính phiên audit này, chất lượng build/test hiện tại phải được xem là **chưa tái xác nhận**, không nên kế thừa vô điều kiện các con số PASS cũ.
