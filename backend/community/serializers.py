from rest_framework import serializers

from .models import Post, Reply


class ReplySerializer(serializers.ModelSerializer):
    liked = serializers.SerializerMethodField()

    class Meta:
        model = Reply
        fields = (
            "id", "author_alias", "text", "from_specialist",
            "likes_count", "liked", "created_at",
        )
        read_only_fields = fields

    def get_liked(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        return obj.likes.filter(user=user).exists()


class PostSerializer(serializers.ModelSerializer):
    replies_count = serializers.IntegerField(
        source="replies.count", read_only=True
    )
    liked = serializers.SerializerMethodField()
    top_reply = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = (
            "id", "author_alias", "text", "tags", "likes_count",
            "replies_count", "is_supported", "liked", "top_reply", "created_at",
        )
        read_only_fields = (
            "id", "author_alias", "likes_count", "replies_count",
            "is_supported", "liked", "top_reply", "created_at",
        )

    def get_liked(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        return obj.likes.filter(user=user).exists()

    def get_top_reply(self, obj):
        # Most recent reply, used for the threaded preview in the feed.
        reply = obj.replies.order_by("-created_at").first()
        if reply is None:
            return None
        return {
            "author_alias": reply.author_alias,
            "text": reply.text,
            "from_specialist": reply.from_specialist,
        }
