"""Auth + profile tests: registration (incl. the admin-role guard), login,
/me access + update, and ProDocument ownership isolation."""

from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework.test import APIClient, APITestCase

from .models import ProDocument

User = get_user_model()


class RegisterTests(APITestCase):
    def setUp(self):
        cache.clear()  # 'auth' scope throttle history lives in the cache
        self.client = APIClient()

    def test_register_returns_user_and_tokens(self):
        res = self.client.post(
            "/api/v1/auth/register",
            {"email": "new@nuva.kz", "password": "Test12345", "name": "Аян"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertIn("access", res.data)
        self.assertIn("refresh", res.data)
        self.assertEqual(res.data["user"]["email"], "new@nuva.kz")
        self.assertEqual(res.data["user"]["role"], "seeker")  # default

    def test_register_as_psychologist_sets_role(self):
        res = self.client.post(
            "/api/v1/auth/register",
            {"email": "p@nuva.kz", "password": "Test12345", "role": "psychologist"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["user"]["role"], "psychologist")

    def test_cannot_self_register_as_admin(self):
        res = self.client.post(
            "/api/v1/auth/register",
            {"email": "evil@nuva.kz", "password": "Test12345", "role": "admin"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(User.objects.filter(email="evil@nuva.kz").exists())

    def test_short_password_rejected(self):
        res = self.client.post(
            "/api/v1/auth/register",
            {"email": "x@nuva.kz", "password": "short"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_duplicate_email_rejected(self):
        User.objects.create_user(email="dup@nuva.kz", password="Test12345")
        res = self.client.post(
            "/api/v1/auth/register",
            {"email": "dup@nuva.kz", "password": "Test12345"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)


class LoginMeTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345", name="Аят"
        )
        self.client = APIClient()

    def test_login_returns_tokens(self):
        res = self.client.post(
            "/api/v1/auth/login",
            {"email": "seeker@nuva.kz", "password": "Test12345"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.data)

    def test_login_wrong_password_rejected(self):
        res = self.client.post(
            "/api/v1/auth/login",
            {"email": "seeker@nuva.kz", "password": "WRONG"},
            format="json",
        )
        self.assertEqual(res.status_code, 401)

    def test_me_requires_auth(self):
        self.assertEqual(self.client.get("/api/v1/auth/me").status_code, 401)

    def test_me_returns_own_profile(self):
        self.client.force_authenticate(self.user)
        res = self.client.get("/api/v1/auth/me")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["email"], "seeker@nuva.kz")

    def test_me_patch_updates_profile_but_not_email_or_role(self):
        self.client.force_authenticate(self.user)
        res = self.client.patch(
            "/api/v1/auth/me",
            {"name": "Новое имя", "email": "hacked@nuva.kz", "role": "admin"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.name, "Новое имя")
        self.assertEqual(self.user.email, "seeker@nuva.kz")  # read-only
        self.assertEqual(self.user.role, "seeker")  # read-only

    def test_oversized_avatar_rejected(self):
        self.client.force_authenticate(self.user)
        res = self.client.patch(
            "/api/v1/auth/me",
            {"avatar": "x" * 4_000_001},
            format="json",
        )
        self.assertEqual(res.status_code, 400)


class ProDocumentOwnershipTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="psy@nuva.kz", password="Test12345", role="psychologist"
        )
        self.other = User.objects.create_user(
            email="other@nuva.kz", password="Test12345"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_create_and_list_only_own_documents(self):
        self.client.post(
            "/api/v1/documents/",
            {"title": "Диплом", "data": "data:image/png;base64,AAAA"},
            format="json",
        )
        ProDocument.objects.create(user=self.other, title="Чужой", data="x")
        res = self.client.get("/api/v1/documents/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]["title"], "Диплом")

    def test_cannot_delete_another_users_document(self):
        doc = ProDocument.objects.create(user=self.other, title="Чужой", data="x")
        res = self.client.delete(f"/api/v1/documents/{doc.id}/")
        self.assertEqual(res.status_code, 404)  # not in my queryset
        self.assertTrue(ProDocument.objects.filter(pk=doc.pk).exists())
