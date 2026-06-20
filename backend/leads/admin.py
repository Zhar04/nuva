from django.contrib import admin

from .models import Lead


@admin.register(Lead)
class LeadAdmin(admin.ModelAdmin):
    list_display = ("id", "for_whom", "severity", "language", "user",
                    "linked_at", "created_at")
    list_filter = ("for_whom", "severity", "format", "language", "consent")
    # Contact/answers are special-category — keep them read-only in the admin
    # and don't expose them in list columns or search.
    readonly_fields = ("created_at", "linked_at", "matched_ids")
    date_hierarchy = "created_at"
