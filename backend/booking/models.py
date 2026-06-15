from django.conf import settings
from django.db import models


class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending_payment", "Ожидает оплаты"
        PAID = "paid", "Оплачено"
        COMPLETED = "completed", "Завершено"
        CANCELLED = "cancelled", "Отменено"
        REFUNDED = "refunded", "Возврат"

    class Format(models.TextChoices):
        VIDEO = "video", "Видео"
        AUDIO = "audio", "Аудио"
        CHAT = "chat", "Чат"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, related_name="bookings", on_delete=models.CASCADE
    )
    specialist = models.ForeignKey(
        "catalog.Specialist", related_name="bookings", on_delete=models.PROTECT
    )
    starts_at = models.DateTimeField()
    format = models.CharField(
        max_length=10, choices=Format.choices, default=Format.VIDEO
    )
    duration_minutes = models.PositiveIntegerField(default=50)
    price_kzt = models.PositiveIntegerField(default=0)
    service_fee_kzt = models.PositiveIntegerField(default=1000)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    payment_provider = models.CharField(max_length=40, blank=True, default="")
    payment_id = models.CharField(max_length=120, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-starts_at"]
        verbose_name = "Сессия (бронь)"
        verbose_name_plural = "Сессии (брони)"

    def __str__(self):
        return f"{self.user} → {self.specialist} @ {self.starts_at:%Y-%m-%d %H:%M} [{self.status}]"
