from django.urls import path

from .views import (
    FavoritesView,
    SpecialistDetailView,
    SpecialistListView,
    SpecialistMeView,
)

urlpatterns = [
    path("", SpecialistListView.as_view(), name="specialist-list"),
    path("me", SpecialistMeView.as_view(), name="specialist-me"),
    path("favorites", FavoritesView.as_view(), name="specialist-favorites"),
    path("<int:pk>", SpecialistDetailView.as_view(), name="specialist-detail"),
]
