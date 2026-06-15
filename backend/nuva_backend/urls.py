"""Root URL configuration for the Nuva backend."""

from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path


def healthz(_request):
    return JsonResponse({"status": "ok", "service": "nuva-backend"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("healthz", healthz),
    path("api/v1/auth/", include("accounts.urls")),
    path("api/v1/specialists/", include("catalog.urls")),
    path("api/v1/bookings/", include("booking.urls")),
]

# Branding for the admin (your "админка").
admin.site.site_header = "Nuva — администрирование"
admin.site.site_title = "Nuva Admin"
admin.site.index_title = "Управление данными"
