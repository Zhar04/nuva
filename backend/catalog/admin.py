from django.contrib import admin

from .models import Education, Favorite, Review, Specialist


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ("user", "specialist", "created_at")
    raw_id_fields = ("user", "specialist")


class EducationInline(admin.TabularInline):
    model = Education
    extra = 1


class ReviewInline(admin.TabularInline):
    model = Review
    extra = 0


@admin.register(Specialist)
class SpecialistAdmin(admin.ModelAdmin):
    list_display = (
        "first_name", "last_name", "title", "session_price_kzt",
        "rating", "review_count", "is_verified", "is_active", "accepts_instant",
    )
    list_filter = ("is_verified", "is_active", "accepts_instant")
    search_fields = ("first_name", "last_name", "title")
    inlines = [EducationInline, ReviewInline]
    fieldsets = (
        (None, {"fields": ("first_name", "last_name", "title", "about")}),
        ("Профиль", {"fields": (
            "years_experience", "languages", "approaches", "works_with",
            "session_price_kzt", "avatar_gradient", "whatsapp",
        )}),
        ("Статус", {"fields": (
            "rating", "review_count", "is_verified", "is_active",
            "accepts_instant", "instant_until",
        )}),
    )


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ("specialist", "author_alias", "rating", "created_at")
    list_filter = ("rating",)
    search_fields = ("author_alias", "text")
