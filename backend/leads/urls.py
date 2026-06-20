from django.urls import path

from .views import LeadCreateView, LeadLinkView

urlpatterns = [
    path("", LeadCreateView.as_view(), name="lead-create"),
    path("<int:pk>/link/", LeadLinkView.as_view(), name="lead-link"),
]
