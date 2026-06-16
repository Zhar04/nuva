from rest_framework import serializers

from catalog.models import Specialist

from .models import Booking, ClientNote


class BookingSpecialistSerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialist
        fields = ("id", "first_name", "last_name", "title", "avatar_gradient")


class BookingSerializer(serializers.ModelSerializer):
    specialist = BookingSpecialistSerializer(read_only=True)
    client_name = serializers.SerializerMethodField()
    client_id = serializers.IntegerField(source="user_id", read_only=True)
    conversation_id = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = (
            "id", "specialist", "client_name", "client_id", "conversation_id",
            "starts_at", "format", "duration_minutes",
            "price_kzt", "service_fee_kzt", "status",
            "intent", "is_intro", "concern", "client_message", "match_score",
            "decline_reason", "proposed_starts_at", "created_at",
        )

    def get_client_name(self, obj):
        n = (obj.user.name or "").strip()
        return n if n else "Клиент"

    def get_conversation_id(self, obj):
        from chat.models import Conversation

        c = Conversation.objects.filter(
            user=obj.user, specialist=obj.specialist
        ).first()
        return c.id if c else None


class BookingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = (
            "specialist", "starts_at", "format", "price_kzt",
            "intent", "is_intro", "concern", "client_message", "match_score",
        )


class BookingDeclineSerializer(serializers.Serializer):
    """Payload when a psychologist declines a request."""

    reason = serializers.CharField(allow_blank=True, required=False, default="")
    proposed_starts_at = serializers.DateTimeField(required=False, allow_null=True)


class ClientNoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClientNote
        fields = ("text", "updated_at")


class ClientSessionSerializer(serializers.ModelSerializer):
    """A single past/upcoming session, for the client card's history list."""

    class Meta:
        model = Booking
        fields = (
            "id", "starts_at", "format", "status", "price_kzt",
            "is_intro", "concern",
        )
