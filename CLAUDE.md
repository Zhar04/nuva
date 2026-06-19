# CLAUDE.md

Guidance for Claude Code (and humans) working in this repo. Read this first — it
captures the architecture and the non-obvious gotchas so you don't have to
re-derive them every session.

## What this repo is

**Nuva** — a mental-health support platform for the Kazakhstan market: AI-assisted
specialist matching, a psychologist marketplace + cabinet, in-app chat, a video
call, an anonymous community, and a mood journal. Liquid-Glass (iOS-style) design.
RU / KK / EN localization.

Three parts live in this repo:

| Part | Path | What it is |
|---|---|---|
| **Flutter app** (the product) | `nuva_app/` | The web/mobile app, Dart/Flutter. Shipped as a PWA on GitHub Pages. **Most frontend work happens here.** |
| **Django backend** (the API) | `backend/` | Django + DRF + SimpleJWT REST API. Runs on Railway. **All real data + auth live here.** |
| **Design showcase** (artifact) | repo root `*.jsx`, `Nuva.html`, `nuva-dashboard.html` | Browser-only React/Babel design gallery. Opened directly in a browser. Not built, not shipped. |

`Nuvastrategy.pdf` is a business/strategy document, not code.

> Unless a task is explicitly about the design showcase, "the app" means `nuva_app/`
> and "the backend" means `backend/`.

## The system is cloud-hosted — work against the deployed services

There is no local server or local database to stand up. The app and the backend
both run in the cloud, and the frontend always talks to the **deployed** backend:

- **Backend → Railway:** <https://nuva-production.up.railway.app>
- **Frontend → GitHub Pages:** <https://zhar04.github.io/nuva/>
- **Database → Railway Postgres** (managed by Railway; see below)
- **Admin (Django):** `https://nuva-production.up.railway.app/admin/`

A fresh `git clone` runs against these immediately — you only need `nuva_app/.env`
(config that points the app at the Railway backend, see *Configuration*).

## How it's deployed (and how to ship changes)

- **Backend:** Railway **auto-deploys on every push to `main`**. `backend/railway.json`
  `startCommand` runs `migrate → ensure_admin → collectstatic → gunicorn`, so
  pushing a model/migration change applies it to Railway Postgres automatically.
  A healthy `/healthz` after a deploy means the migration applied (migrate runs
  before gunicorn). **So: backend changes go live by committing + pushing `main`.**
- **Frontend:** built and served from the **`gh-pages`** branch, base href `/nuva/`.
  To ship a frontend change:
  1. `flutter build web --release --base-href /nuva/`
     — build with the **PowerShell tool, not Git-Bash**: MSYS rewrites `/nuva/`
       into a Windows path and the base href silently falls back to `/`.
  2. Push `build/web` to `gh-pages` (e.g. `git worktree add <dir> gh-pages` →
     replace contents → `touch .nojekyll` → commit → push). GitHub Pages doesn't
     serve dotfiles, and the app's `API_BASE_URL` already points at Railway, so the
     deployed PWA talks to the deployed backend.

## Database — Railway Postgres

- The production database is **Postgres on Railway**, reached through `DATABASE_URL`
  (a Railway service variable). It is the single source of truth — there is no
  separate data store, and the app never depends on any local data.
- The backend reads `DATABASE_URL` via `dj-database-url`
  (`backend/nuva_backend/settings.py`).
- **All backend secrets live in Railway → service → Variables** (`DATABASE_URL`,
  `SECRET_KEY`, `CORS_ALLOWED_ORIGINS`, `ANTHROPIC_API_KEY`, …) — never in the repo.
  See `docs/DEPLOY_RAILWAY.md` for the full list.
- Inspect/edit data via the Django admin (URL above) or any Postgres client pointed
  at the Railway `DATABASE_URL`.

## Backend architecture (`backend/`)

Django 5 + DRF + SimpleJWT. Apps:

- `accounts` — custom email `User` (roles: seeker / psychologist / admin), JWT
  auth (`/api/v1/auth/{register,login,refresh,me}`), pro-document uploads,
  `ensure_admin` command (bootstraps the admin from env on deploy).
- `catalog` — `Specialist` / `Education` / `Review`; public list + detail; a
  psychologist edits their own listing via `PUT /api/v1/specialists/me`
  (writable nested education). Only `is_verified` specialists show in the catalog.
- `booking` — `Booking` (statuses: requested → scheduled / pending_payment → paid →
  completed, plus declined / cancelled / refunded) + `ClientNote`. Endpoints:
  `bookings/`, `bookings/incoming`, `bookings/{id}/{accept,decline,pay}`,
  `bookings/clients/{id}` (the psychologist's private client card: concern, mood
  trend, notes, session history).
- `chat` — 1:1 `Conversation` + `Message`, with a video-call request/accept handshake.
- `community` — anonymous posts + replies + likes.
- `journal` — daily `MoodEntry` (1 per day) + gamification stats.
- `ai` — Claude proxy (`/api/v1/ai/{match,ask}`) for intake/matching.

Check object-level ownership on every endpoint (e.g. a psychologist only sees their
own incoming bookings / client cards).

## Flutter app architecture (`nuva_app/`)

- **State:** `flutter_riverpod`. **Routing:** `go_router` (`lib/router/app_router.dart`).
- **API layer:** `lib/services/api_client.dart` (thin HTTP over `/api/v1/...`, base
  from `API_BASE_URL`), `backend_auth.dart` (JWT session — register / login /
  refresh; `MainShell` has an auth gate, logout bounces to `/auth`), `data.dart`
  (all the Riverpod providers + `PsyActions` for psychologist write actions).
