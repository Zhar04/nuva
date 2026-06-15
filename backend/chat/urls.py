from django.urls import path

from .views import ConversationListCreateView, MessageListCreateView

urlpatterns = [
    path("conversations/", ConversationListCreateView.as_view(), name="conversations"),
    path(
        "conversations/<int:pk>/messages/",
        MessageListCreateView.as_view(),
        name="conversation-messages",
    ),
]
