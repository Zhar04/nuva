from rest_framework import serializers

from catalog.models import Specialist

from .models import Conversation, Message


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ("id", "sender", "text", "is_read", "created_at")
        read_only_fields = ("id", "sender", "is_read", "created_at")


class ConversationSpecialistSerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialist
        fields = ("id", "first_name", "last_name", "title", "avatar_gradient")


class ConversationSerializer(serializers.ModelSerializer):
    specialist = ConversationSpecialistSerializer(read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    viewer_is_specialist = serializers.SerializerMethodField()
    client_name = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = (
            "id", "specialist", "last_message", "unread_count",
            "viewer_is_specialist", "client_name",
            "call_requested", "call_accepted",
            "created_at", "updated_at",
        )

    def _is_spec(self, obj):
        request = self.context.get("request")
        u = getattr(request, "user", None)
        return bool(
            u and u.is_authenticated and obj.specialist.owner_id == u.id
        )

    def get_viewer_is_specialist(self, obj):
        return self._is_spec(obj)

    def get_client_name(self, obj):
        n = (obj.user.name or "").strip()
        return n if n else "Клиент"

    def get_last_message(self, obj):
        msg = obj.messages.order_by("-created_at").first()
        return MessageSerializer(msg).data if msg else None

    def get_unread_count(self, obj):
        # The *other* side's unread messages, from the current viewer's angle.
        other = (
            Message.Sender.USER
            if self._is_spec(obj)
            else Message.Sender.SPECIALIST
        )
        return obj.messages.filter(sender=other, is_read=False).count()
