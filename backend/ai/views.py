"""AI navigator: rule-based specialist matching + a Groq-proxied Q&A helper.

Design choices:
- Matching is deterministic (no LLM) — it's a scoring problem over real tags,
  so it can't hallucinate a specialist.
- Q&A is proxied to Groq (free API) with the key kept server-side. It degrades
  gracefully to a safe canned reply when no key is configured or Groq errors.
- This is a *navigator*, never a therapist: crisis input short-circuits to
  emergency resources and never reaches the model.
"""

import json
import os
import urllib.error
import urllib.request

from rest_framework import permissions, serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from catalog.models import Specialist
from catalog.serializers import SpecialistListSerializer

# ─── Crisis safety net ────────────────────────────────────────────
CRISIS_TERMS = [
    "суицид", "покончить", "не хочу жить", "убить себя", "свести счёты",
    "свести счеты", "самоуб", "порезать себя", "навредить себе", "умереть",
    "суицидал", "убью себя", "нет смысла жить",
    "suicide", "kill myself", "end my life", "want to die", "self-harm",
    "hurt myself", "self harm",
]
CRISIS_REPLY = (
    "Мне очень жаль, что тебе сейчас так тяжело. Если есть мысли причинить себе "
    "вред — пожалуйста, обратись за немедленной помощью прямо сейчас:\n\n"
    "• 112 — единая служба экстренного вызова (Казахстан)\n"
    "• 150 — бесплатный телефон доверия\n\n"
    "Ты не один, и тебе могут помочь. Если можешь — побудь рядом с тем, кому "
    "доверяешь. Я не заменю живого специалиста, но я здесь."
)

FALLBACK_REPLY = (
    "Спасибо, что поделился — это уже шаг. Я пока не могу дать развёрнутый "
    "ответ, но вот что часто помогает: разбей задачу на один маленький шаг на "
    "5 минут, убери телефон на это время и отметь, что получилось. Если состояние "
    "держится — стоит обсудить это со специалистом: в каталоге Nuva можно подобрать "
    "того, кто работает именно с твоим запросом.\n\nЯ навигатор, а не терапевт — "
    "не ставлю диагнозов."
)

SYSTEM_PROMPT = (
    "Ты — Nuva, доброжелательный ассистент-навигатор приложения психологической "
    "поддержки для Казахстана. Ты НЕ терапевт и НЕ ставишь диагнозов и не "
    "назначаешь лекарств. Отвечай по-русски, тепло, на «ты», кратко (3–6 "
    "предложений), давай 1–2 практичных шага. Когда уместно — мягко предложи "
    "записаться к специалисту в приложении Nuva. Не обещай вылечить."
)


def _is_crisis(text: str) -> bool:
    low = text.lower()
    return any(term in low for term in CRISIS_TERMS)


def _groq_chat(message: str, key: str, model: str) -> str:
    payload = {
        "model": model,
        "temperature": 0.6,
        "max_tokens": 500,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": message},
        ],
    }
    req = urllib.request.Request(
        "https://api.groq.com/openai/v1/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return data["choices"][0]["message"]["content"].strip()


class MatchView(APIView):
    """POST {topics: [...], language?, limit?} → ranked specialists with a
    match score and human-readable reasons. Deterministic, no LLM."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        topics = request.data.get("topics") or []
        if not isinstance(topics, list):
            topics = [topics]
        wanted = {str(t).strip().lower() for t in topics if str(t).strip()}
        language = (request.data.get("language") or "").strip().lower()
        try:
            limit = int(request.data.get("limit", 5))
        except (TypeError, ValueError):
            limit = 5
        limit = max(1, min(limit, 10))

        ranked = []
        for sp in Specialist.objects.filter(is_active=True):
            works = {str(w).lower() for w in (sp.works_with or [])}
            approaches = {str(a).lower() for a in (sp.approaches or [])}
            langs = [str(x).lower() for x in (sp.languages or [])]
            overlap = wanted & (works | approaches)

            score = 55.0 + len(overlap) * 13
            score += (float(sp.rating) - 4.5) * 8
            if sp.is_verified:
                score += 5
            lang_ok = bool(language) and any(language in x for x in langs)
            if lang_ok:
                score += 6
            score = int(max(40, min(99, round(score))))

            reasons = []
            if overlap:
                shown = [w for w in (sp.works_with or [])
                         if str(w).lower() in overlap][:3]
                reasons.append("Работает с: " + ", ".join(shown))
            if float(sp.rating) >= 4.7:
                reasons.append(f"Высокий рейтинг · {sp.rating}")
            if lang_ok:
                reasons.append("Говорит на нужном языке")
            if not reasons:
                reasons.append("Подходит по общему профилю")

            ranked.append((score, len(overlap), float(sp.rating), sp, reasons))

        ranked.sort(key=lambda r: (r[0], r[1], r[2]), reverse=True)
        ranked = ranked[:limit]

        results = [
            {
                "specialist": SpecialistListSerializer(sp).data,
                "match_score": score,
                "reasons": reasons,
            }
            for (score, _ov, _rt, sp, reasons) in ranked
        ]
        return Response({"results": results})


class AskView(APIView):
    """POST {message} → a short navigator reply. Crisis input short-circuits to
    emergency resources; otherwise proxied to Groq (graceful fallback)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        message = (request.data.get("message") or "").strip()
        if not message:
            raise serializers.ValidationError({"message": "Пустой вопрос."})
        if len(message) > 1000:
            message = message[:1000]

        if _is_crisis(message):
            return Response({"reply": CRISIS_REPLY, "crisis": True})

        key = os.getenv("GROQ_API_KEY", "").strip()
        model = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile").strip()
        if not key:
            return Response(
                {"reply": FALLBACK_REPLY, "crisis": False, "degraded": True,
                 "reason": "no_key"}
            )
        try:
            reply = _groq_chat(message, key, model)
            return Response({"reply": reply, "crisis": False, "model": model})
        except urllib.error.HTTPError as e:
            body = ""
            try:
                body = e.read().decode("utf-8", "ignore")[:300]
            except Exception:
                pass
            return Response(
                {"reply": FALLBACK_REPLY, "crisis": False, "degraded": True,
                 "reason": f"http_{e.code}", "detail": body}
            )
        except Exception as e:  # noqa: BLE001 — diagnostic surface
            return Response(
                {"reply": FALLBACK_REPLY, "crisis": False, "degraded": True,
                 "reason": type(e).__name__, "detail": str(e)[:200]}
            )
