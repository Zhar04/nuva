from django.conf import settings
from django.db import models


class Lead(models.Model):
    """An entry-quiz lead captured BEFORE registration.

    Mental-health intake answers are special-category personal data under
    Kazakhstan's Закон «О персональных данных» №94-V. Discipline applied here:

    - PII is minimised: we store the quiz answers and a single contact handle,
      nothing more, and only when the visitor explicitly consents.
    - Answers are NEVER written to an open log (no print / logger.info of the
      payload) — see ``leads.views``.
    - The lead starts anonymous (``user`` is null) and is linked to a real
      account only after the visitor registers (``link`` endpoint), at which
      point ``linked_at`` is stamped.
    """

    # ── Quiz answers (branching) ──────────────────────────────────────
    for_whom = models.CharField(
        max_length=20, blank=True,
        help_text="Кому ищут помощь: self / relative / child",
    )
    topics = models.JSONField(
        default=list, blank=True, help_text="Что беспокоит (теги)"
    )
    severity = models.CharField(
        max_length=20, blank=True,
        help_text="Острота: mild / moderate / severe",
    )
    goal = models.CharField(max_length=80, blank=True)
    format = models.CharField(
        max_length=20, blank=True, help_text="online / offline"
    )
    language = models.CharField(max_length=8, blank=True)
    urgency = models.CharField(max_length=20, blank=True)
    budget = models.CharField(max_length=20, blank=True)

    # ── Contact + consent ─────────────────────────────────────────────
    contact = models.CharField(
        max_length=120, blank=True,
        help_text="Телефон / email / @handle, если оставлен",
    )
    consent = models.BooleanField(
        default=False,
        help_text="Согласие на обработку данных (№94-V) на момент отправки",
    )

    # ── Matching + lifecycle ──────────────────────────────────────────
    matched_ids = models.JSONField(
        default=list, blank=True, help_text="ID показанных специалистов"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="leads",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    linked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Лид"
        verbose_name_plural = "Лиды"

    def __str__(self):
        # No answer text in the repr — keep special-category data out of logs.
        who = self.user_id or "анон"
        return f"Lead #{self.pk} ({who}) · {self.created_at:%Y-%m-%d}"
