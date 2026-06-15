from django.contrib import admin

from .models import Conversation, Message


class MessageInline(admin.TabularInline):
    model = Message
    extra = 1
    fields = ("sender", "text", "is_read", "created_at")
    readonly_fields = ("created_at",)


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "specialist", "updated_at")
    list_filter = ("specialist",)
    search_fields = ("user__email", "specialist__first_name", "specialist__last_name")
    date_hierarchy = "updated_at"
    inlines = [MessageInline]


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ("id", "conversation", "sender", "short_text", "is_read", "created_at")
    list_filter = ("sender", "is_read")
    search_fields = ("text",)
    date_hierarchy = "created_at"

    @admin.display(description="Текст")
    def short_text(self, obj):
        return obj.text[:60]
