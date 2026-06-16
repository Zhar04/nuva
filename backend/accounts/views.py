from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import ProDocument
from .serializers import (
    MeUpdateSerializer,
    ProDocumentSerializer,
    RegisterSerializer,
    UserSerializer,
)


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
