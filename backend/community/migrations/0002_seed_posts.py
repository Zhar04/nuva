from django.db import migrations

SEED = [
    {
        "author_alias": "Тихий ветер #101",
        "text": "Кажется, я снова не сплю четвёртую ночь подряд. Голова не отключается, "
                "прокручиваю один и тот же разговор. Кто-нибудь, расскажите, как вы из этого выходите.",
        "tags": ["Тревога"],
        "likes_count": 28,
        "is_supported": False,
    },
    {
        "author_alias": "Утренний свет #102",
        "text": "Сегодня впервые за месяц встала с кровати в 8 утра, заварила чай, открыла окно. "
                "Это так мало, но мне важно это записать.",
        "tags": ["Поддержка", "Самооценка"],
        "likes_count": 142,
        "is_supported": True,
    },
    {
        "author_alias": "Северное озеро #103",
        "text": "Я тут, если кому-то нужно просто чтобы выслушали. Без советов, без обесценивания. Пишите.",
        "tags": ["Я слушаю"],
        "likes_count": 89,
        "is_supported": False,
    },
    {
        "author_alias": "Лесной ручей #104",
        "text": "Мы расстались месяц назад, и я всё ещё ловлю себя на том, что хочу написать. "
                "Не пишу. Но каждый раз больно по-новому.",
        "tags": ["Отношения"],
        "likes_count": 64,
        "is_supported": False,
    },
    {
        "author_alias": "Песчаный берег #105",
        "text": "Маленький лайфхак: когда тревога нарастает — холодная вода на запястья, 30 секунд. "
                "Не отключает, но даёт паузу.",
        "tags": ["Тревога", "Поддержка"],
        "likes_count": 211,
        "is_supported": True,
    },
]


def seed(apps, schema_editor):
    Post = apps.get_model("community", "Post")
    for row in SEED:
        Post.objects.create(**row)


def unseed(apps, schema_editor):
    Post = apps.get_model("community", "Post")
    Post.objects.filter(author_alias__in=[r["author_alias"] for r in SEED]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("community", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed, unseed),
    ]
