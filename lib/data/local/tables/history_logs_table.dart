/// Bảng `history_logs` — lịch sử tổng hợp mọi mốc thời gian: sàng lọc,
/// đánh giá, video, hồ sơ.
const String historyLogsTableCreate = '''
CREATE TABLE history_logs (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  event_type TEXT NOT NULL,
  description TEXT,
  event_date TEXT NOT NULL
);

CREATE INDEX idx_history_child ON history_logs(child_id, event_date);
''';
