import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../models/chat_message.dart';
import '../models/study_task.dart';
import '../providers/chatbot_provider.dart';
import '../providers/study_plan_provider.dart';

// ── Floating Action Button ─────────────────────────────────────────────────────

class ChatbotFAB extends ConsumerWidget {
  const ChatbotFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(chatbotProvider).isLoading;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ChatbotSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('AI Koç',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
      ),
    );
  }
}

// ── Chat Bottom Sheet ──────────────────────────────────────────────────────────

class ChatbotSheet extends ConsumerStatefulWidget {
  const ChatbotSheet({super.key});

  @override
  ConsumerState<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends ConsumerState<ChatbotSheet> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _showConvList = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    if (ref.read(chatbotProvider).isLoading) return;
    _textCtrl.clear();
    _scrollToBottom();
    final intent = await ref.read(chatbotProvider.notifier).sendMessage(text);
    _scrollToBottom();
    if (intent != null && mounted) {
      final type = intent['type'] as String?;
      if (type == 'add_task') {
        _showAddTaskDialog(intent);
      } else if (type == 'assign_topic') {
        _showAssignTopicDialog(intent);
      } else if (type == 'schedule_update') {
        _showScheduleIntentDialog(intent);
      }
    }
  }

  void _showSnack(String msg, {Color? color}) {
    _messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color ?? AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _onNewConversation() {
    final ok = ref.read(chatbotProvider.notifier).newConversation();
    if (!ok) {
      _showSnack(
        'Sohbet limiti doldu (maks. 3). Yeni sohbet açmak için bir tanesini silin.',
        color: Colors.orange.shade700,
      );
    } else {
      setState(() => _showConvList = false);
      _showSnack('Yeni sohbet açıldı ✨');
    }
  }

  void _showScheduleIntentDialog(Map<String, dynamic> intent) {
    final suggestion =
        intent['suggestion'] as String? ?? 'Ders programını güncelleyeyim mi?';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.auto_fix_high, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Program Güncellemesi'),
        ]),
        content: Text(suggestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hayır, kalsın'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Ders programı güncelleme yakında gelecek! 🚧',
                  color: AppColors.primary);
            },
            child: const Text('Evet, güncelle'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(Map<String, dynamic> intent) {
    final subjectName = intent['subjectName'] as String? ?? 'Ders';
    final taskType = intent['taskType'] as String? ?? 'Çalışma';
    final durationMinutes = intent['durationMinutes'] as int? ?? 60;
    final suggestion = intent['suggestion'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.add_task_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Görev Ekle'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestion.isNotEmpty) ...[
              Text(suggestion,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.book_rounded, label: subjectName),
                  const SizedBox(height: 4),
                  _InfoRow(icon: Icons.assignment_rounded, label: taskType),
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: Icons.timer_rounded,
                      label: '$durationMinutes dakika'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hayır, gerek yok'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final now = DateTime.now();
              final task = StudyTask(
                id: 'manual_${now.millisecondsSinceEpoch}',
                subjectName: subjectName,
                emoji: '📚',
                startTime: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${(now.hour + durationMinutes ~/ 60).toString().padLeft(2, '0')}:${((now.minute + durationMinutes % 60) % 60).toString().padLeft(2, '0')}',
                durationMinutes: durationMinutes,
                taskType: taskType,
                isCompleted: false,
                isMola: false,
                isStrong: false,
                date: DateTime(now.year, now.month, now.day),
              );
              ref.read(manualTasksProvider.notifier).add(task);
              _showSnack('$subjectName görevi eklendi! 📚');
            },
            child: const Text('Evet, ekle'),
          ),
        ],
      ),
    );
  }

  void _showAssignTopicDialog(Map<String, dynamic> intent) {
    final suggestion = intent['suggestion'] as String? ?? '';
    final rawTasks = intent['todayTasks'] as List? ?? [];

    final tasks = rawTasks
        .whereType<Map<String, dynamic>>()
        .where((t) => (t['taskType'] as String?) != 'Mola')
        .toList();

    if (tasks.isEmpty) {
      _showSnack('Bugün konu atanacak görev bulunamadı.',
          color: Colors.orange.shade700);
      return;
    }

    String? selectedTaskId;
    final topicCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.topic_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Konu Ata'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (suggestion.isNotEmpty) ...[
                Text(suggestion,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
              ],
              const Text('Hangi derse konu eklensin?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...tasks.map((t) {
                final id = t['id'] as String;
                final name = t['subjectName'] as String? ?? 'Ders';
                final type = t['taskType'] as String? ?? '';
                final isSelected = selectedTaskId == id;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedTaskId = id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Theme.of(ctx)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              if (type.isNotEmpty)
                                Text(type,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: topicCtrl,
                decoration: InputDecoration(
                  hintText: 'Konu adını yaz...',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final topic = topicCtrl.text.trim();
                if (selectedTaskId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Lütfen bir ders seçin.')));
                  return;
                }
                if (topic.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Lütfen konu adını girin.')));
                  return;
                }
                Navigator.pop(ctx);
                ref
                    .read(topicAssignmentsProvider.notifier)
                    .assign(selectedTaskId!, topic);
                _showSnack('Konu atandı: $topic ✅');
              },
              child: const Text('Konu Ata'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatbotProvider);
    final isLoading = chatState.isLoading;
    final messages = chatState.active?.messages ?? [];
    final conversations = chatState.conversations;
    final activeIdx = chatState.activeIndex;

    if (messages.isNotEmpty) _scrollToBottom();

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Başlık çubuğu ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chatState.active?.title ?? 'AI Koç',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Sohbet ${activeIdx + 1}/${conversations.length}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_comment_rounded,
                            color: Colors.grey),
                        tooltip: 'Yeni sohbet',
                        onPressed: _onNewConversation,
                      ),
                      IconButton(
                        icon: Icon(
                          _showConvList
                              ? Icons.chat_bubble_rounded
                              : Icons.more_vert_rounded,
                          color: AppColors.primary,
                        ),
                        tooltip: _showConvList ? 'Sohbete dön' : 'Sohbetler',
                        onPressed: () =>
                            setState(() => _showConvList = !_showConvList),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── İçerik ──────────────────────────────────────────────────
                Expanded(
                  child: _showConvList
                      ? _ConversationList(
                          conversations: conversations,
                          activeIndex: activeIdx,
                          onSwitch: (i) {
                            ref
                                .read(chatbotProvider.notifier)
                                .switchConversation(i);
                            setState(() => _showConvList = false);
                          },
                          onDelete: (i) => ref
                              .read(chatbotProvider.notifier)
                              .deleteConversation(i),
                          onNew: _onNewConversation,
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          itemCount: messages.length + (isLoading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == messages.length) {
                              return const _TypingIndicator();
                            }
                            return _MessageBubble(message: messages[i]);
                          },
                        ),
                ),

                // ── Input ────────────────────────────────────────────────────
                if (!_showConvList)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        MediaQuery.of(context).viewInsets.bottom + 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                          top:
                              BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText:
                                  'Ders programı, uygulama, motivasyon...',
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: isLoading ? null : _send,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: isLoading
                                      ? [
                                          Colors.grey.shade400,
                                          Colors.grey.shade500
                                        ]
                                      : [
                                          AppColors.primary,
                                          AppColors.primaryDark
                                        ]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info Row yardımcısı ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }
}

