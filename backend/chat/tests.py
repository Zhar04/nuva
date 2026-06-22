"""Chat ownership + behavior tests.

The security bar: a user must never read or post into a conversation they're not
a party to (special-category data — №94-V). Also covers sender inference and the
contact-moderation gate.
"""

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient, APITestCase

from catalog.models import Specialist

from .models import Conversation, Message

User = get_user_model()


def _specialist(owner=None, **kw):
    defaults = dict(
        first_name="Аяна", last_name="С.", title="Психолог",
        rating="4.8", is_verified=True, is_active=True,
    )
    defaults.update(kw)
    return Specialist.objects.create(owner=owner, **defaults)


class ConversationOwnershipTests(APITestCase):
    def setUp(self):
        self.seeker = User.objects.create_user(
            email="seeker@nuva.kz", password="Test12345"
        )
        self.psy_user = User.objects.create_user(
            email="psy@nuva.kz", password="Test12345", role="psychologist"
        )
        self.specialist = _specialist(owner=self.psy_user)
        self.outsider = User.objects.create_user(
            email="outsider@nuva.kz", password="Test12345"
        )

    def _client(self, user):
        c = APIClient()
        c.force_authenticate(user)
        return c

    def _open(self):
        return self._client(self.seeker).post(
            "/api/v1/chat/conversations/",
            {"specialist": self.specialist.id},
            format="json",
        )

    def test_open_creates_conversation_with_welcome(self):
        res = self._open()
        self.assertIn(res.status_code, (200, 201))
        convo = Conversation.objects.get(pk=res.data["id"])
        self.assertEqual(convo.user, self.seeker)
        self.assertTrue(convo.messages.filter(sender="system").exists())

    def test_reopen_reuses_same_conversation(self):
        first = self._open()
        second = self._open()
        self.assertEqual(first.data["id"], second.data["id"])
        self.assertEqual(
            Conversation.objects.filter(
                user=self.seeker, specialist=self.specialist
            ).count(),
            1,
        )

    def test_only_parties_see_the_conversation_in_their_list(self):
        self._open()
        seeker_list = self._client(self.seeker).get("/api/v1/chat/conversations/")
        self.assertEqual(len(seeker_list.data), 1)
        psy_list = self._client(self.psy_user).get("/api/v1/chat/conversations/")
        self.assertEqual(len(psy_list.data), 1)
        out_list = self._client(self.outsider).get("/api/v1/chat/conversations/")
        self.assertEqual(len(out_list.data), 0)

    def test_outsider_cannot_read_messages(self):
        convo_id = self._open().data["id"]
        res = self._client(self.outsider).get(
            f"/api/v1/chat/conversations/{convo_id}/messages/"
        )
        self.assertEqual(res.status_code, 400)  # "Нет доступа."

    def test_outsider_cannot_post_message(self):
        convo_id = self._open().data["id"]
        res = self._client(self.outsider).post(
            f"/api/v1/chat/conversations/{convo_id}/messages/",
            {"text": "подслушиваю"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(
            Message.objects.filter(
                conversation_id=convo_id, text="подслушиваю"
            ).exists()
        )

    def test_sender_is_inferred_from_party(self):
        convo_id = self._open().data["id"]
        seeker_msg = self._client(self.seeker).post(
            f"/api/v1/chat/conversations/{convo_id}/messages/",
            {"text": "здравствуйте"},
            format="json",
        )
        self.assertEqual(seeker_msg.data["sender"], "user")
        psy_msg = self._client(self.psy_user).post(
            f"/api/v1/chat/conversations/{convo_id}/messages/",
            {"text": "добрый день"},
            format="json",
        )
        self.assertEqual(psy_msg.data["sender"], "specialist")

    def test_sharing_a_phone_number_is_blocked(self):
        convo_id = self._open().data["id"]
        res = self._client(self.seeker).post(
            f"/api/v1/chat/conversations/{convo_id}/messages/",
            {"text": "мой номер +7 701 234 5678"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
