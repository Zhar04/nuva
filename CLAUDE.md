# CLAUDE.md

Guidance for Claude Code (and humans) working in this repo. Read this first — it
captures the architecture and the non-obvious gotchas so you don't have to
re-derive them every session.

## What this repo is

**Nuva** — a mental-health support platform for the Kazakhstan market: AI-assisted
specialist matching, a psychologist marketplace, in-app chat, a video room, an
anonymous community, and a mood journal. Liquid-Glass (iOS-style) design.
RU / KK / EN localization.

The repo holds **two independent things**:

| Part | Path | What it is |
|---|---|---|
| **Flutter app** (the product) | `nuva_app/` | The actual mobile/web app, Dart/Flutter. **This is where almost all real work happens.** |
| **Design showcase** (artifact) | repo root `*.jsx`, `Nuva.html`, `nuva-dashboard.html`, `lib/ios-frame.jsx` | Browser-only React/Babel design gallery + a standalone business dashboard. Opened directly in a browser (React/Babel via CDN). Not built, not shipped, no backend. |

`Nuvastrategy.pdf` is a business/strategy document, not code.

> Unless a task is explicitly about the design showcase, assume it means `nuva_app/`.

## Flutter app architecture (`nuva_app/`)

- **State:** `flutter_riverpod`. **Routing:** `go_router` (`lib/router/app_router.dart`).
- **Design system:** `lib/theme/` (`tokens.dart`, `theme.dart`) + `lib/widgets/`
  (`glass.dart` = GlassCard/GlassBackdrop, `avatar.dart`). Access theme via
  `context.nuva` extension.
- **Localization:** all strings live in one file — `lib/l10n/strings.dart`
  (`S.of(ref)`), language held in a Riverpod `langProvider`. No `.arb` files.
- **Screens:** `lib/screens/` (~18 screens, one file each). `main_shell.dart` is the
  bottom-nav `IndexedStack`.
- **Models:** `lib/models/` (`specialist.dart`, `chat.dart`, `community.dart`) — also
  contain the in-memory **mock catalogs** (`specialistCatalog`, `mockChats`).
- **Services:** `lib/services/`
  - `backend.dart` — Supabase bootstrap. `Backend.enabled` is false unless
    `SUPABASE_URL`/`SUPABASE_ANON_KEY` are set in `.env`.
  - `auth_service.dart` — phone OTP via Supabase.
  - `db_service.dart` — thin CRUD over Supabase tables.
  - `claude_service.dart` — Anthropic Messages wrapper; proxy mode or direct mode.
  - `observability.dart` — **stub** (just `debugPrint`); Sentry is disabled in
    `pubspec.yaml` pending a Kotlin/R8 fix.
- **Backend (not Dart):**
  - `server/cloudflare-worker.js` — Cloudflare Worker that proxies Claude calls so
    the Anthropic key stays server-side.
  - `supabase/schema.sql` — Postgres schema + Row-Level Security policies + seed data.

### ⚠️ The single most important thing to understand: it's a mock-first prototype

The UI is wired to **in-memory mocks**, not the backend. As of now:

- `DbService` and `AuthService` are written but **never called by any screen**
  (grep confirms). The app shows `specialistCatalog` / `mockChats`, not Supabase data.
- There is **no login/auth screen** and **no auth guard** in the router — every route
  is reachable without signing in.
- **Payment** (`payment_screen.dart`) is a fake `Future.delayed` that always navigates
  to "success." No acquirer is called.
- **Video call** is a visual stub (no WebRTC, no camera/mic).
- **Community "Publish"** just pops the screen (does not call `publishPost`).
- Claude intake works **only** if `CLAUDE_PROXY_URL` (or dev `ANTHROPIC_API_KEY`) is set.

So "the backend is done" means *the scaffolding exists*, not *it's connected*. Treat
README/LAUNCH "✅" claims as aspirational. See `TECHNICAL_LETTER.md` for the full gap list.

## Configuration & secrets

- Config is read from `nuva_app/.env` via `flutter_dotenv`. Template: `.env.example`.
  Keys: `CLAUDE_PROXY_URL`, `ANTHROPIC_API_KEY` (dev only), `SUPABASE_URL`,
  `SUPABASE_ANON_KEY`, `SENTRY_DSN`.
- `.env` is **not committed** (`.gitignore`) and **does not exist on disk** by default —
  you must `cp .env.example .env` before building (it's declared as a Flutter asset, so
  the build needs the file to exist even if empty).
- ⚠️ **`.env` is bundled as a Flutter asset** (`pubspec.yaml` → `flutter: assets: - .env`).
  Anything in it ships inside the APK/web build and is extractable. Only put
  client-safe values there (Supabase **anon** key is fine — it's protected by RLS;
  a raw `ANTHROPIC_API_KEY` is **not** — use the proxy). See `TECHNICAL_LETTER.md` C1.
- Android release signing reads `android/key.properties` (gitignored, absent by
  default). LAUNCH.md references a keystore under `C:\Users\daniko\...` — paths are
  machine-specific and will not resolve here.

## Common commands

```bash
cd nuva_app
cp .env.example .env        # required before first build (even if left blank → mock mode)
flutter pub get
flutter run                 # device / emulator
flutter run -d chrome       # web
flutter analyze             # static analysis (flutter_lints)
flutter test                # only a placeholder smoke test exists today
flutter build apk --release
flutter build appbundle     # AAB for Google Play
```

Fonts: the `Onest` font referenced by the design is expected in `assets/fonts/`
(download separately; not committed). Icons/splash regenerated via
`tool/make_icon.py` + `flutter_launcher_icons` / `flutter_native_splash`.

## Conventions

- Private widgets are file-local `_PascalCase` classes (e.g. `_Header`, `_Composer`)
  — keep that pattern; don't export them.
- Reach theme tokens through `context.nuva`; reach strings through `S.of(ref)`. Add new
  user-facing text to `lib/l10n/strings.dart` in all three languages.
- New routes go in `app_router.dart`. Detail screens are `push`ed; tabs are inside
  `MainShell`.
- Keep the mock-vs-backend duality intact: services must degrade gracefully to mocks
  when `Backend.enabled` is false (return `[]`/`null`/no-op), so the app keeps running
  without keys.

## Security-sensitive areas (be careful here)

This app handles **special-category personal data** (mental-health) plus payments under
Kazakhstan's Закон «О персональных данных» №94-V. Before touching these, read
`TECHNICAL_LETTER.md`:

- `server/cloudflare-worker.js` — currently **open CORS + no auth/rate-limit** (billing-abuse risk).
- `payment_screen.dart` — collects raw PAN/CVV in-app (PCI scope); must move to acquirer SDK.
- `supabase/schema.sql` — RLS policies; a few are spoofable (`sender_id`, `author_alias`, `likes_count`).
- `legal_screens.dart` — privacy policy claims (encryption/TLS) that the code does not yet meet.
- `auth_service.dart` — `verifyOtp` returns `true` in mock mode (latent auth-bypass landmine).

## Related docs

- `nuva_app/README.md` — feature/readiness table.
- `nuva_app/LAUNCH.md` — go-to-market checklist (Supabase, Cloudflare, payments, store).
- `TECHNICAL_LETTER.md` — security & code-review findings + remediation roadmap (read before launch work).
