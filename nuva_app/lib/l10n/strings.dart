import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLang { ru, kk, en }

extension AppLangX on AppLang {
  String get code => switch (this) {
        AppLang.ru => 'RU',
        AppLang.kk => 'KZ',
        AppLang.en => 'EN',
      };
  Locale get locale => switch (this) {
        AppLang.ru => const Locale('ru'),
        AppLang.kk => const Locale('kk'),
        AppLang.en => const Locale('en'),
      };
}

final langProvider = StateProvider<AppLang>((_) => AppLang.ru);

class S {
  final AppLang lang;
  const S(this.lang);

  static S of(WidgetRef ref) => S(ref.watch(langProvider));

  String _pick(Map<AppLang, String> m) => m[lang] ?? m[AppLang.ru]!;

  // Brand
  String get brandTagline => _pick({
        AppLang.ru: 'Вы не одни.',
        AppLang.kk: 'Сіз жалғыз емессіз.',
        AppLang.en: 'You are not alone.',
      });

  // Onboarding
  String get obTitle1 => _pick({
        AppLang.ru: 'Найдите подходящего специалиста',
        AppLang.kk: 'Өзіңізге сәйкес маманды табыңыз',
        AppLang.en: 'Find the right specialist',
      });
  String get obSub1 => _pick({
        AppLang.ru: 'На вашем языке, когда захочется поговорить.',
        AppLang.kk: 'Сізге ыңғайлы тілде, керек кезде.',
        AppLang.en: 'In your language, when you want to talk.',
      });
  String get obTitle2 => _pick({
        AppLang.ru: 'ИИ-помощник на старте',
        AppLang.kk: 'Бастапқы ЖИ-көмекші',
        AppLang.en: 'AI helper to get started',
      });
  String get obSub2 => _pick({
        AppLang.ru: 'Короткий разговор — и мы подберём психолога.',
        AppLang.kk: 'Қысқа сұхбат — біз психолог таңдаймыз.',
        AppLang.en: 'A short chat — and we match a psychologist.',
      });
  String get obTitle3 => _pick({
        AppLang.ru: 'Конфиденциально и анонимно',
        AppLang.kk: 'Құпия және анонимді',
        AppLang.en: 'Confidential and anonymous',
      });
  String get obSub3 => _pick({
        AppLang.ru: 'Вы решаете, чем делиться.',
        AppLang.kk: 'Не айтуды өзіңіз шешесіз.',
        AppLang.en: 'You decide what to share.',
      });

  String get start => _pick({
        AppLang.ru: 'Начать',
        AppLang.kk: 'Бастау',
        AppLang.en: 'Start',
      });
  String get haveAccount => _pick({
        AppLang.ru: 'У меня уже есть аккаунт',
        AppLang.kk: 'Менде аккаунт бар',
        AppLang.en: 'I already have an account',
      });
  String get skip => _pick({
        AppLang.ru: 'Пропустить',
        AppLang.kk: 'Өткізіп жіберу',
        AppLang.en: 'Skip',
      });
  String get next => _pick({
        AppLang.ru: 'Далее',
        AppLang.kk: 'Әрі қарай',
        AppLang.en: 'Next',
      });

  // Intake chat
  String get intakeTitle => _pick({
        AppLang.ru: 'Подбор специалиста',
        AppLang.kk: 'Маман таңдау',
        AppLang.en: 'Find a specialist',
      });
  String get intakeFirstMessage => _pick({
        AppLang.ru:
            'Здравствуйте. Я помогу найти подходящего специалиста. Что вас тревожит прямо сейчас?',
        AppLang.kk:
            'Сәлеметсіз бе. Маман таңдауға көмектесемін. Қазір не алаңдатады?',
        AppLang.en:
            'Hello. I will help you find the right specialist. What is troubling you right now?',
      });
  String get inputHint => _pick({
        AppLang.ru: 'Напишите сообщение…',
        AppLang.kk: 'Хабар жазыңыз…',
        AppLang.en: 'Type a message…',
      });

