# Nuva — Build Progress & Resume Context

**Read this FIRST to resume an interrupted build** (e.g. after usage limits reset).
Single source of truth for the multi-epic UI/feature work. Any agent — a scheduled
cloud routine or a fresh local session — should read this, find the first
unfinished epic, and continue, then update this file.

---

## ⭐ CURRENT STATE (2026-06-15) — now building the BACKEND
The 3 UI epics are ✅ done (`savepoint/epic-1..3`); Liquid-Morph navbar + a GitHub-Pages PWA (`https://zhar04.github.io/nuva/`) shipped. **Current focus: the real backend** — full spec in **[`docs/BACKEND_ARCHITECTURE.md`](BACKEND_ARCHITECTURE.md)**.

**Backend Sprint 1 (Auth) = DONE & pushed** (latest `5946ca8`; tags `backend/sprint-1-auth`, `backend/sprint-1-app`):
- **Django + DRF + JWT** (email/password) in `backend/`. Custom email `User` + roles. `/api/v1/auth/{register,login,refresh,me}`. **Admin panel** at `/admin`.
- **Flutter wired:** `lib/services/api_client.dart` + `backend_auth.dart`; `auth_screen.dart` (email/password). Flow: intro slides → `/auth`; **register → role → onboarding → home**; **login → home**; **logout → gated back to /auth**.
- **DB:** local **SQLite** (`backend/db.sqlite3`, gitignored, **persists on disk** → registered users + admin survive a reboot). Switch to Supabase Postgres later via `DATABASE_URL`.

### ▶▶ RESTART AFTER A DEVICE REBOOT
Local servers stop on reboot, but `.env` + `db.sqlite3` + `.venv` survive on disk. To bring it back:
1. **Backend** (API + admin): `cd backend` → `.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000`
   → admin: http://127.0.0.1:8000/admin/ (`admin@nuva.kz` / `NuvaAdmin2026!`)
2. **App** (web; release build renders in Brave): `cd nuva_app` → `flutter build web --release` → `cd build\web` → `python -m http.server 8090 --bind 127.0.0.1` → open http://localhost:8090
   *(Faster dev loop in Chrome: `flutter run -d chrome` from `nuva_app/` — hot reload; debug white-screens in Brave only.)*
3. Verify: backend `GET /healthz` = ok; app loads; register → onboarding, login → home, logout → gated.

**NEXT: Backend Sprint 2 — Specialists** = `Specialist`/`Education`/`Review` models + `/api/v1/specialists` + register in admin + switch the Flutter specialists list/detail from the Supabase mock → backend API. Then S3 bookings · S4 chat · S5 community · S6 mood/gamification · S7 Claude proxy + **Railway deploy**.

---

## ▶ How to resume (do this first)
1. `cd` to repo root, `git fetch`, `git status`. List savepoints: `git tag -l "savepoint/*"`.
2. Read this file + the epic plan files in [`docs/epics/`](epics/).
3. Find the first epic in the **Status** table not marked ✅ done → continue its checklist.
4. Test per **Testing** below. After an epic completes: commit, tag `savepoint/epic-N`, push, and update this file + that epic's plan doc.

## ▶ Environment / run
- **Flutter SDK:** `C:\Users\uzhar\dev\flutter` (on PATH). Windows, **web target only** (no Android SDK).
- **Run (web):** from `nuva_app/` → `flutter run -d chrome --web-port 8088` → http://localhost:8088
- **Config:** `nuva_app/.env` (gitignored) has Supabase URL + publishable key (project ref `zliydmqixefzdiknbwol`). `schema.sql` is applied. **Anonymous sign-ins are DISABLED** → RLS writes blocked until enabled in Supabase dashboard. No Anthropic key → AI intake disabled; `/skip` command bypasses intake.
- A web build is usually already running in the background; restart it to see changes (full restart picks up `.env`; code changes need at least hot restart).

