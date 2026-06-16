"""Idempotent demo seeder for testing the psychologist cabinet end-to-end.

Run:  .venv\\Scripts\\python.exe manage.py shell -c "exec(open('seed_demo.py', encoding='utf-8').read())"

Creates a verified demo psychologist and a few clients with real booking
requests / sessions so every cabinet screen (Запросы, Расписание, карточка
клиента, Доходы) has live data. Safe to re-run — it resets the demo rows.

Logins (all password: Demo12345):
  demo.psy@nuva.kz      — psychologist (cabinet)
  demo.client1@nuva.kz  — client (Алия)
  demo.client2@nuva.kz  — client (Тимур)
"""
from datetime import timedelta

from django.utils import timezone
from django.contrib.auth import get_user_model

from catalog.models import Education, Specialist
from booking.models import Booking, ClientNote
from journal.models import MoodEntry

U = get_user_model()
PW = "Demo12345"


def user(email, name, role=U.Role.SEEKER):
    u, _ = U.objects.get_or_create(email=email, defaults={"name": name, "role": role})
    u.name = name
    u.role = role
    u.set_password(PW)
    u.save()
    return u


psy = user("demo.psy@nuva.kz", "Айдана Демо", U.Role.PSYCHOLOGIST)
c1 = user("demo.client1@nuva.kz", "Алия")
c2 = user("demo.client2@nuva.kz", "Тимур")

sp, _ = Specialist.objects.get_or_create(owner=psy)
sp.first_name = "Айдана"
sp.last_name = "Демо"
sp.title = "Клинический психолог · КПТ"
sp.years_experience = 8
sp.session_price_kzt = 18000
sp.rating = 4.9
sp.review_count = 57
sp.about = (
    "Помогаю взрослым справляться с тревогой, выгоранием и трудностями в "
    "отношениях. Работаю в когнитивно-поведенческом подходе, бережно и без "
    "оценок. Первая ознакомительная сессия — бесплатно."
)
sp.approaches = ["КПТ", "Схема-терапия", "ACT"]
sp.works_with = ["Тревога", "Отношения", "Выгорание", "Самооценка"]
sp.languages = ["Қазақша", "Русский", "English"]
sp.diplomas = ["Магистр КазНУ", "CBT Beck Institute", "ACT ACBS"]
sp.availability = {
    "1": ["10:00", "11:00", "18:00"],
    "3": ["12:00", "13:00", "19:00"],
    "5": ["10:00", "16:00", "17:00"],
}
sp.is_verified = True
sp.is_active = True
sp.save()

Education.objects.filter(specialist=sp).delete()
Education.objects.bulk_create([
    Education(specialist=sp, institution="КазНУ им. аль-Фараби",
              degree="Магистр психологии", years="2013–2015"),
    Education(specialist=sp, institution="Beck Institute for CBT",
              degree="Сертификация по КПТ", years="2018"),
])

# Reset demo bookings so re-running doesn't pile up.
Booking.objects.filter(specialist=sp, user__in=[c1, c2]).delete()
now = timezone.now()


def book(u, days, hour, status, **kw):
    return Booking.objects.create(
        user=u, specialist=sp,
        starts_at=(now + timedelta(days=days)).replace(
            hour=hour, minute=0, second=0, microsecond=0),
        **kw, status=status,
    )


# Two pending REQUESTS (appear in Запросы):
book(c1, 2, 11, Booking.Status.REQUESTED, intent="intro", is_intro=True,
     price_kzt=0, concern="Тревога", match_score=94,
     client_message="Давно откладываю, хочу попробовать познакомиться.")
book(c2, 3, 19, Booking.Status.REQUESTED, intent="package", is_intro=False,
     price_kzt=18000, concern="Выгорание", match_score=81,
     client_message="Выгорел на работе, нужна системная работа.")
# One confirmed-scheduled (appears in Расписание) + one awaiting payment:
book(c1, 1, 18, Booking.Status.SCHEDULED, intent="intro", is_intro=True,
     price_kzt=0, concern="Тревога", match_score=94)
book(c2, 4, 12, Booking.Status.PENDING, intent="package", is_intro=False,
     price_kzt=18000, concern="Выгорание", match_score=81)
# Past PAID sessions (Доходы + client history):
for d in (-7, -14, -21):
    book(c1, d, 11, Booking.Status.PAID, intent="package", is_intro=False,
         price_kzt=18000, concern="Тревога", match_score=94)
# Past intro freebies (free-session counter):
for d in (-3, -10):
    book(c2, d, 16, Booking.Status.COMPLETED, intent="intro", is_intro=True,
         price_kzt=0, concern="Выгорание", match_score=81)

# A private note + mood history for the client card.
ClientNote.objects.update_or_create(
    specialist=sp, client=c1,
    defaults={"text": "Запрос — тревога перед публичными выступлениями. "
                      "Хорошо отзывается на дыхательные техники."},
)
MoodEntry.objects.filter(user=c1).delete()
for i, m in enumerate([2, 2, 3, 3, 4, 3, 4, 5]):
    MoodEntry.objects.create(
        user=c1, day=(now - timedelta(days=8 - i)).date(), mood=m)

print("Seeded demo psychologist + clients.")
print("Login psychologist: demo.psy@nuva.kz / Demo12345")
print("Login client:       demo.client1@nuva.kz / Demo12345")
print("Requests:", Booking.objects.filter(specialist=sp, status="requested").count())
print("Scheduled:", Booking.objects.filter(specialist=sp, status="scheduled").count())
print("Paid:", Booking.objects.filter(specialist=sp, status="paid").count())
