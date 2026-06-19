# Deploy the Nuva backend to Railway

The backend is deploy-ready: `Procfile` + `railway.json` run
`migrate → collectstatic → gunicorn`, config is 12-factor (env vars), Postgres is
wired via `DATABASE_URL`, static files are served by WhiteNoise, and production
security (HTTPS redirect, secure cookies, HSTS, proxy-SSL header) switches on when
`DEBUG=False`.

You do the clicks in Railway; everything else is already in the repo.

---

## 1. Create the Railway service

1. Go to <https://railway.app> → **New Project** → **Deploy from GitHub repo** →
   pick **`Zhar04/nuva`**. (Authorize Railway to read the repo if asked.)
2. Open the created service → **Settings**:
   - **Root Directory**: `backend`  ← important, the Django app lives there.
   - Builder: **Nixpacks** (default). It auto-detects `requirements.txt` and
     pins Python via `runtime.txt` (3.12.8).

## 2. Add a database

**Easiest — Railway Postgres** (recommended):
- In the project → **New** → **Database** → **Add PostgreSQL**.
- Railway auto-injects `DATABASE_URL` into your service. Nothing else to do.

**Or — your existing Supabase Postgres**:
- Supabase dashboard → **Project Settings → Database → Connection string → URI**.
- Copy it and add `?sslmode=require` at the end if it isn't already there.
- Set it as the `DATABASE_URL` variable on the Railway service (step 3).

## 3. Set environment variables

Service → **Variables** → add:

| Variable | Value |
|---|---|
| `SECRET_KEY` | `#+6qlds3*1fg(4d6=saxp+gun2-(n_v85#k-@a391mu+22a%1j` (or generate your own) |
| `DEBUG` | `False` |
| `ALLOWED_HOSTS` | `localhost,127.0.0.1` (Railway's own domain is trusted automatically) |
| `CORS_ALLOWED_ORIGINS` | `https://zhar04.github.io` (the PWA origin; add others comma-separated) |
| `CSRF_TRUSTED_ORIGINS` | `https://zhar04.github.io` |
| `DATABASE_URL` | only if you chose Supabase in step 2 |
| `ANTHROPIC_API_KEY` | optional — enables real AI Q&A (`/api/v1/ai/ask/`); without it the endpoint returns a safe canned reply |
| `ANTHROPIC_MODEL` | optional — Claude model id (default `claude-opus-4-8`) |

> Railway sets `RAILWAY_PUBLIC_DOMAIN` itself — the settings already append it to
> `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS`, so you don't list the railway.app
> host yourself.

## 4. Deploy

Railway deploys on push and on variable changes. The start command (from
`railway.json`) runs:

```
python manage.py migrate --noinput && python manage.py collectstatic --noinput && gunicorn nuva_backend.wsgi --bind 0.0.0.0:$PORT
```

Migrations also **seed** the catalog (5 specialists) and community (5 starter
posts), so the deployed app isn't empty.

When it goes green, open **Settings → Networking → Generate Domain** to get the
public URL, e.g. `https://nuva-backend-production.up.railway.app`.

Smoke-test it:
```
curl https://<your-domain>/healthz
# {"status":"ok","service":"nuva-backend"}
```

## 5. Create the admin user (one-off)

Locally, with the Railway CLI (`npm i -g @railway/cli`, then `railway link`):
```
railway run python manage.py createsuperuser
```
Or use Railway's web shell on the service. Then log in at
`https://<your-domain>/admin/`.

## 6. Point the app at the deployed backend

1. In `nuva_app/.env` set:
   ```
   API_BASE_URL=https://<your-domain>
   ```
2. Rebuild + redeploy the PWA:
   ```
   cd nuva_app
   flutter build web --release
   # publish build/web to GitHub Pages (the zhar04.github.io/nuva deploy)
   ```
3. Make sure the PWA origin is in `CORS_ALLOWED_ORIGINS` (step 3). If you serve it
   from a different host than `zhar04.github.io`, add that origin too.

---

## Notes / gotchas

- **Don't commit secrets.** `.env`, `db.sqlite3`, `.venv/`, `staticfiles/` are
  gitignored. Set real values only in Railway Variables.
- **SQLite vs Postgres:** with no `DATABASE_URL`, Django falls back to SQLite —
  fine locally, never in prod (Railway's filesystem is ephemeral). Always have a
  Postgres `DATABASE_URL` in Railway.
- **Free tier:** Railway's trial/credits cover a small service + Postgres. If the
  service sleeps, the first request after idle is slow — that's expected.
- **AI navigator (Claude):** specialist matching (`/api/v1/ai/match/`) is rule-based
  and always works. Basic Q&A (`/api/v1/ai/ask/`) is proxied to Anthropic's Claude
  (Messages API) — add `ANTHROPIC_API_KEY` (from <https://console.anthropic.com>) as
  a Railway variable to enable real answers; without it the endpoint returns a safe
  canned reply. Optional `ANTHROPIC_MODEL` (default `claude-opus-4-8`). The key lives
  only in Railway Variables — it never ships in the app. Crisis input is always
  short-circuited to emergency resources and never sent to the model.
