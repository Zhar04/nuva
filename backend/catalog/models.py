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
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    whatsapp = models.CharField(max_length=20, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_verified", "-rating", "id"]
        verbose_name = "Специалист"
        verbose_name_plural = "Специалисты"

    def __str__(self):
        return f"{self.first_name} {self.last_name} — {self.title}"


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
