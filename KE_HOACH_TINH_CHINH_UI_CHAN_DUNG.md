# Kế hoạch tinh chỉnh UI/UX — Tạo hồ sơ / Xác nhận sàng lọc / Đánh giá 7 lĩnh vực

Trạng thái: **GIAI ĐOẠN A — AUDIT, CHƯA SỬA CODE**. Tài liệu này cần được duyệt trước khi
chuyển sang Giai đoạn B.

---

## A1. Audit hiển thị tuổi trẻ trong app

Tìm bằng `grep` cho `formatAgeLabel(` (định nghĩa tại `lib/domain/models/child.dart:76`,
trả về chuỗi dạng `"3 tuổi 2 tháng"` / `"8 tháng tuổi"`) trên toàn bộ `lib/`. Có 9 vị trí gọi
hàm này để hiển thị UI (không tính 1 vị trí dùng làm ngữ cảnh cho AI, xem cuối mục).

Chia làm 2 nhóm theo bản chất khác nhau — **quan trọng để quyết định phạm vi xoá ở B2**:

### Nhóm 1 — Tuổi đặt trong ngoặc, gắn liền tên/tiêu đề (đúng mẫu người dùng phản ánh)

| # | File | Dòng | Đoạn text hiện tại |
|---|------|------|---------------------|
| 1 | `lib/features/screening/screening_tool_confirm_page.dart` | 37 | `'Công cụ sàng lọc sẽ dùng cho ${child.name} (${formatAgeLabel(child)}):'` |
| 2 | `lib/features/assessment/nine_domains/comparison_video/comparison_detail_page.dart` | 91 | `'So sánh chi tiết (${formatAgeLabel(widget.child)})'` |
| 3 | `lib/features/assessment/nine_domains/comparison_video/comparison_video_page.dart` | 95 | `'So sánh nhanh (${formatAgeLabel(widget.child)})'` |

Đây đúng là mẫu "(X tuổi Y tháng)" thừa/rườm rà mà người dùng phản ánh khi xem UI thật — tên
trẻ hoặc tiêu đề màn đã đủ ngữ cảnh, không cần nhắc lại tuổi trong ngoặc ở tiêu đề.

### Nhóm 2 — Tuổi hiển thị như thông tin định danh độc lập (subtitle của thẻ/hồ sơ trẻ)

| # | File | Dòng | Đoạn text hiện tại | Vai trò |
|---|------|------|---------------------|---------|
| 4 | `lib/features/home/home_page.dart` | 259 | `Text(formatAgeLabel(child))` | Dòng phụ dưới tên trẻ, thẻ nhỏ trên `HomePage` |
| 5 | `lib/features/home/home_page.dart` | 497-500 | `Text(formatAgeLabel(child), style: ...primary)` | Dòng phụ dưới tên trẻ, thẻ hồ sơ chính `HomePage` |
| 6 | `lib/features/child_profile/child_list_page.dart` | 112 | `'${formatAgeLabel(child)} • ${child.gender ?? "chưa rõ giới tính"}'` | Subtitle `ListTile` trong danh sách hồ sơ |
| 7 | `lib/features/multi_child_dashboard/multi_child_dashboard_page.dart` | 260-261 | `'${formatAgeLabel(child)} • ${s.doneDomainCount}/$total lĩnh vực • ...'` | Subtitle thẻ trẻ trên dashboard nhiều con |
| 8 | `lib/features/child_profile/profile_detail/profile_detail_page.dart` | 89 | `'${formatAgeLabel(child)} • ${child.gender ?? "chưa rõ giới tính"}'` | Dòng thông tin trên trang chi tiết hồ sơ |
| 9 | `lib/features/screening/assessment_summary_page.dart` | 120 | `Text('Độ tuổi: ${formatAgeLabel(widget.child)}')` | Dòng thông tin trong khối tóm tắt |

Đây là các nơi tuổi đóng vai trò **thông tin định danh chính** (giống ngày sinh/giới tính),
giúp phụ huynh phân biệt hồ sơ khi có nhiều trẻ — không phải kiểu lặp thừa trong ngoặc.

### Vị trí KHÔNG phải hiển thị UI (loại khỏi phạm vi B2)

