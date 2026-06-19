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
| **Flutter app** (the product) | `nuva_app/` | The actual web/mobile app, Dart/Flutter. Deployed as a PWA. **Most frontend work happens here.** |
| **Django backend** (the API) | `backend/` | Django + DRF + SimpleJWT REST API. Deployed on Railway. **All real data + auth live here.** |
| **Design showcase** (artifact) | repo root `*.jsx`, `Nuva.html`, `nuva-dashboard.html` | Browser-only React/Babel design gallery + a standalone business dashboard. Opened directly in a browser (React/Babel via CDN). Not built, not shipped. |

`Nuvastrategy.pdf` is a business/strategy document, not code.

> Unless a task is explicitly about the design showcase, "the app" means `nuva_app/`
> and "the backend" means `backend/`.

## ⚠️ This is a LIVE, backend-connected app (not the old mock-first prototype)

Earlier docs called this a "mock-first prototype wired to in-memory mocks." **That
is outdated.** The app now talks to the Django REST backend for real:

- **Auth is real:** email/password JWT (`lib/services/backend_auth.dart` +
  `auth_screen.dart`). `MainShell` has an auth gate — logout bounces to `/auth`.
  Flow: register → role select → onboarding → home; login → home.
- **Data is real, with mock fallback:** specialists, bookings, chat, community,
  mood journal all come from the backend via `lib/services/data.dart` providers
  (`apiClientProvider`). When the backend is unreachable they **degrade to the
  bundled mock catalogs** (`specialistCatalog`, `mockChats`) — keep that fallback
  intact so the app never hard-crashes offline.
- **Booking lifecycle is real:** бронь → запрос → подтверждение → оплата. A client
  books a *request* (free intro session or paid package); the psychologist
  accepts/declines; paid sessions then go through payment. The card acquirer is
  still mocked, but the booking rows + state transitions are real backend calls.
- **Video call:** opens a Jitsi room **in a new tab** (`video_call_screen.dart`).
  Public Jitsi instances (`meet.ffmuc.net`) now block iframe embedding, so we no
  longer embed — see `docs/VIDEO_CALL.md`.
- **AI intake/matching:** served by the backend `ai` app (`/api/v1/ai/match`,
  `/api/v1/ai/ask`).

## Production deployment (this is deployed and live)

- **Backend → Railway:** <https://nuva-production.up.railway.app>. Auto-deploys on
  push to `main`. `backend/railway.json` `startCommand` runs
  `migrate → ensure_admin → collectstatic → gunicorn` (so a healthy `/healthz`
  after a deploy means the migration applied). Django admin at `/admin/`.
- **Frontend → GitHub Pages:** <https://zhar04.github.io/nuva/>, served from the
  **`gh-pages`** branch, base href `/nuva/`. The app's `API_BASE_URL` points at the
  Railway backend, so **both the GitHub Pages build and any local `:8090` build hit
  Railway/Postgres**, not a local server.
- **To deploy the frontend:** `flutter build web --release --base-href /nuva/`
  (build with the **PowerShell tool, not Git-Bash** — MSYS mangles `/nuva/` into a
  Windows path and the base href silently falls back to `/`), then push `build/web`
  to `gh-pages` (e.g. via `git worktree add <dir> gh-pages` → replace contents →
  `touch .nojekyll` → commit → push). GitHub Pages doesn't serve dotfiles.

## Database — Postgres on Railway (NOT Supabase)