  // Home
  String get homeHello => _pick({
        AppLang.ru: 'Здравствуйте',
        AppLang.kk: 'Сәлеметсіз бе',
        AppLang.en: 'Hello',
      });
  String get homeQuestion => _pick({
        AppLang.ru: 'Как вы себя чувствуете сегодня?',
        AppLang.kk: 'Бүгін өзіңізді қалай сезінесіз?',
        AppLang.en: 'How are you feeling today?',
      });
  String get findSpecialist => _pick({
        AppLang.ru: 'Найти специалиста',
        AppLang.kk: 'Маман табу',
        AppLang.en: 'Find a specialist',
      });
  String get aiHelp => _pick({
        AppLang.ru: 'Чат с ИИ',
        AppLang.kk: 'ЖИ-чат',
        AppLang.en: 'AI chat',
      });
  String get calm => _pick({
        AppLang.ru: 'Успокоиться',
        AppLang.kk: 'Тыныштану',
        AppLang.en: 'Calm down',
      });
  String get calmSub => _pick({
        AppLang.ru: 'Дыхание и звуки',
        AppLang.kk: 'Тыныс және дыбыс',
        AppLang.en: 'Breath & sounds',
      });
  String get community => _pick({
        AppLang.ru: 'Сообщество',
        AppLang.kk: 'Қоғам',
        AppLang.en: 'Community',
      });
  String get communitySub => _pick({
        AppLang.ru: 'Анонимная поддержка',
        AppLang.kk: 'Анонимді қолдау',
        AppLang.en: 'Anonymous support',
      });
  String get needHelpNow => _pick({
        AppLang.ru: 'Нужна помощь сейчас?',
        AppLang.kk: 'Дәл қазір көмек керек пе?',
        AppLang.en: 'Need help right now?',
      });

  // Specialists
  String get specialists => _pick({
        AppLang.ru: 'Специалисты',
        AppLang.kk: 'Мамандар',
        AppLang.en: 'Specialists',
      });
  String get yearsExp => _pick({
        AppLang.ru: 'лет опыта',
        AppLang.kk: 'жыл тәжірибе',
        AppLang.en: 'yrs exp',
      });
  String get sessionFrom => _pick({
        AppLang.ru: 'Сессия от',
        AppLang.kk: 'Сессия',
        AppLang.en: 'Session from',
      });
  String get about => _pick({
        AppLang.ru: 'О специалисте',
        AppLang.kk: 'Маман туралы',
        AppLang.en: 'About',
      });
  String get works => _pick({
        AppLang.ru: 'Работает с',
        AppLang.kk: 'Жұмыс істейді',
        AppLang.en: 'Works with',
      });
  String get education => _pick({
        AppLang.ru: 'Образование',
        AppLang.kk: 'Білімі',
        AppLang.en: 'Education',
      });
  String get diplomas => _pick({
        AppLang.ru: 'Дипломы и сертификаты',
        AppLang.kk: 'Дипломдар мен сертификаттар',
        AppLang.en: 'Diplomas & certifications',
      });
  String get reviews => _pick({
        AppLang.ru: 'Отзывы',
        AppLang.kk: 'Пікірлер',
        AppLang.en: 'Reviews',
      });
  String get allReviews => _pick({
        AppLang.ru: 'Все отзывы',
        AppLang.kk: 'Барлық пікірлер',
        AppLang.en: 'All reviews',
      });
  String get verified => _pick({
        AppLang.ru: 'Верифицирован Nuva',
        AppLang.kk: 'Nuva-мен расталған',
        AppLang.en: 'Verified by Nuva',
      });
  String get nuvaGuarantee => _pick({
        AppLang.ru: 'Гарантия Nuva',
        AppLang.kk: 'Nuva кепілдігі',
        AppLang.en: 'Nuva guarantee',
      });
  String get guarantee1 => _pick({
        AppLang.ru: 'Бесплатная замена специалиста после первой сессии',
        AppLang.kk: 'Бірінші сессиядан кейін маманды тегін ауыстыру',
        AppLang.en: 'Free specialist replacement after the first session',
      });
  String get guarantee2 => _pick({
        AppLang.ru: 'Возврат денег, если сессия не состоялась',
        AppLang.kk: 'Сессия өтпесе ақшаны қайтару',
        AppLang.en: 'Refund if the session did not happen',
      });
  String get guarantee3 => _pick({
        AppLang.ru: 'Все данные защищены и не передаются третьим лицам',
        AppLang.kk: 'Барлық деректер қорғалған',
        AppLang.en: 'All data is encrypted and never shared',
      });

