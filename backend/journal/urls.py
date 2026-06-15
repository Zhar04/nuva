from django.urls import path

from .views import MoodListCreateView, StatsView

urlpatterns = [
    path("moods/", MoodListCreateView.as_view(), name="moods"),
    path("stats/", StatsView.as_view(), name="stats"),
]
