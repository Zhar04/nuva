from django.urls import path

from .views import AskView, MatchView

urlpatterns = [
    path("match/", MatchView.as_view(), name="ai-match"),
    path("ask/", AskView.as_view(), name="ai-ask"),
]
