from django.conf import settings
from django.db import models


class Conversation(models.Model):
    """A 1:1 thread between a seeker (user) and a specialist.

    There is at most one conversation per (user, specialist) pair.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="conversations",
        on_delete=models.CASCADE,
    )
    specialist = models.ForeignKey(
        "catalog.Specialist",
        related_name="conversations",
        on_delete=models.PROTECT,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "specialist"], name="uniq_user_specialist_thread"
            )
        ]
        verbose_name = "Диалог"
        verbose_name_plural = "Диалоги"

    def __str__(self):
        return f"{self.user.email} ↔ {self.specialist}"


class Message(models.Model):
    class Sender(models.TextChoices):
        USER = "user", "Клиент"
        SPECIALIST = "specialist", "Специалист"
        SYSTEM = "system", "Система"

    conversation = models.ForeignKey(
        Conversation, related_name="messages", on_delete=models.CASCADE
    )
    sender = models.CharField(
        max_length=12, choices=Sender.choices, default=Sender.USER
    )
    text = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        verbose_name = "Сообщение"
        verbose_name_plural = "Сообщения"

    def __str__(self):
        return f"[{self.sender}] {self.text[:40]}"
