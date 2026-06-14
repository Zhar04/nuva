/**
 * Nuva Claude proxy — deploy on Cloudflare Workers (free tier covers up to
 * 100k requests/day). Steps:
 *
 *   1. Sign up at https://dash.cloudflare.com (free).
 *   2. Workers & Pages → Create → "Hello World" template.
 *   3. Replace the worker code with this file.
 *   4. Settings → Variables → add ANTHROPIC_API_KEY (encrypted).
 *   5. Deploy. Copy URL like https://nuva-claude.<sub>.workers.dev.
 *   6. Put that URL into the mobile app .env as CLAUDE_PROXY_URL.
 *
 * Why a proxy: shipping the Anthropic key in the APK leaks it to anyone
 * who reverse-engineers the app — and you'll be billed for their usage.
 */

const ALLOWED_ORIGINS = [
  'https://nuva.kz',
  'http://localhost:9090',
];

const SYSTEM_PROMPT = (lang) => `
You are Nuva, an empathetic intake assistant for a Kazakhstan mental-health app.
Always respond in ${lang}.

Goal: in 4 short steps, understand the user well enough to suggest 1–3 psychologists from our catalog. Steps:
1. What's troubling them right now (open question, listen).
2. What outcome they want (relief, clarity, change, support).
3. Format preference (online video, chat, in person), language, budget if comfortable.
4. Practical check (urgency, prior therapy experience, any safety concerns).

Tone: warm, short, validating. One question at a time. 2–3 sentences max per reply. Never diagnose. If user signals crisis or self-harm, gently surface the local helpline (Казахстан: 150) and suggest contacting emergency services.

After step 4 reply with a brief summary and ask if they want to see matched specialists.
`;

const LANG_MAP = { kk: 'Kazakh (қазақша)', en: 'English' };

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return cors(new Response(null, { status: 204 }));
    if (request.method !== 'POST') return cors(new Response('Method not allowed', { status: 405 }));

    let body;
    try {
      body = await request.json();
    } catch {
      return cors(new Response('Bad JSON', { status: 400 }));
    }

    const language = LANG_MAP[body.language] ?? 'Russian (русский)';
    const messages = Array.isArray(body.messages) ? body.messages : [];

    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-6',
        max_tokens: 600,
        system: SYSTEM_PROMPT(language),
        messages,
      }),
    });

    if (!r.ok) {
      return cors(new Response(JSON.stringify({
        error: `claude ${r.status}`, detail: await r.text(),
      }), { status: r.status, headers: { 'content-type': 'application/json' } }));
    }
    const payload = await r.json();
    const reply = (payload.content || [])
      .filter(b => b.type === 'text')
      .map(b => b.text)
      .join('\n')
      .trim();

    return cors(new Response(JSON.stringify({ reply }), {
      headers: { 'content-type': 'application/json' },
    }));
  },
};

function cors(res) {
  const h = new Headers(res.headers);
  h.set('access-control-allow-origin', '*');
  h.set('access-control-allow-headers', 'content-type');
  h.set('access-control-allow-methods', 'POST, OPTIONS');
  return new Response(res.body, { status: res.status, headers: h });
}