  // Booking
  String get book => _pick({
        AppLang.ru: 'Записаться',
        AppLang.kk: 'Жазылу',
        AppLang.en: 'Book',
      });
  String get bookSession => _pick({
        AppLang.ru: 'Записаться на сессию',
        AppLang.kk: 'Сессияға жазылу',
        AppLang.en: 'Book a session',
      });
  String get pickDate => _pick({
        AppLang.ru: 'Выберите дату',
        AppLang.kk: 'Күнді таңдаңыз',
        AppLang.en: 'Pick a date',
      });
  String get pickTime => _pick({
        AppLang.ru: 'Выберите время',
        AppLang.kk: 'Уақытты таңдаңыз',
        AppLang.en: 'Pick a time',
      });
  String get format => _pick({
        AppLang.ru: 'Формат',
        AppLang.kk: 'Формат',
        AppLang.en: 'Format',
      });
  String get video => _pick({
        AppLang.ru: 'Видео',
        AppLang.kk: 'Бейне',
        AppLang.en: 'Video',
      });
  String get audio => _pick({
        AppLang.ru: 'Аудио',
        AppLang.kk: 'Аудио',
        AppLang.en: 'Audio',
      });
  String get chat => _pick({
        AppLang.ru: 'Чат',
        AppLang.kk: 'Чат',
        AppLang.en: 'Chat',
      });
  String get duration50 => _pick({
        AppLang.ru: '50 минут',
        AppLang.kk: '50 минут',
        AppLang.en: '50 min',
      });
  String get continueTo => _pick({
        AppLang.ru: 'Продолжить',
        AppLang.kk: 'Жалғастыру',
        AppLang.en: 'Continue',
      });

  // Payment
  String get payment => _pick({
        AppLang.ru: 'Оплата',
        AppLang.kk: 'Төлем',
        AppLang.en: 'Payment',
      });
  String get paymentMethod => _pick({
        AppLang.ru: 'Способ оплаты',
        AppLang.kk: 'Төлем әдісі',
        AppLang.en: 'Payment method',
      });
  String get payWithCard => _pick({
        AppLang.ru: 'Банковской картой',
        AppLang.kk: 'Банк картасымен',
        AppLang.en: 'Bank card',
      });
  String get payWithKaspi => _pick({
        AppLang.ru: 'Kaspi Pay',
        AppLang.kk: 'Kaspi Pay',
        AppLang.en: 'Kaspi Pay',
      });
  String get payWithApple => _pick({
        AppLang.ru: 'Apple Pay',
        AppLang.kk: 'Apple Pay',
        AppLang.en: 'Apple Pay',
      });
  String get payWithGoogle => _pick({
        AppLang.ru: 'Google Pay',
        AppLang.kk: 'Google Pay',
        AppLang.en: 'Google Pay',
      });
  String get pay => _pick({
        AppLang.ru: 'Оплатить',
        AppLang.kk: 'Төлеу',
        AppLang.en: 'Pay',
      });
  String get paymentSummary => _pick({
        AppLang.ru: 'Детали оплаты',
        AppLang.kk: 'Төлем мәліметтері',
        AppLang.en: 'Payment summary',
      });
  String get sessionPrice => _pick({
        AppLang.ru: 'Сессия',
        AppLang.kk: 'Сессия',
        AppLang.en: 'Session',
      });
  String get serviceFee => _pick({
        AppLang.ru: 'Сервисный сбор',
        AppLang.kk: 'Қызмет ақысы',
        AppLang.en: 'Service fee',
      });
  String get total => _pick({
        AppLang.ru: 'Итого',
        AppLang.kk: 'Барлығы',
        AppLang.en: 'Total',
      });
  String get cardNumber => _pick({
        AppLang.ru: 'Номер карты',
        AppLang.kk: 'Карта нөмірі',
        AppLang.en: 'Card number',
      });
  String get expiry => _pick({
        AppLang.ru: 'Срок',
        AppLang.kk: 'Мерзімі',
        AppLang.en: 'Expiry',
      });
  String get cvv => _pick({
        AppLang.ru: 'CVV',
        AppLang.kk: 'CVV',
        AppLang.en: 'CVV',
      });
  String get holderName => _pick({
        AppLang.ru: 'Имя на карте',
        AppLang.kk: 'Картадағы аты',
        AppLang.en: 'Name on card',
      });
  String get securedBy => _pick({
        AppLang.ru: 'Платежи защищены 3-D Secure. Деньги удерживаются на счёте Nuva до сессии.',
        AppLang.kk: 'Төлемдер 3-D Secure арқылы қорғалған.',
        AppLang.en: 'Payments secured with 3-D Secure. Funds held by Nuva until session.',
      });

