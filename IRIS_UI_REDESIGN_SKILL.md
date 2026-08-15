# IRIS UI REDESIGN SKILL — Codex Implementation Guide

## 0. Vai trò

Bạn là AI Coding chịu trách nhiệm **làm đẹp và chuẩn hóa giao diện IRIS dựa trên codebase hiện có**.

Mục tiêu là nâng cấp visual/UI thành một hệ thống thống nhất theo phong cách IRIS đã được xác định từ bộ ảnh tham chiếu, nhưng **không được tự ý thay đổi bố cục thô, luồng chức năng, dữ liệu, nghiệp vụ, API hoặc ý nghĩa của các màn hình hiện có**.

Bạn phải tự đọc codebase để xác định framework, router, entry point, component tree, asset pipeline, theme system, state management và các màn hình cần chỉnh sửa. Skill này chỉ mô tả **cách thiết kế và cách triển khai**, không chỉ định file nào hoặc thư mục nào.

---

# 1. MỤC TIÊU CỐT LÕI

Thực hiện theo thứ tự:

1. Khảo sát codebase hiện có.
2. Tạo một **Loading / Splash Screen IRIS** xuất hiện trước giao diện chính.
3. Xây dựng hoặc chuẩn hóa **design tokens** dùng chung.
4. Giữ nguyên layout thô của các màn hình hiện tại.
5. Làm đẹp từng màn hình bằng cùng một visual language.
6. Chuẩn hóa card, button, input, badge, progress, header, icon, illustration, trạng thái.
7. Dùng trình tạo ảnh tích hợp khi cần để tạo:
   - mascot/illustration;
   - icon chuyên biệt;
   - ảnh nền;
   - empty state;
   - decorative artwork;
   - hình minh họa phụ huynh/trẻ/chuyên gia.
8. Kiểm tra responsive, accessibility, loading state, empty state và consistency.
9. Chỉ refactor UI ở mức cần thiết; không phá logic hiện hữu.

---

# 2. NGUYÊN TẮC KHÔNG ĐƯỢC VI PHẠM

## 2.1. Không đổi bố cục thô

Giữ nguyên:
- thứ tự các khối;
- thứ tự luồng nghiệp vụ;
- vị trí tương đối của header/content/navigation;
- số lượng section chính;
- nội dung chính;
- luồng chuyển trang;
- hành vi button;
- form field;
- API call;
- validation;
- business logic;
- dữ liệu người dùng;
- navigation logic.

Được phép thay đổi:
- màu;
- font;
- cỡ chữ;
- khoảng cách;
- padding;
- margin;
- border;
- radius;
- shadow;
- icon;
- background;
- illustration;
- trạng thái hover/pressed/focus;
- hierarchy thị giác;
- cách trình bày card;
- animation vi mô;
- skeleton/loading;
- visual grouping.

Không “redesign” theo nghĩa dựng lại UX mới. Đây là **visual redesign trên nền layout hiện có**.

## 2.2. Không làm app thành ứng dụng trẻ em quá nhiều màu

IRIS phải giữ cảm giác:
- chuyên nghiệp;
- đáng tin cậy;
- y tế/giáo dục;
- công nghệ;
- thân thiện với phụ huynh;
- mềm mại cho trẻ em.

Công thức phong cách:

**70% Healthcare / SaaS UI  
15% Educational infographic  
10% Child-friendly illustration  
5% Mascot branding**

Từ khóa:
**Clean + Soft + Rounded + Trustworthy + Data-driven + Friendly**

## 2.3. Không dùng quá nhiều hiệu ứng

Tránh:
- glassmorphism nặng;
- blur mạnh;
- gradient neon;
- shadow đậm;
- 3D button;
- glow;
- animation liên tục;
- background quá nhiều họa tiết;
- card lồng card quá dày.

IRIS gần với:
**soft flat UI + outlined card UI + modern healthcare SaaS**.

---

# 3. PHÂN TÍCH NGÔN NGỮ THỊ GIÁC IRIS

## 3.1. Brand personality

