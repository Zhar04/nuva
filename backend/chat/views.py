from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from catalog.models import Specialist
from nuva_backend.moderation import CONTACT_BLOCKED, has_contact

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer

WELCOME = (
    "Это защищённый чат Nuva. Сообщения видят только вы и специалист. "
    "Не делитесь телефонами и контактами вне платформы — это нарушение правил."
)


def _visible(user):
    """Conversations the user can see — as the seeker OR the specialist owner."""
    return (
        Conversation.objects.filter(Q(user=user) | Q(specialist__owner=user))
        .select_related("specialist", "user")
        .prefetch_related("messages")
        .distinct()
    )


class ConversationListCreateView(generics.ListCreateAPIView):
    """GET my conversations / POST {specialist: id} to open (or reuse) one."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = ConversationSerializer

    def get_queryset(self):
        return _visible(self.request.user)

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
            ConversationSerializer(convo, context={"request": request}).data,
            status=201 if created else 200,
        )


class MessageListCreateView(generics.ListCreateAPIView):
    """GET messages in a conversation / POST a new one. The sender is inferred:
    the specialist owner posts as 'specialist', everyone else as 'user'."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = MessageSerializer

    def _conversation(self):
        convo = get_object_or_404(Conversation, pk=self.kwargs["pk"])
        u = self.request.user
        if convo.user_id != u.id and convo.specialist.owner_id != u.id:
            raise serializers.ValidationError({"detail": "Нет доступа."})
        return convo

    def _is_specialist(self, convo):
        return convo.specialist.owner_id == self.request.user.id

    def get_queryset(self):
        convo = self._conversation()
        # Opening marks the *other* side's messages as read.
        other = (
            Message.Sender.USER
            if self._is_specialist(convo)
            else Message.Sender.SPECIALIST
        )
        convo.messages.filter(sender=other, is_read=False).update(is_read=True)
        return convo.messages.all()

    def create(self, request, *args, **kwargs):
        convo = self._conversation()
        text = (request.data.get("text") or "").strip()
        if not text:
            raise serializers.ValidationError({"text": "Пустое сообщение."})
        if has_contact(text):
            raise serializers.ValidationError({"text": CONTACT_BLOCKED})
        sender = (
            Message.Sender.SPECIALIST
            if self._is_specialist(convo)
            else Message.Sender.USER
        )
        msg = Message.objects.create(
            conversation=convo, sender=sender, text=text
        )
        convo.save(update_fields=["updated_at"])
        return Response(MessageSerializer(msg).data, status=201)


class CallView(APIView):
    """POST {action: request|accept|end} — the video-call handshake.

    request: the client asks for a call. accept: the specialist agrees (now both
    can join). end: clears the handshake."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        convo = get_object_or_404(Conversation, pk=pk)
        u = request.user
        is_spec = convo.specialist.owner_id == u.id
        if convo.user_id != u.id and not is_spec:
            raise serializers.ValidationError({"detail": "Нет доступа."})
        action = request.data.get("action")
        if action == "request":
            convo.call_requested = True
            convo.call_accepted = False
            Message.objects.create(
                conversation=convo, sender=Message.Sender.SYSTEM,
                text="📞 Запрос видеозвонка отправлен.",
            )
        elif action == "accept":
            if not is_spec:
                raise serializers.ValidationError(
                    {"detail": "Принять может только специалист."}
                )
            convo.call_accepted = True
            convo.call_requested = True
            Message.objects.create(
                conversation=convo, sender=Message.Sender.SYSTEM,
                text="✅ Специалист принял звонок — подключайтесь.",
            )
        elif action == "end":
            convo.call_requested = False
            convo.call_accepted = False
        else:
            raise serializers.ValidationError({"action": "request|accept|end"})
        convo.save()
        return Response(
            ConversationSerializer(convo, context={"request": request}).data
        )