  // Success
  String get bookingConfirmed => _pick({
        AppLang.ru: 'Запись подтверждена',
        AppLang.kk: 'Жазылу расталды',
        AppLang.en: 'Booking confirmed',
      });
  String get successSub => _pick({
        AppLang.ru: 'Мы напомним за 1 час до сессии. Если нужно — отмените или перенесите бесплатно за 12 часов.',
        AppLang.kk: 'Сессияға 1 сағат қалғанда еске саламыз.',
        AppLang.en: 'We will remind you 1 hour before the session.',
      });
  String get addToCalendar => _pick({
        AppLang.ru: 'Добавить в календарь',
        AppLang.kk: 'Күнтізбеге қосу',
        AppLang.en: 'Add to calendar',
      });
  String get backHome => _pick({
        AppLang.ru: 'На главный',
        AppLang.kk: 'Басты бетке',
        AppLang.en: 'Back home',
      });

  // Community
  String get communityTitle => _pick({
        AppLang.ru: 'Сообщество',
        AppLang.kk: 'Қоғам',
        AppLang.en: 'Community',
      });
  String get communityHint => _pick({
        AppLang.ru: 'Здесь все анонимно. Без оценок, без обесценивания.',
        AppLang.kk: 'Мұнда барлығы анонимді.',
        AppLang.en: 'Anonymous and judgement-free.',
      });
  String get supportive => _pick({
        AppLang.ru: 'Поддержано',
        AppLang.kk: 'Қолдау алды',
        AppLang.en: 'Supported',
      });
  String get fromSpecialist => _pick({
        AppLang.ru: 'Психолог Nuva',
        AppLang.kk: 'Nuva психологы',
        AppLang.en: 'Nuva psychologist',
      });
  String get replyHint => _pick({
        AppLang.ru: 'Ответить с поддержкой…',
        AppLang.kk: 'Қолдау білдіріп жауап беру…',
        AppLang.en: 'Reply with support…',
      });
  String get compose => _pick({
        AppLang.ru: 'Поделиться',
        AppLang.kk: 'Бөлісу',
        AppLang.en: 'Share',
      });
  String get composeTitle => _pick({
        AppLang.ru: 'Поделиться с сообществом',
        AppLang.kk: 'Қоғаммен бөлісу',
        AppLang.en: 'Share with community',
      });
  String get composeHint => _pick({
        AppLang.ru: 'Что у вас на душе? Без оценок, без советов — просто поделитесь.',
        AppLang.kk: 'Жан дүниеңізде не бар?',
        AppLang.en: 'What is on your mind?',
      });
  String get publish => _pick({
        AppLang.ru: 'Опубликовать',
        AppLang.kk: 'Жариялау',
        AppLang.en: 'Publish',
      });

