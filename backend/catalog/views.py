from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Specialist
from .serializers import (
    SpecialistDetailSerializer,
    SpecialistListSerializer,
    SpecialistMeSerializer,
)


class SpecialistListView(generics.ListAPIView):
    """GET /api/v1/specialists/ — public, plain list (catalog is small)."""

    serializer_class = SpecialistListSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None
    # Only verified psychologists are shown to clients. A freshly self-registered
    # psychologist stays hidden (and unbookable) until an admin checks their
    # documents and flips is_verified.
    queryset = Specialist.objects.filter(is_active=True, is_verified=True)


class SpecialistDetailView(generics.RetrieveAPIView):
    """GET /api/v1/specialists/{id} — public, with education + reviews."""

    serializer_class = SpecialistDetailSerializer
    permission_classes = [permissions.AllowAny]
    queryset = Specialist.objects.all()


class SpecialistMeView(APIView):
    """The signed-in psychologist's own catalog profile.

    GET → {exists, ...profile}; PUT → create or update it (and list them)."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        sp = getattr(request.user, "specialist_profile", None)
        if sp is None:
            return Response({"exists": False})
        return Response({"exists": True, **SpecialistDetailSerializer(sp).data})

    def put(self, request):
        sp = getattr(request.user, "specialist_profile", None)
        ser = SpecialistMeSerializer(sp, data=request.data, partial=sp is not None)
        ser.is_valid(raise_exception=True)
        sp = ser.save(owner=request.user)
        if not sp.is_active:
            sp.is_active = True
            sp.save(update_fields=["is_active"])
        # Owning a specialist profile *is* what makes a user a psychologist.
        # Promote the account so the app shows the specialist cabinet (this also
        # repairs accounts registered before the role was passed at sign-up).
        user = request.user
        if user.role != user.Role.PSYCHOLOGIST:
            user.role = user.Role.PSYCHOLOGIST
            user.save(update_fields=["role"])
        return Response(
            {"exists": True, **SpecialistDetailSerializer(sp).data}
        )
