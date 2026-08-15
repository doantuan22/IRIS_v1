import 'package:uuid/uuid.dart';

import '../../domain/models/ai_conversation.dart';
import '../local/database.dart';

/// Lưu và truy vấn lịch sử hỏi đáp AI trên bảng `ai_conversations`.
class AiConversationRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  AiConversationRepository(this._db);

  Future<AiConversation> save({
    required String childId,
    required String question,
    required String answer,
    required int state,
  }) async {
    final conversation = AiConversation(
      id: _uuid.v4(),
      childId: childId,
      question: question,
      answer: answer,
      state: state,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('ai_conversations', _toRow(conversation));
    return conversation;
  }

  Future<List<AiConversation>> getForChild(String childId) async {
    final db = await _db.database;
    final rows = await db.query(
      'ai_conversations',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _toRow(AiConversation conversation) => {
    'id': conversation.id,
    'child_id': conversation.childId,
    'question': conversation.question,
    'answer': conversation.answer,
    'state': conversation.state,
    'created_at': conversation.createdAt.toIso8601String(),
  };

  AiConversation _fromRow(Map<String, Object?> row) => AiConversation(
    id: row['id'] as String,
    childId: row['child_id'] as String,
    question: row['question'] as String,
    answer: row['answer'] as String,
    state: row['state'] as int,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
