from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Favorite, Specialist
from .serializers import (
    SpecialistDetailSerializer,
    SpecialistListSerializer,
    SpecialistMeSerializer,
)


class SpecialistListView(generics.ListAPIView):
    """GET /api/v1/specialists/ — public list, with optional filters:
    `?q=` (name / works_with / approaches), `?lang=`, `?instant=1`."""

    serializer_class = SpecialistListSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None

    def get_queryset(self):
        # Only verified psychologists are shown to clients. A freshly
        # self-registered psychologist stays hidden until an admin verifies them.
        qs = Specialist.objects.filter(is_active=True, is_verified=True)
        p = self.request.query_params
        q = (p.get("q") or "").strip().lower()
        lang = (p.get("lang") or "").strip().lower()
        instant = p.get("instant")
        if q or lang or instant in ("1", "true"):
            # JSONField text search isn't portable to SQLite, so filter the small
            # verified catalog in Python.
            out = []
            for sp in qs:
                if q:
                    hay = " ".join([
                        sp.first_name, sp.last_name, sp.title,
                        *(sp.works_with or []), *(sp.approaches or []),
                    ]).lower()
                    if q not in hay:
                        continue
                if lang and not any(lang in str(x).lower()
                                    for x in (sp.languages or [])):
                    continue
                if instant in ("1", "true") and not sp.is_instant_available():
                    continue
                out.append(sp)
            return out
        return qs


class FavoritesView(APIView):
    """GET /api/v1/specialists/favorites — the signed-in user's saved
    specialists. POST {specialist} toggles one. Owner-scoped."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        specs = [
            f.specialist
            for f in Favorite.objects.filter(user=request.user)
            .select_related("specialist")
        ]
        data = SpecialistListSerializer(
            specs, many=True, context={"request": request}
        ).data
        return Response(data)

    def post(self, request):
        sp = get_object_or_404(Specialist, pk=request.data.get("specialist"))
        fav, created = Favorite.objects.get_or_create(
            user=request.user, specialist=sp
        )
        if not created:
            fav.delete()
        return Response({"specialist": sp.id, "favorite": created})


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
        creating = sp is None
        ser = SpecialistMeSerializer(sp, data=request.data, partial=not creating)
        ser.is_valid(raise_exception=True)
        sp = ser.save(owner=request.user)
        # "Доступен сейчас" window is server-controlled (instant_until is
        # read-only on the serializer): turning the toggle on opens a 1-hour
        # window so the status auto-expires; turning it off clears the window.
        if "accepts_instant" in ser.validated_data:
            from datetime import timedelta

            from django.utils import timezone

            sp.instant_until = (
                timezone.now() + timedelta(hours=1)
                if sp.accepts_instant
                else None
            )
            sp.save(update_fields=["instant_until"])
        # Activate on first creation; afterwards respect the psychologist's own
        # "приём открыт/закрыт" toggle (is_active) sent from the schedule screen.
        if creating and not sp.is_active:
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