Giao diện phải truyền tải đồng thời 4 cảm giác:

1. **Tin cậy** — vì liên quan đến sàng lọc/đánh giá phát triển trẻ.
2. **Dễ hiểu** — vì phụ huynh không nhất thiết có kiến thức chuyên môn.
3. **Thân thiện** — vì sản phẩm liên quan đến trẻ em.
4. **Có cấu trúc** — vì app có nhiều lĩnh vực, nhiều bước, nhiều trạng thái.

Không dùng phong cách bệnh viện lạnh lẽo.
Không dùng phong cách game trẻ em.
Không dùng phong cách AI cyber/futuristic.

---

# 4. DESIGN TOKENS GỢI Ý

Codex phải kiểm tra theme hiện có. Nếu codebase đã có design token/theme, hãy map các giá trị bên dưới vào hệ thống đó thay vì tạo hệ thống song song.

## 4.1. Color system

### Primary

- `iris-navy-900`: khoảng `#102A6B`
- `iris-navy-800`: khoảng `#15367D`
- `iris-blue-700`: khoảng `#145CCB`
- `iris-blue-600`: khoảng `#1769E8`
- `iris-blue-500`: khoảng `#2A78F2`
- `iris-blue-100`: khoảng `#DDEBFF`
- `iris-blue-50`: khoảng `#F2F7FF`

### Neutral

- Background chính: `#F8FBFF` hoặc trắng hơi xanh.
- Surface/card: `#FFFFFF`.
- Border: `#D9E7F8`.
- Border subtle: `#E8F0FA`.
- Text primary: navy đậm, không dùng pure black.
- Text secondary: xám xanh.
- Disabled: xám xanh nhạt.

### Semantic colors

- Success / hoàn thành: `#22B56B`
- Success background: xanh lá rất nhạt
- Warning / đang thực hiện / cần quan sát: `#F59B23`
- Warning background: cam kem rất nhạt
- Danger / cần chú ý: `#EF5A78`
- Danger background: hồng rất nhạt
- Purple domain: `#7558E8`
- Info: dùng primary blue

Không dùng semantic color làm màu trang trí nếu không có ý nghĩa.

## 4.2. Typography

Ưu tiên font sans-serif hiện đại, hỗ trợ tiếng Việt tốt.

Thứ tự ưu tiên:
1. font hiện tại nếu phù hợp;
2. Be Vietnam Pro;
3. Inter;
4. system sans như SF Pro/Roboto theo platform.

Typography hierarchy:

- Display / page title: 28–40px tùy breakpoint, ExtraBold/Bold.
- Section title: 20–28px, Bold.
- Card title: 16–20px, SemiBold/Bold.
- Body: 14–16px, Regular/Medium.
- Caption: 12–13px.
- Button: 14–16px, SemiBold.

Nguyên tắc:
- heading dùng navy;
- body không dùng xanh primary cho toàn bộ text;
- line-height thoáng;
- ưu tiên căn trái;
- chỉ center các vùng splash, empty state, CTA hoặc summary;
- tránh uppercase cho body text;
- không để text quá nhỏ chỉ vì muốn nhét nhiều nội dung.

## 4.3. Spacing

Dùng hệ spacing theo bội số 4 hoặc 8.

Gợi ý:
- 4
- 8
- 12
- 16
- 20
- 24
- 32
- 40
- 48

Không dùng các giá trị ngẫu nhiên ở từng component nếu có thể tránh.

## 4.4. Radius

- Input nhỏ/tag: 8px
- Button: 10–12px
- Card nhỏ: 12–16px
- Panel lớn: 18–24px
- Pill/badge: radius tối đa

Không dùng radius quá lớn cho mọi thứ.

## 4.5. Shadow

Shadow cực nhẹ.

Card thường nên ưu tiên:
- border xanh nhạt;
- background trắng;
- shadow nhẹ hoặc không shadow.

Chỉ dùng shadow rõ hơn cho:
- modal;
- floating action;
- dropdown;
- bottom sheet;
- active overlay.

