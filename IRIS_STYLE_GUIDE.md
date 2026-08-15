# IRIS — Style Guide (phân tích từ 4 ảnh mockup gốc "BỘ UI LUỒNG CHÍNH THỨC")

> Tài liệu này CHỈ mô tả **phong cách thị giác** (màu sắc, typography, hiệu ứng, icon, mascot) rút ra từ 4 ảnh mockup gốc — dùng để **làm đẹp giao diện hiện có**, KHÔNG dùng để tái tạo lại đúng layout/nội dung trong ảnh.
>
> ⚠️ **Lưu ý bắt buộc**: 4 ảnh mockup được vẽ ở giai đoạn thiết kế ban đầu, một số nội dung trong ảnh ĐÃ KHÔNG CÒN ĐÚNG với app hiện tại (đã thay đổi qua nhiều đợt sau đó) — ví dụ: ảnh vẽ 9 lĩnh vực (app hiện chỉ còn 7), ảnh có mục "Chân dung biểu hiện" trong từng lĩnh vực (đã bỏ), ảnh có màn "chọn tình huống" trong Quay video (đã bỏ), ảnh vẽ luồng 5 phần tuần tự trong 1 lĩnh vực (app hiện là hub tự do 4 phần). **Chỉ lấy phong cách thị giác từ ảnh, giữ nguyên bố cục/nội dung/số lượng thật của app hiện tại, không thêm lại các phần đã bị gỡ bỏ.**

---

## 1. Cảm giác thiết kế tổng thể (mood)

Thân thiện, ấm áp, đáng tin cậy — giảm cảm giác "y tế/lâm sàng" dù chủ đề nhạy cảm (phát triển trẻ, tự kỷ). Đạt được bằng: bo góc lớn ở mọi thành phần, màu pastel nhẹ nhàng, mascot gấu bông dễ thương xuất hiện xuyên suốt, nhiều khoảng trắng (white space), không dùng viền cứng/góc vuông sắc.

Tông màu chủ đạo là **xanh dương** (trust, chuyên nghiệp), phối cùng hệ màu pastel theo từng lĩnh vực và theo trạng thái (xanh lá = hoàn thành, cam = đang làm, xám = chưa bắt đầu).

## 2. Bảng màu (ước lượng — nên dùng công cụ color-picker đối chiếu lại ảnh gốc trước khi khoá cứng vào code/design token)

| Vai trò | Màu ước lượng (hex) | Dùng ở đâu |
|---|---|---|
| Primary (xanh dương chính) | `#2F5FE0` – `#3D6BF0` | Nút CTA chính, badge số bước, tiêu đề lớn, icon nổi bật |
| Primary đậm (navy) | `#1B3A8C` – `#20306B` | Tiêu đề poster, chữ nhấn mạnh |
| Primary nhạt (nền) | `#EAF1FF` – `#E9EEFC` | Nền banner thông tin, nền card nhẹ, nền tab active |
| Thành công / hoàn thành | `#2FB36B` – `#34C77D` | Checkmark, badge "Đã hoàn thành", progress fill |
| Đang thực hiện / cảnh báo nhẹ | `#F5A623` – `#FFA940` | Badge "Đang đánh giá", icon đồng hồ chờ |
| Trung tính / chưa bắt đầu | `#B0B7C3` – `#C7CCD6` | Badge "Chưa bắt đầu", icon mờ |
| Accent hồng/đỏ san hô | `#F45B69` – `#FF7A85` | Domain "Cảm xúc", cảnh báo cần chú ý |
| Accent tím | `#8B7CF6` – `#9B8AFB` | Domain "Quan hệ xã hội" |
| Accent xanh ngọc | `#20C4B0` – `#2FD1BE` | Domain "Ngôn ngữ" |
| Accent cam đất (sinh học) | `#F2994A` | Domain "Sinh học" |
| Nền trắng / card | `#FFFFFF` | Nền card chính |
| Chữ chính | `#1F2430` – `#2B2F3A` | Body text |
| Chữ phụ / mô tả nhỏ | `#8A8F98` – `#9AA0AC` | Placeholder, caption, timestamp |

Mỗi lĩnh vực trong 7 lĩnh vực nên có **1 màu accent riêng + icon riêng**, dùng nhất quán ở mọi nơi hiển thị lĩnh vực đó (lưới chọn lĩnh vực, tiến trình hồ sơ, dashboard, nhãn overview).

## 3. Typography

