import 'package:flutter/material.dart';

import '../utils/format.dart';

/// Community feed — anonymous, Threads-like vertical feed.
/// Phase 0: local mock posts. Phase 1: backend + moderation.

class CommunityAuthor {
  final String alias;
  final List<Color> gradient;
  const CommunityAuthor({required this.alias, required this.gradient});
}

class CommunityPost {
  final String id;
  final CommunityAuthor author;
  final String text;
  final List<String> tags;
  final String timeLabel;
  final int likes;
  final int replies;
  final bool isSupported; // marked as supportive by community
  final bool liked; // whether the current user liked this post
  const CommunityPost({
    required this.id,
    required this.author,
    required this.text,
    required this.tags,
    required this.timeLabel,
    required this.likes,
    required this.replies,
    this.isSupported = false,
    this.liked = false,
  });

  /// Build from a Supabase `community_posts` row. The feed query selects
  /// `replies:community_replies(count)`, which arrives as `[{count: n}]`.
  factory CommunityPost.fromMap(Map<String, dynamic> m) {
    var replies = (m['replies_count'] as num?)?.toInt() ?? 0;
    final r = m['replies'];
    if (replies == 0 && r is List && r.isNotEmpty && r.first is Map) {
      replies = ((r.first as Map)['count'] as num?)?.toInt() ?? 0;
    } else if (replies == 0 && r is num) {
      replies = r.toInt();
    }
    final alias = (m['author_alias'] ?? 'Аноним') as String;
    return CommunityPost(
      id: m['id'].toString(),
      author: CommunityAuthor(alias: alias, gradient: aliasGradient(alias)),
      text: (m['text'] ?? '') as String,
      tags: ((m['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      timeLabel: relativeRu(
        DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
      ),
      likes: (m['likes_count'] as num?)?.toInt() ?? 0,
      replies: replies,
      isSupported: (m['is_supported'] as bool?) ?? false,
      liked: (m['liked'] as bool?) ?? false,
    );
  }
}

class CommunityReply {
  final String id;
  final CommunityAuthor author;
  final String text;
  final String timeLabel;
  final int likes;
  final bool fromSpecialist;
  final bool liked;
  const CommunityReply({
    required this.id,
    required this.author,
    required this.text,
    required this.timeLabel,
    required this.likes,
    this.fromSpecialist = false,
    this.liked = false,
  });

  factory CommunityReply.fromMap(Map<String, dynamic> m) {
    final alias = (m['author_alias'] ?? 'Аноним') as String;
    return CommunityReply(
      id: '${m['id']}',
      author: CommunityAuthor(alias: alias, gradient: aliasGradient(alias)),
      text: (m['text'] ?? '') as String,
      timeLabel: relativeRu(
        DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
      ),
      likes: (m['likes_count'] as num?)?.toInt() ?? 0,
      fromSpecialist: (m['from_specialist'] as bool?) ?? false,
      liked: (m['liked'] as bool?) ?? false,
    );
  }
}

const _authors = [
  CommunityAuthor(
    alias: 'Тихий ветер',
    gradient: [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
  ),
  CommunityAuthor(
    alias: 'Утренний свет',
    gradient: [Color(0xFFFFB6C1), Color(0xFFFFC8DD)],
  ),
  CommunityAuthor(
    alias: 'Северное озеро',
    gradient: [Color(0xFF93D8B5), Color(0xFFB7E8CC)],
  ),
  CommunityAuthor(
    alias: 'Лесной ручей',
    gradient: [Color(0xFFD4B5F0), Color(0xFFE8D4F5)],
  ),
  CommunityAuthor(
    alias: 'Тёплый дождь',
    gradient: [Color(0xFF7FE0D4), Color(0xFFB0EDE5)],
  ),
  CommunityAuthor(
    alias: 'Песчаный берег',
    gradient: [Color(0xFFF5D78E), Color(0xFFFAE4B2)],
  ),
];

const communityTags = <String>[
  'Все',
  'Тревога',
  'Отношения',
  'Поддержка',
  'Я слушаю',
  'Выгорание',
  'Самооценка',
];

final communityFeed = <CommunityPost>[
  CommunityPost(
    id: 'p1',
    author: _authors[0],
    text:
        'Кажется, я снова не сплю четвёртую ночь подряд. Голова не отключается, прокручиваю один и тот же разговор. Кто-нибудь, расскажите, как вы из этого выходите.',
    tags: const ['Тревога'],
    timeLabel: '6 мин назад',
    likes: 28,
    replies: 12,
  ),
  CommunityPost(
    id: 'p2',
    author: _authors[1],
    text:
        'Сегодня впервые за месяц встала с кровати в 8 утра, заварила чай, открыла окно. Это так мало, но мне важно это записать.',
    tags: const ['Поддержка', 'Самооценка'],
    timeLabel: '14 мин назад',
    likes: 142,
    replies: 31,
    isSupported: true,
  ),
  CommunityPost(
    id: 'p3',
    author: _authors[2],
    text:
        'Я тут, если кому-то нужно просто чтобы выслушали. Без советов, без обесценивания. Пишите.',
    tags: const ['Я слушаю'],
    timeLabel: '38 мин назад',
    likes: 89,
    replies: 17,
  ),
  CommunityPost(
    id: 'p4',
    author: _authors[3],
    text:
        'Мы расстались месяц назад, и я всё ещё ловлю себя на том, что хочу написать. Не пишу. Но каждый раз больно по-новому.',
    tags: const ['Отношения'],
    timeLabel: '1 ч назад',
    likes: 64,
    replies: 22,
  ),
  CommunityPost(
    id: 'p5',
    author: _authors[4],
    text:
        'Я работаю 12 часов в день и не помню, когда последний раз ела по-нормальному. Понимаю, что это плохо, но остановиться сейчас — значит всё провалить.',
    tags: const ['Выгорание'],
    timeLabel: '2 ч назад',
    likes: 47,
    replies: 19,
  ),
  CommunityPost(
    id: 'p6',
    author: _authors[5],
    text:
        'Маленький лайфхак: когда тревога нарастает — холодная вода на запястья, 30 секунд. Не отключает, но даёт паузу.',
    tags: const ['Тревога', 'Поддержка'],
    timeLabel: '4 ч назад',
    likes: 211,
    replies: 28,
    isSupported: true,
  ),
];

final List<CommunityReply> communitySampleReplies = [
  CommunityReply(
    id: 'r1',
    author: _authors[2],
    text:
        'Меня выручает 4-7-8 дыхание перед сном. Вдох на 4, задержка на 7, выдох на 8. Через 3–4 цикла мозг отпускает.',
    timeLabel: '4 мин назад',
    likes: 18,
  ),
  CommunityReply(
    id: 'r2',
    author: _authors[5],
    text: 'Обнимаю. Я через это прошла. Главное — что вы это пишете, а не молчите.',
    timeLabel: '3 мин назад',
    likes: 24,
  ),
  CommunityReply(
    id: 'r3',
    author: _authors[1],
    text:
        'Если такие ночи повторяются больше двух недель — это уже не "просто тревога", это сигнал. Айгуль С. в каталоге работает именно с этим.',
    timeLabel: '2 мин назад',
    likes: 9,
    fromSpecialist: true,
  ),
];
