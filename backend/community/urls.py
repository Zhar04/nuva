from django.urls import path

from .views import (
    PostDetailView,
    PostLikeView,
    PostListCreateView,
    ReplyListCreateView,
)

urlpatterns = [
    path("posts/", PostListCreateView.as_view(), name="posts"),
    path("posts/<int:pk>/", PostDetailView.as_view(), name="post-detail"),
    path("posts/<int:pk>/like/", PostLikeView.as_view(), name="post-like"),
    path("posts/<int:pk>/replies/", ReplyListCreateView.as_view(), name="post-replies"),
]
