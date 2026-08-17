/// Bảng `notifications` — lưu trữ danh sách thông báo hệ thống và trạng thái kết nối.
const String notificationsTableCreate = '''
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_notifications_created_at ON notifications(created_at);
''';
