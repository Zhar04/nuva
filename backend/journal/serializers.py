from rest_framework import serializers

from .models import MoodEntry


class MoodEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = MoodEntry
        fields = ("id", "day", "mood", "note", "created_at", "updated_at")
        read_only_fields = ("id", "day", "created_at", "updated_at")
