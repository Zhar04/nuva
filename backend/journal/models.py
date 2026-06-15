from django.conf import settings
from django.db import models


class MoodEntry(models.Model):
    """One mood check-in per user per calendar day (1=sad … 5=great)."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="moods",
        on_delete=models.CASCADE,
    )
    day = models.DateField()
    mood = models.PositiveSmallIntegerField()  # 1..5
    note = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-day"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "day"], name="uniq_user_day_mood"
            )
        ]
        verbose_name = "Настроение"
        verbose_name_plural = "Дневник настроения"

    def __str__(self):
        return f"{self.user.email} {self.day}: {self.mood}"
