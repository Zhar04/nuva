# Nuva — путь от текущего состояния до запуска в Google Play

Это твой чеклист. Технически приложение готово на 90%. Осталось подключить внешние сервисы и юр.часть.

---

## Что уже сделано (можно не трогать)

- ✅ Полный UI: онбординг, ИИ-интейк, маркетплейс, бронирование, оплата, чат, видео-комната, сообщество, дневник, профиль
- ✅ Дизайн-система Liquid Glass + RU/KK/EN локализация
- ✅ Иконка приложения + сплеш-экран
- ✅ Свой подписной keystore (хранится в `C:\Users\daniko\dev\nuva-keys\`)
- ✅ ProGuard + shrinking — APK уменьшается с 22 MB до ~9–12 MB на устройстве
- ✅ Бэкенд-обвязка (Supabase) — работает в моках пока ключи не подставлены
- ✅ SQL-схема готова: [`supabase/schema.sql`](supabase/schema.sql)
- ✅ Cloudflare Worker для Claude-прокси: [`server/cloudflare-worker.js`](server/cloudflare-worker.js)
- ✅ Sentry-обвязка — включается при наличии DSN
- ✅ Юр-страницы (Конфиденциальность / Соглашение / О приложении) — текст-черновик внутри приложения
- ✅ Anti-disintermediation в чате (детектор контактов)
- ✅ Гарантия Nuva в карточке психолога

---

## Чеклист запуска (в порядке)

### Шаг 1 — Регистрация юрлица (на твоей стороне, 1–2 недели)

- [ ] **ИП через eGov.kz** (быстрее) или **ТОО через юриста** (надёжнее, если будут инвесторы).
  Без юрлица ни один платёжный провайдер не подключит.
- [ ] **Открыть расчётный счёт** в банке (любом — Каспи/Halyk/ForteBank). Сюда падают деньги пользователей до выплаты психологу.
- [ ] **Получить ЭЦП юрлица** — пригодится для подачи в стор и подписи договоров.

### Шаг 2 — Supabase бэкенд (~30 минут, бесплатно)

- [ ] Зарегаться на https://supabase.com (войти через Google).
- [ ] Создать новый проект:
  - Name: `nuva-prod`
  - Region: `Frankfurt (eu-central-1)` — ближе всего к KZ
  - Database password: сохранить в надёжном месте.
- [ ] Дождаться пока проект провизионится (~2 минуты).
- [ ] Открыть **SQL Editor** → скопировать всё содержимое [`supabase/schema.sql`](supabase/schema.sql) → Run. Появятся таблицы и политики.
- [ ] **Authentication → Providers**:
  - Включить **Phone** провайдера.
  - В качестве SMS-провайдера выбрать `Custom` → ввести данные **Mobizon** или **Twilio** (см. шаг 3).
- [ ] **Settings → API**:
  - Скопировать `URL` → в `.env` как `SUPABASE_URL`
  - Скопировать `anon public key` → в `.env` как `SUPABASE_ANON_KEY`

### Шаг 3 — SMS-провайдер для отправки кодов (~30 минут)

Для рынка KZ — **Mobizon.kz**, дешевле и быстрее Twilio.

- [ ] Зарегаться на https://mobizon.kz, пополнить баланс на 5 000 ₸.
- [ ] Получить **API-ключ** в личном кабинете.
- [ ] В Supabase → Auth → Phone провайдер → **Custom SMS Hook**:
  ```
  URL: https://api.mobizon.kz/service/message/sendsmsmessage
  Method: POST
  ```
  Пример Edge Function для отправки — есть в Supabase docs.

### Шаг 4 — Claude AI прокси через Cloudflare (~15 минут)

- [ ] Зарегаться на https://dash.cloudflare.com (бесплатно).
- [ ] **Workers & Pages** → Create Worker → "Hello World" template.
- [ ] Заменить код на содержимое [`server/cloudflare-worker.js`](server/cloudflare-worker.js).
- [ ] **Settings → Variables** → добавить `ANTHROPIC_API_KEY` (выбрать "Encrypt"). Ключ получить здесь: https://console.anthropic.com → пополнить баланс на $5–10 для старта.
- [ ] Deploy. Скопировать URL вида `https://nuva-claude.<your-sub>.workers.dev`.
- [ ] В `.env` положить `CLAUDE_PROXY_URL=<этот URL>`.

### Шаг 5 — Платёжный провайдер (~1–2 недели)

В KZ доступны два варианта:

**Вариант A — CloudPayments (быстрее)**
- [ ] Договор: https://cloudpayments.kz → "Подключиться"
- [ ] Тариф: 2.9% от транзакции для услуг.
- [ ] Дают `publicId` + `apiSecret` → положить на бэкенд (в Supabase Edge Function).

**Вариант B — Kaspi Pay напрямую (дешевле, но сложнее)**
- Только для крупных партнёров. Требует API-документ от Kaspi, недели на интеграцию.
- На старте проще через CloudPayments → они умеют принимать через Kaspi Gold.

После подключения: создать Edge Function `payments-webhook` на Supabase, которая принимает уведомления о платеже и меняет `bookings.status` на `paid`.

### Шаг 6 — Реальные психологи (на твоей стороне, параллельно)

- [ ] Найти 3–5 лицензированных психологов через свои каналы.
- [ ] Каждый предоставляет:
  - Скан диплома → проверить через РНЦПЗ или ассоциацию.
  - ИИН + банковские реквизиты для выплат.
- [ ] Подписать договор:
  - Комиссия Nuva 15–25% с сессии.
  - Эксклюзивность 12 месяцев на матченных клиентов (штраф 500 000 ₸ за нарушение).
  - Кризисный протокол: что психолог делает при суицидальных сигналах клиента.
- [ ] Внести их данные в Supabase: SQL editor → `INSERT INTO specialists ...` (или через UI Table editor).

### Шаг 7 — Юр.документы (юрист, ~1 неделя)

Тексты в [`lib/screens/legal_screens.dart`](lib/screens/legal_screens.dart) — это **черновики**. Передай юристу. Финальные версии:

- [ ] Политика конфиденциальности (152-ФЗ РК)
- [ ] Пользовательское соглашение
- [ ] Договор-оферта (если используешь оферту вместо подписи)
- [ ] Договор с психологом (партнёрский)

Когда финальные тексты готовы — обнови `lib/screens/legal_screens.dart`.

### Шаг 8 — Sentry (опционально, 10 минут)

- [ ] https://sentry.io → бесплатный аккаунт.
- [ ] Create Project → Flutter → скопировать DSN.
- [ ] В `.env` положить `SENTRY_DSN=<этот DSN>`.

### Шаг 9 — Google Play Console (~$25 единоразово)

- [ ] https://play.google.com/console — оплатить $25 (привязать карту).
- [ ] **Create app**:
  - App name: Nuva
  - Default language: Russian
  - App or game: App
  - Free / Paid: Free
- [ ] Заполнить **Store listing**:
  - Иконка 512x512 — взять из `build/web/icons/Icon-512.png` после сборки
  - Featured graphic 1024x500 — нужно нарисовать (или скрин дашборда)
  - Скриншоты ≥2 (phone) — сделать с APK на твоём телефоне
  - Short description (80 символов)
  - Full description (4000 символов)
- [ ] **App content**:
  - Privacy Policy URL — обязательно. Залить текст из приложения на nuva.kz/privacy.
  - Data safety — заполнить (что собираете, для чего).
  - Target age: 18+ (mental health).
- [ ] **Closed testing → Create release**:
  - Загрузить **`build/app/outputs/bundle/release/app-release.aab`** (см. инструкцию ниже как собрать AAB).
  - Добавить тестеров (свой email + партнёра).
  - Submit for review — обычно 1–3 дня.

### Шаг 10 — Сборка AAB для стора

APK подходит для теста на устройстве. Для Google Play нужен **AAB** (Android App Bundle):

```bash
cd C:\Users\daniko\Desktop\nuva-main\nuva_app
flutter build appbundle --release
# Файл: build/app/outputs/bundle/release/app-release.aab
```

Этот AAB подписан твоим ключом из шага "Свой keystore" (уже сделано).

---

## iOS — отдельная история

Без Mac никак. Варианты:

1. **Codemagic** (https://codemagic.io) — облачный Mac-билд, $28/мес или 500 минут бесплатно. Apple Developer аккаунт нужен в любом случае ($99/год).
2. **Купить Mac mini** б/у — от 150 000 ₸ за M1.
3. **Mac у знакомого** на 1 день — установить Xcode, выполнить `flutter build ipa`, отправить в App Store Connect.

Когда будет Mac: код приложения уже готов, нужно только:
- `flutter create . --platforms=ios` (создаст ios/ папку)
- Открыть `ios/Runner.xcworkspace` в Xcode, настроить Bundle ID `kz.nuva.nuva`, выбрать команду подписи.
- `flutter build ipa`
- Загрузить через Transporter в App Store Connect.

---

## Стоимость старта (минимум)

| Статья | Цена |
|---|---|
| Регистрация ИП | бесплатно (eGov) |
| Google Play | $25 одноразово |
| Mobizon (1000 SMS на старте) | ~5 000 ₸ |
| CloudPayments | 0 (комиссия с транзакций) |
| Anthropic Claude (первый месяц) | ~$5–20 |
| Supabase | $0 (free tier до 50k пользователей) |
| Cloudflare Workers | $0 (free tier до 100k req/день) |
| Sentry | $0 (5k событий/мес бесплатно) |
| Юрист (договоры) | 50 000–150 000 ₸ |
| Домен .kz | ~5 000 ₸/год |
| **Итого** | **~70 000–200 000 ₸ + $25** |

iOS-сборка прибавит $99/год + либо Mac, либо $28/мес Codemagic.

---

## Локальная разработка

Для запуска проекта на ноуте после клонирования:

```bash
cd nuva_app

# 1. Копируем .env
cp .env.example .env
# Заполняем ключи

# 2. Шрифты (если ещё не)
# Скачать Onest с https://fonts.google.com/specimen/Onest
# Положить TTF в assets/fonts/

# 3. Зависимости
flutter pub get

# 4. Сгенерировать иконки заново (если поменялся PNG):
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# 5. Запуск
flutter run                   # — на подключённое устройство / эмулятор
flutter run -d chrome         # — web
flutter build apk --release   # — APK для Android
flutter build appbundle       # — AAB для Google Play
```

---

## Что я (Claude) могу сделать ещё, когда у тебя появятся ключи

1. **Когда дашь Supabase ключи** — переключу UI с мок-данных на реальные таблицы, добавлю Auth screen.
2. **Когда дашь Cloudflare Worker URL** — Claude-чат заработает в продакшен-режиме.
3. **Когда подключишь CloudPayments** — допишу backend Edge Function + webhook payment flow.
4. **Когда есть Mac доступ** — соберу iOS-билд.

---

## Контакты

Этот файл — для тебя. Если что-то непонятно — спроси в чате со мной (Claude).
