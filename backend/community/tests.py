"""Anonymous community tests: posting + anonymity, the contact-moderation gate,
visibility filtering, like toggle idempotency, and the specialist-reply flag."""

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient, APITestCase

from .models import Post, PostLike, anon_alias

User = get_user_model()


class CommunityPostTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_requires_auth(self):
        res = APIClient().get("/api/v1/community/posts/")
        self.assertEqual(res.status_code, 401)

    def test_create_post_is_anonymous(self):
        res = self.client.post(
            "/api/v1/community/posts/",
            {"text": "Сегодня впервые за неделю выспался.", "tags": ["Сон"]},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        # The author alias is anonymized — never the email/real identity.
        self.assertEqual(res.data["author_alias"], anon_alias(self.user))
        self.assertNotIn("seeker@nuva.kz", res.data["author_alias"])

    def test_too_short_post_rejected(self):
        res = self.client.post(
            "/api/v1/community/posts/", {"text": "ок"}, format="json"
        )
        self.assertEqual(res.status_code, 400)

    def test_post_with_contact_is_blocked(self):
        # Note: a seed migration (0002_seed_posts) pre-populates the feed, so
        # assert on the delta, not an empty table.
        before = Post.objects.count()
        res = self.client.post(
            "/api/v1/community/posts/",
            {"text": "пишите мне +7 701 234 5678"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertEqual(Post.objects.count(), before)  # nothing created

    def test_hidden_post_not_in_feed(self):
        visible_before = len(self.client.get("/api/v1/community/posts/").data)
        Post.objects.create(author=self.user, text="видимый пост здесь")
        Post.objects.create(
            author=self.user, text="скрытый пост здесь", is_visible=False
        )
        res = self.client.get("/api/v1/community/posts/")
        # Only the visible one is added to the feed.
        self.assertEqual(len(res.data), visible_before + 1)

    def test_tag_filter(self):
        # Use a tag unlikely to collide with seeded posts, and assert the delta.
        base = len(
            self.client.get("/api/v1/community/posts/?tag=ТегТеста").data
        )
        Post.objects.create(
            author=self.user, text="мой тестовый пост", tags=["ТегТеста"]
        )
        Post.objects.create(
            author=self.user, text="другой тестовый пост", tags=["Тревога"]
        )
        res = self.client.get("/api/v1/community/posts/?tag=ТегТеста")
        self.assertEqual(len(res.data), base + 1)
        self.assertIn("тестовый", res.data[0]["text"])


class CommunityLikeReplyTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.psy = User.objects.create_user(
            email="psy@nuva.kz", password="Test12345", role="psychologist"
        )
        self.post = Post.objects.create(author=self.user, text="нужна поддержка")
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_like_toggles_idempotently(self):
        url = f"/api/v1/community/posts/{self.post.id}/like/"
        first = self.client.post(url)
        self.assertTrue(first.data["liked"])
        self.assertEqual(first.data["likes_count"], 1)
        # Liking again toggles off — no double-count.
        second = self.client.post(url)
        self.assertFalse(second.data["liked"])
        self.assertEqual(second.data["likes_count"], 0)
        self.assertEqual(PostLike.objects.filter(post=self.post).count(), 0)

    def test_reply_from_specialist_is_flagged(self):
        c = APIClient()
        c.force_authenticate(self.psy)
        res = c.post(
            f"/api/v1/community/posts/{self.post.id}/replies/",
            {"text": "Вы не одни, это нормально."},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(res.data["from_specialist"])

    def test_reply_from_seeker_not_flagged(self):
        res = self.client.post(
            f"/api/v1/community/posts/{self.post.id}/replies/",
            {"text": "Держись, я рядом."},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertFalse(res.data["from_specialist"])

    def test_reply_with_contact_blocked(self):
        res = self.client.post(
            f"/api/v1/community/posts/{self.post.id}/replies/",
            {"text": "мой телеграм @secret_handle"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
