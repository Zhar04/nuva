from django.contrib import admin

from .models import Booking, ClientNote


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = (
        "id", "user", "specialist", "starts_at", "format",
        "status", "intent", "is_intro", "price_kzt", "created_at",
    )
    list_display_links = ("id", "user")
    list_filter = ("status", "format", "intent", "is_intro", "starts_at")
    search_fields = (
        "user__email", "specialist__first_name", "specialist__last_name",
        "concern",
    )
    list_editable = ("status",)
    date_hierarchy = "starts_at"


@admin.register(ClientNote)
class ClientNoteAdmin(admin.ModelAdmin):
    list_display = ("id", "specialist", "client", "updated_at")
    search_fields = ("specialist__first_name", "client__email", "text")
    raw_id_fields = ("specialist", "client")
