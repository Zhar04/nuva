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
            "availability", "is_verified", "is_active",
        )


class SpecialistDetailSerializer(SpecialistListSerializer):
    education = EducationSerializer(many=True, read_only=True)
    reviews = ReviewSerializer(many=True, read_only=True)

    class Meta(SpecialistListSerializer.Meta):
        fields = SpecialistListSerializer.Meta.fields + ("education", "reviews")


class SpecialistMeSerializer(serializers.ModelSerializer):
    """Writable profile a psychologist edits for their own catalog listing.

    Education is a related model; we accept it as a nested list and replace the
    set on each save (the cabinet editor sends the full list)."""

    education = EducationSerializer(many=True, required=False)

    class Meta:
        model = Specialist
        fields = (
            "first_name", "last_name", "title", "years_experience",
            "languages", "approaches", "works_with", "session_price_kzt",
            "about", "diplomas", "avatar_gradient", "availability", "is_active",
            "education",
        )

    def _sync_education(self, specialist, rows):
        specialist.education.all().delete()
        Education.objects.bulk_create(
            [
                Education(
                    specialist=specialist,
                    institution=r.get("institution", ""),
                    degree=r.get("degree", ""),
                    years=r.get("years", ""),
                )
                for r in rows
                if (r.get("institution") or r.get("degree"))
            ]
        )

    def create(self, validated_data):
        education = validated_data.pop("education", None)
        specialist = super().create(validated_data)
        if education is not None:
            self._sync_education(specialist, education)
        return specialist

    def update(self, instance, validated_data):
        education = validated_data.pop("education", None)
        specialist = super().update(instance, validated_data)
        if education is not None:
            self._sync_education(specialist, education)
        return specialist
