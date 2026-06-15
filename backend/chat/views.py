import re

from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, serializers
from rest_framework.response import Response

from catalog.models import Specialist

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer

WELCOME = (
    "Это защищённый чат Nuva. Сообщения видят только вы и специалист. "
    "Не делитесь телефонами и контактами вне платформы — это нарушение правил."
)

# Server-side backstop for the on-platform rule: block phone numbers, external
# links and contact handles (Telegram / WhatsApp / Zoom / Meet / Instagram …).
# The client mirrors this regex for instant feedback; the server enforces it.
CONTACT_RE = re.compile(
    r"(\+?\d[\d\s().\-]{7,}\d)"  # phone numbers
    r"|(https?://)|(www\.)"  # any URL
    r"|(@[\w.]{2,})"  # @handles
    r"|(t\.me|wa\.me|zoom\.us|zoom|meet\.google|g\.co/|instagram|instagr"
    r"|whatsapp|telegram|viber|skype|facebook|fb\.com|vk\.com|youtu"
    r"|телеграм|вотсап|ватсап|инстаграм|вайбер|скайп|вконтакте)",
    re.IGNORECASE,
)
CONTACT_BLOCKED = (
    "Сообщение содержит контакты или внешнюю ссылку. "
    "Общение и звонки — только внутри Nuva."
)


class ConversationListCreateView(generics.ListCreateAPIView):
    """GET my conversations / POST {specialist: id} to open (or reuse) one."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = ConversationSerializer

    def get_queryset(self):
        return (
            Conversation.objects.filter(user=self.request.user)
            .select_related("specialist")
            .prefetch_related("messages")
        )

    def create(self, request, *args, **kwargs):
        spec_id = request.data.get("specialist")
        if not spec_id:
            raise serializers.ValidationError({"specialist": "Обязательное поле."})
        specialist = get_object_or_404(Specialist, pk=spec_id)
        convo, created = Conversation.objects.get_or_create(
            user=request.user, specialist=specialist
        )
        if created:
            Message.objects.create(
                conversation=convo, sender=Message.Sender.SYSTEM, text=WELCOME
            )
        return Response(
            ConversationSerializer(convo).data, status=201 if created else 200
        )


class MessageListCreateView(generics.ListCreateAPIView):
    """GET messages in a conversation / POST a new one (sender = user)."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = MessageSerializer

    def _conversation(self):
        return get_object_or_404(
            Conversation, pk=self.kwargs["pk"], user=self.request.user
        )

    def get_queryset(self):
        convo = self._conversation()
        # Opening the thread marks the specialist's messages as read.
        convo.messages.filter(
            sender=Message.Sender.SPECIALIST, is_read=False
        ).update(is_read=True)
        return convo.messages.all()

    def create(self, request, *args, **kwargs):
        convo = self._conversation()
        text = (request.data.get("text") or "").strip()
        if not text:
            raise serializers.ValidationError({"text": "Пустое сообщение."})
        if CONTACT_RE.search(text):
            raise serializers.ValidationError({"text": CONTACT_BLOCKED})
        msg = Message.objects.create(
            conversation=convo, sender=Message.Sender.USER, text=text
        )
        convo.save(update_fields=["updated_at"])  # bump thread order
        return Response(MessageSerializer(msg).data, status=201)