- `lib/data/repositories/overview_repository.dart:381` — `formatAgeLabel(child)` được truyền
  vào `PromptBuilder.buildOverviewPortraitSummaryPrompt` làm ngữ cảnh cho AI, không render ra
  màn hình. **Không đụng tới** vì không phải "hiển thị" theo đúng nghĩa audit này.

### Đề xuất cho B2

Yêu cầu gốc (B2) nói xoá tuổi ở "MỌI vị trí đã liệt kê ở A1". Đề xuất kỹ thuật:

- **Nhóm 1 (3 vị trí)**: xoá phần `(${formatAgeLabel(...)})` khỏi tiêu đề/câu dẫn — an toàn,
  đúng tinh thần phản ánh ban đầu (tuổi lặp lại thừa cạnh tên/tiêu đề).
- **Nhóm 2 (6 vị trí)**: đây là dòng thông tin định danh trẻ trên các màn danh sách/thẻ hồ
  sơ/tóm tắt — không phải mẫu "(X tuổi Y tháng) đi kèm tên" gây rối như phản ánh gốc. Xoá hẳn
  ở đây sẽ làm mất thông tin tuổi hoàn toàn khỏi các màn danh sách nhiều hồ sơ, ảnh hưởng khả
  năng phân biệt trẻ khi có >1 hồ sơ. **Đề nghị xác nhận lại phạm vi trước khi thực thi Giai
  đoạn B**: xoá cả Nhóm 2, hay chỉ xoá Nhóm 1 và giữ Nhóm 2 như thông tin định danh hợp lệ?

---

## A2. Audit đoạn text dài chưa canh 2 lề (justify)

**Xác nhận bằng grep**: `textAlign: TextAlign.justify` xuất hiện **0 lần** trong toàn bộ
`lib/`. **Không có điểm tập trung** (chưa có `TextStyle`/widget wrapper riêng cho "đoạn mô tả
dài") — `lib/core/widgets/iris_ui.dart` chỉ có các widget UI khác (`IrisBrandWordmark`,
`IrisSparkle`, `IrisAiStatusLamp`, `IrisGenderAvatar`, `IrisAssetIcon`, `IrisRoundArrow`,
`IrisPageBackdrop`, `IrisIconChip`, `IrisStatusBadge`, `IrisInfoBanner`, `IrisDomainIcon`), và
`lib/core/theme/iris_theme.dart` chỉ định nghĩa `bodyLarge/bodyMedium/bodySmall` (màu/kích
thước), không có options về `textAlign`.

**Đề xuất kỹ thuật (khuyến nghị)**: thêm 1 widget dùng chung, ví dụ `IrisParagraph` trong
`lib/core/widgets/iris_ui.dart`, wrap `Text` với `textAlign: TextAlign.justify` mặc định (cho
phép override `style`/`textAlign` khi cần, ví dụ các đoạn empty-state vẫn muốn `center`). Sau
đó thay `Text(...)` bằng `IrisParagraph(...)` tại các vị trí liệt kê dưới — sửa 1 lần tại các
điểm gọi, không cần sửa lặp logic canh lề ở từng nơi.

### Danh sách vị trí cần áp dụng justify (ưu tiên cao — nội dung động/dài, rủi ro cao nhất vì AI sinh ra không giới hạn độ dài)

| # | File | Dòng | Nội dung |
|---|------|------|----------|
| 1 | `overview_portrait_page.dart` | 369-374 | `summary.moTaTongHop!` — văn bản "Chân dung biểu hiện" do AI sinh, dài, không giới hạn |
| 2 | `overview_portrait_page.dart` | 18-20, 477-480 | `_disclaimerText` — luôn hiển thị cuối trang |
| 3 | `overview_portrait_page.dart` | 490-500, 520 | `_expertConnectBannerText` (3 biến thể theo tier) |
| 4 | `video_recording/video_detail_page.dart` | 15-26, 196 | `_expertNoteTemplates` — nhận xét chuyên gia mô phỏng, 3-4 câu/mẫu |
| 5 | `nine_domains/comparison_video/comparison_video_page.dart` | 235 | `item.content` — nội dung so sánh đọc từ `expert_knowledge_chunks`, dùng chung cho cả `ComparisonVideoPage` và `ComparisonDetailPage` (cùng widget `ComparisonItemList`) |

