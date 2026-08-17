# Đối chiếu luồng thực tế với sơ đồ “HOW IRIS WORKS”

**Ngày audit:** 2026-08-16  
**Phạm vi:** Đọc mã nguồn và cấu trúc dữ liệu hiện có tại `D:\IRIS_v1`; không sửa mã, dữ liệu hay manifest; không chạy test/build.  
**Mục tiêu:** Xác định mỗi khối trong sơ đồ có thực sự tồn tại trong app hay chỉ là mô tả pitch.

## Kết luận ngắn

Sơ đồ phản ánh đúng ý tưởng tổng quát của IRIS: tạo hồ sơ, sàng lọc tùy chọn, thu thập bảy lĩnh vực, đối chiếu theo tuổi, rồi đưa ra một mức tổng quan và hướng người dùng tìm hỗ trợ. Tuy nhiên, **không nên trình bày sơ đồ như một mô tả 1:1 của sản phẩm hiện tại**.

Các khác biệt quan trọng nhất là:

- Không có ảnh đại diện/ảnh thật của trẻ trong model hồ sơ.
- Sàng lọc là ba **mức biểu hiện**, không phải ba mức “risk” mang nghĩa đánh giá nguy cơ lâm sàng; bỏ qua sàng lọc cũng không đi thẳng vào màn hình bảy lĩnh vực như mũi tên trong sơ đồ.
- “Sinh học” không chứa Gross Motor/Fine Motor/Behavior; `Hành vi` đã bị bỏ và `Ứng xử` gộp vào `Quan hệ xã hội`.
- AI có tham gia gắn nhãn từng lĩnh vực và viết mô tả tổng hợp, nhưng mức cuối được tính bằng quy tắc Dart, không có màn hình AI tuần tự “Analyze → Compare → Identify patterns”.
- “Chân dung toàn cảnh” không hiển thị các thanh mức phát triển theo từng lĩnh vực; thanh duy nhất là tiến độ đã nhập mô tả.
- Không có gauge rủi ro. “Kết nối chuyên gia/trung tâm” dựa chủ yếu trên mức đầy đủ dữ liệu và đang hiển thị danh sách đơn vị minh hoạ tĩnh.

## Bằng chứng và giới hạn audit

- Đã đọc luồng tạo hồ sơ, sàng lọc, AI chat, Chân dung toàn cảnh, Kết nối chuyên gia, các repository và schema SQLite liên quan.
- Workspace không có file SQLite dữ liệu chạy để truy vấn trực tiếp. Trong phiên audit trước đó, `adb devices -l` không có thiết bị kết nối. Vì vậy không có bằng chứng runtime/UI trên máy thật; mọi kết luận bên dưới là **static audit** từ mã nguồn hiện hành.
- Không chạy test, build hay cài APK theo yêu cầu. Các trạng thái “CÓ” bên dưới nghĩa là có đường mã và UI được khai báo, không đồng nghĩa đã xác nhận chạy thành công trên thiết bị.

## Ma trận đối chiếu sáu bước

