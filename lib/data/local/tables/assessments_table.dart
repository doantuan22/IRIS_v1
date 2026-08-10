/// Bảng `assessments` — CHỈ dữ liệu riêng của trẻ (mục 1: Mô tả biểu hiện,
/// và ghi chú case-specific từ chuyên gia, VD sau khi xem video).
/// KHÔNG chứa nội dung tham khảo chung — nội dung đó nằm ở
/// `expert_knowledge_chunks_table.dart`.
const String assessmentsTableCreate = '''
CREATE TABLE assessments (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id),
  linh_vuc TEXT NOT NULL,
  content_type TEXT NOT NULL,
  content TEXT NOT NULL,
  nguon TEXT,
  performed_by TEXT,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_assessments_child ON assessments(child_id, linh_vuc);
''';
