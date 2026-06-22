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
        AppLang.ru: 'Поможем с подбором',
        AppLang.kk: 'Таңдауға көмектесеміз',
        AppLang.en: 'We help you match',
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
        AppLang.ru: 'Помощь в подборе',
        AppLang.kk: 'Маман таңдауға көмек',
        AppLang.en: 'Help matching',
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
  String get securedBy => _pick({
        AppLang.ru: 'Платежи защищены 3-D Secure. Деньги удерживаются на счёте Nuva до сессии.',
        AppLang.kk: 'Төлемдер 3-D Secure арқылы қорғалған.',
        AppLang.en: 'Payments secured with 3-D Secure. Funds held by Nuva until session.',
      });
  // Card payments are delegated to the acquirer's secure page — the app never
  // collects the card number / CVV (keeps it out of PCI scope).
  String get cardRedirectTitle => _pick({
        AppLang.ru: 'Защищённая страница оплаты',
        AppLang.kk: 'Қорғалған төлем беті',
        AppLang.en: 'Secure payment page',
      });
  String get cardRedirectBody => _pick({
        AppLang.ru: 'Данные карты вводятся на защищённой странице банка-эквайера, '
            'а не в приложении. Nuva не видит и не хранит номер карты и CVV.',
        AppLang.kk: 'Карта деректері қосымшада емес, эквайер-банктің қорғалған '
            'бетінде енгізіледі. Nuva карта нөмірі мен CVV-ді көрмейді.',
        AppLang.en: 'Card details are entered on the acquirer bank’s secure '
            'page, not in the app. Nuva never sees or stores your card number or CVV.',
      });
  String get continueToPayment => _pick({
        AppLang.ru: 'Перейти к оплате',
        AppLang.kk: 'Төлемге өту',
        AppLang.en: 'Continue to payment',
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
  String get psychologist => _pick({
        AppLang.ru: 'Психолог',
        AppLang.kk: 'Психолог',
        AppLang.en: 'Psychologist',
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

  // ─── Entry quiz (lead capture) ──────────────────────────────────
  String get quizCtaEntry => _pick({
        AppLang.ru: 'Подобрать за минуту',
        AppLang.kk: 'Бір минутта таңдау',
        AppLang.en: 'Match me in a minute',
      });
  String get quizCtaSub => _pick({
        AppLang.ru: 'Ответьте на пару вопросов — покажем подходящих специалистов.',
        AppLang.kk: 'Бірнеше сұраққа жауап беріңіз — сәйкес мамандарды көрсетеміз.',
        AppLang.en: 'Answer a few questions — we’ll show specialists who fit.',
      });
  String get quizTitle => _pick({
        AppLang.ru: 'Подбор специалиста',
        AppLang.kk: 'Маман таңдау',
        AppLang.en: 'Find your specialist',
      });
  String get quizStepOf => _pick({
        AppLang.ru: 'Шаг',
        AppLang.kk: 'Қадам',
        AppLang.en: 'Step',
      });
  String get quizNext => _pick({
        AppLang.ru: 'Далее',
        AppLang.kk: 'Әрі қарай',
        AppLang.en: 'Next',
      });
  String get quizBack => _pick({
        AppLang.ru: 'Назад',
        AppLang.kk: 'Артқа',
        AppLang.en: 'Back',
      });
  String get quizShowResults => _pick({
        AppLang.ru: 'Показать подбор',
        AppLang.kk: 'Таңдауды көрсету',
        AppLang.en: 'Show matches',
      });

  // Q1 — for whom
  String get quizQWho => _pick({
        AppLang.ru: 'Для кого ищете поддержку?',
        AppLang.kk: 'Кімге қолдау іздеп жүрсіз?',
        AppLang.en: 'Who are you seeking support for?',
      });
  String get quizWhoSelf => _pick({
        AppLang.ru: 'Для себя',
        AppLang.kk: 'Өзіме',
        AppLang.en: 'For myself',
      });
  String get quizWhoRelative => _pick({
        AppLang.ru: 'Для близкого',
        AppLang.kk: 'Жақыныма',
        AppLang.en: 'For someone close',
      });
  String get quizWhoChild => _pick({
        AppLang.ru: 'Для ребёнка или подростка',
        AppLang.kk: 'Бала немесе жасөспірімге',
        AppLang.en: 'For a child or teen',
      });

  // Q2 — topics
  String get quizQTopics => _pick({
        AppLang.ru: 'Что беспокоит больше всего?',
        AppLang.kk: 'Сізді не қатты алаңдатады?',
        AppLang.en: 'What troubles you most?',
      });
  String get quizQTopicsHint => _pick({
        AppLang.ru: 'Можно выбрать несколько',
        AppLang.kk: 'Бірнешеуін таңдауға болады',
        AppLang.en: 'You can pick several',
      });

  // Q3 — severity
  String get quizQSeverity => _pick({
        AppLang.ru: 'Насколько это влияет на жизнь?',
        AppLang.kk: 'Бұл өмірге қаншалықты әсер етеді?',
        AppLang.en: 'How much does it affect your life?',
      });
  String get quizSevMild => _pick({
        AppLang.ru: 'Терпимо, но хочу разобраться',
        AppLang.kk: 'Шыдауға болады, бірақ түсінгім келеді',
        AppLang.en: 'Manageable, but I want to understand it',
      });
  String get quizSevModerate => _pick({
        AppLang.ru: 'Заметно мешает повседневной жизни',
        AppLang.kk: 'Күнделікті өмірге айтарлықтай кедергі',
        AppLang.en: 'It noticeably gets in the way',
      });
  String get quizSevSevere => _pick({
        AppLang.ru: 'Очень тяжело, трудно справляться',
        AppLang.kk: 'Өте ауыр, төтеп беру қиын',
        AppLang.en: 'Very hard, I struggle to cope',
      });
  String get quizCrisisAsk => _pick({
        AppLang.ru: 'Бывают мысли причинить себе вред?',
        AppLang.kk: 'Өзіңізге зиян келтіру ойлары бола ма?',
        AppLang.en: 'Do you have thoughts of harming yourself?',
      });
  String get quizCrisisYes => _pick({
        AppLang.ru: 'Да, иногда',
        AppLang.kk: 'Иә, кейде',
        AppLang.en: 'Yes, sometimes',
      });
  String get quizCrisisNo => _pick({
        AppLang.ru: 'Нет',
        AppLang.kk: 'Жоқ',
        AppLang.en: 'No',
      });
  String get quizCrisisTitle => _pick({
        AppLang.ru: 'Вы не одни — это важно',
        AppLang.kk: 'Сіз жалғыз емессіз — бұл маңызды',
        AppLang.en: 'You’re not alone — this matters',
      });
  String get quizCrisisBody => _pick({
        AppLang.ru:
            'Если есть мысли причинить себе вред — пожалуйста, обратитесь за помощью прямо сейчас:\n\n• 112 — единая служба экстренного вызова\n• 150 — бесплатный телефон доверия\n\nNuva не заменяет экстренную помощь, но мы рядом.',
        AppLang.kk:
            'Егер өзіңізге зиян келтіру ойлары болса — қазір көмекке жүгініңіз:\n\n• 112 — бірыңғай шұғыл қызмет\n• 150 — тегін сенім телефоны\n\nNuva шұғыл көмекті алмастырмайды, бірақ біз жаныңыздамыз.',
        AppLang.en:
            'If you have thoughts of harming yourself, please reach out right now:\n\n• 112 — emergency services\n• 150 — free helpline\n\nNuva is not a substitute for emergency help, but we’re here.',
      });

  // Q4 — goal
  String get quizQGoal => _pick({
        AppLang.ru: 'Какого результата хотите?',
        AppLang.kk: 'Қандай нәтиже күтесіз?',
        AppLang.en: 'What result do you want?',
      });
  String get quizGoalUnderstand => _pick({
        AppLang.ru: 'Понять себя',
        AppLang.kk: 'Өзімді түсіну',
        AppLang.en: 'Understand myself',
      });
  String get quizGoalCope => _pick({
        AppLang.ru: 'Справиться с состоянием',
        AppLang.kk: 'Жағдаймен күресу',
        AppLang.en: 'Cope with how I feel',
      });
  String get quizGoalRelations => _pick({
        AppLang.ru: 'Наладить отношения',
        AppLang.kk: 'Қарым-қатынасты жөнге салу',
        AppLang.en: 'Improve relationships',
      });
  String get quizGoalDecision => _pick({
        AppLang.ru: 'Принять решение',
        AppLang.kk: 'Шешім қабылдау',
        AppLang.en: 'Make a decision',
      });

  // Q5 — format + language
  String get quizQFormat => _pick({
        AppLang.ru: 'Удобный формат и язык',
        AppLang.kk: 'Ыңғайлы формат пен тіл',
        AppLang.en: 'Format and language',
      });
  String get quizFormatOnline => _pick({
        AppLang.ru: 'Онлайн',
        AppLang.kk: 'Онлайн',
        AppLang.en: 'Online',
      });
  String get quizFormatOffline => _pick({
        AppLang.ru: 'Очно',
        AppLang.kk: 'Жеке кездесу',
        AppLang.en: 'In person',
      });
  String get quizLangLabel => _pick({
        AppLang.ru: 'Язык общения',
        AppLang.kk: 'Сөйлесу тілі',
        AppLang.en: 'Language',
      });

  // Q6 — urgency + budget
  String get quizQUrgency => _pick({
        AppLang.ru: 'Когда хотите начать?',
        AppLang.kk: 'Қашан бастағыңыз келеді?',
        AppLang.en: 'When do you want to start?',
      });
  String get quizUrgWeek => _pick({
        AppLang.ru: 'На этой неделе',
        AppLang.kk: 'Осы аптада',
        AppLang.en: 'This week',
      });
  String get quizUrgMonth => _pick({
        AppLang.ru: 'В этом месяце',
        AppLang.kk: 'Осы айда',
        AppLang.en: 'This month',
      });
  String get quizUrgExploring => _pick({
        AppLang.ru: 'Пока просто изучаю',
        AppLang.kk: 'Әзірге тек қарап жүрмін',
        AppLang.en: 'Just exploring',
      });
  String get quizQBudget => _pick({
        AppLang.ru: 'Комфортный бюджет за сессию',
        AppLang.kk: 'Сессияға ыңғайлы бюджет',
        AppLang.en: 'Comfortable budget per session',
      });
  String get quizBudgetEco => _pick({
        AppLang.ru: 'Эконом',
        AppLang.kk: 'Үнемді',
        AppLang.en: 'Budget',
      });
  String get quizBudgetMid => _pick({
        AppLang.ru: 'Средний',
        AppLang.kk: 'Орташа',
        AppLang.en: 'Mid',
      });
  String get quizBudgetPremium => _pick({
        AppLang.ru: 'Премиум',
        AppLang.kk: 'Премиум',
        AppLang.en: 'Premium',
      });
  String get quizBudgetAny => _pick({
        AppLang.ru: 'Не важно',
        AppLang.kk: 'Маңызды емес',
        AppLang.en: 'Doesn’t matter',
      });

  // Q7 — contact + consent
  String get quizQContact => _pick({
        AppLang.ru: 'Куда прислать подбор?',
        AppLang.kk: 'Таңдауды қайда жіберейік?',
        AppLang.en: 'Where should we send your matches?',
      });
  String get quizContactHint => _pick({
        AppLang.ru: 'Телефон, email или @username',
        AppLang.kk: 'Телефон, email немесе @username',
        AppLang.en: 'Phone, email or @username',
      });
  String get quizContactInvalid => _pick({
        AppLang.ru: 'Введите телефон, email или @username',
        AppLang.kk: 'Телефон, email немесе @username енгізіңіз',
        AppLang.en: 'Enter a phone, email or @username',
      });
  String get quizConsent => _pick({
        AppLang.ru:
            'Согласен(на) на обработку моих ответов для подбора специалиста (особая категория данных, №94-V).',
        AppLang.kk:
            'Маман таңдау үшін жауаптарымды өңдеуге келісемін (ерекше санаттағы деректер, №94-V).',
        AppLang.en:
            'I consent to processing my answers to match a specialist (special-category data, №94-V).',
      });
  String get quizConsentRequired => _pick({
        AppLang.ru: 'Без согласия продолжить нельзя',
        AppLang.kk: 'Келісімсіз жалғастыру мүмкін емес',
        AppLang.en: 'Consent is required to continue',
      });

  // Result
  String get quizResultTitle => _pick({
        AppLang.ru: 'Мы подобрали для вас',
        AppLang.kk: 'Сізге таңдадық',
        AppLang.en: 'We found a match for you',
      });
  String get quizResultSub => _pick({
        AppLang.ru: 'Создайте аккаунт, чтобы написать и записаться.',
        AppLang.kk: 'Жазылу үшін аккаунт жасаңыз.',
        AppLang.en: 'Create an account to message and book.',
      });
  String get quizResultCta => _pick({
        AppLang.ru: 'Создать аккаунт и записаться',
        AppLang.kk: 'Аккаунт жасап, жазылу',
        AppLang.en: 'Create account & book',
      });
  String get quizResultEmpty => _pick({
        AppLang.ru: 'Пока не нашли точного совпадения — посмотрите весь каталог.',
        AppLang.kk: 'Дәл сәйкестік табылмады — толық каталогты қараңыз.',
        AppLang.en: 'No exact match yet — browse the full catalog.',
      });
  String get quizPrivacyNote => _pick({
        AppLang.ru: 'Ответы анонимны до регистрации и используются только для подбора.',
        AppLang.kk: 'Жауаптар тіркелгенге дейін анонимді және тек таңдау үшін қолданылады.',
        AppLang.en: 'Answers stay anonymous until you register and are used only for matching.',
      });

  // ─── "Поговорить сейчас" instant funnel ─────────────────────────
  String get talkNow => _pick({
        AppLang.ru: 'Поговорить сейчас',
        AppLang.kk: 'Қазір сөйлесу',
        AppLang.en: 'Talk now',
      });
  String get talkNowSub => _pick({
        AppLang.ru: 'Найдём свободного психолога прямо сейчас',
        AppLang.kk: 'Қазір бос психологты табамыз',
        AppLang.en: 'Find an available psychologist right now',
      });
  String get instantSearching => _pick({
        AppLang.ru: 'Ищем свободного психолога…',
        AppLang.kk: 'Бос психолог іздеудеміз…',
        AppLang.en: 'Finding an available psychologist…',
      });
  String get instantMatched => _pick({
        AppLang.ru: 'Психолог готов поговорить',
        AppLang.kk: 'Психолог сөйлесуге дайын',
        AppLang.en: 'A psychologist is ready',
      });
  String get instantPickChannel => _pick({
        AppLang.ru: 'Как удобнее начать?',
        AppLang.kk: 'Қалай бастаған ыңғайлы?',
        AppLang.en: 'How would you like to start?',
      });
  String get instantVideo => _pick({
        AppLang.ru: 'Видеозвонок',
        AppLang.kk: 'Бейнеқоңырау',
        AppLang.en: 'Video call',
      });
  String get instantChat => _pick({
        AppLang.ru: 'Чат',
        AppLang.kk: 'Чат',
        AppLang.en: 'Chat',
      });
  String get instantFree => _pick({
        AppLang.ru: 'Первая сессия — бесплатно',
        AppLang.kk: 'Алғашқы сессия — тегін',
        AppLang.en: 'First session is free',
      });
  String get instantNoneTitle => _pick({
        AppLang.ru: 'Сейчас никто не на связи',
        AppLang.kk: 'Қазір ешкім желіде жоқ',
        AppLang.en: 'No one is available right now',
      });
  String instantNoneBody(int minutes) => _pick({
        AppLang.ru: 'Оставьте заявку — психолог свяжется в течение $minutes минут. А пока можно поговорить с ботом-помощником.',
        AppLang.kk: 'Өтінім қалдырыңыз — психолог $minutes минут ішінде хабарласады. Әзірге бот-көмекшімен сөйлесуге болады.',
        AppLang.en: 'Leave a request — a psychologist will reach out within $minutes minutes. Meanwhile you can talk to the assistant bot.',
      });
  String get instantLeaveRequest => _pick({
        AppLang.ru: 'Оставить заявку',
        AppLang.kk: 'Өтінім қалдыру',
        AppLang.en: 'Leave a request',
      });
  String get instantTalkToBot => _pick({
        AppLang.ru: 'Пока поговорить с ботом',
        AppLang.kk: 'Әзірге ботпен сөйлесу',
        AppLang.en: 'Talk to the bot for now',
      });
  String get instantBrowseCatalog => _pick({
        AppLang.ru: 'Смотреть каталог психологов',
        AppLang.kk: 'Психологтар каталогы',
        AppLang.en: 'Browse the catalog',
      });
  String get instantWaitingTitle => _pick({
        AppLang.ru: 'Заявка отправлена',
        AppLang.kk: 'Өтінім жіберілді',
        AppLang.en: 'Request sent',
      });
  String instantWaitingBody(int minutes) => _pick({
        AppLang.ru: 'Психолог свяжется в течение $minutes минут. Можно закрыть экран — мы уведомим, когда кто-то примет заявку.',
        AppLang.kk: 'Психолог $minutes минут ішінде хабарласады. Экранды жабуға болады — біреу өтінімді қабылдағанда хабарлаймыз.',
        AppLang.en: 'A psychologist will reach out within $minutes minutes. You can close this screen — we’ll notify you when someone picks it up.',
      });
  String get instantClaimed => _pick({
        AppLang.ru: 'Психолог принял заявку!',
        AppLang.kk: 'Психолог өтінімді қабылдады!',
        AppLang.en: 'A psychologist accepted!',
      });
  String get instantStartSession => _pick({
        AppLang.ru: 'Начать сессию',
        AppLang.kk: 'Сессияны бастау',
        AppLang.en: 'Start the session',
      });
  String get instantCancelRequest => _pick({
        AppLang.ru: 'Отменить заявку',
        AppLang.kk: 'Өтінімнен бас тарту',
        AppLang.en: 'Cancel request',
      });
  String get instantOfflineTitle => _pick({
        AppLang.ru: 'Нет связи с сервером',
        AppLang.kk: 'Сервермен байланыс жоқ',
        AppLang.en: 'No connection to the server',
      });
  String get instantRetry => _pick({
        AppLang.ru: 'Повторить',
        AppLang.kk: 'Қайталау',
        AppLang.en: 'Retry',
      });
  String get instantOfflineBody => _pick({
        AppLang.ru: 'Мгновенный подбор недоступен офлайн. Если нужна срочная помощь — позвоните на линию доверия 150.',
        AppLang.kk: 'Жедел таңдау офлайн қолжетімсіз. Шұғыл көмек қажет болса — 150 сенім желісіне қоңырау шалыңыз.',
        AppLang.en: 'Instant matching is unavailable offline. If you need urgent help, call the helpline at 150.',
      });

  // Cabinet toggle (psychologist) — RU-only cabinet, kept simple cross-lang.
  String get cabinetInstantToggle => _pick({
        AppLang.ru: 'Доступен сейчас',
        AppLang.kk: 'Қазір қолжетімді',
        AppLang.en: 'Available now',
      });
  String get cabinetInstantHint => _pick({
        AppLang.ru: 'Принимать мгновенные сессии «Поговорить сейчас» (на 1 час)',
        AppLang.kk: '«Қазір сөйлесу» жедел сессияларын қабылдау (1 сағатқа)',
        AppLang.en: 'Accept instant “Talk now” sessions (for 1 hour)',
      });

  // ─── Auth (password help + friendly server errors) ──────────────
  String get pwHint => _pick({
        AppLang.ru: 'Минимум 8 символов. Не используйте простые пароли (12345678, qwerty, password).',
        AppLang.kk: 'Кемінде 8 таңба. Қарапайым парольдерді қолданбаңыз (12345678, qwerty, password).',
        AppLang.en: 'At least 8 characters. Avoid common passwords (12345678, qwerty, password).',
      });
  String get pwTooCommon => _pick({
        AppLang.ru: 'Этот пароль слишком простой. Придумайте более надёжный — с буквами, цифрами и символом.',
        AppLang.kk: 'Бұл пароль тым қарапайым. Әріптер, сандар және белгісі бар сенімдірек парольді ойлап табыңыз.',
        AppLang.en: 'That password is too common. Choose a stronger one — mix letters, numbers and a symbol.',
      });
  String get pwTooShort => _pick({
        AppLang.ru: 'Пароль слишком короткий — минимум 8 символов.',
        AppLang.kk: 'Пароль тым қысқа — кемінде 8 таңба.',
        AppLang.en: 'Password is too short — at least 8 characters.',
      });
  String get pwTooNumeric => _pick({
        AppLang.ru: 'Пароль не должен состоять только из цифр.',
        AppLang.kk: 'Пароль тек сандардан тұрмауы керек.',
        AppLang.en: 'Password can’t be entirely numeric.',
      });
  String get emailTaken => _pick({
        AppLang.ru: 'Этот email уже зарегистрирован. Попробуйте войти.',
        AppLang.kk: 'Бұл email тіркелген. Кіріп көріңіз.',
        AppLang.en: 'This email is already registered. Try signing in.',
      });

  // ─── Legal screens ──────────────────────────────────────────────
  /// Honest banner shown above every legal document: this is a draft, the
  /// authoritative version is RU and finalized by a lawyer before launch.
  String get legalDraftNotice => _pick({
        AppLang.ru: 'Черновик. Текст готовится к проверке юристом и может измениться. '
            'Юридически значимая версия — на русском языке.',
        AppLang.kk: 'Жоба. Мәтін заңгердің тексеруіне дайындалуда және өзгеруі мүмкін. '
            'Заңды күші бар нұсқа — орыс тілінде.',
        AppLang.en: 'Draft. This text is being prepared for legal review and may change. '
            'The authoritative version is in Russian.',
      });
}
