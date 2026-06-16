from django.urls import path

from .views import SpecialistDetailView, SpecialistListView, SpecialistMeView

urlpatterns = [
    path("", SpecialistListView.as_view(), name="specialist-list"),
    path("me", SpecialistMeView.as_view(), name="specialist-me"),
    path("<int:pk>", SpecialistDetailView.as_view(), name="specialist-detail"),
]
