from django.conf import settings
from django.db import models

# JSONField is used for the small list-fields so the schema works on both
# SQLite (local) and Postgres (Supabase/Railway) without ArrayField.


class Specialist(models.Model):
    # A real psychologist account that owns this catalog listing (null for the
    # seeded demo specialists). One user → one specialist profile.
    owner = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="specialist_profile",
    )
    first_name = models.CharField(max_length=80)
    last_name = models.CharField(max_length=80)
    title = models.CharField(max_length=120)
    years_experience = models.PositiveIntegerField(default=0)
    languages = models.JSONField(default=list, blank=True)
    approaches = models.JSONField(default=list, blank=True)
    works_with = models.JSONField(default=list, blank=True)
    session_price_kzt = models.PositiveIntegerField(default=0)
    rating = models.DecimalField(max_digits=2, decimal_places=1, default=0)
    review_count = models.PositiveIntegerField(default=0)
    about = models.TextField(blank=True, default="")
    diplomas = models.JSONField(
        default=list, blank=True, help_text="Названия дипломов и сертификатов"
    )
    avatar_gradient = models.JSONField(
        default=list, blank=True, help_text="['#7FB7E8','#A3D8F4']"
    )
    # Weekly availability the psychologist sets in their cabinet. Map of ISO
    # weekday ("1"=Mon … "7"=Sun) → list of "HH:MM" start times, e.g.
    # {"1": ["10:00", "11:00"], "3": ["18:00"]}.
    availability = models.JSONField(default=dict, blank=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    # "Доступен сейчас" for the instant ("поговорить сейчас") funnel. The
    # psychologist flips this on in their cabinet; it auto-expires at
    # instant_until so we never route a now-offline psychologist a live request.
    accepts_instant = models.BooleanField(
        default=False, help_text="Готов(а) к мгновенным сессиям «поговорить сейчас»"
    )
    instant_until = models.DateTimeField(
        null=True, blank=True,
        help_text="До какого момента действует статус «доступен сейчас»",
    )
    whatsapp = models.CharField(max_length=20, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_verified", "-rating", "id"]
        verbose_name = "Специалист"
        verbose_name_plural = "Специалисты"

    def __str__(self):
        return f"{self.first_name} {self.last_name} — {self.title}"

    def is_instant_available(self, now=None) -> bool:
        """True when this specialist can take a live session right now."""
        from django.utils import timezone

        now = now or timezone.now()
        if not (self.is_active and self.is_verified and self.accepts_instant):
            return False
        # No expiry set → treat the toggle as open-ended; otherwise honor it.
        return self.instant_until is None or self.instant_until > now


class Favorite(models.Model):
    """A seeker's saved specialist. One row per (user, specialist) pair."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="favorites",
        on_delete=models.CASCADE,
    )
    specialist = models.ForeignKey(
        Specialist, related_name="favorited_by", on_delete=models.CASCADE
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "specialist"], name="uniq_user_favorite"
            )
        ]
        verbose_name = "Избранное"
        verbose_name_plural = "Избранное"


class Education(models.Model):
    specialist = models.ForeignKey(
        Specialist, related_name="education", on_delete=models.CASCADE
    )
    institution = models.CharField(max_length=160)
    degree = models.CharField(max_length=160)
    years = models.CharField(max_length=40, blank=True, default="")

    class Meta:
        verbose_name = "Образование"
        verbose_name_plural = "Образование"

    def __str__(self):
        return f"{self.institution} — {self.degree}"


class Review(models.Model):
    specialist = models.ForeignKey(
        Specialist, related_name="reviews", on_delete=models.CASCADE
    )
    author_alias = models.CharField(max_length=80, default="Аноним")
    rating = models.PositiveSmallIntegerField(default=5)
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Отзыв"
        verbose_name_plural = "Отзывы"

    def __str__(self):
        return f"{self.author_alias} ★{self.rating}"