| Bước trên sơ đồ | Kết luận | App thực tế đang làm gì | Bằng chứng mã nguồn |
| --- | --- | --- | --- |
| 1. Child Profile | **CÓ NHƯNG KHÁC** | Có tạo/chọn hồ sơ trẻ với tên, ngày sinh **hoặc** số tháng tuổi, giới tính, người đánh giá và vai trò. Có trạng thái hồ sơ active. Không có trường avatar/ảnh trẻ trong `Child`; hình bé trong sơ đồ chỉ phù hợp tính minh hoạ. | `lib/features/child_profile/create_profile/create_profile_page.dart:11-24,93-104`; `lib/domain/models/child.dart:2-25`; `lib/data/local/tables/children_table.dart:6` |
| 2. Initial Screening (optional) | **CÓ NHƯNG KHÁC** | Có màn giới thiệu nói sàng lọc là tùy chọn, rồi bài sàng lọc 50 câu và kết quả được lưu cùng 50 câu trả lời + điểm bảy lĩnh vực trong một transaction. Ba mức thật là “Mức 1 - Ít biểu hiện”, “Mức 2 - Có biểu hiện cần theo dõi”, “Mức 3 - Nhiều biểu hiện khó khăn”; không dùng No/Medium/High Risk. Khi bỏ qua, onboarding quay về Home; luồng ngoài onboarding mở trang tổng kết đánh giá, không điều hướng thẳng sang một màn “7 areas”. | `lib/features/screening/screening_intro_page.dart`; `lib/features/screening/screening_tool_confirm_page.dart`; `lib/domain/services/screening_scoring_service.dart:216-225,295-348`; `lib/data/repositories/screening_repository.dart:39-92` |
| 3. 7 Developmental Areas | **CÓ NHƯNG KHÁC** | Có đúng 7 code/lĩnh vực: Nhận thức, Cảm xúc, Giác quan, Quan hệ xã hội, Ngôn ngữ, Sinh học, Sinh hoạt cá nhân. Khớp phần lớn sơ đồ. Riêng `Quan hệ xã hội` là tương ứng gần nhất với Social Interaction; `Hành vi` không phải nhánh của Sinh học mà đã bị loại khỏi danh sách/gộp khái niệm ứng xử vào Quan hệ xã hội. Không có các nhánh Gross Motor/Fine Motor/Behavior bên trong Sinh học. | `lib/core/constants/domains.dart:14-23`; ghi chú migration tại `lib/data/local/database.dart:105-137` |
| 4. IRIS AI: Analyze → Compare → Identify patterns | **CÓ NHƯNG KHÁC** | Có hai phần gần nhất. (a) AI chat lấy embedding câu hỏi, truy hồi mô tả hồ sơ, lọc tri thức tham khảo theo tuổi rồi gửi context cho Groq. (b) Chân dung toàn cảnh lần lượt gắn nhãn từng lĩnh vực bằng mô tả của trẻ + so sánh các chunk “thường gặp/cần quan sát thêm” cùng độ tuổi; sau đó tổng hợp bảy nhãn. Không có một màn hình/engine duy nhất thể hiện ba bước tuần tự như sơ đồ. Việc “identify patterns” là tổng hợp nhãn và mô tả văn xuôi, không phải một thuật toán nhận dạng mẫu tự chủ xuyên lĩnh vực. | `lib/data/repositories/ai_repository.dart:60-113`; `lib/data/repositories/overview_repository.dart:82-86,129-239,244-285,371-398`; `lib/domain/services/prompt_builder.dart:63-80,105-114` |
| 5. Child Development Profile | **CÓ NHƯNG KHÁC** | Có `OverviewPortraitPage` hiển thị tên/mức tổng quan, đoạn “Chân dung biểu hiện” nếu AI tạo được, và danh sách bảy lĩnh vực với nhãn “Thường gặp/Cần theo dõi/Chưa đủ dữ liệu” cùng lý do. Không có các thanh tiến trình/mức phát triển riêng cho từng lĩnh vực như hình. `LinearProgressIndicator` hiện có chỉ là “Tiến độ mô tả: x/7 lĩnh vực”, tức mức hoàn tất nhập liệu. | `lib/features/assessment/overview/overview_portrait_page.dart:50-53,119-120,214-222,255-412` |
| 6. Risk Assessment & Next Steps | **CÓ NHƯNG KHÁC** | Có ba mức tổng quan: “Trong giới hạn thường gặp”, “Có điểm cần theo dõi”, “Nên tìm đánh giá chuyên môn sớm”. Chúng được tính bằng code từ số nhãn `can_theo_doi`: 0-2, 3-5, 6-7; ngưỡng được chính mã nguồn ghi là tạm, không phải thang lâm sàng đã kiểm định. Không có gauge/meter màu. Nút kết nối chuyên gia chỉ hiện từ Chân dung khi ở mức cao nhất. Trang Expert Connect tự phân loại dựa trên đã sàng lọc, số lĩnh vực có mô tả và video được xem; không dùng tier tổng quan và không đưa ra khuyến nghị cá thể hoá theo từng lĩnh vực. | `lib/domain/services/overview_tier_calculator.dart:1-23,80-104`; `lib/features/assessment/overview/overview_portrait_page.dart:255-412`; `lib/features/expert_connect/expert_connect_page.dart:135-177,181-232` |

## Phân tích kỹ bước 4 — AI có thật, nhưng không đúng cách sơ đồ diễn đạt

1. **Analyze observations:** Có. Người dùng nhập mô tả biểu hiện theo lĩnh vực; AI chat và `OverviewRepository` dùng phần mô tả này làm input. Đây không phải phân tích tự động ảnh/video.
2. **Compare with age-based development knowledge:** Có về thiết kế. `labelDomain` tạo embedding của mô tả, truy vấn `expert_knowledge_chunks` theo `linh_vuc`, `ageInMonths` và `content_type = 'so_sanh'`, sau đó tách nhóm “bình thường”/“rối loạn” làm context cho Groq.
3. **Identify patterns across multiple areas:** Có ở mức tổng hợp có kiểm soát, nhưng không đúng nghĩa engine AI tìm mẫu xuyên lĩnh vực. `labelAllDomains` gọi tuần tự cho từng lĩnh vực; `calculateOverviewTier` chỉ đếm nhãn “cần theo dõi” để quyết định mức. Groq có thể viết đoạn văn “Chân dung biểu hiện” từ bảy nhãn và assessment, nhưng không được phép quyết định tier cuối.
4. **Điều kiện dữ liệu:** Phần đối chiếu theo tuổi chỉ có ý nghĩa khi bảng `expert_knowledge_chunks` đã được nạp. Mã `onCreate` chỉ tạo bảng; thao tác nạp hiện diện trong `ChildDebugPage` và được bảo vệ bởi `kDebugMode`. Vì không có DB/thiết bị để truy vấn, audit này không thể xác nhận dữ liệu tham khảo thực sự có trong bản đang chạy. Đây là điểm chặn trực tiếp của lời hứa “Compare” trong runtime release, đã được nêu là BUG-01 trong báo cáo audit toàn diện trước đó.

## Phân tích kỹ bước 6 — không nên gọi là “Risk Assessment”

