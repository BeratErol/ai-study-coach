import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'study_plan_provider.dart';

const _maxConversations = 3;
const _welcomeText =
    'Merhaba! Ben senin AI koçunum 🎓 Ders programın, uygulama özellikleri veya çalışma stratejin hakkında her şeyi sorabilirsin!';

// Tek bir konuşma
class Conversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
  });

  Conversation copyWith({String? title, List<ChatMessage>? messages}) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  // Karşılama mesajı ile yeni boş sohbet
  static Conversation fresh(String id) => Conversation(
        id: id,
        title: 'Yeni Sohbet',
        messages: [
          ChatMessage(role: 'model', content: _welcomeText, time: DateTime.now()),
        ],
      );
}

class ChatbotState {
  final List<Conversation> conversations;
  final int activeIndex;
  final bool isLoading;

  const ChatbotState({
    this.conversations = const [],
    this.activeIndex = 0,
    this.isLoading = false,
  });

  Conversation? get active =>
      conversations.isEmpty ? null : conversations[activeIndex];

  ChatbotState copyWith({
    List<Conversation>? conversations,
    int? activeIndex,
    bool? isLoading,
  }) =>
      ChatbotState(
        conversations: conversations ?? this.conversations,
        activeIndex: activeIndex ?? this.activeIndex,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final Ref _ref;
  String? _userId;

  ChatbotNotifier(this._ref) : super(const ChatbotState()) {
    _init();
  }

  static String _prefsKey(String userId) => 'chatbot_conversations_$userId';

  Future<void> _init() async {
    _userId = await TokenService.getUserId();
    if (_userId == null) {
      state = ChatbotState(
        conversations: [Conversation.fresh('conv_0')],
        activeIndex: 0,
      );
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(_userId!));
    if (raw == null) {
      state = ChatbotState(
        conversations: [Conversation.fresh('conv_${DateTime.now().millisecondsSinceEpoch}')],
        activeIndex: 0,
      );
      return;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
      state = ChatbotState(
        conversations: list.isEmpty
            ? [Conversation.fresh('conv_${DateTime.now().millisecondsSinceEpoch}')]
            : list,
        activeIndex: 0,
      );
    } catch (_) {
      state = ChatbotState(
        conversations: [Conversation.fresh('conv_${DateTime.now().millisecondsSinceEpoch}')],
        activeIndex: 0,
      );
    }
  }

  Future<void> _save() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(state.conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_prefsKey(_userId!), raw);
  }

  void _updateActive(Conversation updated) {
    final convs = [...state.conversations];
    convs[state.activeIndex] = updated;
    state = state.copyWith(conversations: convs);
  }

  // Yeni sohbet aç — max 3 kontrolü
  // true döner = başarılı, false = limit doldu
  bool newConversation() {
    if (state.conversations.length >= _maxConversations) return false;
    final conv = Conversation.fresh('conv_${DateTime.now().millisecondsSinceEpoch}');
    final convs = [...state.conversations, conv];
    state = state.copyWith(
      conversations: convs,
      activeIndex: convs.length - 1,
    );
    _save();
    return true;
  }

  void switchConversation(int index) {
    if (index < 0 || index >= state.conversations.length) return;
    state = state.copyWith(activeIndex: index);
  }

  void renameConversation(int index, String newTitle) {
    if (index < 0 || index >= state.conversations.length) return;
    final convs = [...state.conversations];
    convs[index] = convs[index].copyWith(title: newTitle.trim().isEmpty ? 'Sohbet ${index + 1}' : newTitle.trim());
    state = state.copyWith(conversations: convs);
    _save();
  }

  void deleteConversation(int index) {
    if (state.conversations.length <= 1) {
      // Son sohbeti silmek yerine sıfırla
      final fresh = Conversation.fresh('conv_${DateTime.now().millisecondsSinceEpoch}');
      state = ChatbotState(conversations: [fresh], activeIndex: 0);
    } else {
      final convs = [...state.conversations]..removeAt(index);
      final newIdx = (state.activeIndex >= convs.length)
          ? convs.length - 1
          : state.activeIndex;
      state = state.copyWith(conversations: convs, activeIndex: newIdx);
    }
    _save();
  }