- The backend uses `dj-database-url` (`backend/nuva_backend/settings.py`):
  **SQLite locally** (`backend/db.sqlite3`, gitignored) and **Postgres in
  production via `DATABASE_URL`**. In production that `DATABASE_URL` is **Railway
  Postgres** (Railway's managed Postgres, injected as a service variable). The
  local SQLite file is a throwaway dev DB — it is *not* the production data.
- **Supabase is legacy.** `lib/services/{backend,auth_service,db_service}.dart`,
  `nuva_app/supabase/schema.sql`, and the `SUPABASE_*` keys in `.env` are
  left over from an earlier Supabase-targeted design. The live app does **not**
  use Supabase as its database or auth — that all moved to the Django backend. The
  Supabase anon key in `.env` is vestigial (don't treat Supabase as the source of
  truth).
- **Production secrets live in Railway → service → Variables** (`DATABASE_URL`,
  `SECRET_KEY`, `CORS_ALLOWED_ORIGINS`, etc.), **not** in any committed or local
  file. There is no `backend/.env` on disk by default — local dev just falls back
  to SQLite + insecure defaults. See `docs/DEPLOY_RAILWAY.md`.

## Backend architecture (`backend/`)

Django 5 + DRF + SimpleJWT. Apps:

- `accounts` — custom email `User` (roles: seeker / psychologist / admin), JWT
  auth (`/api/v1/auth/{register,login,refresh,me}`), pro-document uploads,
  `ensure_admin` management command (bootstraps the admin from env on deploy).
- `catalog` — `Specialist` / `Education` / `Review`; public list + detail; a
  psychologist edits their own listing via `PUT /api/v1/specialists/me`
  (writable nested education). Only `is_verified` specialists show in the catalog.
- `booking` — `Booking` (statuses: requested → scheduled/pending_payment → paid →
  completed, plus declined/cancelled/refunded) + `ClientNote`. Endpoints:
  `bookings/`, `bookings/incoming`, `bookings/{id}/{accept,decline,pay}`,
  `bookings/clients/{id}` (the psychologist's private client card: concern, mood
  trend, notes, session history).
- `chat` — 1:1 `Conversation` + `Message`, with a video-call request/accept
  handshake.
- `community` — anonymous posts + replies + likes.
- `journal` — daily `MoodEntry` (1 per day) + gamification stats.
- `ai` — Claude proxy (`/api/v1/ai/{match,ask}`) for intake/matching.

Local run: `cd backend && .venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000`.
⚠️ Django's autoreloader does **not** always pick up serializer/model edits —
restart `runserver` after backend `.py` changes (kill the PID on :8000, re-run).
`dev` seeder: `backend/seed_demo.py` fills the *local* SQLite with a demo
psychologist + clients/requests (useless against Railway — seed Railway via the
public API instead).

## Flutter app architecture (`nuva_app/`)

- **State:** `flutter_riverpod`. **Routing:** `go_router` (`lib/router/app_router.dart`).
- **API layer:** `lib/services/api_client.dart` (thin HTTP over `/api/v1/...`,
  base from `API_BASE_URL`), `backend_auth.dart` (JWT session), `data.dart` (all
  the Riverpod providers + `PsyActions` for psychologist write actions).
- **Design system:** `lib/theme/` (`tokens.dart`, `theme.dart`) + `lib/widgets/`
  (`glass.dart` = GlassCard/GlassBackdrop, `avatar.dart` = GradientAvatar / Tag /
  SectionLabel). Reach theme via the `context.nuva` extension.
- **Localization:** all strings in `lib/l10n/strings.dart` (`S.of(ref)`), language
  in the Riverpod `langProvider` (RU/KK/EN). No `.arb` files. Theme mode in
  `themeModeProvider`. (The psychologist cabinet screens are RU-only by design.)
- **Screens:** `lib/screens/` (one file each). `main_shell.dart` is the bottom-nav
  `IndexedStack` — it shows a **different 5-tab product for psychologists**
  (`psy_screens.dart`: Сегодня / Расписание / Запросы / Доходы / Профиль, plus
  `psy_client_screen.dart` and `psy_cabinet_edit_screen.dart`) vs seekers
  (home / specialists / community / calm / profile).
- **Models:** `lib/models/` (`specialist.dart`, `booking.dart`, `chat.dart`,
  `community.dart`) — also hold the in-memory **mock catalogs** used as the
  offline fallback.

## Configuration & secrets

- Frontend config is `nuva_app/.env` (via `flutter_dotenv`; template `.env.example`).
  Keys that matter: **`API_BASE_URL`** (→ the Railway backend), `JITSI_DOMAIN`
  (video instance), and the legacy `SUPABASE_URL` / `SUPABASE_ANON_KEY`,
  `CLAUDE_PROXY_URL`, `SENTRY_DSN`.
- `.env` is **gitignored** and **does not exist on a fresh clone** — `cp .env.example .env`
  (or copy the real one) before building. It is declared as a Flutter **asset**, so
  the build fails without it, and **anything in it ships inside the web/APK build
  and is extractable** — only client-safe values (the Supabase *anon* key is fine;
  a raw `ANTHROPIC_API_KEY` is not — use the backend/proxy).
- **Backend prod secrets are in Railway Variables**, never in the repo.
- Android release signing would read `android/key.properties` (gitignored, absent) —
  Android signing is not set up; **web (GitHub Pages PWA) is the shipped target.**

## Common commands

```bash
# Frontend
cd nuva_app
flutter pub get
flutter run -d chrome                       # local dev (talks to Railway via .env)
flutter analyze                             # static analysis
flutter build web --release --base-href /nuva/   # build for GitHub Pages (use PowerShell, not Git-Bash)

# Backend (local)
cd backend
.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
.venv\Scripts\python.exe manage.py migrate
```

## Conventions

- Private widgets are file-local `_PascalCase` classes — keep that pattern; don't export.
- Reach theme tokens through `context.nuva`; reach shared strings through `S.of(ref)`.
  Psychologist-cabinet copy is hardcoded Russian (by design) — match the surrounding file.
- New routes go in `app_router.dart`. Detail screens are `push`ed; tabs live in `MainShell`.
- **Keep the backend-vs-mock fallback intact:** providers must degrade to the mock
  catalogs / empty results when the backend is unreachable, so the app keeps running.
- The user prefers commit + push each working increment with savepoint tags
  (`git tag savepoint/...`). Pushing `main` redeploys Railway; deploying the
  frontend means rebuilding + pushing `gh-pages` (see above).

## Security-sensitive areas (be careful here)

This app handles **special-category personal data** (mental-health) plus payments
under Kazakhstan's Закон «О персональных данных» №94-V. Before touching these, read
`TECHNICAL_LETTER.md`:

- `backend/` — RLS is no longer the model; the Django ORM + DRF permissions are.
  Check object-level ownership on every endpoint (e.g. a psychologist can only see
  their own incoming bookings / client cards).
- `payment_screen.dart` — still renders a raw PAN/CVV card form (PCI scope); the
  live flow uses a mock acquirer. Must move to a real acquirer SDK before launch.
- `video_call_screen.dart` — public Jitsi instances aren't private enough for
  mental-health calls; self-host or JaaS for production (`docs/VIDEO_CALL.md`).
- `legal_screens.dart` — privacy-policy claims (encryption/TLS) the code doesn't
  fully meet yet.
- Legacy (Supabase/Cloudflare era, mostly dormant but still in-repo):
  `server/cloudflare-worker.js` (open CORS), `supabase/schema.sql`,
  `auth_service.dart` (mock OTP returns `true`).

## Related docs

- `docs/PROGRESS.md` — resume notes + local restart-after-reboot steps.
- `docs/BACKEND_ARCHITECTURE.md` — backend spec + sprint roadmap.
- `docs/DEPLOY_RAILWAY.md` — Railway setup + the env vars to set.
- `docs/VIDEO_CALL.md` — Jitsi customization / self-host / JaaS options.
- `TECHNICAL_LETTER.md` — security & code-review findings (read before launch work).
