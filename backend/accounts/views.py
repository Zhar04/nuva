from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import generics, permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import ProDocument
from .serializers import (
    MeUpdateSerializer,
    ProDocumentSerializer,
    RegisterSerializer,
    UserSerializer,
)

User = get_user_model()


def _tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {"access": str(refresh.access_token), "refresh": str(refresh)}


class RegisterView(generics.CreateAPIView):
    """POST /api/v1/auth/register → {user, access, refresh}"""

    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]
    throttle_scope = "auth"

    def create(self, request, *args, **kwargs):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user = ser.save()
        return Response(
            {"user": UserSerializer(user).data, **_tokens_for(user)},
            status=status.HTTP_201_CREATED,
        )


class LoginView(TokenObtainPairView):
    """POST /api/v1/auth/login {email, password} → {access, refresh}"""

    permission_classes = [permissions.AllowAny]
    throttle_scope = "auth"


class MeView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/v1/auth/me (Bearer)."""

    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return MeUpdateSerializer
        return UserSerializer


class DocumentListCreateView(generics.ListCreateAPIView):
    """GET my documents / POST a new one (base64 data URL)."""

    serializer_class = ProDocumentSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return ProDocument.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class DocumentDetailView(generics.RetrieveDestroyAPIView):
    """DELETE one of my documents."""

    serializer_class = ProDocumentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ProDocument.objects.filter(user=self.request.user)


class PasswordResetRequestView(APIView):
    """POST {email} → always 200 (don't leak which emails exist). If the email
    matches an account, email a uid+token reset link.

    Email is sent via Django's EMAIL_BACKEND — console in dev, real SMTP once
    EMAIL_HOST/… are set in Railway Variables (like the acquirer, the transport
    is pending infra, but the flow is complete and the token is real)."""

    permission_classes = [permissions.AllowAny]
    throttle_scope = "auth"

    def post(self, request):
        email = (request.data.get("email") or "").strip().lower()
        user = User.objects.filter(email__iexact=email).first()
        if user is not None:
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)
            base = settings.FRONTEND_RESET_URL.rstrip("/")
            link = f"{base}?uid={uid}&token={token}"
            send_mail(
                subject="Сброс пароля Nuva",
                message=(
                    "Вы запросили сброс пароля в Nuva.\n\n"
                    f"Откройте ссылку, чтобы задать новый пароль:\n{link}\n\n"
                    "Если это были не вы — просто игнорируйте письмо."
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        # Same response whether or not the email exists (no account enumeration).
        return Response(
            {"detail": "Если такой аккаунт есть, мы отправили ссылку на email."}
        )


class PasswordResetConfirmView(APIView):
    """POST {uid, token, password} → set a new password if the token is valid."""

    permission_classes = [permissions.AllowAny]
    throttle_scope = "auth"

    def post(self, request):
        uid = request.data.get("uid") or ""
        token = request.data.get("token") or ""
        password = request.data.get("password") or ""
        try:
            pk = force_str(urlsafe_base64_decode(uid))
            user = User.objects.get(pk=pk)
        except (User.DoesNotExist, ValueError, TypeError, OverflowError):
            user = None
        if user is None or not default_token_generator.check_token(user, token):
            raise serializers.ValidationError(
                {"detail": "Ссылка недействительна или устарела."}
            )
        try:
            validate_password(password, user)
        except DjangoValidationError as e:
            # Surface password-policy failures as a 400, not a 500.
            raise serializers.ValidationError({"password": list(e.messages)})
        user.set_password(password)
        user.save(update_fields=["password"])
        return Response({"detail": "Пароль обновлён. Войдите с новым паролем."})
