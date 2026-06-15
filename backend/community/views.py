from django.db.models import F
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from nuva_backend.moderation import CONTACT_BLOCKED, has_contact

from .models import Post, PostLike, Reply, anon_alias
from .serializers import PostSerializer, ReplySerializer


class PostListCreateView(generics.ListCreateAPIView):
    """GET the anonymous feed (optional ?tag=) / POST a new post."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = PostSerializer

    def get_queryset(self):
        qs = Post.objects.filter(is_visible=True)
        tag = self.request.query_params.get("tag")
        if tag and tag not in ("", "Все"):
            # JSONField __contains isn't supported on SQLite, so filter in
            # Python — the feed is small.
            return [p for p in qs if tag in (p.tags or [])]
        return qs

    def create(self, request, *args, **kwargs):
        text = (request.data.get("text") or "").strip()
        if len(text) < 4:
            raise serializers.ValidationError({"text": "Слишком короткий пост."})
        if has_contact(text):
            raise serializers.ValidationError({"text": CONTACT_BLOCKED})
        tags = request.data.get("tags") or []
        if not isinstance(tags, list):
            tags = []
        post = Post.objects.create(
            author=request.user,
            author_alias=anon_alias(request.user),
            text=text,
            tags=tags,
        )
        return Response(
            self.get_serializer(post).data, status=status.HTTP_201_CREATED
        )


class PostDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PostSerializer
    queryset = Post.objects.filter(is_visible=True)


class PostLikeView(APIView):
    """POST toggles the current user's like on a post."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        post = get_object_or_404(Post, pk=pk, is_visible=True)
        like, created = PostLike.objects.get_or_create(post=post, user=request.user)
        if created:
            Post.objects.filter(pk=post.pk).update(likes_count=F("likes_count") + 1)
            liked = True
        else:
            like.delete()
            # guard against underflow
            Post.objects.filter(pk=post.pk, likes_count__gt=0).update(
                likes_count=F("likes_count") - 1
            )
            liked = False
        post.refresh_from_db(fields=["likes_count"])
        return Response({"liked": liked, "likes_count": post.likes_count})


class ReplyListCreateView(generics.ListCreateAPIView):
    """GET replies for a post / POST a reply."""

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    serializer_class = ReplySerializer

    def _post(self):
        return get_object_or_404(Post, pk=self.kwargs["pk"], is_visible=True)

    def get_queryset(self):
        return self._post().replies.all()

    def create(self, request, *args, **kwargs):
        post = self._post()
        text = (request.data.get("text") or "").strip()
        if not text:
            raise serializers.ValidationError({"text": "Пустой ответ."})
        if has_contact(text):
            raise serializers.ValidationError({"text": CONTACT_BLOCKED})
        reply = Reply.objects.create(
            post=post,
            author=request.user,
            author_alias=anon_alias(request.user),
            text=text,
            from_specialist=getattr(request.user, "role", "") == "psychologist",
        )
        return Response(
            ReplySerializer(reply).data, status=status.HTTP_201_CREATED
        )
