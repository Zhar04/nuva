from django.urls import path

from .views import SpecialistDetailView, SpecialistListView

urlpatterns = [
    path("", SpecialistListView.as_view(), name="specialist-list"),
    path("<int:pk>", SpecialistDetailView.as_view(), name="specialist-detail"),
]
