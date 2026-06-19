"""Tests for the AI navigator endpoints.

Network is never hit: the Claude call (`_claude_chat`) is patched. We cover the
three branches that matter for safety and resilience — crisis short-circuit,
graceful fallback when no key / on error, and a successful proxied reply — plus
the auth gate on both endpoints.
"""

from unittest import mock

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework.test import APITestCase

User = get_user_model()


class AskViewTests(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )

    def test_requires_auth(self):
        res = self.client.post("/api/v1/ai/ask/", {"message": "привет"}, format="json")
        self.assertEqual(res.status_code, 401)

    def test_empty_message_rejected(self):
        self.client.force_authenticate(self.user)
        res = self.client.post("/api/v1/ai/ask/", {"message": "   "}, format="json")
        self.assertEqual(res.status_code, 400)

    def test_crisis_short_circuits_without_calling_model(self):
        self.client.force_authenticate(self.user)
        with mock.patch("ai.views._claude_chat") as chat:
            res = self.client.post(
                "/api/v1/ai/ask/",
                {"message": "я не хочу жить"},
                format="json",
            )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["crisis"])
        self.assertIn("150", res.data["reply"])
        chat.assert_not_called()

    def test_graceful_fallback_when_no_key(self):
        self.client.force_authenticate(self.user)
        with mock.patch.dict("os.environ", {}, clear=False) as _env:
            import os

            os.environ.pop("ANTHROPIC_API_KEY", None)
            res = self.client.post(
                "/api/v1/ai/ask/",
                {"message": "мне тревожно"},
                format="json",
            )
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.data["crisis"])
        self.assertTrue(res.data["degraded"])
        self.assertEqual(res.data["reason"], "no_key")

    @mock.patch.dict("os.environ", {"ANTHROPIC_API_KEY": "sk-test"}, clear=False)
    def test_successful_reply_is_proxied(self):
        self.client.force_authenticate(self.user)
        with mock.patch("ai.views._claude_chat", return_value="Дыши глубже.") as chat:
            res = self.client.post(
                "/api/v1/ai/ask/",
                {"message": "как успокоиться?"},
                format="json",
            )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["reply"], "Дыши глубже.")
        self.assertFalse(res.data["crisis"])
        chat.assert_called_once()

    @mock.patch.dict("os.environ", {"ANTHROPIC_API_KEY": "sk-test"}, clear=False)
    def test_graceful_fallback_on_model_error(self):
        self.client.force_authenticate(self.user)
        with mock.patch("ai.views._claude_chat", side_effect=ValueError("boom")):
            res = self.client.post(
                "/api/v1/ai/ask/",
                {"message": "мне тревожно"},
                format="json",
            )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["degraded"])
        self.assertEqual(res.data["reason"], "ValueError")


class MatchViewTests(APITestCase):
    def test_requires_auth(self):
        res = APIClient().post(
            "/api/v1/ai/match/", {"topics": ["тревога"]}, format="json"
        )
        self.assertEqual(res.status_code, 401)

    def test_returns_results_envelope(self):
        user = User.objects.create_user(email="m@nuva.kz", password="Test12345")
        client = APIClient()
        client.force_authenticate(user)
        res = client.post("/api/v1/ai/match/", {"topics": ["тревога"]}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertIn("results", res.data)
        self.assertIsInstance(res.data["results"], list)
