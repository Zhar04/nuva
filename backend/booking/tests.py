"""Tests for the "поговорить сейчас" instant funnel.

Covers: instant match when a psychologist is available vs not; the promo/free
flags on the spawned booking (so analytics/commission exclude the freebie);
the callback-request lifecycle; and object-level ownership (a client can't read
another's request; only a verified psychologist can claim).
"""

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase

from catalog.models import Specialist

from .models import Booking, InstantRequest

User = get_user_model()


def _specialist(owner=None, **kw):
    defaults = dict(
        first_name="Аяна", last_name="С.", title="Психолог",
        rating="4.8", is_verified=True, is_active=True, accepts_instant=True,
    )
    defaults.update(kw)
    return Specialist.objects.create(owner=owner, **defaults)


class InstantMatchTests(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.client.force_authenticate(self.user)

    def test_requires_auth(self):
        res = APIClient().post("/api/v1/bookings/instant", {}, format="json")
        self.assertEqual(res.status_code, 401)

    def test_matches_available_specialist_with_free_promo_booking(self):
        _specialist()
        res = self.client.post(
            "/api/v1/bookings/instant", {"concern": "Тревога"}, format="json"
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(res.data["available"])
        b = res.data["booking"]
        # Free + fee-exempt + flagged so commission/analytics skip it.
        self.assertEqual(b["price_kzt"], 0)
        self.assertEqual(b["service_fee_kzt"], 0)
        self.assertTrue(b["is_promo"])
        self.assertEqual(b["source"], "instant")
        self.assertTrue(b["is_intro"])
        self.assertEqual(b["status"], "scheduled")
        self.assertIsNotNone(b["conversation_id"])

    def test_no_one_available_returns_fallback(self):
        # accepts_instant off → not available.
        _specialist(accepts_instant=False)
        res = self.client.post("/api/v1/bookings/instant", {}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.data["available"])
        self.assertIn("respond_within_min", res.data)

    def test_expired_instant_window_is_not_available(self):
        _specialist(
            accepts_instant=True,
            instant_until=timezone.now() - timezone.timedelta(minutes=1),
        )
        res = self.client.post("/api/v1/bookings/instant", {}, format="json")
        self.assertFalse(res.data["available"])

    def test_unverified_specialist_not_matched(self):
        _specialist(is_verified=False)
        res = self.client.post("/api/v1/bookings/instant", {}, format="json")
        self.assertFalse(res.data["available"])


class InstantRequestTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.psy_user = User.objects.create_user(
            email="psy@nuva.kz", password="Test12345", role="psychologist"
        )
        self.specialist = _specialist(owner=self.psy_user, accepts_instant=False)

    def _make_request(self, user):
        c = APIClient()
        c.force_authenticate(user)
        res = c.post(
            "/api/v1/bookings/instant/request",
            {"concern": "Сон", "channel": "chat"},
            format="json",
        )
        return c, res

    def test_create_request_returns_respond_window(self):
        _, res = self._make_request(self.user)
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["status"], "waiting")
        self.assertEqual(res.data["channel"], "chat")
        self.assertEqual(res.data["respond_within_min"], 15)

    def test_owner_can_poll_but_others_cannot(self):
        _, res = self._make_request(self.user)
        req_id = res.data["id"]
        owner = APIClient()
        owner.force_authenticate(self.user)
        self.assertEqual(
            owner.get(f"/api/v1/bookings/instant/request/{req_id}").status_code,
            200,
        )
        # A different client: 404 (existence not even leaked).
        other = User.objects.create_user(email="o@nuva.kz", password="Test12345")
        oc = APIClient()
        oc.force_authenticate(other)
        self.assertEqual(
            oc.get(f"/api/v1/bookings/instant/request/{req_id}").status_code,
            404,
        )

    def test_verified_psychologist_claims_and_spawns_promo_booking(self):
        _, res = self._make_request(self.user)
        req_id = res.data["id"]
        psy = APIClient()
        psy.force_authenticate(self.psy_user)
        claim = psy.post(
            f"/api/v1/bookings/instant/request/{req_id}/claim", {}, format="json"
        )
        self.assertEqual(claim.status_code, 200)
        self.assertEqual(claim.data["status"], "claimed")
        booking = claim.data["booking"]
        self.assertTrue(booking["is_promo"])
        self.assertEqual(booking["source"], "instant")
        self.assertEqual(booking["format"], "chat")  # honors the request channel
        self.assertEqual(Booking.objects.get(pk=booking["id"]).user, self.user)

    def test_non_psychologist_cannot_claim(self):
        _, res = self._make_request(self.user)
        req_id = res.data["id"]
        other = User.objects.create_user(email="o@nuva.kz", password="Test12345")
        oc = APIClient()
        oc.force_authenticate(other)
        claim = oc.post(
            f"/api/v1/bookings/instant/request/{req_id}/claim", {}, format="json"
        )
        self.assertEqual(claim.status_code, 403)
        self.assertEqual(InstantRequest.objects.get(pk=req_id).status, "waiting")

    def test_request_cannot_be_claimed_twice(self):
        _, res = self._make_request(self.user)
        req_id = res.data["id"]
        psy = APIClient()
        psy.force_authenticate(self.psy_user)
        psy.post(f"/api/v1/bookings/instant/request/{req_id}/claim", {}, format="json")
        psy2_user = User.objects.create_user(
            email="psy2@nuva.kz", password="Test12345", role="psychologist"
        )
        _specialist(owner=psy2_user, first_name="Бота")
        psy2 = APIClient()
        psy2.force_authenticate(psy2_user)
        again = psy2.post(
            f"/api/v1/bookings/instant/request/{req_id}/claim", {}, format="json"
        )
        self.assertEqual(again.status_code, 409)

    def test_queue_visible_only_to_psychologists(self):
        self._make_request(self.user)
        psy = APIClient()
        psy.force_authenticate(self.psy_user)
        q = psy.get("/api/v1/bookings/instant/queue")
        self.assertEqual(q.status_code, 200)
        self.assertEqual(len(q.data), 1)
        seeker = APIClient()
        seeker.force_authenticate(self.user)
        self.assertEqual(seeker.get("/api/v1/bookings/instant/queue").data, [])

    def test_owner_can_cancel(self):
        c, res = self._make_request(self.user)
        req_id = res.data["id"]
        cancel = c.post(
            f"/api/v1/bookings/instant/request/{req_id}/cancel", {}, format="json"
        )
        self.assertEqual(cancel.status_code, 200)
        self.assertEqual(cancel.data["status"], "cancelled")
