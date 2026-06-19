# Nuva — Flutter MVP

Психологическая поддержка для рынка Казахстана. Liquid Glass дизайн, ИИ-интейк через Claude, маркетплейс психологов, внутренний чат, видео-комната, анонимное сообщество.

> Полный путь от текущего состояния до Google Play — в [`LAUNCH.md`](LAUNCH.md).

## Состояние

| Слой | Готовность |
|---|---|
| UI (~20 экранов) | ✅ |
| Дизайн-система Liquid Glass | ✅ |
| Локализация RU / KK / EN | ✅ |
| Иконка + сплеш | ✅ |
| Релизный keystore + подпись APK | ✅ |
| ИИ-интейк (Claude API + Cloudflare-прокси) | ✅ код, ❌ ключи |
| Бэкенд-обвязка (Supabase) | ✅ код, ❌ ключи |
| SQL-схема под Supabase | ✅ |
| Платежи (UI: Kaspi / карта / Apple / Google Pay) | ✅ моки, ❌ реальные |
| Видеосвязь | ✅ заглушка, ❌ WebRTC |
| Sentry | ⏳ заглушка (Kotlin-конфликт) |
| iOS-сборка | ❌ нужен Mac |

## Структура

```
nuva_app/
├── LAUNCH.md                          # пошаговый launch-чеклист
├── pubspec.yaml
├── .env.example                       # шаблон ключей
├── lib/
│   ├── main.dart                      # точка входа
│   ├── theme/                         # токены + ThemeData
│   ├── widgets/                       # GlassCard, GlassBackdrop, GradientAvatar, Tag, StarRow
│   ├── l10n/strings.dart              # все строки RU/KK/EN в одном месте
│   ├── models/                        # specialist, chat, community
│   ├── services/
│   │   ├── backend.dart               # Supabase init (graceful fallback)
│   │   ├── auth_service.dart
│   │   ├── db_service.dart
│   │   └── observability.dart         # Sentry-stub
│   ├── router/app_router.dart
│   └── screens/
│       ├── onboarding_screen.dart
│       ├── intake_screen.dart         # ИИ-чат
│       ├── home_screen.dart
│       ├── specialists_screen.dart    # список + детальная
│       ├── booking_screen.dart
│       ├── payment_screen.dart        # Kaspi / карта / Apple / Google Pay
│       ├── payment_success_screen.dart
│       ├── chat_list_screen.dart
│       ├── chat_screen.dart           # внутренний чат с anti-disintermediation
│       ├── video_call_screen.dart     # видео-заглушка
│       ├── community_screen.dart      # Threads-like лента
│       ├── community_post_screen.dart
│       ├── community_compose_screen.dart
│       ├── profile_screen.dart
│       ├── legal_screens.dart         # Privacy / Terms / About
│       └── main_shell.dart            # bottom-nav
├── supabase/
│   └── schema.sql                     # таблицы + RLS + сид
├── assets/
│   ├── images/                        # иконка, splash
│   └── fonts/                         # Onest (скачать отдельно)
└── tool/
    └── make_icon.py                   # генератор иконки
```

## Локальный запуск

```bash
cd nuva_app

cp .env.example .env
# Заполнить ключи (необязательно — без них всё работает на моках)

flutter pub get
flutter run                            # на устройство/эмулятор
flutter run -d chrome                  # в браузер
flutter build apk --release            # релизный APK
flutter build appbundle                # AAB для Google Play
```

## Сборка иконки и сплеша заново

```bash
python tool/make_icon.py
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## Подпись релиза

Ключ: `C:\Users\daniko\dev\nuva-keys\nuva-release.jks`
Подключается через `android/key.properties` (не коммитится — в `.gitignore`).

## Что дальше

См. [`LAUNCH.md`](LAUNCH.md) — там полный путь до публикации в Google Play, включая регистрацию ИП, Supabase, Cloudflare, Mobizon, CloudPayments, юр.документы и стор-материалы.
