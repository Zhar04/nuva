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

    class Meta:
        model = Conversation
        fields = (
            "id", "specialist", "last_message", "unread_count",
            "created_at", "updated_at",
        )

    def get_last_message(self, obj):
        msg = obj.messages.order_by("-created_at").first()
        return MessageSerializer(msg).data if msg else None

    def get_unread_count(self, obj):
        # Messages from the specialist the seeker has not read yet.
        return obj.messages.filter(
            sender=Message.Sender.SPECIALIST, is_read=False
        ).count()
