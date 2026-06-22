"""Tests for the specialist catalog — focused on the instant-availability
toggle, where the server (not the client) controls the auto-expiry window."""

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase

from .models import Specialist

User = get_user_model()


class InstantToggleTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="psy@nuva.kz", password="Test12345", role="psychologist"
        )
        self.sp = Specialist.objects.create(
            owner=self.user, first_name="Аяна", last_name="С.", title="Психолог",
            rating="4.8", is_verified=True, is_active=True,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_turning_on_sets_server_controlled_window(self):
        # The client may not pin itself available forever: instant_until is
        # read-only on the serializer and set by the server to ~now + 1h.
        far_future = "2099-01-01T00:00:00Z"
        res = self.client.put(
            "/api/v1/specialists/me",
            {"accepts_instant": True, "instant_until": far_future},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.sp.refresh_from_db()
        self.assertTrue(self.sp.accepts_instant)
        self.assertIsNotNone(self.sp.instant_until)
        # Window is ~1 hour out, NOT the client's far-future value.
        delta = self.sp.instant_until - timezone.now()
        self.assertLess(delta.total_seconds(), 2 * 3600)
        self.assertGreater(delta.total_seconds(), 0)

    def test_turning_off_clears_the_window(self):
        self.sp.accepts_instant = True
        self.sp.instant_until = timezone.now() + timezone.timedelta(hours=1)
        self.sp.save()
        res = self.client.put(
            "/api/v1/specialists/me", {"accepts_instant": False}, format="json"
        )
        self.assertEqual(res.status_code, 200)
        self.sp.refresh_from_db()
        self.assertFalse(self.sp.accepts_instant)
        self.assertIsNone(self.sp.instant_until)

    def test_is_instant_available_predicate(self):
        now = timezone.now()
        self.assertFalse(self.sp.is_instant_available(now))  # toggle off
        self.sp.accepts_instant = True
        self.sp.instant_until = now + timezone.timedelta(minutes=30)
        self.assertTrue(self.sp.is_instant_available(now))
        self.sp.instant_until = now - timezone.timedelta(minutes=1)
        self.assertFalse(self.sp.is_instant_available(now))  # expired


class FavoritesTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.sp = Specialist.objects.create(
            first_name="Аяна", last_name="С.", title="Психолог",
            works_with=["Тревога"], languages=["русский"],
            rating="4.8", is_verified=True, is_active=True,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_toggle_adds_then_removes(self):
        add = self.client.post(
            "/api/v1/specialists/favorites",
            {"specialist": self.sp.id},
            format="json",
        )
        self.assertTrue(add.data["favorite"])
        self.assertEqual(
            self.client.get("/api/v1/specialists/favorites").data.__len__(), 1
        )
        # Toggling again removes it.
        rm = self.client.post(
            "/api/v1/specialists/favorites",
            {"specialist": self.sp.id},
            format="json",
        )
        self.assertFalse(rm.data["favorite"])
        self.assertEqual(
            self.client.get("/api/v1/specialists/favorites").data.__len__(), 0
        )

    def test_favorites_are_owner_scoped(self):
        self.client.post(
            "/api/v1/specialists/favorites",
            {"specialist": self.sp.id},
            format="json",
        )
        other = User.objects.create_user(email="o@nuva.kz", password="Test12345")
        oc = APIClient()
        oc.force_authenticate(other)
        self.assertEqual(oc.get("/api/v1/specialists/favorites").data, [])

    def test_detail_reports_is_favorite(self):
        self.client.post(
            "/api/v1/specialists/favorites",
            {"specialist": self.sp.id},
            format="json",
        )
        res = self.client.get(f"/api/v1/specialists/{self.sp.id}")
        self.assertTrue(res.data["is_favorite"])

    def test_requires_auth(self):
        self.assertEqual(
            APIClient().get("/api/v1/specialists/favorites").status_code, 401
        )


class CatalogSearchTests(APITestCase):
    # NB: a seed migration pre-populates the catalog, so use a unique marker
    # ("Цитрус") and assert on membership, not absolute counts.
    def setUp(self):
        Specialist.objects.create(
            first_name="Зухра", last_name="Цитрусовна", title="Цитрус-психолог",
            works_with=["Цитрустерапия"], languages=["волапюк"],
            rating="4.9", is_verified=True, is_active=True,
        )

    def test_q_filters_by_unique_topic(self):
        res = self.client.get("/api/v1/specialists/?q=цитрустерапия")
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]["first_name"], "Зухра")

    def test_q_for_unknown_term_returns_nothing(self):
        res = self.client.get("/api/v1/specialists/?q=небывалыйзапрос")
        self.assertEqual(len(res.data), 0)

    def test_lang_filter_unique(self):
        res = self.client.get("/api/v1/specialists/?lang=волапюк")
        self.assertEqual(len(res.data), 1)

    def test_no_filter_returns_seeded_plus_mine(self):
        res = self.client.get("/api/v1/specialists/")
        names = [s["first_name"] for s in res.data]
        self.assertIn("Зухра", names)
        self.assertGreaterEqual(len(res.data), 1)
