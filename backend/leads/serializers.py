import re

from rest_framework import serializers

from .models import Lead

# A lead contact is a phone, an email, or an @handle. This is the INVERSE of the
# chat moderation rule (which blocks contacts) — here a contact is exactly what
# we want, so we validate it positively rather than reusing has_contact().
_PHONE_RE = re.compile(r"^\+?\d[\d\s().\-]{6,}\d$")
_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
_HANDLE_RE = re.compile(r"^@?[\w.]{3,}$")

_FOR_WHOM = {"self", "relative", "child", ""}
_SEVERITY = {"mild", "moderate", "severe", ""}
_FORMAT = {"online", "offline", "", "any"}


class LeadCreateSerializer(serializers.ModelSerializer):
    """Write serializer for the entry quiz. Validates the (required) contact and
    the consent flag; everything else is short, capped text the model stores."""

    class Meta:
        model = Lead
        fields = (
            "for_whom", "topics", "severity", "goal", "format",
            "language", "urgency", "budget", "contact", "consent",
        )

    def validate_topics(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError("Ожидался список тем.")
        # Cap count and length so a caller can't send a huge payload.
        return [str(t).strip()[:60] for t in value[:20] if str(t).strip()]

    def validate_for_whom(self, value):
        if value not in _FOR_WHOM:
            raise serializers.ValidationError("Недопустимое значение.")
        return value

    def validate_severity(self, value):
        if value not in _SEVERITY:
            raise serializers.ValidationError("Недопустимое значение.")
        return value

    def validate_format(self, value):
        if value not in _FORMAT:
            raise serializers.ValidationError("Недопустимый формат.")
        return value

    def validate_contact(self, value):
        value = (value or "").strip()
        if not value:
            raise serializers.ValidationError("Укажите контакт для связи.")
        if not (
            _PHONE_RE.match(value)
            or _EMAIL_RE.match(value)
            or _HANDLE_RE.match(value)
        ):
            raise serializers.ValidationError(
                "Введите телефон, email или @username."
            )
        return value[:120]

    def validate_consent(self, value):
        if not value:
            raise serializers.ValidationError(
                "Без согласия на обработку данных продолжить нельзя."
            )
        return value


class LeadResultSerializer(serializers.ModelSerializer):
    """Read-back of a created lead (no contact echoed — minimise PII surface)."""

    class Meta:
        model = Lead
        fields = ("id", "created_at", "linked_at")
        read_only_fields = fields
