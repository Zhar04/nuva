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
    instant_available = serializers.SerializerMethodField()

    class Meta:
        model = Specialist
        fields = (
            "id", "first_name", "last_name", "title", "years_experience",
            "languages", "approaches", "works_with", "session_price_kzt",
            "rating", "review_count", "about", "diplomas", "avatar_gradient",
            "availability", "is_verified", "is_active", "instant_available",
        )

    def get_instant_available(self, obj):
        return obj.is_instant_available()


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
            "accepts_instant", "instant_until",
            "education",
        )
        # instant_until is the safety window for "Доступен сейчас": the server
        # sets it (now + 1h) when accepts_instant is turned on, so a client can't
        # pin itself available forever — see SpecialistMeView.put.
        read_only_fields = ("instant_until",)

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
