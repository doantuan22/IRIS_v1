/// Bảng `children` — hồ sơ trẻ (tên, ngày sinh/tuổi, giới tính, người đánh
/// giá + vai trò), lưu local. `nguoi_danh_gia`/`vai_tro` thêm ở version 2
/// (xem `onUpgrade` trong `database.dart`) — CREATE TABLE dưới đây đã gồm
/// cả 2 cột để cài mới đi thẳng đúng schema mới nhất.
const String childrenTableCreate = '''
CREATE TABLE children (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  dob TEXT,
  age_years INTEGER,
  gender TEXT,
  nguoi_danh_gia TEXT,
  vai_tro TEXT,
  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL
);
''';
