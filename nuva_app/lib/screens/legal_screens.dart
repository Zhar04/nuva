import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import '../widgets/glass.dart';

/// Three legal pages with placeholder copy. Replace text with versions
/// drafted by your lawyer before submitting to the stores.
class LegalScreen extends ConsumerWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final data = doc.content;

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Expanded(
                      child: Text(data.title,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          )),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.version,
                        style: TextStyle(color: t.textTer, fontSize: 11),
                      ),
                      const SizedBox(height: 18),
                      for (final section in data.sections) ...[
                        Text(
                          section.heading,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.body,
                          style: TextStyle(
                            color: t.textSec,
                            fontSize: 13.5,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LegalDoc { privacy, terms, about }

extension LegalContent on LegalDoc {
  _LegalData get content => switch (this) {
        LegalDoc.privacy => const _LegalData(
            title: 'Конфиденциальность',
            version: 'Версия 0.1 · черновик · заменить юристом до запуска',
            sections: [
              _Section(
                'Кто оператор',
                'Оператор персональных данных — Nuva (юр.лицо будет указано после регистрации). '
                'Адрес: Республика Казахстан, г. Алматы. Контакт: privacy@nuva.kz',
              ),
              _Section(
                'Какие данные мы собираем',
                '• Номер телефона — для входа в аккаунт.\n'
                '• Сообщения в чате с психологом — для оказания услуги.\n'
                '• История бронирований и платежей — для учёта.\n'
                '• Эмоциональное состояние, которое вы указываете в дневнике, — для вашей собственной аналитики.\n\n'
                'Мы относимся к этим данным как к данным особой категории '
                '(статья 9 ОЕ "Закон о персональных данных №94-V ЗРК").',
              ),
              _Section(
                'Зачем мы их используем',
                'Только для оказания услуги: подобрать специалиста, провести сессию, '
                'выставить чек, напомнить о записи, поддержать вас в кризисной ситуации.',
              ),
              _Section(
                'Кому передаём',
                'Платёжные данные — только провайдеру эквайринга (CloudPayments / ePay). '
                'Психолог получает только тот текст, которым вы делитесь в чате. '
                'Третьим лицам не продаём и не передаём.',
              ),
              _Section(
                'Где хранится',
                'Серверы Supabase (Frankfurt) и зашифрованное локальное хранилище на вашем устройстве. '
                'Все каналы — TLS 1.3, базы шифруются на покое.',
              ),
              _Section(
                'Ваши права',
                'Вы можете запросить копию всех ваших данных, потребовать удалить аккаунт '
                'и отозвать согласие на обработку в любой момент. Напишите на privacy@nuva.kz.',
              ),
              _Section(
                'Кризисный протокол',
                'Если приложение распознаёт сигналы суицидального риска или насилия, '
                'мы покажем вам телефон Республиканской линии помощи Казахстан: 150 '
                '(или 112 — в экстренной ситуации).',
              ),
            ],
          ),
        LegalDoc.terms => const _LegalData(
            title: 'Пользовательское соглашение',
            version: 'Версия 0.1 · черновик · заменить юристом до запуска',
            sections: [
              _Section(
                '1. Что такое Nuva',
                'Nuva — мобильное приложение, которое соединяет пользователей с лицензированными '
                'психологами в Республике Казахстан. Мы выступаем агрегатором: помогаем найти '
                'специалиста, провести сессию и оплатить услугу через приложение.',
              ),
              _Section(
                '2. Кто оказывает услугу',
                'Психологическую услугу оказывает специалист — не Nuva. Nuva отвечает за работу '
                'платформы, верификацию дипломов и удобство расчётов.',
              ),
              _Section(
                '3. Как мы зарабатываем',
                'Мы удерживаем сервисный сбор с каждой сессии (комиссия указана при оплате). '
                'Психологу выплачивается оставшаяся сумма после успешного проведения сессии.',
              ),
              _Section(
                '4. Отмена и возврат',
                'Отмена бесплатно за 12 часов до сессии. Если сессия не состоялась по вине специалиста — '
                'возврат 100%. Если по вашей вине без предупреждения — сбор остаётся.',
              ),
              _Section(
                '5. Гарантия Nuva',
                'Если первая сессия с подобранным специалистом не подошла — бесплатно подберём другого.',
              ),
              _Section(
                '6. Запреты',
                'В чате запрещено: делиться контактами вне Nuva (телефоны, мессенджеры), '
                'передавать материалы экстремистского характера, нарушать законодательство РК. '
                'Нарушение → блокировка аккаунта без возврата средств.',
              ),
              _Section(
                '7. Ограничение ответственности',
                'Nuva не заменяет экстренную медицинскую помощь. В кризисной ситуации звоните 150 / 112.',
              ),
            ],
          ),
        LegalDoc.about => const _LegalData(
            title: 'О приложении',
            version: 'Nuva 0.1.0 · build 1',
            sections: [
              _Section(
                'Миссия',
                'Сделать качественную психологическую помощь доступной в Казахстане — '
                'на родном языке, конфиденциально, без барьеров.',
              ),
              _Section(
                'Что в этой версии',
                '• Помощь в подборе специалиста\n'
                '• Маркетплейс верифицированных психологов\n'
                '• Чат и видео-связь внутри приложения\n'
                '• Анонимное сообщество поддержки\n'
                '• Дневник настроения\n'
                '• Дыхательные и медитативные практики',
              ),
              _Section(
                'Команда',
                'Сделано в Алматы. Контакт: hello@nuva.kz',
              ),
              _Section(
                'Помощь сейчас',
                'Казахстан — линия доверия: 150\n'
                'Экстренные службы: 112',
              ),
            ],
          ),
      };
}

class _LegalData {
  final String title;
  final String version;
  final List<_Section> sections;
  const _LegalData({
    required this.title,
    required this.version,
    required this.sections,
  });
}

class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}