  Future<Map<String, dynamic>?> sendMessage(String text) async {
    if (text.trim().isEmpty || state.active == null) return null;

    final userMsg = ChatMessage(role: 'user', content: text, time: DateTime.now());
    final currentConv = state.active!;

    // Başlığı ilk kullanıcı mesajından belirle
    final title = currentConv.messages.any((m) => m.role == 'user')
        ? currentConv.title
        : (text.length > 24 ? '${text.substring(0, 24)}…' : text);

    final newMessages = [...currentConv.messages, userMsg];
    _updateActive(currentConv.copyWith(title: title, messages: newMessages));
    state = state.copyWith(isLoading: true);

    try {
      final onboarding = await _ref.read(onboardingDataProvider.future);

      // İlk model mesajını (karşılama) backend'e gönderme
      final historyToSend = newMessages.where((m) =>
          !(m.role == 'model' && m.content == _welcomeText)).toList();

      // Son 6 mesajla sınırla
      final limited = historyToSend.length > 6
          ? historyToSend.sublist(historyToSend.length - 6)
          : historyToSend;

      // Bugünkü görevleri payload'a ekle
      final todayPlan = await _ref.read(studyPlanProvider.future);
      final today = DateTime.now();
      final todayDay = todayPlan.firstWhere(
        (d) => d.date.year == today.year && d.date.month == today.month && d.date.day == today.day,
        orElse: () => todayPlan.isNotEmpty ? todayPlan.first : throw Exception('no plan'),
      );
      final todayTasks = todayDay.blocks
          .where((b) => !b.isMola)
          .map((b) => {
                'id': b.id,
                'subjectName': b.subjectName,
                'taskType': b.taskType,
                'durationMinutes': b.durationMinutes,
                'startTime': '${b.startTime.hour.toString().padLeft(2, '0')}:${b.startTime.minute.toString().padLeft(2, '0')}',
                'endTime': '${b.endTime.hour.toString().padLeft(2, '0')}:${b.endTime.minute.toString().padLeft(2, '0')}',
              })
          .toList();

      final payload = {
        'messages': limited
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        'userName': onboarding?.name,
        'targetExam': onboarding?.targetExam,
        'selectedArea': onboarding?.selectedArea,
        'weakLessons': onboarding?.weakSubjects ?? [],
        'strongLessons': onboarding?.strongSubjects ?? [],
        'todayTasks': todayTasks,
      };

      final res = await ApiService().dio.post('/Ai/chat', data: payload);
      final data = res.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? '...';

      final modelMsg = ChatMessage(role: 'model', content: message, time: DateTime.now());
      final conv = state.active!;
      _updateActive(conv.copyWith(messages: [...conv.messages, modelMsg]));
      state = state.copyWith(isLoading: false);
      await _save();

      // Hangi intent döndü?
      if (data['addTaskIntent'] != null) {
        return {'type': 'add_task', ...data['addTaskIntent'] as Map<String, dynamic>};
      }
      if (data['assignTopicIntent'] != null) {
        return {'type': 'assign_topic', 'todayTasks': todayTasks, ...data['assignTopicIntent'] as Map<String, dynamic>};
      }
      if (data['scheduleIntent'] != null) {
        return {'type': 'schedule_update', ...data['scheduleIntent'] as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      debugPrint('[ChatbotProvider] sendMessage error: $e');
      final errMsg = ChatMessage(
        role: 'model',
        content: 'Şu an yanıt veremiyorum, biraz sonra tekrar dene. 🙏',
        time: DateTime.now(),
      );
      final conv = state.active!;
      _updateActive(conv.copyWith(messages: [...conv.messages, errMsg]));
      state = state.copyWith(isLoading: false);
      await _save();
      return null;
    }
  }
}

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier(ref);
});
