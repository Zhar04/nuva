from django.db import migrations

SPECIALISTS = [
    {
        "first_name": "Айгуль", "last_name": "С.", "title": "Клинический психолог",
        "years_experience": 9,
        "languages": ["Қазақша", "Русский", "English"],
        "approaches": ["КПТ", "Схема-терапия"],
        "works_with": ["Тревога", "Самооценка", "Отношения"],
        "session_price_kzt": 18000, "rating": "4.9", "review_count": 142,
        "about": "Помогаю взрослым справиться с тревожностью и стрессом. Работаю в когнитивно-поведенческом подходе.",
        "avatar_gradient": ["#FFB6C1", "#FFC8DD"], "is_verified": True,
        "education": [
            ("КазНУ им. аль-Фараби", "Магистр психологии", "2012–2014"),
            ("Beck Institute for CBT", "Сертификация по КПТ", "2017"),
        ],
        "reviews": [
            ("Анонимно · 24 года", 5, "После 4 сессий стало гораздо легче засыпать. Айгуль аккуратно работает с тревогой."),
            ("Анонимно · 31 год", 5, "Очень внимательная. Помогла разобраться с отношениями в семье."),
        ],
    },
    {
        "first_name": "Арман", "last_name": "Б.", "title": "Психотерапевт",
        "years_experience": 12,
        "languages": ["Русский", "Қазақша"],
        "approaches": ["Гештальт", "EMDR"],
        "works_with": ["Травма", "ПТСР", "Утрата"],
        "session_price_kzt": 22000, "rating": "4.8", "review_count": 98,
        "about": "Специализируюсь на работе с травматическим опытом и переживанием утраты. EMDR-сертифицированный специалист.",
        "avatar_gradient": ["#7FB7E8", "#A3D8F4"], "is_verified": True,
        "education": [
            ("МГУ им. Ломоносова", "Клиническая психология", "2008–2013"),
            ("EMDR Europe", "Базовый и продвинутый курс EMDR", "2018–2020"),
        ],
        "reviews": [
            ("Анонимно · 36 лет", 5, "Помог пережить потерю близкого. Без EMDR я бы ещё долго не справился."),
        ],
    },
    {
        "first_name": "Дана", "last_name": "К.", "title": "Семейный психолог",
        "years_experience": 7,
        "languages": ["Русский", "English"],
        "approaches": ["Системная терапия"],
        "works_with": ["Семья", "Пары", "Развод"],
        "session_price_kzt": 20000, "rating": "4.9", "review_count": 167,
        "about": "Работаю с парами и семьями. Помогаю восстановить контакт, наладить общение, пройти через кризисы.",
        "avatar_gradient": ["#D4B5F0", "#E8D4F5"], "is_verified": True,
        "education": [("КазГУ", "Семейная психология", "2013–2017")],
        "reviews": [
            ("Анонимно · пара", 5, "Дана спасла наш брак. 6 сессий — и мы научились разговаривать."),
        ],
    },
    {
        "first_name": "Нурлан", "last_name": "Ж.", "title": "Психолог · подростки",
        "years_experience": 6,
        "languages": ["Қазақша", "Русский"],
        "approaches": ["КПТ", "Игровая терапия"],
        "works_with": ["Подростки", "Школа", "Родители"],
        "session_price_kzt": 15000, "rating": "4.7", "review_count": 81,
        "about": "Работаю с подростками 12–18 лет и их родителями. Школьная тревога, конфликты, самооценка.",
        "avatar_gradient": ["#93D8B5", "#B7E8CC"], "is_verified": True,
        "education": [("КазНПУ", "Детская и подростковая психология", "2014–2018")],
        "reviews": [
            ("Анонимно · мама", 5, "Дочь ходит сама с удовольствием. Школьная тревога ушла."),
        ],
    },
    {
        "first_name": "Камила", "last_name": "И.", "title": "Психолог · карьера",
        "years_experience": 5,
        "languages": ["Русский", "English"],
        "approaches": ["КПТ", "ACT"],
        "works_with": ["Тревога", "Прокрастинация", "Выгорание"],
        "session_price_kzt": 16000, "rating": "4.8", "review_count": 64,
        "about": "Помогаю взрослым справиться с выгоранием, тревожностью и трудностями в карьере.",
        "avatar_gradient": ["#7FE0D4", "#B0EDE5"], "is_verified": True,
        "education": [("НИУ ВШЭ", "Психология личности", "2015–2019")],
        "reviews": [
            ("Анонимно · СТО", 5, "Помогла выйти из выгорания за 8 сессий. Конкретные техники, никакой воды."),
        ],
    },
]


def seed(apps, schema_editor):
    Specialist = apps.get_model("catalog", "Specialist")
    Education = apps.get_model("catalog", "Education")
    Review = apps.get_model("catalog", "Review")
    if Specialist.objects.exists():
        return
    for s in SPECIALISTS:
        sp = Specialist.objects.create(
            first_name=s["first_name"], last_name=s["last_name"], title=s["title"],
            years_experience=s["years_experience"], languages=s["languages"],
            approaches=s["approaches"], works_with=s["works_with"],
            session_price_kzt=s["session_price_kzt"], rating=s["rating"],
            review_count=s["review_count"], about=s["about"],
            avatar_gradient=s["avatar_gradient"], is_verified=s["is_verified"],
        )
        for inst, deg, yrs in s["education"]:
            Education.objects.create(
                specialist=sp, institution=inst, degree=deg, years=yrs
            )
        for alias, rating, text in s["reviews"]:
            Review.objects.create(
                specialist=sp, author_alias=alias, rating=rating, text=text
            )


def unseed(apps, schema_editor):
    apps.get_model("catalog", "Specialist").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [("catalog", "0001_initial")]
    operations = [migrations.RunPython(seed, unseed)]
