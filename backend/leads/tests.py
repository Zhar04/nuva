"""Tests for entry-quiz lead capture.

Covers the anonymous funnel (create lead + matched results in one call),
contact/consent validation (a lead contact is required and is NOT blocked by the
chat contact filter), and the post-registration link with its ownership rule.
"""

from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework.test import APIClient, APITestCase

from catalog.models import Specialist

from .models import Lead

User = get_user_model()


def _make_specialist(**kw):
    defaults = dict(
        first_name="Аяна",
        last_name="С.",
        title="Психолог",
        years_experience=6,
        languages=["русский", "казахский"],
        approaches=["КПТ"],
        works_with=["Тревога", "Выгорание"],
        session_price_kzt=12000,
        rating="4.8",
        is_verified=True,
        is_active=True,
    )
    defaults.update(kw)
    return Specialist.objects.create(**defaults)


class LeadCreateTests(APITestCase):
    def setUp(self):
        cache.clear()  # anon throttle history lives in the cache
        self.client = APIClient()
        _make_specialist()

    def _payload(self, **over):
        base = {
            "for_whom": "self",
            "topics": ["Тревога"],
            "severity": "moderate",
            "goal": "Справиться с состоянием",
            "format": "online",
            "language": "ru",
            "urgency": "this_week",
            "budget": "mid",
            "contact": "+7 701 000 0000",
            "consent": True,
        }
        base.update(over)
        return base

    def test_anonymous_can_create_lead_and_get_matches(self):
        res = self.client.post("/api/v1/leads/", self._payload(), format="json")
        self.assertEqual(res.status_code, 201)
        self.assertIn("lead_id", res.data)
        self.assertIsInstance(res.data["results"], list)
        self.assertTrue(res.data["results"], "expected at least one match")
        lead = Lead.objects.get(pk=res.data["lead_id"])
        self.assertIsNone(lead.user)  # anonymous until linked
        self.assertEqual(lead.matched_ids,
                         [r["specialist"]["id"] for r in res.data["results"]])

    def test_contact_is_required(self):
        res = self.client.post(
            "/api/v1/leads/", self._payload(contact=""), format="json"
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("contact", res.data)

    def test_consent_is_required(self):
        res = self.client.post(
            "/api/v1/leads/", self._payload(consent=False), format="json"
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("consent", res.data)

    def test_contact_accepts_phone_email_handle(self):
        for contact in ("+77010000000", "user@mail.kz", "@my_handle"):
            cache.clear()
            res = self.client.post(
                "/api/v1/leads/", self._payload(contact=contact), format="json"
            )
            self.assertEqual(res.status_code, 201, contact)

    def test_garbage_contact_rejected(self):
        res = self.client.post(
            "/api/v1/leads/", self._payload(contact="??"), format="json"
        )
        self.assertEqual(res.status_code, 400)

    def test_severe_severity_biases_toward_trauma(self):
        # A trauma-savvy specialist should outrank on a 'severe' lead even when
        # the visitor only picked a generic topic.
        _make_specialist(first_name="Бота", works_with=["Травма"], rating="4.9")
        res = self.client.post(
            "/api/v1/leads/",
            self._payload(topics=["Сон"], severity="severe"),
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        reasons = " ".join(
            r for m in res.data["results"] for r in m["reasons"]
        )
        self.assertIn("Травма", reasons)


class LeadLinkTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )

    def _lead(self, user=None):
        return Lead.objects.create(topics=["Тревога"], contact="@x", user=user)

    def test_link_requires_auth(self):
        lead = self._lead()
        res = APIClient().post(f"/api/v1/leads/{lead.id}/link/", format="json")
        self.assertEqual(res.status_code, 401)

    def test_authenticated_user_claims_anonymous_lead(self):
        lead = self._lead()
        client = APIClient()
        client.force_authenticate(self.user)
        res = client.post(f"/api/v1/leads/{lead.id}/link/", format="json")
        self.assertEqual(res.status_code, 200)
        lead.refresh_from_db()
        self.assertEqual(lead.user, self.user)
        self.assertIsNotNone(lead.linked_at)

    def test_cannot_claim_another_users_lead(self):
        other = User.objects.create_user(email="o@nuva.kz", password="Test12345")
        lead = self._lead(user=other)
        client = APIClient()
        client.force_authenticate(self.user)
        res = client.post(f"/api/v1/leads/{lead.id}/link/", format="json")
        self.assertEqual(res.status_code, 403)
        lead.refresh_from_db()
        self.assertEqual(lead.user, other)
