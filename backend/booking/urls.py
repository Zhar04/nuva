from django.urls import path

from .views import (
    BookingAcceptView,
    BookingDeclineView,
    BookingDetailView,
    BookingListCreateView,
    BookingPayView,
    ClientCardView,
    IncomingBookingsView,
    InstantMatchView,
    InstantRequestCancelView,
    InstantRequestClaimView,
    InstantRequestCreateView,
    InstantRequestDetailView,
    InstantRequestQueueView,
)

urlpatterns = [
    path("", BookingListCreateView.as_view(), name="booking-list"),
    path("incoming", IncomingBookingsView.as_view(), name="booking-incoming"),
    # "Поговорить сейчас" funnel — keep these BEFORE the <int:pk> catch-alls.
    path("instant", InstantMatchView.as_view(), name="instant-match"),
    path("instant/request", InstantRequestCreateView.as_view(),
         name="instant-request"),
    path("instant/queue", InstantRequestQueueView.as_view(),
         name="instant-queue"),
    path("instant/request/<int:pk>", InstantRequestDetailView.as_view(),
         name="instant-request-detail"),
    path("instant/request/<int:pk>/cancel", InstantRequestCancelView.as_view(),
         name="instant-request-cancel"),
    path("instant/request/<int:pk>/claim", InstantRequestClaimView.as_view(),
         name="instant-request-claim"),
    path("clients/<int:client_id>", ClientCardView.as_view(), name="client-card"),
    path("<int:pk>/accept", BookingAcceptView.as_view(), name="booking-accept"),
    path("<int:pk>/decline", BookingDeclineView.as_view(), name="booking-decline"),
    path("<int:pk>/pay", BookingPayView.as_view(), name="booking-pay"),
    path("<int:pk>", BookingDetailView.as_view(), name="booking-detail"),
]