// ── Sohbet Listesi ─────────────────────────────────────────────────────────────

class _ConversationList extends ConsumerWidget {
  final List<Conversation> conversations;
  final int activeIndex;
  final void Function(int) onSwitch;
  final void Function(int) onDelete;
  final VoidCallback onNew;

  const _ConversationList({
    required this.conversations,
    required this.activeIndex,
    required this.onSwitch,
    required this.onDelete,
    required this.onNew,
  });

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, int index, String currentTitle) {
    final ctrl = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sohbeti Yeniden Adlandır'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: 'Sohbet adı...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (v) {
            ref.read(chatbotProvider.notifier).renameConversation(index, v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref
                  .read(chatbotProvider.notifier)
                  .renameConversation(index, ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        ...conversations.asMap().entries.map((e) {
          final i = e.key;
          final conv = e.value;
          final isActive = i == activeIndex;
          final lastMsg = conv.messages.lastWhere(
            (m) => m.role == 'user',
            orElse: () => conv.messages.last,
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: ListTile(
              onTap: () => onSwitch(i),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : Theme.of(context).dividerColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              title: Text(
                conv.title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                lastMsg.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.grey, size: 20),
                    tooltip: 'Yeniden adlandır',
                    onPressed: () =>
                        _showRenameDialog(context, ref, i, conv.title),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.grey, size: 20),
                    tooltip: 'Sil',
                    onPressed: () => onDelete(i),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Sohbet Aç'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Mesaj Balonu ───────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : null,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

// ── Yazıyor... Animasyonu ──────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: FadeTransition(
          opacity: _anim,
          child: const Text('Yazıyor...',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ),
      ),
    );
  }
}
