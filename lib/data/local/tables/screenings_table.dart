/// Bảng `screenings` — kết quả sàng lọc, chỉ có bản ghi khi người dùng THỰC SỰ
/// chọn "Có" ở Bước 3 và hoàn thành. Không có dòng nào cho child_id tương ứng
/// chính là tín hiệu "chưa sàng lọc" (không phải kết luận âm tính).
const String screeningsTableCreate = '''
CREATE TABLE screenings (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  tool_name TEXT,
  score TEXT,
  result_summary TEXT,
  performed_at TEXT,
  created_at TEXT NOT NULL
);
''';
