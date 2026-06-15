# Nuva Backend (Django + DRF)

Real API backend for Nuva. See [`../docs/BACKEND_ARCHITECTURE.md`](../docs/BACKEND_ARCHITECTURE.md)
for the full architecture + endpoint spec + sprint roadmap.

**Stack:** Django 5.2 · DRF · SimpleJWT (email+password) · PostgreSQL (Supabase) /
SQLite locally · Django Admin · deploy on Railway.

## Local dev (Windows)
```bash
cd backend
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt   # psycopg/gunicorn are prod-only; SQLite needs neither
copy .env.example .env            # optional; SQLite works with defaults
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py createsuperuser            # for /admin
.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```
- API base: `http://127.0.0.1:8000/api/v1/`
- Admin panel ("админка"): `http://127.0.0.1:8000/admin/`
- Health: `http://127.0.0.1:8000/healthz`

## Auth endpoints (Sprint 1 — done)
| Method | Path | Body | Auth |
|---|---|---|---|
| POST | `/api/v1/auth/register` | `{email, password, name?, role?}` | – |
| POST | `/api/v1/auth/login` | `{email, password}` | – |
| POST | `/api/v1/auth/refresh` | `{refresh}` | – |
| GET/PATCH | `/api/v1/auth/me` | (PATCH: `{name,age,gender,mbti,bio}`) | Bearer |

## Using Supabase Postgres instead of SQLite
Set `DATABASE_URL` in `.env` to the Supabase connection string (add your project's DB
password) and re-run `migrate` — all records then land in Supabase:
```
DATABASE_URL=postgresql://postgres:<DB_PASSWORD>@db.zliydmqixefzdiknbwol.supabase.co:5432/postgres
```

## Deploy to Railway
- New Railway project → deploy from the `backend/` dir (Nixpacks auto-detects Python).
- Set service variables: `SECRET_KEY`, `DEBUG=False`, `ALLOWED_HOSTS`, `DATABASE_URL`
  (Supabase), `CORS_ALLOWED_ORIGINS` (your app origins), later `ANTHROPIC_API_KEY`.
- `Procfile` / `railway.json` run `migrate` + `collectstatic` + gunicorn on `$PORT`.
