from django.conf import settings
from django.db import models

# Anonymous, nature-themed aliases (mirrors the app's palette source).
ALIAS_WORDS = [
    "Тихий ветер",
    "Утренний свет",
    "Северное озеро",
    "Лесной ручей",
    "Тёплый дождь",
    "Песчаный берег",
    "Горный воздух",
    "Дальний берег",
]


def anon_alias(user) -> str:
    """A stable, anonymous alias for a user (never exposes identity)."""
    if user is None or not getattr(user, "id", None):
        return "Аноним"
    return f"{ALIAS_WORDS[user.id % len(ALIAS_WORDS)]} #{100 + user.id}"


class Post(models.Model):
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="community_posts",
    )
    author_alias = models.CharField(max_length=60, default="Аноним")
    text = models.TextField()
    tags = models.JSONField(default=list, blank=True)
    likes_count = models.PositiveIntegerField(default=0)
    is_supported = models.BooleanField(
        default=False, help_text="Отмечен модератором как поддерживающий"
    )
    is_visible = models.BooleanField(
        default=True, help_text="Снимите, чтобы скрыть пост из ленты"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Пост сообщества"
        verbose_name_plural = "Посты сообщества"

    def __str__(self):
        return f"{self.author_alias}: {self.text[:40]}"


class PostLike(models.Model):
    post = models.ForeignKey(Post, related_name="likes", on_delete=models.CASCADE)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["post", "user"], name="uniq_post_like"
            )
        ]
        verbose_name = "Лайк"
        verbose_name_plural = "Лайки"


class Reply(models.Model):
    post = models.ForeignKey(Post, related_name="replies", on_delete=models.CASCADE)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="community_replies",
    )
    author_alias = models.CharField(max_length=60, default="Аноним")
    text = models.TextField()
    from_specialist = models.BooleanField(default=False)
    likes_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        verbose_name = "Ответ"
        verbose_name_plural = "Ответы"

    def __str__(self):
        return f"{self.author_alias}: {self.text[:40]}"


class ReplyLike(models.Model):
    reply = models.ForeignKey(Reply, related_name="likes", on_delete=models.CASCADE)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["reply", "user"], name="uniq_reply_like"
            )
        ]
        verbose_name = "Лайк ответа"
        verbose_name_plural = "Лайки ответов"
