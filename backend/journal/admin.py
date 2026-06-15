from django.contrib import admin

from .models import MoodEntry


@admin.register(MoodEntry)
class MoodEntryAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "day", "mood", "short_note")
    list_filter = ("mood",)
    search_fields = ("user__email", "note")
    date_hierarchy = "day"

    @admin.display(description="Заметка")
    def short_note(self, obj):
        return obj.note[:60]
