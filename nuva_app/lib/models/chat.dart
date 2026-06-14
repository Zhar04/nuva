/// Phase-0 in-app chat. All data local. Phase 1 = realtime via Supabase / Firestore.

enum MsgSender { user, specialist, system }

class Message {
  final String id;
  final MsgSender sender;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isVoice;
  final int? voiceSeconds;
  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.isRead = true,
    this.isVoice = false,
    this.voiceSeconds,
  });
}

class Chat {
  final String id;
  final String specialistId;
  final List<Message> messages;
  final bool specialistOnline;
  final DateTime? nextSessionAt;
  const Chat({
    required this.id,
    required this.specialistId,
    required this.messages,
    required this.specialistOnline,
    this.nextSessionAt,
  });

  Message? get lastMessage => messages.isEmpty ? null : messages.last;
  int get unreadCount =>
      messages.where((m) => !m.isRead && m.sender == MsgSender.specialist).length;
}

DateTime _ago(Duration d) => DateTime.now().subtract(d);

final mockChats = <Chat>[
  Chat(
    id: 'c1',
    specialistId: 'aigul',
    specialistOnline: true,
    nextSessionAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
    messages: [
      Message(
        id: 'm1',
        sender: MsgSender.system,
        text:
            'Это защищённый чат. Сообщения шифруются. Делиться номерами и контактами вне Nuva нельзя — это нарушение правил платформы.',
        sentAt: _ago(const Duration(days: 3)),
      ),
      Message(
        id: 'm2',
        sender: MsgSender.specialist,
        text:
            'Здравствуйте! Я Айгуль. Получила вашу заявку — спасибо, что пришли. Скажите, как мне удобнее к вам обращаться?',
        sentAt: _ago(const Duration(days: 3, hours: -1)),
      ),
      Message(
        id: 'm3',
        sender: MsgSender.user,
        text: 'Можно на «ты». Я Алия. Немного нервничаю — это моя первая сессия.',
        sentAt: _ago(const Duration(days: 3, hours: -1, minutes: -22)),
      ),
      Message(
        id: 'm4',
        sender: MsgSender.specialist,
        text:
            'Алия, это абсолютно нормально. Мы пойдём в вашем темпе. Перед первой встречей расскажете, что привело вас сюда — буквально пара фраз, как удобно.',
        sentAt: _ago(const Duration(days: 3, hours: -2)),
      ),
      Message(
        id: 'm5',
        sender: MsgSender.user,
        text:
            'Последний месяц очень тяжело засыпать. Думаю о работе ночами, утром встаю разбитой. Хочется выдохнуть.',
        sentAt: _ago(const Duration(days: 1, hours: 5)),
      ),
      Message(
        id: 'm6',
        sender: MsgSender.specialist,
        text:
            'Понимаю. Сегодня перед сном попробуйте короткое упражнение «4-7-8»: вдох на 4, задержка на 7, выдох на 8. Сделайте 4 цикла. На сессии разберём, что именно вас держит в напряжении ночью.',
        sentAt: _ago(const Duration(days: 1, hours: 4)),
      ),
      Message(
        id: 'm7',
        sender: MsgSender.specialist,
        text: 'Жду нашу встречу завтра в 14:00. Если что-то изменится — напишите здесь.',
        sentAt: _ago(const Duration(hours: 6)),
        isRead: false,
      ),
    ],
  ),
  Chat(
    id: 'c2',
    specialistId: 'arman',
    specialistOnline: false,
    nextSessionAt: null,
    messages: [
      Message(
        id: 'm1',
        sender: MsgSender.system,
        text: 'Чат с Арман Б. Сессия не назначена.',
        sentAt: _ago(const Duration(days: 10)),
      ),
      Message(
        id: 'm2',
        sender: MsgSender.specialist,
        text:
            'Спасибо за работу на прошлой сессии. Между встречами ведите дневник по схеме: что почувствовал → когда → что предшествовало.',
        sentAt: _ago(const Duration(days: 5)),
      ),
      Message(
        id: 'm3',
        sender: MsgSender.user,
        text: 'Хорошо, попробую. Запишу за неделю.',
        sentAt: _ago(const Duration(days: 5, hours: -1)),
      ),
    ],
  ),
];
