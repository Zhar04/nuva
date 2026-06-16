from rest_framework import serializers

from .models import Education, Review, Specialist


class EducationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Education
        fields = ("institution", "degree", "years")


class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = ("author_alias", "rating", "text", "created_at")


class SpecialistListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialist
        fields = (
            "id", "first_name", "last_name", "title", "years_experience",
            "languages", "approaches", "works_with", "session_price_kzt",
            "rating", "review_count", "about", "diplomas", "avatar_gradient",
            "is_verified", "is_active",
        )


class SpecialistDetailSerializer(SpecialistListSerializer):
    education = EducationSerializer(many=True, read_only=True)
    reviews = ReviewSerializer(many=True, read_only=True)

    class Meta(SpecialistListSerializer.Meta):
        fields = SpecialistListSerializer.Meta.fields + ("education", "reviews")


class SpecialistMeSerializer(serializers.ModelSerializer):
    """Writable profile a psychologist edits for their own catalog listing."""

    class Meta:
        model = Specialist
        fields = (
            "first_name", "last_name", "title", "years_experience",
            "languages", "approaches", "works_with", "session_price_kzt",
            "about", "diplomas", "avatar_gradient", "is_active",
        )
