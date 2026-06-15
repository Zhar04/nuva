from rest_framework import serializers

from catalog.models import Specialist

from .models import Booking


class BookingSpecialistSerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialist
        fields = ("id", "first_name", "last_name", "title", "avatar_gradient")


class BookingSerializer(serializers.ModelSerializer):
    specialist = BookingSpecialistSerializer(read_only=True)

    class Meta:
        model = Booking
        fields = (
            "id", "specialist", "starts_at", "format", "duration_minutes",
            "price_kzt", "service_fee_kzt", "status", "created_at",
        )


class BookingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ("specialist", "starts_at", "format", "price_kzt")
