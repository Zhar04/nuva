from django.urls import path

from .views import (
    BookingAcceptView,
    BookingDeclineView,
    BookingDetailView,
    BookingListCreateView,
    BookingPayView,
    ClientCardView,
    IncomingBookingsView,
)

urlpatterns = [
    path("", BookingListCreateView.as_view(), name="booking-list"),
    path("incoming", IncomingBookingsView.as_view(), name="booking-incoming"),
    path("clients/<int:client_id>", ClientCardView.as_view(), name="client-card"),
    path("<int:pk>/accept", BookingAcceptView.as_view(), name="booking-accept"),
    path("<int:pk>/decline", BookingDeclineView.as_view(), name="booking-decline"),
    path("<int:pk>/pay", BookingPayView.as_view(), name="booking-pay"),
    path("<int:pk>", BookingDetailView.as_view(), name="booking-detail"),
]
