/// Bảng `videos` — video quay tình huống, lưu file local, có thể gửi cho
/// chuyên gia theo yêu cầu (mô phỏng trong phạm vi 1 thiết bị cho bản demo).
const String videosTableCreate = '''
CREATE TABLE videos (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  situation TEXT,
  file_path TEXT NOT NULL,
  status TEXT DEFAULT 'not_sent',
  expert_note TEXT,
  recorded_at TEXT NOT NULL
);
''';
