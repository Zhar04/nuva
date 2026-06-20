"""Entry-quiz lead capture.

Anonymous visitors complete a branching quiz BEFORE registering; this captures
the lead and returns matched specialists in one call. After they register, the
app links the lead to the new account.

№94-V discipline: the quiz answers are special-category data. We never log the
payload, only persist it, and we require an explicit consent flag.
"""

from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.generics import get_object_or_404
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework.views import APIView

from ai.views import rank_specialists

from .models import Lead
from .serializers import LeadCreateSerializer, LeadResultSerializer


class _LeadCreateThrottle(AnonRateThrottle):
    # Own bucket so quiz submissions can't be used to hammer the endpoint, and
    # so it's tunable independently of the global anon rate.
    scope = "lead_create"


# Quiz severity maps onto an extra matching topic so "tougher" states bias the
# ranking toward trauma/crisis-savvy specialists without exposing the raw answer.
_SEVERITY_TOPIC = {"severe": "Травма", "moderate": "Стресс"}

# Map the quiz language answer onto the catalog's language strings.
_LANG = {"ru": "русский", "kk": "казахский", "en": "english"}


class LeadCreateView(APIView):
    """POST quiz answers (anonymous) → create a Lead + return matched
    specialists. The single anonymous entry point of the funnel."""

    permission_classes = [permissions.AllowAny]
    authentication_classes = []  # never tie an anonymous lead to a token here
    throttle_classes = [_LeadCreateThrottle]

    def post(self, request):
        serializer = LeadCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        topics = list(data.get("topics") or [])
        extra = _SEVERITY_TOPIC.get(data.get("severity"))
        if extra and extra not in topics:
            topics = topics + [extra]
        language = _LANG.get((data.get("language") or "").lower(), "")

        results = rank_specialists(topics, language=language, limit=3)
        matched_ids = [r["specialist"]["id"] for r in results]

        lead = serializer.save(matched_ids=matched_ids)
        # NB: deliberately no logging of `data` / answers here (№94-V).

        return Response(
            {"lead_id": lead.id, "results": results},
            status=status.HTTP_201_CREATED,
        )


class LeadLinkView(APIView):
    """POST (authenticated) → claim an anonymous lead for the current user.

    Ownership rule: a lead can be claimed only while it has no user, or if it's
    already this user's. A lead already linked to a *different* account is never
    re-assignable — you can't claim someone else's quiz answers.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        lead = get_object_or_404(Lead, pk=pk)
        if lead.user_id and lead.user_id != request.user.id:
            return Response(
                {"detail": "Этот лид уже связан с другим аккаунтом."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if lead.user_id is None:
            lead.user = request.user
            lead.linked_at = timezone.now()
            lead.save(update_fields=["user", "linked_at"])
        return Response(LeadResultSerializer(lead).data)
