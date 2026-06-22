import 'package:flutter/material.dart';

import '../utils/format.dart';

/// Psychologist profile. Phase 0 keeps these locally; Phase 1 moves to backend.
class Specialist {
  final String id;
  final String firstName;
  final String lastName;
  final String title;
  final int yearsExperience;
  final List<String> languages;
  final List<String> approaches;
  final List<String> worksWith;
  final int sessionPriceKzt;
  final double rating;
  final int reviewCount;
  final String about;
  final List<Education> education;
  final List<String> diplomas; // diploma image placeholder labels
  final List<Review> reviews;
  final List<String> availableDates; // ISO yyyy-MM-dd
  final List<String> availableSlots; // HH:mm

  /// Soft gradient palette for placeholder avatar.
  final List<Color> avatarGradient;

  /// Moderation status: a self-registered psychologist is hidden from clients
  /// until an admin verifies their documents. Mock/demo specialists are verified.
  final bool isVerified;

  /// Weekly availability the psychologist sets: ISO weekday (1=Mon … 7=Sun) →
  /// sorted list of "HH:mm" start times.
  final Map<int, List<String>> availability;

  /// "Доступен сейчас" — ready for an instant ("поговорить сейчас") session.
  /// Server-computed (accepts_instant + verified + not expired).
  final bool instantAvailable;

  /// Whether the signed-in user has this specialist in their favorites
  /// (only populated by the detail endpoint).
  final bool isFavorite;

