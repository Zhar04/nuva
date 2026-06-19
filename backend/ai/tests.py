"""Tests for the AI navigator endpoints.

Network is never hit: the Claude call (`_claude_chat`) is patched. We cover the
three branches that matter for safety and resilience — crisis short-circuit,
graceful fallback when no key / on error, and a successful proxied reply — plus
the auth gate on both endpoints.
"""

from unittest import mock

from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework.throttling import SimpleRateThrottle
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

    def test_oversized_topics_list_is_capped(self):
        """A huge topics list must not be processed wholesale (denial-of-wallet
        / CPU): it's truncated to 20 and the request still succeeds."""
        user = User.objects.create_user(email="big@nuva.kz", password="Test12345")
        client = APIClient()
        client.force_authenticate(user)
        res = client.post(
            "/api/v1/ai/match/",
            {"topics": [f"тема{i}" for i in range(500)]},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("results", res.data)


class ThrottleTests(APITestCase):
    """The AI endpoints bill Anthropic per call, so they carry a dedicated,
    tight scoped throttle to bound denial-of-wallet."""

    def setUp(self):
        cache.clear()  # throttle history lives in the cache
        self.user = User.objects.create_user(
            email="rate@nuva.kz", password="Test12345"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        # DRF binds the rate map to SimpleRateThrottle.THROTTLE_RATES at import,
        # so override_settings doesn't reach it — mutate that map in place and
        # restore the original 'ai' rate afterwards.
        self._orig_ai = SimpleRateThrottle.THROTTLE_RATES.get("ai")
        SimpleRateThrottle.THROTTLE_RATES["ai"] = "2/min"

    def tearDown(self):
        if self._orig_ai is None:
            SimpleRateThrottle.THROTTLE_RATES.pop("ai", None)
        else:
            SimpleRateThrottle.THROTTLE_RATES["ai"] = self._orig_ai
        cache.clear()

    def test_ai_endpoint_throttles_after_scope_limit(self):
        with mock.patch("ai.views._claude_chat", return_value="ok"):
            codes = [
                self.client.post(
                    "/api/v1/ai/ask/", {"message": "hi"}, format="json"
                ).status_code
                for _ in range(3)
            ]
        # First two within the 2/min scope pass; the third is throttled.
        self.assertEqual(codes[:2], [200, 200])
        self.assertEqual(codes[2], 429)
