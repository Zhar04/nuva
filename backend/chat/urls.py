from django.urls import path

from .views import CallView, ConversationListCreateView, MessageListCreateView

urlpatterns = [
    path("conversations/", ConversationListCreateView.as_view(), name="conversations"),
    path(
        "conversations/<int:pk>/messages/",
        MessageListCreateView.as_view(),
        name="conversation-messages",
    ),
    path("conversations/<int:pk>/call/", CallView.as_view(), name="conversation-call"),
]
