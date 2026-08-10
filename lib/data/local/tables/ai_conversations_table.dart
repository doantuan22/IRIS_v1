/// Bảng `ai_conversations` — lịch sử hỏi đáp AI theo từng trẻ, lưu cả
/// `state` (1/2/3) do guardrail xác định.
const String aiConversationsTableCreate = '''
CREATE TABLE ai_conversations (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  state INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
''';