## ▶ Testing (run after each epic)
- `flutter analyze` → **0 errors** required (warnings/infos from pre-existing code are OK).
- Rebuild web (`flutter run -d chrome --web-port 8088`) and confirm http://localhost:8088 returns 200 and key screens render.
- Add/keep lightweight widget tests under `nuva_app/test/` where feasible; `flutter test`.

## ▶ Git / savepoints
- Remote: **github.com/Zhar04/nuva** (`origin/main`). Linear history + savepoint **tags** (NOT feature branches).
- Rollback to any point: `git reset --hard savepoint/<tag>`.
- After each epic: `git add -A && git commit -m "..." && git tag savepoint/epic-N && git push origin main --tags`.
- Never commit `nuva_app/.env` or any key/keystore (already in `.gitignore` — verify before each push with `git ls-files | grep -iE '\.env$|key\.properties|\.jks'`).

---

## The work: 10 requests → 3 epics

Original 10 points (RU, from the user):
1. Redesign mood selector emoji (Грустно–Хорошо) to match the Liquid Glass design.
2. Home cards too gray / not clickable-looking → make them more Liquid Glass.
3. Rename "Чат с ИИ" → softer name (e.g. "Найти мэтч" / "Помощь в подборе"); the word "ИИ" feels unsafe.
4. Pull-to-refresh + no dead space when scrolling to the end of lists.
5. Floating bottom navbar (App Store / iOS-26 Liquid Glass style).
6. Покой (Calm) menu → richer experience like Endel / "Mediatopia: Sleep".
7. In chats, label "Психолог" for psychologists; no label for regular users.
8. Profile menu items that don't open (Мои сессии, Дневник настроения, Избранные, Уведомления, Помощь, account settings) → make them work; add avatar photo, edit name, bio, MBTI.
9. User rating/points (monthly reset) + psychologist-awarded achievements after a course (IronMan-style badge) + course progress bar, shareable like Strava.
10. Role-based registration (User / Psychologist) with a kind name for the user role; onboarding pipelines for both; data + document upload (diploma PDF/PNG), avatar/name/age/gender/MBTI (+ note to take a fuller test), 4–5 calm intro psychology questions then hand off to the AI module (with skip). Psychologists skip the AI module entirely; require diploma/certs, expertise area, maybe work record, mandatory photo + basics.

### Epic grouping
- **Epic 1 — Liquid Glass UI polish:** points 1, 2, 4, 5
- **Epic 2 — Content & wording:** points 3, 6, 7
- **Epic 3 — Identity & engagement:** points 8, 9, 10

### Locked decisions
- Design points: document **3 concepts** each in the epic plan file; **build the recommended one**; user picks the final later (I swap if needed).
- **Epic 3 = UI/flow prototype** first: local state, diploma-upload UI stubbed, new Supabase tables/Storage/RLS documented as a follow-up (not built tonight).
- Git: dedicated project repo, linear history, savepoint tags, push to origin/main.

---

## Status
| Epic | Scope | Status | Savepoint |
|---|---|---|---|
| 0 | Baseline + earlier Supabase data-layer integration | ✅ done | `savepoint/epic-0-baseline` |
| 1 | Liquid Glass UI: mood, cards, pull-refresh, floating navbar | ✅ done | `savepoint/epic-1` |
| 2 | Content & wording: rename Чат с ИИ, Покой redesign, chat labels | ✅ done | `savepoint/epic-2` |
| 3 | Identity: profile editing, gamification, role onboarding | ✅ done | `savepoint/epic-3` |

## Next step
**All 3 epics complete.** ✅ The scheduled `nuva-epic-resume` routine can now be deleted (https://claude.ai/code/routines) — when it next fires it will see all epics done and no-op.

Possible follow-ups (not requested tonight): wire the documented Supabase tables/Storage for real diploma uploads + role data; trilingualize the new Epic 3 screens (currently RU); the user will pick final design variants from the 3 concepts per design point (in each EPIC_*.md) and I swap if needed.

_Last updated: Epic 3 complete + pushed (savepoint/epic-3). Role-based registration + user/psychologist onboarding steppers, working profile + editor (persisted), gamification card + progress screen. analyze-clean, web serves 200. All epics done._
