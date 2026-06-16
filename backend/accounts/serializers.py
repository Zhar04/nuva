from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import ProDocument

User = get_user_model()

MAX_B64 = 4_000_000  # ~3 MB of binary; keeps base64-in-DB sane


def _check_size(value):
    if value and len(value) > MAX_B64:
        raise serializers.ValidationError("Файл слишком большой (макс ~3 МБ).")
    return value


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id", "email", "name", "role",
            "age", "gender", "mbti", "bio", "avatar", "created_at",
        )
        read_only_fields = ("id", "email", "role", "created_at")


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, min_length=8, style={"input_type": "password"}
    )

    class Meta:
        model = User
        fields = ("email", "password", "name", "role")
        extra_kwargs = {
            "name": {"required": False},
            "role": {"required": False},
        }

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate_role(self, value):
        # Self-registration as admin is not allowed.
        if value == User.Role.ADMIN:
            raise serializers.ValidationError("Недопустимая роль.")
        return value

    def create(self, validated):
        password = validated.pop("password")
        user = User(**validated)
        user.set_password(password)
        user.save()
        return user


class MeUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("name", "age", "gender", "mbti", "bio", "avatar")

    def validate_avatar(self, value):
        return _check_size(value)


class ProDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProDocument
        fields = ("id", "title", "data", "content_type", "created_at")
        read_only_fields = ("id", "created_at")

    def validate_data(self, value):
        return _check_size(value)