- **Mức tổng quan:** Có ba tầng và có hướng tìm đánh giá chuyên môn ở tầng cao nhất, nhưng tên sản phẩm đã tránh từ “risk”. Đây là cách diễn đạt an toàn hơn sơ đồ.
- **Cách tính:** Không phải score/gauge rủi ro và không phải AI quyết định. Có ít nhất 4/7 nhãn “chưa đủ dữ liệu” thì không tính tier; khi đủ hơn, code đếm số lĩnh vực “cần theo dõi”.
- **Insights & explanation:** Có ở mức lý do ngắn theo lĩnh vực và đoạn tổng hợp do AI tạo khi gọi API thành công. Nếu API lỗi, tier vẫn lưu nhưng không có đoạn AI.
- **Personalized recommendations:** Chỉ có giới hạn. Nút hướng sang Expert Connect theo tier cao; Expert Connect lại suy từ độ hoàn thành dữ liệu, và cùng một danh sách provider tĩnh được hiển thị. Đây không phải gợi ý địa điểm/chuyên gia được cá nhân hoá, cũng không được kết nối dữ liệu ngoài.
- **Professional assessment:** Có lời khuyên tìm đánh giá chuyên môn. Tuy nhiên, các thẻ provider có tên, rating và khoảng cách dễ tạo ấn tượng là dữ liệu thật, trong khi UI chỉ ghi chú ở cuối: “Đây là danh sách minh hoạ, chưa phải dữ liệu đơn vị/chuyên gia thật.”

## Đối chiếu lưu ý “không chẩn đoán”

| Vị trí | Kết luận | Nội dung thực tế |
| --- | --- | --- |
| Kết quả sàng lọc | **CÓ** | Hiển thị lưu ý không dùng tổng điểm/mức mô tả để kết luận hoặc chẩn đoán rối loạn phổ tự kỷ, cũng không thay thế đánh giá chuyên môn. |
| Chân dung toàn cảnh | **CÓ** | Hiển thị rằng đây là tổng hợp tham khảo từ mô tả và dữ liệu trong app, không phải kết luận chẩn đoán y khoa. Prompt AI cũng cấm kết luận chẩn đoán. |
| Kết nối chuyên gia | **CÓ NHƯNG KHÁC** | Có chú thích danh sách provider là minh hoạ, nhưng không có disclaimer “không chẩn đoán” riêng trên màn này. |

Nguồn: `lib/features/screening/screening_result_page.dart:14-16,262-295`; `lib/features/assessment/overview/overview_portrait_page.dart:17-19,420-438`; `lib/domain/services/prompt_builder.dart:4-7,50-56,105-114`; `lib/features/expert_connect/expert_connect_page.dart:228`.

## Khuyến nghị cho sơ đồ/pitch hiện tại (không thay đổi app trong audit này)

1. Đổi “Risk Assessment” thành **“Mức tổng quan & bước hỗ trợ tiếp theo”**; bỏ gauge hoặc ghi rõ đó chỉ là minh hoạ giao diện tương lai.
2. Đổi ba nhãn sàng lọc thành “Ít biểu hiện / Có biểu hiện cần theo dõi / Nhiều biểu hiện khó khăn”; không gắn chúng với No/Medium/High Risk.
3. Thay thanh phát triển bảy lĩnh vực bằng danh sách nhãn thực tế, hoặc ghi rõ thanh là “mức độ hoàn tất dữ liệu” nếu giữ hình thanh.
4. Sửa mục Sinh học: không hiển thị Gross Motor/Fine Motor/Behavior như cấu trúc dữ liệu hiện có. Nếu pitch cần mô tả hành vi, đặt chú thích rằng nội dung này nằm trong phạm vi Quan hệ xã hội/ứng xử theo cấu trúc hiện hành.
5. Diễn đạt AI chính xác hơn: **“IRIS sử dụng mô tả người chăm sóc và dữ liệu tham khảo theo độ tuổi để hỗ trợ đối chiếu từng lĩnh vực; mức tổng quan được tính theo quy tắc minh bạch.”**
6. Trước khi dùng cụm “recommended professional/provider”, thay dữ liệu minh hoạ bằng dữ liệu đã xác minh hoặc đưa cảnh báo ngay trên đầu danh sách.
7. Khắc phục hoặc xác nhận cơ chế seed dữ liệu tham khảo trong release trước khi đưa lời hứa “Compare with age-based knowledge” ra bên ngoài.

## Phán quyết cuối

**Sơ đồ dùng được như mô hình định hướng sản phẩm, nhưng chưa đạt độ chính xác cần thiết để mô tả app hiện tại như một luồng đã triển khai hoàn toàn.** Các khối đều có đối ứng một phần trong code, nên không có bước nào hoàn toàn bịa đặt; tuy vậy cả sáu bước đều thuộc nhóm **CÓ NHƯNG KHÁC**. Hai điểm cần sửa trước khi dùng sơ đồ cho demo/đối tác là: (1) thay cách gọi/hiển thị “risk” và gauge, (2) nói rõ giới hạn của AI, thanh tiến độ và danh sách chuyên gia minh hoạ.