---

# 5. LOADING / SPLASH SCREEN — ƯU TIÊN LÀM ĐẦU TIÊN

Phải triển khai màn hình này trước khi beautify các trang khác.

## 5.1. Mục tiêu

Loading screen phải:
- thể hiện ngay thương hiệu IRIS;
- tạo cảm giác mềm mại, tin cậy;
- không rối;
- không giống quảng cáo;
- không chặn người dùng lâu hơn cần thiết.

## 5.2. Cấu trúc visual

Giữ tối giản:

- nền trắng hoặc xanh rất nhạt;
- gradient xanh cực nhẹ nếu framework hỗ trợ đẹp;
- logo IRIS ở vùng trung tâm hoặc trên mascot;
- mascot gấu IRIS hoặc illustration liên quan đến chăm sóc phát triển trẻ;
- một câu tagline ngắn;
- loading indicator mềm;
- optional: các shape tròn/đám mây rất mờ ở nền.

Gợi ý tagline:
**“Đồng hành cùng sự phát triển của trẻ”**

Không nhồi thêm menu, button hoặc thông tin chức năng.

## 5.3. Motion

Animation được phép:
- logo fade/scale nhẹ;
- mascot float 2–4px;
- loading dots;
- progress bar mảnh;
- pulse rất nhẹ.

Không:
- bounce mạnh;
- xoay liên tục;
- flashy transition;
- âm thanh;
- confetti.

Ưu tiên 60fps.

Nếu app có bootstrap/auth/data initialization:
- splash hiển thị trong thời gian thực sự khởi tạo.
- Khi ready thì transition mềm sang UI chính.
- Không tạo delay dài giả tạo.
- Nếu cần minimum brand exposure, giữ rất ngắn và không gây khó chịu.

## 5.4. Responsive

Loading screen phải đẹp ở:
- mobile nhỏ;
- mobile phổ biến;
- tablet;
- desktop nếu app có desktop/web.

Asset phải scale theo container, không dùng fixed pixel khiến mascot/logo bị cắt.

---

# 6. IMAGE GENERATION — PHẢI TẬN DỤNG

Codex có trình tạo ảnh thì được phép chủ động dùng để tạo asset nếu codebase thiếu asset phù hợp.

## 6.1. Asset nên tạo bằng image generator

Ưu tiên tạo:
- mascot IRIS;
- biến thể mascot theo ngữ cảnh;
- parent-child illustration;
- doctor/specialist illustration;
- empty state;
- onboarding artwork;
- loading screen artwork;
- subtle background illustration;
- decorative domain illustrations;
- avatar minh họa nếu không phải dữ liệu người dùng thật.

## 6.2. Icon

Có thể dùng image generator cho icon mang tính thương hiệu/chuyên biệt, nhưng phải giữ consistency.

Functional icon phổ biến như:
- back;
- close;
- chevron;
- home;
- settings;
- search;
- calendar;
- camera;
- upload;
- edit;

nên ưu tiên icon system/vector library hiện có để:
- sắc nét;
- dễ đổi màu;
- accessible;
- nhẹ;
- nhất quán.

Image generator phù hợp hơn với:
- icon lĩnh vực đặc thù;
- mascot badge;
- illustration icon lớn;
- category artwork.

Nếu tạo icon bằng AI:
- nền transparent;
- một chủ thể;
- không chữ;
- centered;
- cùng góc nhìn;
- cùng stroke/volume;
- cùng độ mềm;
- cùng palette;
- cùng kích thước canvas;
- không shadow nặng.

## 6.3. Prompt style cho asset IRIS

Khi tạo asset, dùng tinh thần:

> friendly pediatric healthcare app illustration, clean modern SaaS aesthetic, soft rounded shapes, white and light blue background, royal blue and navy accents, subtle pastel colors, warm supportive mood, professional but child-friendly, minimal details, no text, isolated composition, consistent IRIS brand style

Đối với mascot:

