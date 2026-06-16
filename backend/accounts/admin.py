from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .forms import UserCreateForm, UserUpdateForm
from .models import ProDocument, User


@admin.register(ProDocument)
class ProDocumentAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "title", "content_type", "created_at")
    search_fields = ("user__email", "title")
    date_hierarchy = "created_at"


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    add_form = UserCreateForm
    form = UserUpdateForm
    model = User

    ordering = ("-created_at",)
    list_display = ("email", "name", "role", "is_staff", "is_active", "created_at")
    list_filter = ("role", "is_staff", "is_active")
    search_fields = ("email", "name")
    readonly_fields = ("created_at", "updated_at", "last_login")

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Профиль", {"fields": ("name", "role", "age", "gender", "mbti", "bio")}),
        ("Права", {
            "fields": (
                "is_active", "is_staff", "is_superuser",
                "groups", "user_permissions",
            )
        }),
        ("Даты", {"fields": ("last_login", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": (
                "email", "name", "role",
                "password1", "password2",
                "is_staff", "is_superuser",
            ),
        }),
    )
