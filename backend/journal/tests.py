"""Mood-journal tests: one entry per day (upsert), validation, and isolation —
a user only ever sees their own moods (special-category data — №94-V)."""

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase

from .models import MoodEntry

User = get_user_model()


class MoodJournalTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_requires_auth(self):
        res = APIClient().post("/api/v1/journal/moods/", {"mood": 3}, format="json")
        self.assertEqual(res.status_code, 401)

    def test_logging_mood_creates_one_entry(self):
        res = self.client.post("/api/v1/journal/moods/", {"mood": 4}, format="json")
        self.assertEqual(res.status_code, 201)
        self.assertEqual(MoodEntry.objects.filter(user=self.user).count(), 1)

    def test_second_log_same_day_upserts_not_duplicates(self):
        self.client.post("/api/v1/journal/moods/", {"mood": 2}, format="json")
        self.client.post("/api/v1/journal/moods/", {"mood": 5}, format="json")
        entries = MoodEntry.objects.filter(user=self.user, day=timezone.localdate())
        self.assertEqual(entries.count(), 1)
        self.assertEqual(entries.first().mood, 5)  # latest wins

    def test_out_of_range_mood_rejected(self):
        for bad in (0, 6, "x"):
            res = self.client.post(
                "/api/v1/journal/moods/", {"mood": bad}, format="json"
            )
            self.assertEqual(res.status_code, 400, bad)

    def test_user_only_sees_own_moods(self):
        self.client.post("/api/v1/journal/moods/", {"mood": 3}, format="json")
        other = User.objects.create_user(email="o@nuva.kz", password="Test12345")
        MoodEntry.objects.create(user=other, day=timezone.localdate(), mood=1)
        res = self.client.get("/api/v1/journal/moods/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data), 1)  # not the other user's entry

    def test_stats_reflect_logged_mood(self):
        self.client.post("/api/v1/journal/moods/", {"mood": 4}, format="json")
        res = self.client.get("/api/v1/journal/stats/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["today_logged"])
        self.assertGreaterEqual(res.data["points"], 10)