> cute friendly bear mascot for a child development support app, soft 3D/cartoon appearance, beige fur, royal blue IRIS shirt, warm smile, trustworthy and supportive, clean studio lighting, white or transparent background, polished app-brand character, not toy-like, not overly childish, no text

Đối với background:

> subtle pediatric healthcare background, extremely light blue and white, abstract rounded blobs, tiny supportive care symbols, low visual noise, lots of negative space, suitable behind mobile app UI, no text, no strong contrast

## 6.4. Không để AI tự sinh chữ trong ảnh

Text/logo quan trọng phải render bằng code.

Không dùng chữ do image generator tạo ra cho:
- tên app;
- button;
- heading;
- label;
- disclaimer;
- thông tin người dùng.

---

# 7. COMPONENT LANGUAGE

## 7.1. Card

Default card:
- white surface;
- thin light-blue border;
- radius 14–20;
- padding 16–24;
- shadow rất nhẹ hoặc none;
- title navy;
- icon có background pastel.

Selected/active card:
- border primary blue;
- background blue-50;
- shadow nhẹ.

Success card:
- border success nhạt;
- background success rất nhạt.

Warning card:
- border orange nhạt;
- background kem.

Danger card:
- border pink/red nhạt;
- background hồng rất nhạt.

Không lồng quá nhiều card có border vào nhau.

## 7.2. Buttons

### Primary
- royal blue;
- text trắng;
- medium/semi-bold;
- radius 10–12;
- height đủ lớn để chạm;
- hover đậm hơn nhẹ;
- pressed scale rất nhỏ hoặc shade change.

### Secondary
- nền trắng/xanh rất nhạt;
- border blue;
- text blue.

### Tertiary
- text button;
- không shadow.

### Danger
Chỉ dùng đỏ/hồng cho action thật sự nguy hiểm.

Không biến tất cả action thành nút xanh đặc.

## 7.3. Inputs

- background trắng;
- border xanh xám nhạt;
- radius 10–12;
- height thoải mái;
- label rõ;
- placeholder không quá nhạt;
- focus border primary + focus ring nhẹ;
- error state có icon + message;
- không dùng chỉ màu để biểu thị lỗi.

## 7.4. Badge / status

Style dạng pill.

Các trạng thái:
- Hoàn thành → xanh lá
- Đang thực hiện → cam
- Chưa bắt đầu → neutral
- Cần chú ý → hồng/đỏ
- Thông tin → xanh

Phải có label, không chỉ dùng dot màu.

## 7.5. Progress

Progress bar:
- track xanh/xám rất nhạt;
- fill theo semantic/domain color;
- radius full;
- animation khi cập nhật nhẹ.

Nếu có phần trăm:
- hiển thị ở vị trí dễ đọc;
- tránh label quá nhỏ.

## 7.6. Domain tiles / lĩnh vực

Các lĩnh vực nên có:
- icon riêng;
- màu nhận diện riêng;
- cùng kích thước tile;
- heading;
- progress/trạng thái;
- hit area lớn.

Giữ màu domain nhất quán xuyên app.

---

# 8. ICONOGRAPHY

Ngôn ngữ icon:
- rounded;
- stroke mềm;
- hình học đơn giản;
- dễ hiểu;
- không chi tiết quá nhỏ.

Icon container:
- circle hoặc rounded-square pastel;
- kích thước đồng đều;
- padding đồng đều.

Tránh trộn:
- outline cực mảnh;
- 3D icon;
- filled icon nặng;
- emoji;
- clipart;

trong cùng một nhóm.

Nếu codebase đã có một icon library, hãy chuẩn hóa quanh library đó trước.

---

# 9. ILLUSTRATION & MASCOT GUIDELINE

Mascot là yếu tố cảm xúc, không phải decor phủ khắp app.

Dùng mascot tại:
- splash/loading;
- onboarding;
- empty state;
- success state;
- helper tip;
- educational explanation;
- milestone.

Không đặt mascot:
- cạnh mọi button;
- trong list dài;
- ở form nhập liệu dày đặc;
- nơi cần tập trung dữ liệu chuyên môn.