  const Specialist({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.yearsExperience,
    required this.languages,
    required this.approaches,
    required this.worksWith,
    required this.sessionPriceKzt,
    required this.rating,
    required this.reviewCount,
    required this.about,
    required this.education,
    required this.diplomas,
    required this.reviews,
    required this.availableDates,
    required this.availableSlots,
    required this.avatarGradient,
    this.isVerified = true,
    this.availability = const {},
    this.instantAvailable = false,
    this.isFavorite = false,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.characters.first}${lastName.characters.first}';

  /// Build from a Supabase `specialists` row (optionally with nested
  /// `reviews(*)` and `education(*)`).
  factory Specialist.fromMap(Map<String, dynamic> m) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    // DRF can serialize numbers as strings (DecimalField -> "4.9"), so parse
    // defensively: a single bad cast must never crash us into the mock catalog.
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final grad = strList(m['avatar_gradient']);
    return Specialist(
      id: m['id'].toString(),
      firstName: (m['first_name'] ?? '') as String,
      lastName: (m['last_name'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      yearsExperience: toInt(m['years_experience']),
      languages: strList(m['languages']),
      approaches: strList(m['approaches']),
      worksWith: strList(m['works_with']),
      sessionPriceKzt: toInt(m['session_price_kzt']),
      rating: toDouble(m['rating']),
      reviewCount: toInt(m['review_count']),
      about: (m['about'] ?? '') as String,
      education: ((m['education'] as List?) ?? const [])
          .map((e) => Education.fromMap(e as Map<String, dynamic>))
          .toList(),
      diplomas: strList(m['diplomas']),
      reviews: ((m['reviews'] as List?) ?? const [])
          .map((e) => Review.fromMap(e as Map<String, dynamic>))
          .toList(),
      availableDates: const [],
      availableSlots: _defaultSlots,
      avatarGradient: grad.length >= 2
          ? grad.map(hexToColor).toList()
          : const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
      isVerified: (m['is_verified'] as bool?) ?? false,
      availability: _parseAvailability(m['availability']),
      instantAvailable: (m['instant_available'] as bool?) ?? false,
      isFavorite: (m['is_favorite'] as bool?) ?? false,
    );
  }

  static Map<int, List<String>> _parseAvailability(dynamic v) {
    if (v is! Map) return const {};
    final out = <int, List<String>>{};
    v.forEach((key, val) {
      final day = int.tryParse('$key');
      if (day == null || val is! List) return;
      final slots = val.map((e) => e.toString()).toList()..sort();
      out[day] = slots;
    });
    return out;
  }
}

class Education {
  final String institution;
  final String degree;
  final String years;
  const Education({
    required this.institution,
    required this.degree,
    required this.years,
  });

  factory Education.fromMap(Map<String, dynamic> m) => Education(
        institution: (m['institution'] ?? '') as String,
        degree: (m['degree'] ?? '') as String,
        years: (m['years'] ?? '') as String,
      );
}

class Review {
  final String authorAlias; // anonymized
  final int rating;
  final String text;
  final String dateLabel;
  const Review({
    required this.authorAlias,
    required this.rating,
    required this.text,
    required this.dateLabel,
  });

  factory Review.fromMap(Map<String, dynamic> m) => Review(
        authorAlias: (m['author_alias'] ?? 'Аноним') as String,
        rating: (m['rating'] as num?)?.toInt() ?? 5,
        text: (m['text'] ?? '') as String,
        dateLabel: relativeRu(
          DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
        ),
      );
}

const _defaultSlots = [
  '10:00',
  '12:00',
  '14:00',
  '16:00',
  '18:00',
  '20:00',
];

final specialistCatalog = <Specialist>[
  Specialist(
    id: 'aigul',
    firstName: 'Айгуль',
    lastName: 'С.',
    title: 'Клинический психолог',
    yearsExperience: 9,
    languages: ['Қазақша', 'Русский', 'English'],
    approaches: ['КПТ', 'Схема-терапия'],
    worksWith: ['Тревога', 'Самооценка', 'Отношения'],
    sessionPriceKzt: 18000,
    rating: 4.9,
    reviewCount: 142,
    about:
        'Помогаю взрослым справиться с тревожностью и стрессом. Работаю в когнитивно-поведенческом подходе. Верю, что психотерапия — это совместная работа, в которой клиент учится видеть себя по-новому.',
    education: const [
      Education(
        institution: 'КазНУ им. аль-Фараби',
        degree: 'Магистр психологии',
        years: '2012–2014',
      ),
      Education(
        institution: 'Beck Institute for CBT',
        degree: 'Сертификация по КПТ',
        years: '2017',
      ),
    ],
    diplomas: const ['Магистр КазНУ', 'CBT Beck Institute', 'Схема-терапия ISST'],
    reviews: const [
      Review(
        authorAlias: 'Анонимно · 24 года',
        rating: 5,
        text:
            'После 4 сессий стало гораздо легче засыпать. Айгуль аккуратно работает с тревогой, не давит.',
        dateLabel: '2 недели назад',
      ),
      Review(
        authorAlias: 'Анонимно · 31 год',
        rating: 5,
        text:
            'Очень внимательная. Помогла разобраться с отношениями в семье. Рекомендую.',
        dateLabel: 'месяц назад',
      ),
      Review(
        authorAlias: 'Анонимно · 28 лет',
        rating: 4,
        text:
            'Профессионально. Подача спокойная, без оценок. Жду продолжения работы.',
        dateLabel: '2 месяца назад',
      ),
    ],
    availableDates: const [],
    availableSlots: _defaultSlots,
    avatarGradient: const [Color(0xFFFFB6C1), Color(0xFFFFC8DD)],
  ),
  Specialist(
    id: 'arman',
    firstName: 'Арман',
    lastName: 'Б.',
    title: 'Психотерапевт',
    yearsExperience: 12,
    languages: ['Русский', 'Қазақша'],
    approaches: ['Гештальт', 'EMDR'],
    worksWith: ['Травма', 'ПТСР', 'Утрата'],
    sessionPriceKzt: 22000,
    rating: 4.8,
    reviewCount: 98,
    about:
        'Специализируюсь на работе с травматическим опытом и переживанием утраты. EMDR-сертифицированный специалист. Работаю бережно, в комфортном для клиента темпе.',
    education: const [
      Education(
        institution: 'МГУ им. Ломоносова',
        degree: 'Клиническая психология',
        years: '2008–2013',
      ),
      Education(
        institution: 'EMDR Europe',
        degree: 'Базовый и продвинутый курс EMDR',
        years: '2018–2020',
      ),
    ],
    diplomas: const ['МГУ', 'EMDR Europe', 'Гештальт МГИ'],
    reviews: const [
      Review(
        authorAlias: 'Анонимно · 36 лет',
        rating: 5,
        text:
            'Помог пережить потерю близкого. Без EMDR я бы ещё долго не справился.',
        dateLabel: 'месяц назад',
      ),
      Review(
        authorAlias: 'Анонимно · 29 лет',
        rating: 5,
        text:
            'Очень глубокий специалист. Не торопит, видно опыт.',
        dateLabel: '3 недели назад',
      ),
    ],
    availableDates: const [],
    availableSlots: _defaultSlots,
    avatarGradient: const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
  ),
  Specialist(
    id: 'dana',
    firstName: 'Дана',
    lastName: 'К.',
    title: 'Семейный психолог',
    yearsExperience: 7,
    languages: ['Русский', 'English'],
    approaches: ['Системная терапия'],
    worksWith: ['Семья', 'Пары', 'Развод'],
    sessionPriceKzt: 20000,
    rating: 4.9,
    reviewCount: 167,
    about:
        'Работаю с парами и семьями. Помогаю восстановить контакт, наладить общение, пройти через кризисы и расставания.',
    education: const [
      Education(
        institution: 'КазГУ',
        degree: 'Семейная психология',
        years: '2013–2017',
      ),
      Education(
        institution: 'Институт Bowen Center',
        degree: 'Системная семейная терапия',
        years: '2019',
      ),
    ],
    diplomas: const ['КазГУ', 'Bowen Center'],
    reviews: const [
      Review(
        authorAlias: 'Анонимно · пара',
        rating: 5,
        text:
            'Дана спасла наш брак. Без её работы мы бы развелись. 6 сессий — и мы научились разговаривать.',
        dateLabel: '3 недели назад',
      ),
      Review(
        authorAlias: 'Анонимно · 34 года',
        rating: 5,
        text:
            'Спокойная, очень тактичная. Не принимает чью-то сторону.',
        dateLabel: 'месяц назад',
      ),
      Review(
        authorAlias: 'Анонимно · 41 год',
        rating: 4,
        text:
            'Профессионально и по делу. Помогло прийти к решению о расставании без боли.',
        dateLabel: '2 месяца назад',
      ),
    ],
    availableDates: const [],
    availableSlots: _defaultSlots,
    avatarGradient: const [Color(0xFFD4B5F0), Color(0xFFE8D4F5)],
  ),
  Specialist(
    id: 'nurlan',
    firstName: 'Нурлан',
    lastName: 'Ж.',
    title: 'Психолог · подростки',
    yearsExperience: 6,
    languages: ['Қазақша', 'Русский'],
    approaches: ['КПТ', 'Игровая терапия'],
    worksWith: ['Подростки', 'Школа', 'Родители'],
    sessionPriceKzt: 15000,
    rating: 4.7,
    reviewCount: 81,
    about:
        'Работаю с подростками 12–18 лет и их родителями. Школьная тревога, конфликты, самооценка, сложности с учёбой.',
    education: const [
      Education(
        institution: 'КазНПУ',
        degree: 'Детская и подростковая психология',
        years: '2014–2018',
      ),
    ],
    diplomas: const ['КазНПУ'],
    reviews: const [
      Review(
        authorAlias: 'Анонимно · мама',
        rating: 5,
        text:
            'Дочь подружилась с Нурланом, ходит сама с удовольствием. Школьная тревога ушла.',
        dateLabel: '2 недели назад',
      ),
      Review(
        authorAlias: 'Анонимно · 16 лет',
        rating: 4,
        text: 'Прикольный, говорит на одном языке со мной.',
        dateLabel: 'месяц назад',
      ),
    ],
    availableDates: const [],
    availableSlots: _defaultSlots,
    avatarGradient: const [Color(0xFF93D8B5), Color(0xFFB7E8CC)],
  ),
  Specialist(
    id: 'kamila',
    firstName: 'Камила',
    lastName: 'И.',
    title: 'Психолог · карьера',
    yearsExperience: 5,
    languages: ['Русский', 'English'],
    approaches: ['КПТ', 'ACT'],
    worksWith: ['Тревога', 'Прокрастинация', 'Выгорание'],
    sessionPriceKzt: 16000,
    rating: 4.8,
    reviewCount: 64,
    about:
        'Помогаю взрослым справиться с выгоранием, тревожностью и трудностями в карьере. Работаю с IT-специалистами, основателями, менеджерами.',
    education: const [
      Education(
        institution: 'НИУ ВШЭ',
        degree: 'Психология личности',
        years: '2015–2019',
      ),
      Education(
        institution: 'ACBS',
        degree: 'ACT-практик',
        years: '2021',
      ),
    ],
    diplomas: const ['ВШЭ', 'ACBS ACT'],
    reviews: const [
      Review(
        authorAlias: 'Анонимно · СТО',
        rating: 5,
        text:
            'Помогла выйти из выгорания за 8 сессий. Конкретные техники, никакой воды.',
        dateLabel: 'неделю назад',
      ),
      Review(
        authorAlias: 'Анонимно · 27 лет',
        rating: 5,
        text:
            'Прокрастинация ушла, появилась структура в работе. Очень благодарна.',
        dateLabel: 'месяц назад',
      ),
    ],
    availableDates: const [],
    availableSlots: _defaultSlots,
    avatarGradient: const [Color(0xFF7FE0D4), Color(0xFFB0EDE5)],
  ),
];

extension SpecialistById on List<Specialist> {
  Specialist byId(String id) => firstWhere((s) => s.id == id);
}
