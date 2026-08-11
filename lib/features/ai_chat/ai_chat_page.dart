import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/repositories/ai_conversation_repository.dart';
import '../../data/repositories/ai_repository.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/child.dart';

/// Hỏi đáp AI — RAG trên dữ liệu hồ sơ trẻ + dữ liệu tham khảo chuyên môn,
/// thông qua AiRepository. Chưa streaming, chưa làm đẹp giao diện.
class AiChatPage extends StatefulWidget {
  final Child child;

  const AiChatPage({super.key, required this.child});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _aiConversationRepository = AiConversationRepository(AppDatabase.instance);
  late final AiRepository _aiRepository = AiRepository(db: AppDatabase.instance);
  final _questionController = TextEditingController();

  late Future<List<AiConversation>> _conversationsFuture;
  bool _asking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _conversationsFuture = _aiConversationRepository.getForChild(widget.child.id);
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _asking = true;
      _errorMessage = null;
    });
    _questionController.clear();

    try {
      await _aiRepository.ask(child: widget.child, question: question);
      _reload();
    } catch (e) {
      setState(() => _errorMessage = 'Không lấy được câu trả lời: $e');
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hỏi đáp AI — ${widget.child.name}')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<AiConversation>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final conversations = snapshot.data!;
                if (conversations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Chưa có hỏi đáp nào. Hãy đặt câu hỏi bên dưới.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) => _ConversationBubble(conversation: conversations[index]),
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      enabled: !_asking,
                      decoration: const InputDecoration(
                        hintText: 'Đặt câu hỏi về trẻ...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _asking
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(onPressed: _ask, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  final AiConversation conversation;

  const _ConversationBubble({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(conversation.question),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conversation.answer),
                const SizedBox(height: 4),
                Text(
                  'Trạng thái ${conversation.state}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
