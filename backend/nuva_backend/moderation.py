"""Shared content-moderation helpers.

The on-platform rule: no phone numbers, external links or contact handles in
chat messages, community posts or replies. The Flutter client mirrors this
regex for instant feedback; the server enforces it as the real gate.
"""

import re

CONTACT_RE = re.compile(
    r"(\+?\d[\d\s().\-]{7,}\d)"  # phone numbers
    r"|(https?://)|(www\.)"  # any URL
    r"|(@[\w.]{2,})"  # @handles
    r"|(t\.me|wa\.me|zoom\.us|zoom|meet\.google|g\.co/|instagram|instagr"
    r"|whatsapp|telegram|viber|skype|facebook|fb\.com|vk\.com|youtu"
    r"|телеграм|вотсап|ватсап|инстаграм|вайбер|скайп|вконтакте)",
    re.IGNORECASE,
)

CONTACT_BLOCKED = (
    "Сообщение содержит контакты или внешнюю ссылку. "
    "Общение и звонки — только внутри Nuva."
)


def has_contact(text: str) -> bool:
    return bool(CONTACT_RE.search(text or ""))
