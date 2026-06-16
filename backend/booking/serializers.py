from rest_framework import serializers

from catalog.models import Specialist

from .models import Booking


class BookingSpecialistSerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialist
        fields = ("id", "first_name", "last_name", "title", "avatar_gradient")


class BookingSerializer(serializers.ModelSerializer):
    specialist = BookingSpecialistSerializer(read_only=True)
    client_name = serializers.SerializerMethodField()
    conversation_id = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = (
            "id", "specialist", "client_name", "conversation_id",
            "starts_at", "format", "duration_minutes",
            "price_kzt", "service_fee_kzt", "status", "created_at",
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
        fields = ("specialist", "starts_at", "format", "price_kzt")