  // Profile
  String get profile => _pick({
        AppLang.ru: 'Профиль',
        AppLang.kk: 'Профиль',
        AppLang.en: 'Profile',
      });
  String get mySessions => _pick({
        AppLang.ru: 'Мои сессии',
        AppLang.kk: 'Менің сессияларым',
        AppLang.en: 'My sessions',
      });
  String get myJournal => _pick({
        AppLang.ru: 'Дневник настроения',
        AppLang.kk: 'Көңіл-күй күнделігі',
        AppLang.en: 'Mood journal',
      });
  String get language => _pick({
        AppLang.ru: 'Язык',
        AppLang.kk: 'Тіл',
        AppLang.en: 'Language',
      });
  String get notifications => _pick({
        AppLang.ru: 'Уведомления',
        AppLang.kk: 'Хабарландырулар',
        AppLang.en: 'Notifications',
      });
  String get privacy => _pick({
        AppLang.ru: 'Конфиденциальность',
        AppLang.kk: 'Құпиялылық',
        AppLang.en: 'Privacy',
      });
  String get helpSupport => _pick({
        AppLang.ru: 'Помощь и поддержка',
        AppLang.kk: 'Көмек және қолдау',
        AppLang.en: 'Help & support',
      });
  String get signOut => _pick({
        AppLang.ru: 'Выйти',
        AppLang.kk: 'Шығу',
        AppLang.en: 'Sign out',
      });

  // Tabs
  String get tabHome => _pick({
        AppLang.ru: 'Главная',
        AppLang.kk: 'Басты',
        AppLang.en: 'Home',
      });
  String get tabSpecialists => _pick({
        AppLang.ru: 'Поиск',
        AppLang.kk: 'Іздеу',
        AppLang.en: 'Search',
      });
  String get tabCommunity => _pick({
        AppLang.ru: 'Сообщество',
        AppLang.kk: 'Қоғам',
        AppLang.en: 'Community',
      });
  String get tabCalm => _pick({
        AppLang.ru: 'Покой',
        AppLang.kk: 'Тыныштық',
        AppLang.en: 'Calm',
      });
  String get tabProfile => _pick({
        AppLang.ru: 'Профиль',
        AppLang.kk: 'Профиль',
        AppLang.en: 'Profile',
      });

  // Chat
  String get chats => _pick({
        AppLang.ru: 'Чаты',
        AppLang.kk: 'Чаттар',
        AppLang.en: 'Chats',
      });
  String get noChats => _pick({
        AppLang.ru: 'Пока нет чатов',
        AppLang.kk: 'Әзірге чаттар жоқ',
        AppLang.en: 'No chats yet',
      });
  String get noChatsSub => _pick({
        AppLang.ru: 'Запишитесь к специалисту — переписка появится здесь.',
        AppLang.kk: 'Маманға жазылыңыз.',
        AppLang.en: 'Book a session — chat will appear here.',
      });
  String get online => _pick({
        AppLang.ru: 'онлайн',
        AppLang.kk: 'желіде',
        AppLang.en: 'online',
      });
  String get offline => _pick({
        AppLang.ru: 'не в сети',
        AppLang.kk: 'желіде емес',
        AppLang.en: 'offline',
      });
  String get typing => _pick({
        AppLang.ru: 'печатает…',
        AppLang.kk: 'жазып жатыр…',
        AppLang.en: 'typing…',
      });
  String get encryptedNote => _pick({
        AppLang.ru:
            'Сообщения шифруются. Не делитесь контактами вне Nuva — это нарушение правил.',
        AppLang.kk: 'Хабарлар шифрланған. Сыртқы байланыстарды бөліспеңіз.',
        AppLang.en: 'Messages encrypted. Sharing contacts outside Nuva is prohibited.',
      });
  String get contactWarning => _pick({
        AppLang.ru:
            'Похоже, вы делитесь контактом. Все сессии, чаты и оплаты идут через Nuva — это защищает вас и специалиста.',
        AppLang.kk: 'Сіз байланыс бөлісіп жатқан сияқтысыз.',
        AppLang.en:
            'You seem to be sharing contact info. All sessions and payments must go through Nuva.',
      });
  String get sessionTomorrow => _pick({
        AppLang.ru: 'Сессия завтра в',
        AppLang.kk: 'Ертең сессия',
        AppLang.en: 'Session tomorrow at',
      });
  String get joinVideo => _pick({
        AppLang.ru: 'Войти в видео',
        AppLang.kk: 'Бейнеге кіру',
        AppLang.en: 'Join video',
      });
  String get videoSessionWith => _pick({
        AppLang.ru: 'Сессия с',
        AppLang.kk: 'Сессия:',
        AppLang.en: 'Session with',
      });
  String get cameraOn => _pick({
        AppLang.ru: 'Камера',
        AppLang.kk: 'Камера',
        AppLang.en: 'Camera',
      });
  String get micOn => _pick({
        AppLang.ru: 'Микрофон',
        AppLang.kk: 'Микрофон',
        AppLang.en: 'Mic',
      });
  String get endCall => _pick({
        AppLang.ru: 'Завершить',
        AppLang.kk: 'Аяқтау',
        AppLang.en: 'End',
      });
  String get connecting => _pick({
        AppLang.ru: 'Соединяем…',
        AppLang.kk: 'Қосылуда…',
        AppLang.en: 'Connecting…',
      });
  String get messagePlaceholder => _pick({
        AppLang.ru: 'Сообщение…',
        AppLang.kk: 'Хабар…',
        AppLang.en: 'Message…',
      });