- Heading/tiêu đề: font sans-serif bo tròn, thân thiện (kiểu dáng gần với **Nunito**, **Baloo 2**, hoặc **Quicksand**) — đậm (bold/extrabold), có hỗ trợ dấu tiếng Việt đầy đủ (kiểm tra kỹ trên Google Fonts trước khi chọn).
- Body/nội dung: sans-serif chuẩn dễ đọc (kiểu **Inter**, **Be Vietnam Pro**, hoặc **Roboto**) — trọng lượng regular/medium.
- Phân cấp gợi ý: Tiêu đề lớn 22–28px bold, tiêu đề phần 16–18px semibold, body 14px regular, caption/phụ 12px regular màu chữ phụ.
- Số liệu lớn (VD điểm sàng lọc, số liệu dashboard): dùng font đậm, cỡ lớn nổi bật, có thể đặt trong vòng tròn/khung màu.

## 4. Bo góc & khoảng cách (radius & spacing)

- Card/hộp nội dung: bo góc lớn, ước lượng **16–24px**.
- Nút bấm chính (CTA): dạng pill/full-round, bo góc **≥ 24px** hoặc bo tròn hoàn toàn 2 đầu.
- Input field: bo góc vừa, **10–14px**.
- Badge/chip trạng thái: pill hoàn toàn tròn 2 đầu.
- Icon nền tròn/vuông bo (icon "chip" màu pastel chứa icon ở giữa): bo góc lớn hoặc hình tròn hoàn toàn.
- Khoảng cách (padding/margin): rộng rãi, nhất quán theo lưới 8px (8/12/16/24/32...), tránh dồn ép nội dung.

## 5. Hiệu ứng (shadow, depth)

- Card nổi nhẹ trên nền: đổ bóng mềm, lan toả rộng, độ đậm thấp (soft shadow, không dùng bóng cứng/gắt) — ví dụ `box-shadow: 0 4px 16px rgba(20, 30, 70, 0.06)`.
- Không dùng gradient mạnh ở nền chính (nền tổng thể trắng/rất nhạt); gradient nhẹ có thể dùng cho mascot (áo gấu) hoặc nút CTA nổi bật nhất.
- Trạng thái nhấn/hover (nếu áp dụng desktop/web): nâng nhẹ card + tăng bóng.
- Progress ring/circular gauge: nét dày vừa phải, bo đầu tròn (round line cap), màu theo trạng thái (xanh dương/xanh lá).
- Đường nối giữa các bước trong sơ đồ luồng (VD Bước 6 — 5 bước cũ, Bước 15 tổng thể): mũi tên/đường nối màu xanh dương nhạt, nét mảnh, có thể là nét đứt cho các đường "liên kết dữ liệu" (VD sơ đồ hồ sơ trẻ ở giữa toả ra các node).

## 6. Icon style

- Phong cách: **flat, bo tròn, duotone/filled nhẹ** — không dùng icon outline mảnh khô khan, không dùng icon 3D/skeuomorphic.
- Mỗi icon chức năng thường được đặt trong 1 "chip" nền màu pastel tròn hoặc bo góc lớn (kiểu Material "icon container"), màu nền chip nhạt hơn nhiều so với màu icon chính.
- Bộ icon cần nhất quán về độ dày nét và tỉ lệ trong toàn app — khuyến nghị Codex dùng **1 bộ icon nguồn duy nhất** (tự sinh bằng trình tạo ảnh theo đúng 1 style prompt cố định, xem mục 8) thay vì trộn nhiều nguồn icon khác nhau.
- Icon theo ngữ nghĩa: dấu tích tròn xanh lá = hoàn thành; đồng hồ/cam = đang chờ hoặc đang thực hiện; khiên/shield = an toàn dữ liệu hoặc nguyên tắc bảo vệ; đám mây = lưu trữ/đồng bộ; bóng nói (speech bubble) = hỏi đáp/AI/chia sẻ; kính lúp = so sánh/tìm kiếm; ống nghe = thông tin y khoa.

## 7. Mascot (linh vật gấu IRIS)

- Nhân vật gấu bông màu be/nâu nhạt, mặc áo thun xanh dương có chữ "IRIS", xuất hiện xuyên suốt các màn hình như 1 "hướng dẫn viên" thân thiện.
- Các tư thế đã thấy: vẫy tay chào, cầm khiên (an toàn), giơ ngón cái, cầm bảng kẹp hồ sơ, chỉ tay.
- Vai trò: xuất hiện ở màn chào mừng, màn xác nhận thành công, góc dưới các banner nguyên tắc — tạo cảm giác đồng hành, không dùng ở màn nhập liệu nghiêm túc (form) để tránh gây xao nhãng.
- Khi sinh ảnh mascot mới bằng AI, cần giữ **nhất quán tuyệt đối** về: màu lông, kiểu áo/logo, tỉ lệ đầu-thân, phong cách vẽ (flat/vector, không phải ảnh thật hay 3D render) qua mọi tư thế — nên tạo 1 "reference sheet" gồm nhiều tư thế trong cùng 1 lần sinh ảnh hoặc dùng chung 1 prompt gốc + biến thể nhỏ.

