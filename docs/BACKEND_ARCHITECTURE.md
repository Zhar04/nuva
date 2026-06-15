# Nuva Backend — Architecture & API Spec

**Status:** Sprint 0 (planning) → building incrementally.
**Stack (locked):** Django 5.2 + Django REST Framework + SimpleJWT (email/password auth) ·
PostgreSQL on **Supabase** (schema owned by Django migrations) · **Django Admin** for ops ·
deployed on **Railway**. Local dev runs on SQLite (zero-config) and flips to Supabase via `DATABASE_URL`.

---

## 1. Why / what changes
Today the Flutter app talks **directly** to Supabase (client SDK + RLS) with many stubs.
We're inserting a **real backend service** so every write goes through a validated, audited
API, and you get an **admin panel** to manage data. The app's data layer migrates from
`supabase_flutter` → a thin **HTTP client** hitting this API, feature by feature (stubs
removed as each endpoint lands).

```
Flutter app  ──HTTPS──▶  Django REST API (Railway)  ──▶  Supabase Postgres
                              │
                              ├─ /admin  (Django Admin: CRUD users, psychologists, sessions…)
                              ├─ /api/v1/… (versioned REST, JWT-auth, OpenAPI docs)
                              └─ /api/v1/intake (Claude proxy — replaces the Cloudflare Worker)
```

## 2. Project structure
```
backend/
  manage.py · requirements.txt · .env.example · Procfile · railway.json · README.md
  nuva_backend/        # settings, urls, wsgi/asgi
  accounts/   ✅Sprint1 # custom User (email login), JWT auth, profile, role
  catalog/    Sprint2   # specialists, education, reviews
  booking/    Sprint3   # bookings / sessions
  chat/       Sprint4   # chats, messages
  community/  Sprint5   # posts, replies, likes
  mood/       Sprint6   # mood journal entries
  gamification/ Sprint6 # points, achievements, course progress
  intake/     Sprint7   # Claude proxy endpoint
  core/                 # shared: base models, pagination, permissions, health
```

## 3. Data model (Django-owned schema)
- **User** (accounts): `email` (unique, USERNAME_FIELD), `password`, `role` (`seeker|psychologist|admin`), `name`, `age`, `gender`, `mbti`, `bio`, `is_staff`, `is_active`, timestamps.
- **Specialist** (catalog): first/last name, title, years_experience, languages[], approaches[], works_with[], session_price_kzt, rating, review_count, about, avatar_gradient[], is_verified, is_active, whatsapp; FK optional → User (psychologist account).
- **Education**, **Review** → FK Specialist.
- **Booking** (booking): FK user, FK specialist, starts_at, format (`video|audio|chat`), duration, price_kzt, service_fee_kzt, status (`pending_payment|paid|completed|cancelled|refunded`), payment_provider/id.
- **Chat** → (user, specialist) unique; **Message** → FK chat, sender, text, is_voice, sent_at.
- **CommunityPost** → author, alias, text, tags[], likes_count, is_supported; **CommunityReply** → post, author, alias, text, from_specialist.
- **MoodEntry** → user, mood(1-5), note, created_at.
- **Achievement / PointsLedger / CourseProgress** (gamification).

## 4. Auth (Sprint 1) — JWT, email + password
- `POST /api/v1/auth/register` `{email, password, name, role?}` → `{user, access, refresh}`
- `POST /api/v1/auth/login` `{email, password}` → `{access, refresh}`
- `POST /api/v1/auth/refresh` `{refresh}` → `{access}`
- `GET  /api/v1/auth/me` (Bearer) → current user
- `PATCH /api/v1/auth/me` → update name/bio/mbti/age/gender
- Access token ~30 min, refresh ~7 days (SimpleJWT). Passwords hashed (PBKDF2).
- Phone-OTP and anonymous are **later** add-ons (need an SMS provider $).

## 5. REST endpoints (by sprint)
| Resource | Methods | Notes |
|---|---|---|
| `auth/*` | register, login, refresh, me | Sprint 1 |
| `specialists` | `GET /` list (filters: tag, lang), `GET /{id}` detail (+reviews, education) | Sprint 2, public read |
| `bookings` | `GET /` mine, `POST /`, `GET /{id}`, `PATCH /{id}` cancel | Sprint 3, auth |
| `chats` | `GET /`, `POST /`, `GET /{id}/messages`, `POST /{id}/messages` | Sprint 4, auth |
| `community/posts` | `GET /` (tag filter, pagination), `POST /`, `GET /{id}`, `POST /{id}/replies`, `POST /{id}/like` | Sprint 5 |
| `mood` | `GET /`, `POST /` | Sprint 6, auth |
| `gamification/me` | `GET /` points+achievements+course | Sprint 6 |
| `intake` | `POST /` Claude proxy (server holds the key) | Sprint 7 |
| `health` | `GET /healthz` | always |

Conventions: JSON, `snake_case`, cursor/page pagination, DRF throttling, consistent error
envelope `{detail|errors}`, OpenAPI/Swagger at `/api/schema` + `/api/docs`.

## 6. Admin panel
**Django Admin at `/admin`** (superuser login). Registers every model with list/search/
filter/inline editing → you add/delete **users, psychologists, education, reviews,
bookings, sessions, posts, mood entries**. This is the "админка" requirement, batteries-included.

## 7. Config / env (`backend/.env`, server-side only — never in the app)
`SECRET_KEY` · `DEBUG` · `ALLOWED_HOSTS` · `DATABASE_URL` (unset → SQLite local; set →
Supabase Postgres) · `CORS_ALLOWED_ORIGINS` · `ANTHROPIC_API_KEY` (Sprint 7) ·
`ACCESS_TOKEN_MIN` · `REFRESH_TOKEN_DAYS`.
Supabase Postgres URL form: `postgresql://postgres:<DB_PASSWORD>@db.zliydmqixefzdiknbwol.supabase.co:5432/postgres` (you add the DB password locally; it stays out of git/chat).

## 8. Local dev vs prod
- **Local:** `python manage.py runserver` on SQLite (no Postgres needed) → test endpoints with curl.
- **Supabase:** set `DATABASE_URL` to the Supabase connection string → `migrate` → records land in Supabase.
- **Railway:** `Procfile` (`web: gunicorn nuva_backend.wsgi`), release runs `migrate`,
  `collectstatic` + WhiteNoise for admin assets, `DATABASE_URL`/secrets in Railway vars,
  `psycopg[binary]` added for Postgres (Linux wheels available on Railway).

## 9. Standards checklist
Hashed passwords · JWT · CORS allowlist (not `*`) · per-view permissions · input validation
(serializers) · pagination + throttling · OpenAPI docs · 12-factor config via env ·
migrations in VCS · `.env`/secrets gitignored · health check · structured errors.

## 10. Sprint roadmap (each: endpoints + admin + remove stubs + wire app + test local + commit)
- **S0** scaffold + this doc ✅
- **S1** auth (User, JWT, /me, admin) + Flutter login/register → backend
- **S2** specialists (real catalog) — remove specialist mocks
- **S3** bookings/sessions — remove fake payment-success-only flow
- **S4** chat (messages) — remove mockChats
- **S5** community (posts/replies/likes) — remove communityFeed mock
- **S6** mood + gamification — remove local-only mood/points
- **S7** Claude intake proxy + admin polish + **Railway deploy**

_Last updated: Sprint 0 — scaffold done (Django 5.2.15 on Py3.14), architecture locked._
