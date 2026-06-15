from datetime import timedelta

from django.utils import timezone
from rest_framework import generics, permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import MoodEntry
from .serializers import MoodEntrySerializer

# Points awarded per activity — gamification is *computed* from real data
# (no stored counter to drift / double-count).
POINTS = {"mood": 10, "booking": 50, "post": 15, "reply": 5}
LEVEL_SPAN = 500


def _plural_days(n: int) -> str:
    n10, n100 = n % 10, n % 100
    if n10 == 1 and n100 != 11:
        return "день"
    if 2 <= n10 <= 4 and not 12 <= n100 <= 14:
        return "дня"
    return "дней"


def compute_stats(user) -> dict:
    # Local imports avoid circular app dependencies.
    from booking.models import Booking
    from community.models import Post, Reply

    day_set = set(MoodEntry.objects.filter(user=user).values_list("day", flat=True))
    mood_days = len(day_set)
    bookings = Booking.objects.filter(user=user).count()
    posts = Post.objects.filter(author=user).count()
    replies = Reply.objects.filter(author=user).count()

    points = (
        mood_days * POINTS["mood"]
        + bookings * POINTS["booking"]
        + posts * POINTS["post"]
        + replies * POINTS["reply"]
    )
    level = points // LEVEL_SPAN + 1

    today = timezone.localdate()
    today_logged = today in day_set
    streak = 0
    cursor = today if today_logged else today - timedelta(days=1)
    while cursor in day_set:
        streak += 1
        cursor -= timedelta(days=1)

    mood_days_this_month = sum(
        1 for d in day_set if d.year == today.year and d.month == today.month
    )

    achievements = [
        {
            "key": "first_step",
            "title": "Первый шаг",
            "issuer": "Nuva",
            "unlocked": (mood_days + bookings + posts) >= 1,
        },
        {
            "key": "streak_7",
            "title": "7 дней подряд",
            "issuer": "Nuva",
            "unlocked": streak >= 7,
        },
        {
            "key": "open_heart",
            "title": "Открытость",
            "issuer": "Сообщество",
            "unlocked": posts >= 1,
        },
        {
            "key": "marathon",
            "title": "Марафон · 30 дней",
            "issuer": "Nuva",
            "unlocked": mood_days >= 30,
        },
    ]

    return {
        "points": points,
        "level": level,
        "level_span": LEVEL_SPAN,
        "points_this_level": points % LEVEL_SPAN,
        "streak": streak,
        "streak_label": f"{streak} {_plural_days(streak)} подряд",
        "today_logged": today_logged,
        "mood_days_this_month": mood_days_this_month,
        "monthly_goal": 30,
        "achievements": achievements,
    }


class MoodListCreateView(generics.ListCreateAPIView):
    """GET mood history / POST upserts today's mood (one per day)."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = MoodEntrySerializer

    def get_queryset(self):
        return MoodEntry.objects.filter(user=self.request.user)[:60]

    def create(self, request, *args, **kwargs):
        try:
            mood = int(request.data.get("mood"))
        except (TypeError, ValueError):
            raise serializers.ValidationError({"mood": "Ожидается число 1–5."})
        if not 1 <= mood <= 5:
            raise serializers.ValidationError({"mood": "Настроение от 1 до 5."})
        note = (request.data.get("note") or "").strip()
        entry, _created = MoodEntry.objects.update_or_create(
            user=request.user,
            day=timezone.localdate(),
            defaults={"mood": mood, "note": note},
        )
        return Response(
            MoodEntrySerializer(entry).data, status=status.HTTP_201_CREATED
        )


class StatsView(APIView):
    """GET the user's computed gamification stats."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(compute_stats(request.user))
