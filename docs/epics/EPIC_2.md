# Epic 2 — Content & wording

Covers user requests **3, 6, 7**. Design points get **3 concepts**; I build the **★** one.
Rollback before this epic: `git reset --hard savepoint/epic-1`.

---

## Point 3 — Rename "Чат с ИИ" (drop the anxiety-inducing "ИИ")
"ИИ" appears user-facing in 3 spots: `strings.dart` `aiHelp` ("Чат с ИИ", home action), `obTitle2` ("ИИ-помощник на старте", onboarding), `legal_screens.dart` ("• ИИ-подбор специалиста", About).

Naming options (the rename itself is the "3 concepts"):
- **A ★ "Помощь в подборе"** — clear, supportive, zero tech/anxiety; pairs with sub "Найти специалиста".
- **B "Найти своего"** — warm, personal, a touch playful.
- **C "Тёплый старт"** — cozy but vaguer about what it does.

**Build: A** everywhere "ИИ" was user-facing. (`aiHelp` → "Помощь в подборе"; `obTitle2` → "Поможем с подбором"; legal → "Помощь в подборе специалиста".) EN/KK updated too.
Test: home quick-action reads "Помощь в подборе"; onboarding p2 + About have no "ИИ"; grep `ИИ` in `lib/` returns only non-user code (none expected).

## Point 6 — Покой (Calm) redesign (Endel / "Mediatopia: Sleep" vibe)
Current: a hero card + a flat list of 5 practices.

- **A ★ "Immersive scenes + categories"** — a "recommended" gradient hero with play; a horizontal **ambient scenes** rail (Дождь, Лес, Океан, Ночь, Костёр) as tall gradient cards; then category sections (Сон · Снять тревогу · Фокус) with session rows. Endel-style immersion + Mediatopia structure.
- **B "Generative focus (Endel-pure)"** — one big breathing orb to start a soundscape + a Relax/Focus/Sleep switch; minimal.
- **C "Daily ritual"** — guided day plan (утро/день/вечер) + streak.

**Build: A.** Rationale: matches both references, adds depth/scannability, reuses our gradient/glass language; controls are visual stubs (SnackBar "скоро") since audio isn't in scope tonight.
Test: scenes rail scrolls; categories render; hero play taps; nothing overlaps the floating navbar; light+dark OK.

## Point 7 — "Психолог" label in chats
- Community replies already badge psychologists (`fromSpecialist` → "Психолог Nuva") — keep.
- 1:1 chat (`chat_screen.dart`) shows the specialist with name + verified tick but no role label.

- **A ★ "Header role badge"** — a small "Психолог" pill next to the specialist's name in the chat header; regular users (future user↔user chats) get none.
- **B "Per-bubble tag"** — a tiny "Психолог" caption above each specialist bubble. More repetitive.
- **C "Both"** — header badge + first-bubble tag.

**Build: A.** Cleanest, unambiguous, no repetition. New string `psychologist` (RU "Психолог" / KK "Психолог" / EN "Psychologist").
Test: chat header shows "Психолог" badge next to the name; community psychologist replies still badged; user messages unlabeled.

---

## Test plan
1. `flutter analyze` → 0 errors.
2. Rebuild web; serves 200.
3. Smoke: Home action renamed; Покой shows scenes + categories; chat header shows "Психолог"; no "ИИ" left in UI.

## Done / notes (implemented)
- **Point 3 (rename)** — `strings.dart`: `aiHelp` "Чат с ИИ" → **"Помощь в подборе"**; `obTitle2` "ИИ-помощник на старте" → **"Поможем с подбором"** (RU/KK/EN). `legal_screens.dart`: "ИИ-подбор специалиста" → "Помощь в подборе специалиста". `grep ИИ lib/` → **no matches** (UI clean).
- **Point 6 (Покой)** — `main_shell.dart` `_CalmScreen` rebuilt (Concept A): subtitle "Дыши. Замедлись. Восстановись."; enhanced "СЕЙЧАС ДЛЯ ВАС" hero with play + "Начать сейчас"; horizontal **Звуковые сцены** rail (`_SceneCard`: Дождь/Лес/Океан/Ночь/Костёр, gradient + icon + "Ambient"); category sections (Сон · Снять тревогу · Фокус) with `_SessionRow`s. Controls show a floating "скоро" toast (`_soon`) since audio is out of scope. Bottom padding clears the floating navbar.
- **Point 7 (Психолог label)** — `chat_screen.dart` `_Header`: added a blue "Психолог" pill next to the specialist name (+ name made `Flexible`/ellipsis so the badge always fits). New string `psychologist`. Community psychologist replies already badged ("Психолог Nuva") — unchanged.
- **Verify:** `flutter analyze` → 0 errors (15 pre-existing warnings/infos). Web build serves 200.
- **Rollback:** `git reset --hard savepoint/epic-1`. This epic's savepoint: `savepoint/epic-2`.

