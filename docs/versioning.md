# Quy ước Versioning

Dự án dùng [Semantic Versioning](https://semver.org/) — `MAJOR.MINOR.PATCH+BUILD`,
khớp định dạng `version` trong `pubspec.yaml` (hiện `1.0.0+1`).

## Khi nào bump từng phần

- **MAJOR**: đổi kiến trúc lớn không tương thích ngược — ví dụ đổi từ
  local-first sang bắt buộc có backend, đổi schema DB không migrate được
  từ bản cũ.
- **MINOR**: thêm tính năng mới, tương thích ngược với dữ liệu/hành vi cũ —
  ví dụ thêm lĩnh vực đánh giá mới, thêm màn hình, thêm luồng sàng lọc.
- **PATCH**: sửa lỗi, không đổi tính năng hay hành vi có chủ đích.
- **`+BUILD`**: tăng mỗi lần build release (độc lập với MAJOR.MINOR.PATCH),
  theo đúng cách Flutter dùng hiện tại (`flutter build apk --build-number=N`).

## Gắn tag git

Mỗi lần release, gắn tag `vMAJOR.MINOR.PATCH` (ví dụ `v1.0.0`) tại đúng
commit đã build, để đối chiếu ngược version ↔ commit khi cần. Repo hiện
chưa có tag nào — bắt đầu áp dụng từ lần bump version tiếp theo.

## Changelog

Mỗi lần bump version, ghi lại thay đổi vào `CHANGELOG.md` ở gốc repo theo
format [Keep a Changelog](https://keepachangelog.com/).
