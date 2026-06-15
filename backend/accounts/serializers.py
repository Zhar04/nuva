from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id", "email", "name", "role",
            "age", "gender", "mbti", "bio", "created_at",
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
        fields = ("name", "age", "gender", "mbti", "bio")