## 8. Component pattern tham khảo

| Component | Đặc điểm |
|---|---|
| Nút CTA chính | Pill bo tròn hoàn toàn, nền xanh dương primary, chữ trắng đậm, full-width hoặc gần full-width |
| Nút phụ/outline | Viền mỏng màu primary hoặc xám nhạt, nền trắng/trong suốt, chữ màu primary |
| Badge trạng thái | Pill nhỏ, nền màu nhạt tương ứng trạng thái + chữ đậm cùng tông đậm hơn (VD nền xanh lá nhạt, chữ xanh lá đậm) |
| Card thông tin/banner nguyên tắc | Nền pastel nhạt (thường xanh dương nhạt), icon tròn bên trái, tiêu đề đậm + mô tả phụ nhỏ |
| Card domain (lĩnh vực) | Icon trong chip màu accent riêng của lĩnh vực, tên lĩnh vực, có thể kèm % hoặc trạng thái nhỏ |
| Ô nhập liệu | Bo góc vừa, viền mỏng xám nhạt, label phía trên (không phải placeholder-only), icon phụ trợ bên phải nếu cần (calendar, mic...) |
| Timeline lịch sử | Chấm tròn màu trên đường thẳng đứng mảnh, card nội dung bên cạnh mỗi chấm, ngày/giờ ở đầu card |
| Chat bubble AI | Bubble AI: nền trắng/xám rất nhạt, bo góc, có avatar robot nhỏ bên trái; bubble người dùng: nền xanh dương, chữ trắng, căn phải |
| Progress tròn (circular gauge) | Vòng tròn nét dày, số lớn ở giữa, màu theo mức kết quả |
| Bottom nav | Nền trắng, icon + label, tab đang chọn tô màu primary, các tab còn lại màu xám trung tính |

## 9. Nguyên tắc áp dụng khi làm đẹp (không đổi bố cục)

- Giữ nguyên toàn bộ cấu trúc/nội dung/số lượng phần tử đang có trong app thật (7 lĩnh vực, hub 4 phần tự do, không có "chọn tình huống" video, không có "chân dung biểu hiện" cấp lĩnh vực...).
- Chỉ áp dụng: màu sắc, bo góc, shadow, spacing, typography, icon, mascot theo mô tả ở trên.
- Với 7 lĩnh vực thật hiện tại, gán lại đúng 7 màu accent nhất quán (có thể tái sử dụng 7 trong số các màu domain đã thấy ở ảnh, bỏ bớt màu của "Hành vi"/"Ứng xử" cũ nếu dư).
- Banner nguyên tắc ("Sàng lọc không phải là chẩn đoán", "AI không tự chẩn đoán"...) PHẢI giữ nguyên nội dung chữ, chỉ đổi hình thức trình bày cho đẹp hơn — đây là nội dung an toàn bắt buộc, không được rút gọn hay bỏ.

---

## 10. Prompt gợi ý dùng trình tạo ảnh cho icon/mascot (để Codex tham khảo, điều chỉnh lại cho khớp công cụ đang dùng)

**Prompt gốc cho mascot (dùng lại cho mọi tư thế, chỉ đổi mô tả hành động):**
```
A cute, friendly cartoon teddy bear mascot, flat vector illustration style,
soft rounded shapes, warm beige/tan fur, wearing a simple blue t-shirt with
"IRIS" logo text on chest, big round friendly eyes, no outline lines, soft
pastel color palette, centered on transparent background, children's
educational app mascot style, [MÔ TẢ HÀNH ĐỘNG: waving hello / giving thumbs
up / holding a clipboard / holding a shield]
```

**Prompt gốc cho icon chức năng (dùng lại cho mọi icon, chỉ đổi tên biểu tượng):**
```
Flat vector icon, rounded friendly style, duotone color (1 main color +
1 lighter shade of same color), centered inside a soft rounded square
container background in a matching pastel tone, minimal detail, no outline
stroke, consistent icon grid size, app icon style for a warm and trustworthy
children's health app, icon of: [TÊN BIỂU TƯỢNG, VD: "calendar", "shield
with checkmark", "speech bubble with heart"]
```

Codex nên sinh **toàn bộ icon trong cùng 1 phiên** (hoặc lưu prompt gốc cố định) để đảm bảo nhất quán về nét vẽ, không sinh rời rạc từng icon bằng prompt khác nhau.
