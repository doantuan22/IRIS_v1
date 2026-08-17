import 'package:flutter/material.dart';

import '../../core/theme/iris_assets.dart';
import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
import '../../data/local/database.dart';
import '../../data/repositories/ai_conversation_repository.dart';
import '../../data/repositories/ai_repository.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/child.dart';
import '../../domain/services/ai_connectivity_service.dart';

/// Hỏi đáp AI — RAG trên dữ liệu hồ sơ trẻ + dữ liệu tham khảo chuyên môn,
/// thông qua AiRepository. Chưa streaming, chưa làm đẹp giao diện.
class AiChatPage extends StatefulWidget {
  final Child child;

  const AiChatPage({super.key, required this.child});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _aiConversationRepository = AiConversationRepository(
    AppDatabase.instance,
  );
  late final AiRepository _aiRepository = AiRepository(
    db: AppDatabase.instance,
  );
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
      _conversationsFuture = _aiConversationRepository.getForChild(
        widget.child.id,
      );
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

    if (!AiConnectivityService.instance.isConnected) {
      setState(
        () => _errorMessage =
            'AI đang chưa kết nối được, xin vui lòng thử lại sau.',
      );
      return;
    }

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
          ValueListenableBuilder<AiConnectivityState>(
            valueListenable: AiConnectivityService.instance.stateNotifier,
            builder: (context, connectivityState, _) {
              if (!connectivityState.isConnected) {
                return Container(
                  width: double.infinity,
                  color: IrisColors.dangerSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: IrisSpacing.md,
                    vertical: IrisSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: IrisColors.danger),
                      const SizedBox(width: IrisSpacing.sm),
                      Expanded(
                        child: Text(
                          'AI đang chưa kết nối được, xin vui lòng thử lại sau.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
                      padding: EdgeInsets.all(IrisSpacing.lg),
                      child: Text(
                        'Chưa có hỏi đáp nào. Hãy đặt câu hỏi bên dưới.',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: IrisSpacing.page,
                  itemCount: conversations.length,
                  itemBuilder: (context, index) =>
                      _ConversationBubble(conversation: conversations[index]),
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: IrisSpacing.md,
                vertical: IrisSpacing.xxs,
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: IrisColors.danger),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(IrisSpacing.xs),
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
                  const SizedBox(width: IrisSpacing.xs),
                  _asking
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _ask,
                          icon: const Icon(Icons.send),
                        ),
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
            margin: const EdgeInsets.only(bottom: IrisSpacing.xxs),
            padding: const EdgeInsets.all(IrisSpacing.sm),
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width *
                  IrisSizes.maxBubbleWidthFactor,
            ),
            decoration: BoxDecoration(
              color: IrisColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(IrisRadii.card),
                topRight: Radius.circular(IrisRadii.card),
                bottomLeft: Radius.circular(IrisRadii.card),
                bottomRight: Radius.circular(IrisSpacing.xxs),
              ),
            ),
            child: Text(
              conversation.question,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IrisAssetIcon(asset: IrisAssets.iconAiChat),
              const SizedBox(width: IrisSpacing.xs),
              Container(
                margin: const EdgeInsets.only(bottom: IrisSpacing.md),
                padding: const EdgeInsets.all(IrisSpacing.sm),
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width *
                          IrisSizes.maxBubbleWidthFactor -
                      IrisSizes.iconChip -
                      IrisSpacing.xs,
                ),
                decoration: const BoxDecoration(
                  color: IrisColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(IrisSpacing.xxs),
                    topRight: Radius.circular(IrisRadii.card),
                    bottomLeft: Radius.circular(IrisRadii.card),
                    bottomRight: Radius.circular(IrisRadii.card),
                  ),
                  boxShadow: IrisShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conversation.answer),
                    const SizedBox(height: IrisSpacing.xxs),
                    Text(
                      'Trạng thái ${conversation.state}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
