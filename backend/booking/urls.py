from django.urls import path

from .views import BookingDetailView, BookingListCreateView, IncomingBookingsView

urlpatterns = [
    path("", BookingListCreateView.as_view(), name="booking-list"),
    path("incoming", IncomingBookingsView.as_view(), name="booking-incoming"),
    path("<int:pk>", BookingDetailView.as_view(), name="booking-detail"),
]
