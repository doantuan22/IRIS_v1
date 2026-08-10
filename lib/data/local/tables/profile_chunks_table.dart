/// Bảng `profile_chunks` — chunk dữ liệu hồ sơ trẻ dùng cho RAG, lọc theo
/// child_id. Embedding tính qua NVIDIA API, lưu local dạng BLOB (bytes của
/// Float32List đã serialize).
const String profileChunksTableCreate = '''
CREATE TABLE profile_chunks (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  content TEXT NOT NULL,
  linh_vuc TEXT,
  nguon TEXT,
  embedding BLOB NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_profile_chunks_child ON profile_chunks(child_id);
''';