Mỗi screen tối đa 1 mascot chính trừ khi là màn hình onboarding/marketing.

Illustration con người:
- biểu cảm tích cực;
- không phóng đại bệnh lý;
- không tạo cảm giác chẩn đoán;
- đa dạng nhưng giữ style;
- background tối giản.

---

# 10. HEADER / NAVIGATION

Giữ cấu trúc navigation hiện có.

Chỉ làm đẹp bằng:
- icon thống nhất;
- khoảng cách hợp lý;
- active state rõ;
- sticky header nếu đã có behavior tương ứng;
- border/shadow nhẹ;
- title navy;
- back affordance rõ.

Bottom navigation nếu có:
- surface trắng;
- divider/shadow rất nhẹ;
- active blue;
- inactive muted;
- label ngắn;
- icon cùng style.

Không tự thêm tab mới.

---

# 11. CONTENT HIERARCHY

Mỗi màn hình phải có thứ tự nhận thức rõ:

1. Người dùng đang ở đâu?
2. Mục tiêu chính của màn hình là gì?
3. Hành động tiếp theo là gì?
4. Trạng thái hiện tại là gì?
5. Thông tin hỗ trợ nằm ở đâu?

Ưu tiên:
- heading;
- summary;
- primary action;
- supporting content;
- disclaimer.

Không để disclaimer tranh hierarchy với CTA, nhưng vẫn phải dễ thấy.

---

# 12. IRIS SAFETY / TRUST UI

Các thông điệp liên quan đến đánh giá/sàng lọc phải giữ tone:
- tham khảo;
- hỗ trợ;
- không tự chẩn đoán;
- khuyến nghị chuyên gia khi cần.

Visual phù hợp:
- shield icon;
- info card;
- soft blue background;
- readable text.

Không dùng visual gây hoảng sợ.

---

# 13. RESPONSIVE STRATEGY

Codex phải tự xác định app là:
- mobile-first;
- responsive web;
- tablet;
- hybrid;
- native.

Không thay layout architecture nhưng được điều chỉnh:
- padding;
- gap;
- text wrapping;
- card width;
- column count;
- breakpoints;
- image size;
- max-width.

Yêu cầu:
- không horizontal overflow;
- không cắt chữ tiếng Việt;
- không cắt mascot;
- button không quá nhỏ;
- form usable trên mobile;
- keyboard không che CTA nếu framework hỗ trợ xử lý.

---

# 14. ACCESSIBILITY

Tối thiểu:
- contrast đủ đọc;
- touch target khoảng 44px trở lên khi phù hợp;
- focus state rõ trên web;
- alt/accessibility label cho image/icon có ý nghĩa;
- icon-only button phải có label;
- trạng thái không được biểu thị chỉ bằng màu;
- text phải scale hợp lý;
- hỗ trợ reduced motion nếu platform có.

Không hy sinh accessibility để “đẹp”.

---

# 15. IMPLEMENTATION WORKFLOW CHO CODEX

## Phase A — Audit

Trước khi sửa code:
1. xác định framework;
2. xác định entry point;
3. xác định navigation/router;
4. xác định global theme;
5. liệt kê component reusable;
6. tìm asset hiện có;
7. tìm icon library;
8. xác định các screen chính;
9. xác định loading/bootstrap hiện tại;
10. xác định nơi đang dùng màu/font/radius hard-coded.

Không hỏi người dùng những thông tin có thể tự đọc từ code.

## Phase B — Visual foundation

Tạo/chuẩn hóa:
- theme;
- colors;
- typography;
- spacing;
- radius;
- shadows;
- status palette;
- domain palette.

Không refactor toàn dự án nếu chỉ cần một lớp theme mỏng.

## Phase C — Loading screen

Làm splash/loading trước.
Đảm bảo:
- transition không giật;
- không flash white bất thường;
- asset load sớm;
- brand rõ;
- không gây delay dài.

## Phase D — Shared components

Ưu tiên làm shared primitives:
- button;
- card;
- input;
- badge;
- icon container;
- progress;
- section header;
- info/warning box;
- avatar;
- empty state.

