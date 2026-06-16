import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    """Idempotently create/repair the admin superuser from env vars.

    Runs on every deploy (see Procfile / railway.json start command). Reads
    DJANGO_SUPERUSER_EMAIL + DJANGO_SUPERUSER_PASSWORD from the environment so
    the password is never committed. Safe to run repeatedly: it (re)sets the
    password and promotes the account to staff+superuser, which also recovers a
    forgotten admin password without touching the database by hand.
    """

    help = "Create or update the admin superuser from env vars (idempotent)."

    def handle(self, *args, **opts):
        email = (os.environ.get("DJANGO_SUPERUSER_EMAIL") or "").strip()
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD") or ""
        if not email or not password:
            self.stdout.write(
                "ensure_admin: DJANGO_SUPERUSER_EMAIL/PASSWORD not set — skipping."
            )
            return

        User = get_user_model()
        email = User.objects.normalize_email(email)
        user, created = User.objects.get_or_create(
            email=email, defaults={"name": "Admin", "role": User.Role.ADMIN}
        )
        user.is_staff = True
        user.is_superuser = True
        if user.role != User.Role.ADMIN:
            user.role = User.Role.ADMIN
        user.set_password(password)
        user.save()
        self.stdout.write(
            self.style.SUCCESS(
                f"ensure_admin: {'created' if created else 'updated'} superuser {email}"
            )
        )
