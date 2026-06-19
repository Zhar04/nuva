/**
 * Nuva — Claude intake proxy (Cloudflare Worker)
 *
 * Secrets (set via wrangler secret put):
 *   ANTHROPIC_API_KEY   — Anthropic billing key, never leaves the server
 *   NUVA_CLIENT_KEY     — shared token Flutter sends in x-nuva-key header
 *
 * Deploy:
 *   cd nuva_app/server
 *   npx wrangler deploy
 *   npx wrangler secret put ANTHROPIC_API_KEY
 *   npx wrangler secret put NUVA_CLIENT_KEY
 */

// Origins allowed for browser (Flutter web) callers.
// Mobile apps don't send Origin, so they bypass this check.
const ALLOWED_ORIGINS = [
  'https://nuva.kz',
  'https://www.nuva.kz',
  'https://zhar04.github.io',
  'http://localhost:9090',
  'http://localhost:8088',
];

const SYSTEM_PROMPT = (lang) => `
You are Nuva, an empathetic intake assistant for a Kazakhstan mental-health app.
Always respond in ${lang}.

Goal: in 4 short steps, understand the user well enough to suggest 1–3 psychologists from our catalog. Steps:
1. What's troubling them right now (open question, listen).
2. What outcome they want (relief, clarity, change, support).
3. Format preference (online video, chat, in person), language, budget if comfortable.
4. Practical check (urgency, prior therapy experience, any safety concerns).

Tone: warm, short, validating. One question at a time. 2–3 sentences max per reply. Never diagnose.
If user signals crisis or self-harm, gently surface the local helpline (Казахстан: 150) and suggest contacting emergency services.

After step 4 reply with a brief summary and ask if they want to see matched specialists.
`;

const LANG_MAP = { kk: 'Kazakh (қазақша)', en: 'English' };

export default {
  async fetch(request, env) {
    const origin = request.headers.get('origin') ?? '';

    // ── CORS pre-flight ────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return corsResponse(null, 204, origin);
    }

    // ── Method guard ───────────────────────────────────────────────
    if (request.method !== 'POST') {
      return corsResponse('Method not allowed', 405, origin);
    }

    // ── Origin check (browser clients only; mobile has no Origin) ──
    if (origin && !ALLOWED_ORIGINS.includes(origin)) {
      return corsResponse('Forbidden', 403, origin);
    }

    // ── Client auth token ─────────────────────────────────────────
    // Flutter sends x-nuva-key from CLAUDE_CLIENT_KEY in .env.
    // Mobile APK can be reverse-engineered, so this stops casual abuse only.
    // For robust protection enable Cloudflare Rate Limiting in the dashboard.
    const clientKey = request.headers.get('x-nuva-key') ?? '';
    if (env.NUVA_CLIENT_KEY && clientKey !== env.NUVA_CLIENT_KEY) {
      return corsResponse('Unauthorized', 401, origin);
    }

    // ── Parse body ────────────────────────────────────────────────
    let body;
    try {
      body = await request.json();
    } catch {
      return corsResponse('Bad JSON', 400, origin);
    }

    const messages = Array.isArray(body.messages) ? body.messages : [];
    if (messages.length === 0) {
      return corsResponse('messages array required', 400, origin);
    }
    // Sanity-cap to prevent token-stuffing.
    if (messages.length > 40) {
      return corsResponse('Too many messages', 400, origin);
    }

    const language = LANG_MAP[body.language] ?? 'Russian (русский)';

    // ── Forward to Anthropic ──────────────────────────────────────
    const upstream = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001', // fast + cheap for intake chat
        max_tokens: 600,
        system: SYSTEM_PROMPT(language),
        messages,
      }),
    });

    if (!upstream.ok) {
      const detail = await upstream.text();
      return corsResponse(
        JSON.stringify({ error: `claude ${upstream.status}`, detail }),
        upstream.status,
        origin,
        'application/json',
      );
    }

    const payload = await upstream.json();
    const reply = (payload.content ?? [])
      .filter((b) => b.type === 'text')
      .map((b) => b.text)
      .join('\n')
      .trim();

    return corsResponse(JSON.stringify({ reply }), 200, origin, 'application/json');
  },
};

// ── Helpers ───────────────────────────────────────────────────────

function corsHeaders(origin) {
  // Reflect a specific allowed origin back; fall back to wildcard only when
  // there is no Origin (native mobile — no browser same-origin enforcement).
  const allowOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : '*';
  return {
    'access-control-allow-origin': allowOrigin,
    'access-control-allow-headers': 'content-type, x-nuva-key',
    'access-control-allow-methods': 'POST, OPTIONS',
  };
}

function corsResponse(body, status, origin, contentType = 'text/plain') {
  const headers = {
    ...corsHeaders(origin),
    ...(body !== null ? { 'content-type': contentType } : {}),
  };
  return new Response(body, { status, headers });
}
