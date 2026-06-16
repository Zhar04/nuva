from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from catalog.models import Specialist

from .models import Booking, ClientNote
from .serializers import (
    BookingCreateSerializer,
    BookingDeclineSerializer,
    BookingSerializer,
    ClientNoteSerializer,
    ClientSessionSerializer,
)


def _ensure_conversation(booking):
    """Make sure a chat thread exists for this (client, specialist) pair so the
    psychologist can message/call once a request is accepted."""
    from chat.models import Conversation

    convo, _ = Conversation.objects.get_or_create(
        user=booking.user, specialist=booking.specialist
    )
    return convo


class BookingListCreateView(generics.ListCreateAPIView):
    """GET (mine) / POST a booking request — authenticated."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return (
            Booking.objects.filter(user=self.request.user)
            .select_related("specialist")
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return BookingCreateSerializer
        return BookingSerializer

    def create(self, request, *args, **kwargs):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)
        is_intro = ser.validated_data.get("is_intro") or (
            ser.validated_data.get("intent") == Booking.Intent.INTRO
        )
        # A booking is a REQUEST first — it waits for the psychologist to accept.
        # An intro session is free, so its price is forced to 0.
        booking = ser.save(
            user=request.user,
            status=Booking.Status.REQUESTED,
            is_intro=is_intro,
            price_kzt=0 if is_intro else ser.validated_data.get("price_kzt", 0),
        )
        return Response(BookingSerializer(booking).data, status=201)


class IncomingBookingsView(generics.ListAPIView):
    """GET the sessions/requests booked with the signed-in psychologist."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = BookingSerializer

    def get_queryset(self):
        return (
            Booking.objects.filter(specialist__owner=self.request.user)
            .select_related("specialist", "user")
        )


class _SpecialistActionView(APIView):
    """Base for psychologist-only actions on an incoming booking."""

    permission_classes = [permissions.IsAuthenticated]

    def get_booking(self, request, pk):
        return get_object_or_404(
            Booking.objects.select_related("specialist", "user"),
            pk=pk,
            specialist__owner=request.user,
        )


class BookingAcceptView(_SpecialistActionView):
    """POST /bookings/{id}/accept — psychologist confirms a request.

    Free intro → SCHEDULED (straight to the calendar). Paid → PENDING (the
    client now sees "Подтверждён — ждёт оплаты")."""

    def post(self, request, pk):
        b = self.get_booking(request, pk)
        if b.status == Booking.Status.REQUESTED:
            b.status = (
                Booking.Status.SCHEDULED if b.is_intro
                else Booking.Status.PENDING
            )
            b.decline_reason = ""
            b.proposed_starts_at = None
            b.save(update_fields=["status", "decline_reason", "proposed_starts_at"])
            _ensure_conversation(b)
        return Response(BookingSerializer(b).data)


class BookingDeclineView(_SpecialistActionView):
    """POST /bookings/{id}/decline — with a reason and an optional new time."""

    def post(self, request, pk):
        b = self.get_booking(request, pk)
        ser = BookingDeclineSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        b.status = Booking.Status.DECLINED
        b.decline_reason = ser.validated_data.get("reason", "")
        b.proposed_starts_at = ser.validated_data.get("proposed_starts_at")
        b.save(update_fields=["status", "decline_reason", "proposed_starts_at"])
        return Response(BookingSerializer(b).data)


class BookingPayView(generics.GenericAPIView):
    """POST /bookings/{id}/pay — client marks a confirmed session as paid.

    The acquirer is mocked; this transitions PENDING → PAID so the session
    locks into both calendars."""

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = BookingSerializer

    def post(self, request, pk):
        b = get_object_or_404(
            Booking.objects.select_related("specialist", "user"),
            pk=pk,
            user=request.user,
        )
        if b.status == Booking.Status.PENDING:
            b.status = Booking.Status.PAID
            b.payment_provider = request.data.get("provider", "mock")
            b.save(update_fields=["status", "payment_provider"])
        return Response(BookingSerializer(b).data)


class BookingDetailView(generics.RetrieveUpdateAPIView):
    """GET one / PATCH to cancel — owner only."""

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = BookingSerializer

    def get_queryset(self):
        return (
            Booking.objects.filter(user=self.request.user)
            .select_related("specialist")
        )

    def patch(self, request, *args, **kwargs):
        booking = self.get_object()
        if request.data.get("status") == "cancelled":
            booking.status = Booking.Status.CANCELLED
            booking.save(update_fields=["status"])
        return Response(BookingSerializer(booking).data)


class ClientCardView(APIView):
    """GET/PUT /bookings/clients/{client_id} — the psychologist's view of one
    client: concern, session history, a private note and a mood trend.

    Only the specialist who actually has bookings with this client can see it.
    The client's private mood journal is NOT exposed — the trend is derived from
    the moods the client logged around their sessions only when the booking
    relationship exists, kept coarse on purpose."""

    permission_classes = [permissions.IsAuthenticated]

    def _specialist(self, request):
        return getattr(request.user, "specialist_profile", None)

    def _sessions(self, specialist, client_id):
        return (
            Booking.objects.filter(specialist=specialist, user_id=client_id)
            .order_by("-starts_at")
        )

    def get(self, request, client_id):
        sp = self._specialist(request)
        if sp is None:
            return Response({"detail": "Не специалист"}, status=403)
        sessions = self._sessions(sp, client_id)
        if not sessions.exists():
            return Response({"detail": "Нет клиента"}, status=404)
        first = sessions.first()
        client = first.user
        note = ClientNote.objects.filter(specialist=sp, client_id=client_id).first()
        # Coarse mood trend (1..5) from this client's own journal, last 8 points.
        mood_trend = []
        try:
            from journal.models import MoodEntry

            mood_trend = list(
                MoodEntry.objects.filter(user_id=client_id)
                .order_by("-day")
                .values_list("mood", flat=True)[:8]
            )[::-1]
        except Exception:
            mood_trend = []
        concern = next((s.concern for s in sessions if s.concern), "")
        return Response(
            {
                "client_id": client_id,
                "name": (client.name or "").strip() or "Клиент",
                "concern": concern,
                "note": note.text if note else "",
                "mood_trend": mood_trend,
                "sessions": ClientSessionSerializer(sessions, many=True).data,
            }
        )

    def put(self, request, client_id):
        sp = self._specialist(request)
        if sp is None:
            return Response({"detail": "Не специалист"}, status=403)
        if not self._sessions(sp, client_id).exists():
            return Response({"detail": "Нет клиента"}, status=404)
        note, _ = ClientNote.objects.get_or_create(specialist=sp, client_id=client_id)
        ser = ClientNoteSerializer(note, data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(ser.data)
