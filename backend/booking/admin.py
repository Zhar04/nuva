from django.contrib import admin

from .models import Booking


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = (
        "id", "user", "specialist", "starts_at", "format",
        "status", "price_kzt", "created_at",
    )
    list_display_links = ("id", "user")
    list_filter = ("status", "format", "starts_at")
    search_fields = (
        "user__email", "specialist__first_name", "specialist__last_name",
    )
    list_editable = ("status",)
    date_hierarchy = "starts_at"
