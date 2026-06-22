import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// Three legal pages with DRAFT copy. The technical claims here are kept in
/// sync with what the code actually does (HTTPS transport, secure-store tokens,
/// no app-layer message encryption, hosted-page payments, no Supabase) — see the
/// reality audit. "ПРОВЕРИТЬ ЮРИСТУ" / TODO markers flag what a lawyer must
/// finalize (operator entity, retention periods, consent text, acquirer, the new
/// KZ psychology-practice law). Replace with lawyer-finalized versions before
/// store submission. The body is RU (authoritative); the top banner is localized.
class LegalScreen extends ConsumerWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final s = S.of(ref);
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
                      // Localized honesty banner (RU/KK/EN) — the body stays RU
                      // because the authoritative legal text is RU, finalized by
                      // a lawyer; auto-translating legal copy would be unsafe.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.blue.withValues(alpha: 0.10),
                          border:
                              Border.all(color: t.blue.withValues(alpha: 0.30)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: t.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.legalDraftNotice,
                                style: TextStyle(
                                    color: t.textSec,
                                    fontSize: 12,
                                    height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
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
            version: 'Версия 0.2 · черновик · ПРОВЕРИТЬ ЮРИСТУ до запуска',
            sections: [
              _Section(
                'Кто оператор',
                'Оператор персональных данных — Nuva (юридическое лицо будет указано '
                'после регистрации — ПРОВЕРИТЬ ЮРИСТУ). '
                'Республика Казахстан, г. Алматы. Контакт: privacy@nuva.kz',
              ),
              _Section(
                'Какие данные мы собираем',
                '• Email и пароль — для входа в аккаунт (пароль хранится только в виде хеша).\n'
                '• Имя или псевдоним, которые вы указываете в профиле.\n'
                '• Сообщения в чате с психологом — для оказания услуги.\n'
                '• Запрос и ответы анкеты подбора, история бронирований — для подбора и учёта.\n'
                '• Отметки настроения в дневнике — для вашей собственной аналитики.\n\n'
                'Данные о ментальном состоянии относятся к особой категории персональных '
                'данных по Закону Республики Казахстан «О персональных данных и их защите» '
                '№94-V. Мы стремимся собирать минимум необходимого (минимизация данных).',
              ),
              _Section(
                'На каком основании',
                'Обработка ведётся на основании вашего согласия, которое вы даёте при '
                'регистрации и при прохождении анкеты, а также для исполнения договора '
                'оказания услуг. Согласие можно отозвать (см. «Ваши права»). '
                'Точные формулировки согласия — ПРОВЕРИТЬ ЮРИСТУ.',
              ),
              _Section(
                'Зачем мы их используем',
                'Только для оказания услуги: подобрать специалиста, провести сессию, '
                'вести запись, напомнить о встрече и поддержать вас в кризисной ситуации. '
                'Мы не используем ваши данные для рекламы и не продаём их.',
              ),
              _Section(
                'Кому передаём',
                'Психолог видит только тот текст, которым вы делитесь с ним в чате. '
                'Оплата проводится на стороне платёжного провайдера (эквайера) — интеграция '
                'в разработке; реквизиты карты не вводятся внутри приложения и нам не '
                'передаются. Конкретный эквайер и условия передачи — ПРОВЕРИТЬ ЮРИСТУ. '
                'Третьим лицам в иных целях данные не передаём.',
              ),
              _Section(
                'Где и как хранится',
                'Серверы и база данных размещены у облачного провайдера (Railway). '
                'Соединение между приложением и сервером защищено по протоколу HTTPS (TLS). '
                'Сессионные токены на вашем устройстве хранятся в защищённом системном '
                'хранилище (Keychain на iOS, Keystore на Android). '
                'Шифрование данных «в покое» на стороне сервера обеспечивается средствами '
                'облачного провайдера. Конкретная страна размещения и условия трансграничной '
                'передачи для резидентов РК — ПРОВЕРИТЬ ЮРИСТУ.\n\n'
                'Сообщения и записи дневника на текущем этапе не имеют дополнительного '
                'сквозного (end-to-end) шифрования на уровне приложения — мы не заявляем '
                'обратного.',
              ),
              _Section(
                'Сколько храним',
                'Мы храним данные, пока активен ваш аккаунт, и удаляем или обезличиваем их '
                'в разумный срок после удаления аккаунта, если иное не требует закон '
                '(например, учётные данные о платежах). Точные сроки хранения — '
                'ПРОВЕРИТЬ ЮРИСТУ.',
              ),
              _Section(
                'Ваши права',
                'Вы вправе запросить копию ваших данных, исправить их, потребовать '
                'удаления аккаунта и отозвать согласие на обработку. Сейчас это делается '
                'по запросу на privacy@nuva.kz; самостоятельное удаление и экспорт в '
                'приложении — в разработке (TODO). Мы отвечаем в срок, установленный №94-V — '
                'ПРОВЕРИТЬ ЮРИСТУ.',
              ),
              _Section(
                'Кризисный протокол',
                'Nuva — навигатор, а не служба экстренной помощи. Если в ваших сообщениях '
                'распознаются сигналы риска для жизни, мы показываем телефоны помощи в '
                'Казахстане: 150 (линия доверия) и 112 (экстренные службы).',
              ),
              _Section(
                'Информированное согласие (черновик-плейсхолдер)',
                'Перед использованием психологических услуг вам будет предложено отдельное '
                'информированное согласие: о характере услуг, их ограничениях, '
                'конфиденциальности и её пределах. Текст согласия и его соответствие '
                'новому законодательству РК о психологической деятельности — '
                'ПОДГОТОВИТ ЮРИСТ (TODO).',
              ),
            ],
          ),
        LegalDoc.terms => const _LegalData(
            title: 'Пользовательское соглашение',
            version: 'Версия 0.2 · черновик · ПРОВЕРИТЬ ЮРИСТУ до запуска',
            sections: [
              _Section(
                '0. Статус документа (договор-оферта)',
                'Этот текст — черновик-плейсхолдер. Перед запуском его заменит публичный '
                'договор-оферта, подготовленный юристом с учётом законодательства '
                'Республики Казахстан, включая новое регулирование психологической '
                'деятельности (TODO — ПОДГОТОВИТ ЮРИСТ).',
              ),
              _Section(
                '1. Что такое Nuva',
                'Nuva — приложение, которое соединяет пользователей с психологами в '
                'Республике Казахстан. Мы выступаем платформой-агрегатором: помогаем найти '
                'специалиста, провести сессию и оплатить услугу через приложение.',
              ),
              _Section(
                '2. Кто оказывает услугу',
                'Психологическую услугу оказывает специалист — не Nuva. Nuva проверяет '
                'документы специалистов, отвечает за работу платформы и удобство расчётов. '
                'Порядок и объём проверки квалификации — ПРОВЕРИТЬ ЮРИСТУ.',
              ),
              _Section(
                '3. Как мы зарабатываем',
                'Мы удерживаем сервисный сбор с платных сессий (комиссия показывается при '
                'оплате). Ознакомительные/промо-сессии бесплатны. Психологу выплачивается '
                'оставшаяся сумма после проведения сессии.',
              ),
              _Section(
                '4. Оплата',
                'Оплата проводится на стороне платёжного провайдера (эквайера); реквизиты '
                'карты не вводятся внутри приложения. Интеграция эквайера в разработке — '
                'условия оплаты и возвратов ПРОВЕРИТЬ ЮРИСТУ.',
              ),
              _Section(
                '5. Отмена и возврат',
                'Предполагается: отмена бесплатно за 12 часов до сессии; при срыве по вине '
                'специалиста — возврат 100%. Окончательные условия — ПРОВЕРИТЬ ЮРИСТУ.',
              ),
              _Section(
                '6. Запреты',
                'В чате запрещено делиться контактами вне Nuva (телефоны, мессенджеры), '
                'передавать противоправные материалы и нарушать законодательство РК. '
                'Нарушение может повлечь блокировку аккаунта.',
              ),
              _Section(
                '7. Ограничение ответственности',
                'Nuva не заменяет экстренную медицинскую или психиатрическую помощь. '
                'В кризисной ситуации звоните 150 (линия доверия) или 112.',
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
