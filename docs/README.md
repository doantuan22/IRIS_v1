# Tài liệu dự án IRIS

Quy ước thư mục `docs/` — áp dụng dần khi có tài liệu mới, không hồi tố lại
tài liệu cũ đã nằm ở nơi khác.

## `architecture/`
Tài liệu kiến trúc hệ thống: sơ đồ, luồng dữ liệu, mô tả cách các thành
phần (app Flutter hiện tại, backend/web sau này) tương tác với nhau. Dùng
khi cần giải thích **hệ thống hoạt động thế nào**.

## `adr/` — Architecture Decision Records
Mỗi file 1 quyết định kiến trúc/kỹ thuật quan trọng, đánh số thứ tự
(`0001-...`, `0002-...`). Dùng khi cần giải thích **tại sao lại chọn như
vậy** — đặc biệt các quyết định có thể gây thắc mắc sau này (VD: tại sao
chưa tách monorepo, tại sao chưa chuyển video sang CDN). Mỗi ADR theo format:

```
## Bối cảnh
## Quyết định
## Lý do
## Điều kiện revisit
```

ADR không xóa khi quyết định thay đổi — thêm ADR mới ghi đè quyết định cũ
và trỏ ngược lại ADR bị thay thế, để giữ nguyên lịch sử tư duy.

## `reports/`
Nơi lưu báo cáo/audit theo thời điểm (VD: audit dọn dẹp repo, báo cáo kiểm
thử) — thay vì để rối ở gốc repo. Đặt tên file kèm ngày để dễ tra cứu theo
thời gian.

## `api/`
Tài liệu API — hiện chưa có nội dung (dự án chưa có backend service). Sẽ
dùng khi bắt đầu code backend/web.

## `versioning.md`
Quy ước Semantic Versioning áp dụng cho dự án.