### Ưu tiên trung bình (mô tả tĩnh, đã biết trước nội dung)

| # | File | Dòng | Nội dung |
|---|------|------|----------|
| 6 | `expert_connect_page.dart` | 27-47, 147 | `_NeedInfo.description` (3 biến thể) |
| 7 | `expert_connect_page.dart` | 49-51, 175-178 | `_notDiagnosisDisclaimer` |
| 8 | `expert_connect_page.dart` | 240-243 | Mô tả trung tâm Tường Minh |
| 9 | `screening/screening_tool_confirm_page.dart` | 62-66 | Mô tả bộ câu hỏi sàng lọc — **sẽ viết lại nội dung ở B2, áp justify cùng lúc** |
| 10 | `screening/assessment_summary_page.dart` | 65-89, 188 | `_buildSuggestion` — 4 biến thể gợi ý hướng đánh giá |
| 11 | `screening/screening_result_page.dart` | 14-17, 310-313 | `_disclaimerText` |
| 12 | `screening/screening_result_page.dart` | render tại đây; định nghĩa tại `domain/services/screening_scoring_service.dart:160-174` | `screeningGiaiDoanDescription` — hiện đã có `textAlign: TextAlign.center`, cần đổi thành `justify` |
| 13 | `screening/screening_questionnaire_page.dart` | 330-337 | `currentQuestion.noiDung` — nội dung câu hỏi đọc từ `screening_questions.json`, nhiều câu dài |
| 14 | `nine_domains/description/description_page.dart` | 14-28 (const), 191-197 (render) | `_domainIntroTextTemp` — mô tả 7 lĩnh vực |
| 15 | `assessment/domain_hub_page.dart` | 14-28 (const, **trùng lặp nội dung** với #14), 127-130 (render) | `_domainIntroText` |
| 16 | `nine_domains/description/description_page.dart` | 243-245 | "Bạn không cần kiến thức chuyên môn..." |
| 17 | `assessment/domain_hub_page.dart` | 252-256 | "Ghi nhận những gì bạn quan sát được..." |
| 18 | `assessment/domain_list_page.dart` | 138-141 | "Bạn không cần hoàn thành tất cả 7 lĩnh vực..." |

**Ghi chú kỹ thuật**: `_domainIntroTextTemp` (description_page.dart) và `_domainIntroText`
(domain_hub_page.dart) là 2 bản sao trùng nội dung — nên hợp nhất về 1 nguồn chung (constant
dùng lại, ví dụ đặt trong `core/constants/domains.dart`) khi sửa, tránh 2 nơi lệch nhau về
sau. Việc hợp nhất này KHÔNG bắt buộc để hoàn thành B2 (có thể sửa riêng từng chỗ nếu muốn
giảm rủi ro diff), nhưng nên làm nếu không mất nhiều công.

### Borderline — KHÔNG đưa vào phạm vi B2 (đề xuất giữ nguyên)

- Dialog xác nhận xoá hồ sơ (`home_page.dart:426-429`, `multi_child_dashboard_page.dart:165-167`)
  — dialog ngắn, đã đủ rõ, giữ `left-align` mặc định của `AlertDialog` là chuẩn UX thông thường.
- `create_profile_page.dart:196-198` — nội dung sẽ bị **xoá hẳn** theo B1, không cần justify.
- `child_debug_page.dart:105-108` — chỉ hiện ở `kDebugMode`, không phải UI người dùng cuối.
- Các empty-state đã `center` (`screening_history_list_page.dart:185-187`,
  `history_page.dart:131-134`, empty-text trong `ComparisonItemList`) — 1 câu ngắn, giữ `center`
  hợp lý hơn `justify` (justify với 1 dòng không có tác dụng thị giác).
- `domain_hub_page.dart:269-270` (`_HubNavigationCard.subtitle`) — subtitle nhỏ 1 câu trong
  card điều hướng, độ dài không đáng kể.

---

## A3. Audit logic "Xem chân dung" (Đánh giá 7 lĩnh vực)

### A3.1 — Điều kiện hiện tại để nút "Xem chân dung" xuất hiện

File: `lib/features/assessment/domain_list_page.dart`, hàm `build()` (dòng 67-136).

Logic thực tế: **không phải nút mờ/sáng** — nút **hoàn toàn không tồn tại trên cây widget**
cho tới khi đủ 7/7:

```dart
Domain? nextDomain;
for (final domain in domains) {
  if (!domainsWithDescription.contains(domain.code)) {
    nextDomain = domain;
    break;
  }
}
...
if (nextDomain != null)
  _NextDomainCard(...)              // còn thiếu ít nhất 1 lĩnh vực -> hiện card "Tiếp tục ngay"
else ...[
  Row(... 'Bạn đã hoàn thành đánh giá cả 7 lĩnh vực!' ...),
  FilledButton.icon(
    onPressed: () => Navigator.push(... OverviewPortraitPage ...),
    label: const Text('Xem Chân dung toàn cảnh'),
  ),
]
```

- Xác nhận: điều kiện đúng là **7/7 lĩnh vực có bản ghi `assessments` với `content_type =
  'mo_ta'`** (dòng 40-46, 58-59). Không có trạng thái "đủ ≥1" nào được nút này quan tâm hiện
  tại.
- **Vị trí hiện tại của nút**: nằm ở khối `Padding` ngay trên `GridView` 7 thẻ lĩnh vực (dòng
  94-147), tức **phía trên** danh sách 7 thẻ — chưa ở cuối màn hình như yêu cầu B3.
- **`_NextDomainCard` ("Tiếp tục ngay")**: hiện chỉ hiển thị khi `nextDomain != null`, tức
  hiện đúng khi CHƯA đủ 7/7 — khi đủ 7/7 nó tự động biến mất (thay bằng khối "đã hoàn
  thành..."). Vậy hành vi "ẩn khi đủ 7/7" của yêu cầu B3 với "Tiếp tục ngay" **thực ra đã đúng
  sẵn** trong code hiện tại — B3 chỉ cần đảm bảo không phá vỡ hành vi này khi thêm điều kiện
  bật nút "Xem chân dung" mới.

### A3.2 — Nguồn dữ liệu AI đọc để tổng hợp chân dung — có giả định đủ 7/7 không?

Hiện tại có **3 lớp gate cứng yêu cầu đủ 7/7**, độc lập với nhau, cần gỡ cả 3 cho B4:

**Lớp 1 — `OverviewPortraitPage._load()`** (`overview_portrait_page.dart:88-111`):
```dart
if (doneDomains.length < domains.length) {
  return _LoadedState(doneDomainCount: doneDomains.length, labels: const {});
  // KHÔNG load labels, KHÔNG load summary — dừng ở đây
}
```
`_LoadedState.isComplete` (dòng 48) = `doneDomainCount >= domains.length`. Khi chưa đủ 7/7,
`build()` gọi `_buildIncomplete()` (dòng 263-286) — chỉ hiện tiến độ + nút "Quay lại tiếp tục
mô tả", **không có bất kỳ đường dẫn nào tới việc tổng hợp văn bản** dù chỉ 1 lĩnh vực.

**Lớp 2 — `OverviewRepository.computeAndSaveOverview()`** (`overview_repository.dart:248-303`):
```dart
for (final domain in domains) {           // luôn lặp đủ 7 domain cố định
  final label = latest[domain.code];
  if (label == null) {
    return OverviewComputationResult.insufficientLabels(...);   // thiếu nhãn -> dừng
  }
  orderedLabels.add(label);
}
final tierResult = calculateOverviewTier(orderedLabels.map((l) => l.nhan).toList());
...
final moTaTongHop = await _generateSummaryDescription(...);   // CHỈ chạy SAU khi tier đã tính xong
```
=> **Việc sinh văn bản tổng hợp (`_generateSummaryDescription`) hiện nằm PHÍA SAU và PHỤ THUỘC
vào việc tính tier thành công** — đây là điểm mấu chốt cần tách theo yêu cầu B4. Không thể gọi
sinh văn bản độc lập với N<7 bằng pipeline hiện tại.

**Lớp 3 — `OverviewRepository.labelAllDomains()`** (dòng 129-135) gọi `labelDomain()` cho
**toàn bộ 7 domain cố định** (`for (final domain in domains)`), kể cả domain chưa có mô tả —
với domain chưa có mô tả thì gán cứng nhãn `labelChuaDuDuLieu` mà KHÔNG gọi AI (dòng 157-163,
đúng nguyên tắc không suy diễn). Nhãn `chua_du_du_lieu` này sau đó được đưa vào
`_formatDomainsSummaryText()` (dòng 331-369) — hàm này **lặp qua cả 7 domain và với domain
thiếu mô tả sẽ viết `"- Mô tả người dùng: (chưa có)"` cùng nhãn `"Chưa đủ dữ liệu"` vào chính
prompt gửi AI**. Tức là hiện tại, nếu pipeline này chạy được (nó không chạy được khi <7 vì bị
Lớp 1/2 chặn trước), AI vẫn "nhìn thấy" cả các domain rỗng trong ngữ cảnh — không vi phạm
nguyên tắc (không suy diễn nội dung), nhưng **không phù hợp cho chế độ N<7** vì mục tiêu B4 là
văn bản CHỈ dựa trên N lĩnh vực đã có, không nhắc tới domain còn thiếu.

### A3.3 — Cách tính tier — điều kiện đầu vào, có tách rời khỏi tạo văn bản không?

File: `lib/domain/services/overview_tier_calculator.dart`. Hàm `calculateOverviewTier(List<String> labels)`:
- Input: **danh sách nhãn của đúng 7 lĩnh vực** (comment dòng 74-79 xác nhận rõ: "thường là 7
  nhãn — 1 nhãn/lĩnh vực"). Hàm tự nó KHÔNG kiểm tra `labels.length == 7` — chỉ đếm số lượng
  `'can_theo_doi'` và `'chua_du_du_lieu'` trong list truyền vào rồi so ngưỡng
  (`nguongThuongGap`, `nguongCanTheoDoi`, `nguongThieuDuLieuToiThieu`). **Ràng buộc "đủ 7/7"
  hiện nằm ở TẦNG GỌI (`computeAndSaveOverview`, dòng 251-260 — vòng lặp qua `domains` và trả
  `insufficientLabels` nếu thiếu bất kỳ domain nào), không phải bên trong
  `calculateOverviewTier` chính nó.** Đây là điểm thuận lợi: hàm tính tier vốn đã thuần code,
  không phụ thuộc AI, không phụ thuộc I/O — chỉ cần đảm bảo TẦNG GỌI (repository) tiếp tục ép
  đủ 7/7 trước khi gọi hàm này cho mục đích B4 (thực tế tầng gọi đã ép sẵn, chỉ cần KHÔNG được
  nới lỏng khi thêm luồng N<7 mới).
- Xác nhận: **hiện tại việc tính tier và việc sinh văn bản tổng hợp gọi chung trong 1 hàm nối
  tiếp** (`computeAndSaveOverview`, dòng 262 tính tier → dòng 273 sinh văn bản ngay sau, cùng 1
  lần gọi, cùng 1 kết quả trả về `OverviewComputationResult`) — **CHƯA tách rời** như yêu cầu
  B4. Đây là thay đổi logic chính cần thiết kế.

### A3.4 — Prompt sinh văn bản tổng hợp hiện tại

File: `lib/domain/services/prompt_builder.dart`, hàm `buildOverviewPortraitSummaryPrompt`
(dòng 104-124):
- Tham số bắt buộc gồm `tierLabel` — **tier được nhúng cứng vào prompt** ("MỨC TỔNG QUAN HIỆN
  TẠI CỦA TRẺ: $tierLabel", dòng 115). Với chế độ N<7 (chưa có tier), prompt hiện tại **không
  dùng được nguyên trạng** — cần 1 biến thể prompt mới không nhắc tới tier.
- Câu nhiệm vụ (dòng 113) viết cứng "dựa trên thông tin 7 lĩnh vực" — cần đổi thành số lĩnh
  vực thực tế N khi ở chế độ từng phần.
- Guardrail đã có sẵn khá tốt cho mục tiêu B4 (dòng 121): "Chỉ được mô tả và tổng hợp dựa trên
  dữ liệu đã cung cấp ở trên, TUYỆT ĐỐI không thêm thông tin ngoài dữ liệu, không tự suy diễn
  nguyên nhân" — nguyên tắc này áp dụng được cho cả 2 chế độ (N<7 và N=7), chỉ cần đảm bảo
  `domainsSummaryText` truyền vào KHÔNG chứa các domain rỗng (xem A3.2 Lớp 3).

### A3.5 — Kết luận: đủ dữ kiện để thiết kế B4

Xác nhận tách được 2 luồng độc lập theo đúng yêu cầu:
- **Luồng "tổng hợp văn bản"**: chạy được với N ≥ 1 (không cần đủ 7), chỉ dùng dữ liệu của N
  domain đã có mô tả, không tính/không hiển thị tier.
- **Luồng "tính tier"**: chỉ chạy khi N = 7 (giữ nguyên `calculateOverviewTier` +
  `computeAndSaveOverview` hiện tại y nguyên logic, không sửa ngưỡng/thuật toán).

---

## Đề xuất kỹ thuật cụ thể cho Giai đoạn B (để duyệt, CHƯA code)

### B1 — Màn Tạo hồ sơ trẻ (`create_profile_page.dart`)
- Dòng 169: đổi `'Không rõ ngày sinh — chọn mức tuổi'` → `'Chọn theo độ tuổi'`.
- Dòng 195-198: xoá khối `Text('Dải tháng tuổi hiện dùng là giả định làm việc...')` khỏi UI.
  Comment kỹ thuật tương đương (đã có ở code, tại `screening_domains.dart` theo đợt chuẩn hoá
  trước — cần xác nhận lại vị trí đúng khi vào B) **giữ nguyên**, không xoá.

### B2 — Màn Xác nhận sàng lọc + các vị trí tuổi khác
- Xoá `(${formatAgeLabel(...)})` tại 3 vị trí Nhóm 1 (mục A1). **Chờ xác nhận** có xoá luôn 6
  vị trí Nhóm 2 hay không trước khi thực thi.
- Viết lại đoạn mô tả bộ câu hỏi tại `screening_tool_confirm_page.dart:62-66` — giữ đủ thông
  tin (20 câu, 5 lĩnh vực + tên 5 lĩnh vực, thang 0-3 + N/A), văn phong tự nhiên hơn.
- Thêm widget `IrisParagraph` (hoặc tên tương đương) vào `iris_ui.dart`, áp dụng cho toàn bộ
  danh sách ở A2 (18 vị trí, trừ nhóm "borderline — giữ nguyên").

### B3 — Hub 7 lĩnh vực (`domain_list_page.dart`)
- Đổi điều kiện: tính `doneCount = domainsWithDescription.length` (đã có sẵn) →
  - `doneCount == 0`: nút "Xem chân dung" ở trạng thái mờ (`FilledButton` với `onPressed:
    null`, hoặc ẩn hẳn tuỳ quyết định UX — đề xuất **mờ** thay vì ẩn hẳn, để phụ huynh biết
    tính năng tồn tại và cần làm ít nhất 1 lĩnh vực).
  - `doneCount >= 1`: nút bật, điều hướng sang `OverviewPortraitPage` (đã hỗ trợ N<7 sau B4).
- Di chuyển nút xuống cuối `Column` — dưới `Expanded(child: GridView...)`, ngoài vùng
  `Expanded`/`scroll` hiện tại (cần đổi `Column` cha thành có thể cuộn được nếu nút đặt sau
  `GridView`, hoặc dùng `Column` + nút cố định dưới cùng ngoài phần cuộn — cần quyết định layout
  cụ thể khi code).
- `_NextDomainCard` ("Tiếp tục ngay"): giữ nguyên logic ẩn khi `nextDomain == null` (đã đúng
  sẵn, xem A3.1) — không cần sửa gì thêm cho phần này, chỉ xác nhận lại bằng test thủ công.

### B4 — Tách "tổng hợp văn bản theo N lĩnh vực" khỏi "tính tier" (thay đổi logic)

Thiết kế đề xuất tại `overview_repository.dart`:

1. **Hàm mới `generatePartialSummaryDescription(Child child)`** (hoặc tên tương đương):
   - Đọc `assessments` hiện có (`content_type = 'mo_ta'`), lọc ra đúng tập domain có mô tả
     (không lặp cố định qua cả 7 domain như `_formatDomainsSummaryText` hiện tại).
   - **KHÔNG gọi `labelAllDomains`/`labelDomain`** (bước gắn nhãn so sánh với dữ liệu chuyên
     gia) — vì nhãn `thuong_gap`/`can_theo_doi` chỉ có ý nghĩa dùng cho tier, không cần cho
     văn bản mô tả thuần tuý theo yêu cầu B4 (tránh gọi API thừa, tránh rò rỉ khái niệm
     "nhãn"/"tier" vào văn bản khi chưa đủ 7/7).
   - Dùng 1 prompt mới trong `prompt_builder.dart` (ví dụ
     `buildPartialOverviewPortraitSummaryPrompt`) — bỏ tham số `tierLabel`, đổi câu nhiệm vụ
     thành "...dựa trên thông tin N lĩnh vực đã có mô tả dưới đây (trẻ chưa hoàn thành đủ 7
     lĩnh vực)", **thêm guardrail rõ ràng**: "TUYỆT ĐỐI không suy diễn, không generalize, không
     đưa ra bất kỳ nhận định nào về các lĩnh vực CHƯA có dữ liệu trong danh sách trên — chỉ mô
     tả đúng N lĩnh vực đã liệt kê."
   - **Không lưu vào bảng `overview_summaries`** (bảng này gắn với tier, giữ nguyên vai trò chỉ
     dùng khi đủ 7/7) — kết quả N<7 trả trực tiếp cho UI hiển thị (không cache/không lưu DB),
     đúng yêu cầu "không dùng cache kết quả cũ, tổng hợp lại theo dữ liệu mới nhất mỗi lần bấm".
2. **Giữ nguyên nguyên trạng `labelAllDomains` + `computeAndSaveOverview`** cho luồng N=7 (tier)
   — không sửa ngưỡng, không sửa `overview_tier_calculator.dart`.
3. **`OverviewPortraitPage`**: sửa `_load()` bỏ điều kiện chặn cứng `doneDomains.length <
   domains.length`; thêm nhánh hiển thị mới khi `1 <= doneCount < 7`:
   - Gọi `generatePartialSummaryDescription` mỗi lần vào màn hoặc bấm nút tổng hợp.
   - Hiển thị đúng 1 dòng trạng thái: `"Chân dung dựa trên N/7 lĩnh vực đã đánh giá — mức độ
     tổng quan sẽ hiển thị sau khi hoàn thành đủ 7 lĩnh vực."` — **không hiển thị bất kỳ
     card/nhãn/màu "Mức tổng quan" nào** trong nhánh này (khác nhánh `isComplete` hiện tại vẫn
     hiển thị đầy đủ như cũ).
   - Khi `doneCount == 7`: giữ nguyên luồng hiện tại (`_buildReady`, có tier).

### Rủi ro cần lưu ý khi thực thi B4
- Đảm bảo nút "Tổng hợp"/tự động gọi ở chế độ N<7 **không vô tình gọi nhầm**
  `computeAndSaveOverview` (hàm này tính tier) — phải là 2 entrypoint tách biệt rõ trong code,
  không dùng chung 1 hàm với flag `bool partial` (dễ gây lẫn lộn, khó review an toàn) — nên
  **2 hàm riêng, 2 prompt riêng**, đúng tinh thần "tách 2 bước độc lập" đã ghi trong comment
  hiện tại của `overview_repository.dart` dòng 82-86.
- Vì không lưu N<7 vào DB, mỗi lần vào lại màn hoặc bấm lại sẽ gọi AI lại — chấp nhận được ở
  quy mô demo hiện tại (đúng như comment "quy mô demo (7 lần gọi) nên không cần tối ưu song
  song" đã có trong code cho luồng 7/7).

---

## Câu hỏi cần chốt trước khi sang Giai đoạn B

1. **A1 Nhóm 2** (6 vị trí tuổi hiển thị dạng subtitle/thông tin định danh trên
   home/list/dashboard/profile/summary): xoá theo đúng nghĩa đen "MỌI vị trí đã liệt kê ở A1",
   hay chỉ xoá Nhóm 1 (3 vị trí kiểu "(tuổi)" trong ngoặc cạnh tên/tiêu đề)?
2. **B3 khi `doneCount == 0`**: nút "Xem chân dung" nên **mờ nhưng vẫn hiện** (để biết tính
   năng tồn tại), hay **ẩn hẳn** giống hành vi hiện tại của toàn bộ nút này khi <7/7?