  // Errors
  String get aiError => _pick({
        AppLang.ru:
            'Не удалось получить ответ. Проверьте интернет и API-ключ.',
        AppLang.kk: 'Жауап алынбады. Интернет пен API-кілтті тексеріңіз.',
        AppLang.en: 'Could not get a response. Check internet and API key.',
      });
  String get comingSoon => _pick({
        AppLang.ru: 'Скоро',
        AppLang.kk: 'Жақында',
        AppLang.en: 'Coming soon',
      });

  // Auth
  String get signIn => _pick({
        AppLang.ru: 'Войти',
        AppLang.kk: 'Кіру',
        AppLang.en: 'Sign in',
      });
  String get account => _pick({
        AppLang.ru: 'Аккаунт',
        AppLang.kk: 'Аккаунт',
        AppLang.en: 'Account',
      });
  String get signInTitle => _pick({
        AppLang.ru: 'Вход в Nuva',
        AppLang.kk: 'Nuva-ға кіру',
        AppLang.en: 'Sign in to Nuva',
      });
  String get signInSub => _pick({
        AppLang.ru: 'Введите номер телефона — пришлём код в SMS.',
        AppLang.kk: 'Телефон нөмірін енгізіңіз — SMS-код жібереміз.',
        AppLang.en: 'Enter your phone — we will text you a code.',
      });
  String get phoneNumber => _pick({
        AppLang.ru: 'Номер телефона',
        AppLang.kk: 'Телефон нөмірі',
        AppLang.en: 'Phone number',
      });
  String get sendCode => _pick({
        AppLang.ru: 'Получить код',
        AppLang.kk: 'Кодты алу',
        AppLang.en: 'Send code',
      });
  String get smsCode => _pick({
        AppLang.ru: 'Код из SMS',
        AppLang.kk: 'SMS коды',
        AppLang.en: 'SMS code',
      });
  String get verifyCode => _pick({
        AppLang.ru: 'Подтвердить',
        AppLang.kk: 'Растау',
        AppLang.en: 'Verify',
      });
  String get continueAnon => _pick({
        AppLang.ru: 'Продолжить анонимно',
        AppLang.kk: 'Анонимді жалғастыру',
        AppLang.en: 'Continue anonymously',
      });
  String get otpSent => _pick({
        AppLang.ru: 'Код отправлен. Проверьте SMS.',
        AppLang.kk: 'Код жіберілді. SMS-ті тексеріңіз.',
        AppLang.en: 'Code sent. Check your SMS.',
      });
  String get authError => _pick({
        AppLang.ru: 'Не удалось войти. Проверьте номер/код и настройки.',
        AppLang.kk: 'Кіру сәтсіз. Нөмір/кодты тексеріңіз.',
        AppLang.en: 'Sign-in failed. Check the number/code and settings.',
      });
  String get signedInAnon => _pick({
        AppLang.ru: 'Вы вошли анонимно',
        AppLang.kk: 'Сіз анонимді кірдіңіз',
        AppLang.en: 'Signed in anonymously',
      });
  String get signInToPost => _pick({
        AppLang.ru: 'Войдите, чтобы опубликовать',
        AppLang.kk: 'Жариялау үшін кіріңіз',
        AppLang.en: 'Sign in to publish',
      });
}