- **Real flows (all backed by the Railway API):** auth, specialists, the booking
  lifecycle (бронь → запрос → подтверждение → оплата; free intro vs paid package —
  the card acquirer is still mocked but bookings + state transitions are real),
  chat, community, mood journal, AI intake. Providers fall back to bundled sample
  catalogs **only** when the backend is unreachable (offline resilience) — keep
  that fallback intact so the app never hard-crashes.
- **Design system:** `lib/theme/` (`tokens.dart`, `theme.dart`) + `lib/widgets/`
  (`glass.dart` = GlassCard / GlassBackdrop, `avatar.dart` = GradientAvatar / Tag /
  SectionLabel). Reach theme via the `context.nuva` extension.
- **Localization:** all strings in `lib/l10n/strings.dart` (`S.of(ref)`), language
  in `langProvider` (RU/KK/EN); theme mode in `themeModeProvider`. No `.arb` files.
  (The psychologist cabinet screens are RU-only by design.)
- **Screens:** `lib/screens/` (one file each). `main_shell.dart` is the bottom-nav
  `IndexedStack` — a **different 5-tab product for psychologists** (`psy_screens.dart`:
  Сегодня / Расписание / Запросы / Доходы / Профиль, plus `psy_client_screen.dart`
  and `psy_cabinet_edit_screen.dart`) vs seekers (home / specialists / community /
  calm / profile).
- **Video call:** `video_call_screen.dart` opens a Jitsi room **in a new tab**
  (public instances block iframe embedding) — see `docs/VIDEO_CALL.md`.

## Configuration

- The only config the frontend needs is **`nuva_app/.env`** (via `flutter_dotenv`;
  template `.env.example`). The key that matters is **`API_BASE_URL`** → the Railway
  backend; also `JITSI_DOMAIN` (video instance). `.env` is gitignored and isn't on a
  fresh clone — `cp .env.example .env` and set `API_BASE_URL` before building.
- `.env` is declared as a Flutter **asset**, so it ships inside the web build and is
  extractable — only put client-safe values in it (never a raw `ANTHROPIC_API_KEY`;
  AI calls go through the backend `ai` app).
- Backend secrets are configured in **Railway Variables**, not in the repo.
- The shipped target is **web (GitHub Pages PWA)**; Android signing is not set up.

## Common commands

```bash
cd nuva_app
flutter pub get
flutter run -d chrome                              # dev run (talks to the Railway backend)
flutter analyze                                    # static analysis
flutter build web --release --base-href /nuva/     # build for GitHub Pages (use PowerShell, not Git-Bash)
```

Test logins on the live backend: psychologist `demo.psy@nuva.kz` / `Demo12345`,
client `demo.client1@nuva.kz` / `Demo12345`.

## Conventions

- Private widgets are file-local `_PascalCase` classes — keep that; don't export.
- Reach theme tokens through `context.nuva`; shared strings through `S.of(ref)`.
  Psychologist-cabinet copy is hardcoded Russian (by design) — match the file.
- New routes go in `app_router.dart`. Detail screens are `push`ed; tabs live in `MainShell`.
- Keep the offline fallback intact: providers degrade to sample catalogs / empty
  results when the backend is unreachable.
- Workflow: commit + push each working increment with savepoint tags
  (`git tag savepoint/...`). Pushing `main` redeploys Railway; shipping the frontend
  means rebuilding + pushing `gh-pages` (see *How it's deployed*).

## Working a task (process — follow this every time)

For every change, in this order:

1. **Plan before touching code.** Outline the approach and the files/endpoints
   you'll touch first. If the task prompt says "show the plan and wait for OK"
   (payments, models, data-rights, anything irreversible), do that and **wait**
   before writing code.
2. **Follow the task prompt and the existing architecture.** Stay inside the
   patterns this file describes (Riverpod providers + `api_client`, `S.of(ref)`
   strings, `context.nuva` theme, DRF apps with object-level ownership). Don't
   introduce a parallel way of doing something that already has a convention.
3. **Write or extend tests for the change.** Backend: add/extend the app's
   `tests.py` and run `python manage.py test` (e.g. webhook signature +
   idempotency, ownership checks, status transitions). Frontend: at minimum keep
   `flutter analyze` clean and add widget/unit tests for new logic.
4. **Commit only after tests pass.** Run the tests (and `flutter analyze`) first;
   if green, commit the increment with a savepoint tag, then push (`main`
   redeploys the backend; frontend ships via `gh-pages`). Never commit on red.
5. **Keep this file current (memory).** If a change alters the architecture,
   conventions, env vars, or deploy flow, update the relevant section of
   `CLAUDE.md` in the same change — this file is the project's memory, so a stale
   line here costs every future session.

## Security-sensitive areas (be careful here)

This app handles **special-category personal data** (mental-health) plus payments
under Kazakhstan's Закон «О персональных данных» №94-V. Before touching these, read
`TECHNICAL_LETTER.md`:

- **Backend permissions** — enforce object-level ownership on every endpoint; users
  must never read another user's bookings, messages, or client notes.
- `payment_screen.dart` — still renders a raw PAN/CVV card form (PCI scope); the live
  flow uses a mock acquirer. Must move to a real acquirer SDK before launch.
- `video_call_screen.dart` — public Jitsi instances aren't private enough for
  mental-health calls; self-host or JaaS for production (`docs/VIDEO_CALL.md`).
- `legal_screens.dart` — privacy-policy claims (encryption/TLS) the code doesn't
  fully meet yet.

## Related docs

- `docs/BACKEND_ARCHITECTURE.md` — backend spec + roadmap.
- `docs/DEPLOY_RAILWAY.md` — Railway setup + the env vars to set.
- `docs/VIDEO_CALL.md` — Jitsi customization / self-host / JaaS options.
- `TECHNICAL_LETTER.md` — security & code-review findings (read before launch work).