Sau đó các screen hiện có chỉ cần dùng lại style.

## Phase E — Screen-by-screen beautification

Với từng screen:
1. giữ DOM/component hierarchy chính nếu có thể;
2. áp token;
3. sửa spacing;
4. sửa typography;
5. sửa border/radius;
6. chuẩn hóa icon;
7. xử lý trạng thái;
8. thêm illustration có kiểm soát;
9. test small screen;
10. test dữ liệu dài.

## Phase F — QA

Kiểm tra:
- navigation vẫn hoạt động;
- form vẫn submit;
- loading không loop;
- API không bị ảnh hưởng;
- state không mất;
- keyboard/focus đúng;
- text tiếng Việt không tràn;
- loading/empty/error/success đều đẹp;
- không có màn hình nào lệch hẳn design system.

---

# 16. CÁCH XỬ LÝ CODE CŨ

Nếu code hiện có:
- inline style;
- duplicated color;
- component trùng;
- spacing rời rạc;

được phép gom lại nếu ít rủi ro.

Không được:
- đổi architecture chỉ vì thích;
- chuyển framework;
- thay router;
- thay state management;
- đổi API layer;
- rewrite toàn bộ app.

Mục tiêu là **visual refactor an toàn**.

---

# 17. PERFORMANCE

Asset ảnh:
- nén;
- kích thước hợp lý;
- lazy load khi không ở above-the-fold;
- preload logo/splash nếu cần;
- không dùng ảnh 4K cho icon 48px;
- dùng WebP/AVIF nếu stack hỗ trợ;
- transparent PNG/WebP cho mascot khi cần.

Animation:
- ưu tiên transform/opacity;
- tránh layout thrashing.

---

# 18. CÁC MÀN HÌNH / NHÓM UI CẦN GIỮ CÙNG NGÔN NGỮ

Dựa trên bộ tham chiếu, style phải đủ linh hoạt cho các nhóm sau nếu codebase có:

- màn hình mở app;
- tạo/chọn hồ sơ trẻ;
- sàng lọc;
- kết quả sàng lọc;
- hồ sơ trẻ;
- đề xuất đánh giá;
- đánh giá theo lĩnh vực;
- mô tả biểu hiện;
- so sánh với trẻ cùng độ tuổi;
- chia sẻ từ phụ huynh;
- thông tin bác sĩ/chuyên gia;
- chân dung biểu hiện;
- lưu kết quả;
- tiếp tục đánh giá;
- lịch sử;
- hồ sơ dữ liệu tổng hợp;
- hỏi đáp AI;
- AI theo mức độ dữ liệu;
- quay/gửi video;
- chuyên gia/trung tâm;
- dashboard quản lý nhiều trẻ;
- báo cáo/trạng thái tiến độ.

Không cần tự tạo các màn hình không tồn tại trong codebase.

---

# 19. NGÔN NGỮ THIẾT KẾ CHO DỮ LIỆU ĐÁNH GIÁ

Khi hiển thị dữ liệu đánh giá:
- ưu tiên scan nhanh;
- dùng progress;
- status chip;
- concise summary;
- icon domain;
- màu semantic;
- callout vừa phải.

Không trình bày như dashboard tài chính nặng biểu đồ nếu dữ liệu không cần.

Nếu có chart:
- ít màu;
- legend rõ;
- không 3D;
- background sạch;
- label readable.

---

# 20. MICROINTERACTION

Được dùng:
- button press;
- card selected;
- accordion expand;
- progress animation;
- success check;
- smooth screen transition;
- skeleton shimmer rất nhẹ.

Thời lượng gợi ý:
- 120–180ms cho press/hover;
- 180–260ms cho component transition;
- 250–400ms cho screen-level transition.

Không animation mọi thứ.

---

# 21. EMPTY / ERROR / SUCCESS STATES

## Empty
- icon/illustration đơn giản;
- title ngắn;
- body giải thích;
- CTA nếu có hành động.

