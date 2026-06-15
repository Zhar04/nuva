from rest_framework import generics, permissions
from rest_framework.response import Response

from .models import Booking
from .serializers import BookingCreateSerializer, BookingSerializer


class BookingListCreateView(generics.ListCreateAPIView):
    """GET (mine) / POST a booking — authenticated."""

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
        booking = ser.save(user=request.user)
        return Response(BookingSerializer(booking).data, status=201)


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
