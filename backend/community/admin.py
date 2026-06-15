from django.contrib import admin

from .models import Post, PostLike, Reply


class ReplyInline(admin.TabularInline):
    model = Reply
    extra = 1
    fields = ("author_alias", "text", "from_specialist", "likes_count", "created_at")
    readonly_fields = ("created_at",)


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = (
        "id", "author_alias", "short_text", "likes_count",
        "is_supported", "is_visible", "created_at",
    )
    list_editable = ("is_supported", "is_visible")
    list_filter = ("is_supported", "is_visible")
    search_fields = ("author_alias", "text")
    date_hierarchy = "created_at"
    inlines = [ReplyInline]

    @admin.display(description="Текст")
    def short_text(self, obj):
        return obj.text[:60]


@admin.register(Reply)
class ReplyAdmin(admin.ModelAdmin):
    list_display = ("id", "post", "author_alias", "from_specialist", "created_at")
    list_filter = ("from_specialist",)
    search_fields = ("text", "author_alias")


@admin.register(PostLike)
class PostLikeAdmin(admin.ModelAdmin):
    list_display = ("id", "post", "user", "created_at")