## Error
- hồng/đỏ mềm;
- icon cảnh báo;
- message cụ thể;
- action retry;
- không chỉ hiện “Có lỗi xảy ra”.

## Success
- xanh lá;
- check icon;
- mascot có thể xuất hiện nếu phù hợp;
- confirmation rõ;
- action tiếp theo.

---

# 22. DO / DON'T

## DO
- dùng nhiều white space hợp lý;
- dùng navy cho hierarchy;
- dùng blue cho hành động;
- dùng pastel cho support;
- bo góc mềm;
- border mảnh;
- icon nhất quán;
- illustration tiết chế;
- ưu tiên tiếng Việt dễ đọc;
- giữ cảm giác y tế + giáo dục + gia đình.

## DON'T
- đổi luồng;
- đổi bố cục thô;
- thêm chức năng không yêu cầu;
- dùng gradient neon;
- dùng dark theme tự phát;
- dùng quá nhiều màu;
- dùng nhiều loại icon khác nhau;
- thêm mascot khắp nơi;
- render text bằng ảnh;
- tạo background gây nhiễu;
- thay đổi logic dữ liệu.

---

# 23. ACCEPTANCE CRITERIA

Công việc chỉ được xem là hoàn thành khi:

1. Có loading/splash screen IRIS hoàn chỉnh.
2. Loading transition vào app mượt.
3. Toàn bộ UI chính giữ nguyên cấu trúc/luồng.
4. Các màn hình có cùng color/typography/spacing/radius system.
5. Không còn cảm giác mỗi screen là một style khác nhau.
6. Buttons/inputs/cards/status/progress nhất quán.
7. Asset mới đồng bộ phong cách.
8. Không có text quan trọng nằm trong ảnh AI.
9. Không có overflow rõ trên các breakpoint chính.
10. Không phá API/business logic/navigation.
11. Các trạng thái loading/error/empty/success được xử lý.
12. UI nhìn hiện đại nhưng vẫn nghiêm túc và đáng tin.
13. Mascot tạo cảm giác thân thiện nhưng không lấn át chuyên môn.
14. Các disclaimer quan trọng vẫn dễ đọc.
15. Code UI sau chỉnh sửa dễ maintain hơn hoặc ít nhất không tệ hơn trước.

---

# 24. OUTPUT CỦA CODEX SAU KHI THỰC HIỆN

Sau khi sửa, Codex phải báo cáo ngắn gọn:

- đã phát hiện framework/structure gì;
- đã thêm loading screen theo cách nào;
- đã tạo/chuẩn hóa design token nào;
- component nào được làm đẹp;
- asset AI nào đã tạo;
- màn hình nào đã chỉnh;
- điểm nào cố tình giữ nguyên vì liên quan business logic;
- các test/check đã chạy;
- các vấn đề còn lại nếu có.

Không cần hỏi người dùng vị trí file nếu có thể tự xác định từ codebase.

---

# 25. CHỈ THỊ THỰC THI CUỐI CÙNG

Hãy bắt đầu bằng việc **đọc toàn bộ cấu trúc dự án và nhận diện cách app khởi động**.

Sau đó:

1. dựng hệ visual token IRIS;
2. tạo loading/splash screen;
3. tích hợp loading vào lifecycle hiện có;
4. làm đẹp các shared component;
5. đi qua từng màn hình hiện hữu và áp cùng một design language;
6. dùng image generation khi asset thương hiệu/illustration/icon chuyên biệt còn thiếu;
7. không tự thay đổi bố cục thô hoặc chức năng;
8. tự kiểm tra kết quả trên các breakpoint chính;
9. hoàn thiện đến mức có thể chạy trực tiếp trong codebase hiện tại.

Nguyên tắc ưu tiên:

**Preserve structure → Improve hierarchy → Standardize components → Add brand assets → Polish motion → Verify functionality.**

Khi có mâu thuẫn giữa “đẹp hơn” và “giữ nguyên hành vi”, luôn ưu tiên **giữ nguyên hành vi**.
