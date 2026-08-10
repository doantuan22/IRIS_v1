/// Bảng `children` — hồ sơ trẻ (tên, ngày sinh/tuổi, giới tính), lưu local.
const String childrenTableCreate = '''
CREATE TABLE children (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  dob TEXT,
  age_years INTEGER,
  gender TEXT,
  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL
);
''';
