from django.conf import settings
from django.db import models


class Booking(models.Model):
    class Status(models.TextChoices):
        # New lifecycle: a client booking starts as a REQUEST the psychologist
        # must accept. On accept it becomes SCHEDULED (free intro session — goes
        # straight to the calendar) or PENDING (paid session — client must pay).
        REQUESTED = "requested", "Запрос (ждёт подтверждения)"
        PENDING = "pending_payment", "Подтверждён — ждёт оплаты"
        SCHEDULED = "scheduled", "В расписании"
        PAID = "paid", "Оплачено"
        COMPLETED = "completed", "Завершено"
        DECLINED = "declined", "Отклонено"
        CANCELLED = "cancelled", "Отменено"
        REFUNDED = "refunded", "Возврат"

    class Format(models.TextChoices):
        VIDEO = "video", "Видео"
        AUDIO = "audio", "Аудио"
        CHAT = "chat", "Чат"

    class Intent(models.TextChoices):
        INTRO = "intro", "Ознакомительная сессия"
        PACKAGE = "package", "Пакет сессий"

    class Source(models.TextChoices):
        MANUAL = "manual", "Обычная бронь"
        INSTANT = "instant", "Поговорить сейчас"
        QUIZ = "quiz", "Из квиза"

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
        max_length=20, choices=Status.choices, default=Status.REQUESTED
    )
    # ── Request metadata shown to the psychologist on the "Запросы" screen ──
    intent = models.CharField(
        max_length=12, choices=Intent.choices, default=Intent.INTRO,
        help_text="Хочет ознакомительную сессию или пакет",
    )
    is_intro = models.BooleanField(
        default=False, help_text="Бесплатная ознакомительная сессия"
    )
    # A promo/free session must NOT make repeat sessions free or fee-exempt:
    # analytics and the commission split key off is_promo, so a promo intro is
    # excluded from revenue/commission while a later paid session is not.
    is_promo = models.BooleanField(
        default=False,
        help_text="Промо/бесплатная мгновенная сессия — не основа для комиссии",
    )
    source = models.CharField(
        max_length=10, choices=Source.choices, default=Source.MANUAL,
        help_text="Откуда пришла бронь (для аналитики)",
    )
    concern = models.CharField(
        max_length=80, blank=True, default="",
        help_text="Что беспокоит (Тревога, Отношения…)",
    )
    client_message = models.TextField(blank=True, default="")
    match_score = models.PositiveSmallIntegerField(
        default=0, help_text="% совпадения по подбору (0–100)"
    )
    # ── Set when the psychologist declines ──
    decline_reason = models.TextField(blank=True, default="")
    proposed_starts_at = models.DateTimeField(
        null=True, blank=True, help_text="Психолог предложил другое время"
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


class ClientNote(models.Model):
    """Private note a psychologist keeps about one of their clients.

    Visible only to the specialist's owner — never to the client. One note per
    (specialist, client) pair; the cabinet edits it in place.
    """

    specialist = models.ForeignKey(
        "catalog.Specialist", related_name="client_notes", on_delete=models.CASCADE
    )
    client = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="notes_about_me",
        on_delete=models.CASCADE,
    )
    text = models.TextField(blank=True, default="")
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["specialist", "client"], name="uniq_specialist_client_note"
            )
        ]
        verbose_name = "Заметка о клиенте"
        verbose_name_plural = "Заметки о клиентах"

    def __str__(self):
        return f"Заметка {self.specialist} о {self.client}"


class InstantRequest(models.Model):
    """A "поговорить сейчас" callback request — created when no specialist is
    instantly available, so a psychologist can claim it within X minutes.

    Object-level ownership: a request is visible/cancellable only by its `user`,
    and claimable only by a verified psychologist. On claim it spawns a free
    promo Booking (see views) so the live session reuses the booking lifecycle.
    """

    class Status(models.TextChoices):
        WAITING = "waiting", "Ждёт психолога"
        CLAIMED = "claimed", "Психолог принял"
        EXPIRED = "expired", "Истекла"
        CANCELLED = "cancelled", "Отменена"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="instant_requests",
        on_delete=models.CASCADE,
    )
    concern = models.CharField(max_length=80, blank=True, default="")
    channel = models.CharField(
        max_length=10, choices=Booking.Format.choices,
        default=Booking.Format.VIDEO,
    )
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.WAITING
    )
    respond_within_min = models.PositiveSmallIntegerField(
        default=15, help_text="Обещанное время отклика, мин (из настроек)"
    )
    specialist = models.ForeignKey(
        "catalog.Specialist",
        null=True,
        blank=True,
        related_name="instant_requests",
        on_delete=models.SET_NULL,
    )
    booking = models.ForeignKey(
        Booking,
        null=True,
        blank=True,
        related_name="instant_request",
        on_delete=models.SET_NULL,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    claimed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Заявка «поговорить сейчас»"
        verbose_name_plural = "Заявки «поговорить сейчас»"

    def __str__(self):
        return f"InstantRequest #{self.pk} ({self.user}) [{self.status}]"
