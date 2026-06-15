from rest_framework import generics, permissions

from .models import Specialist
from .serializers import SpecialistDetailSerializer, SpecialistListSerializer


class SpecialistListView(generics.ListAPIView):
    """GET /api/v1/specialists/ — public, plain list (catalog is small)."""

    serializer_class = SpecialistListSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None
    queryset = Specialist.objects.filter(is_active=True)


class SpecialistDetailView(generics.RetrieveAPIView):
    """GET /api/v1/specialists/{id} — public, with education + reviews."""

    serializer_class = SpecialistDetailSerializer
    permission_classes = [permissions.AllowAny]
    queryset = Specialist.objects.all()
