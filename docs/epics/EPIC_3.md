# Epic 3 — Identity & engagement (UI/flow prototype)

Covers user requests **8, 9, 10**. Per locked decision: **UI/flow prototype** — local
state (Riverpod + `shared_preferences`), diploma upload **stubbed**, new Supabase
tables **documented here** (not built tonight). Design points get 3 concepts; build ★.
Rollback before this epic: `git reset --hard savepoint/epic-2`.

---

## Point 10 — Role-based registration + onboarding pipelines
Entry flow becomes: Onboarding slides → **Role select** → role-specific onboarding → app.

**Kind name for the user role (3 options):**
- **A ★** User = "Ищу поддержку" · Specialist = "Я психолог"
- **B** User = "Мне нужна помощь" · Specialist = "Я специалист"
- **C** User = "Хочу разобраться в себе" · Specialist = "Я психолог"
Build **A** (warm, clear, non-clinical).

**Onboarding pipeline (data collected):**
- **User (`Ищу поддержку`):** avatar (stub "добавить фото"), имя, возраст, пол, MBTI (16-type dropdown + note "Не уверены? Пройдите тест 16Personalities в разделе профиля"), then **4–5 calm intro questions** (gentle, single-select: что привело · как часто · формат · опыт терапии · срочность) → hand off to the AI module (`/intake`, which has the `/skip`). 
- **Psychologist (`Я психолог`):** **skips the AI module entirely.** Collects: фото (required, stub), имя, направления/экспертиза (multi-select), документы — диплом + сертификаты (**upload stubbed**: shows file rows "Загрузить PDF/PNG" → marked "прикреплено" mock), опыт (лет), опционально трудовая книжка (stub) → review → done → `/home`.

Flow structure concepts:
- **A ★ stepper** — a progress dots header + Next/Back, one question per screen. Calm, focused.
- **B single long form** — everything on one scroll. Faster but heavier.
- **C chat-like** — questions as a guided chat. Nice but more build.
Build **A** (stepper) for both pipelines.

New Supabase (follow-up, documented only): `profiles` add `role`, `full_name`, `age`, `gender`, `mbti`, `bio`, `avatar_url`; new `specialist_applications` (docs, expertise, status); a Storage bucket `documents` (private, RLS owner-only) for diploma PDFs/PNGs.

## Point 8 — Working profile + editing
Currently most profile menu items are dead (`onTap: () {}`).

- **A ★** every item opens a real (if simple) screen: **Мои сессии** (bookings/mock list), **Дневник настроения** (mood history + quick add), **Избранные** (saved specialists), **Уведомления** (toggles), **Помощь** (contacts/FAQ), **account settings → Profile edit** (avatar stub, имя, bio, MBTI, пол/возраст) persisted via `shared_preferences`.
- **B** lightweight bottom-sheets instead of full screens.
- **C** only the edit screen + journal; rest show "скоро".
Build **A**.

## Point 9 — Gamification (points, achievements, course progress)
- **A ★** a "rating" card on the profile: level + points (with **monthly reset** date), a horizontal **achievements** row (psychologist-awarded badges, IronMan-style, locked/unlocked), and an active **course progress** bar with a **"Поделиться"** (Strava-like) stub.
- **B** a separate dedicated "Прогресс" screen.
- **C** just a points pill in the header.
Build **A** (card on profile) + tapping opens a fuller progress screen. Local mock provider; points/achievements not yet server-driven (documented).

---

## Test plan
1. `flutter analyze` → 0 errors.
2. Rebuild web; serves 200.
3. Smoke: role-select reachable; user & specialist steppers complete; profile items all open; profile edit persists name/bio/MBTI; gamification card renders.

## Done / notes (implemented)
**New files:** `models/user_profile.dart` (role + name/age/gender/mbti/bio, shared_prefs-persisted via `userProfileProvider`), `models/gamification.dart` (`gamificationProvider` mock), `widgets/onboarding_kit.dart` (StepDots, SingleSelect, OnboardField, AvatarPickerStub), `screens/role_select_screen.dart`, `screens/onboarding_user_screen.dart`, `screens/onboarding_specialist_screen.dart`, `screens/profile_edit_screen.dart`, `screens/profile_subscreens.dart` (Sessions/Journal/Favorites/Notifications/Help), `screens/progress_screen.dart` (`GamificationCard` + `ProgressScreen`).

- **Point 10 (roles + onboarding)** — Onboarding slides now route to **`/role`** (RoleSelectScreen: "Ищу поддержку" / "Я психолог"). **User** stepper: basics (avatar stub, name, age, gender) → MBTI (16 chips + 16Personalities note) → 4 calm single-select questions → saves profile → `/intake` (AI, with `/skip`). **Psychologist** stepper: photo (stub) + basics → expertise multi-select → documents (diploma/cert/work-record **upload stubbed** — tap toggles "Прикреплено") → review → submit-for-moderation toast → `/home` (AI module skipped entirely).
- **Point 8 (profile)** — All previously-dead profile items now open real screens (Мои сессии, Дневник настроения, Избранные, Уведомления, Помощь, + "Редактировать профиль"). Profile **edit** screen (avatar stub, name, bio, MBTI, gender, age) persists via shared_preferences; header now shows the saved name + role and taps through to edit.
- **Point 9 (gamification)** — `GamificationCard` on the profile (level, points, monthly-reset note, level progress bar, achievement badges) → taps to `ProgressScreen` (level hero, achievements grid with locked/unlocked, course progress bar + "Поделиться" stub). Local mock provider.
- **Routes added** (`app_router.dart`): `/role`, `/onboarding/user`, `/onboarding/specialist`, `/profile/edit`, `/sessions`, `/journal`, `/favorites`, `/notifications`, `/help`, `/progress`.
- **Verify:** `flutter analyze` → 0 errors. Web build serves 200.
- **Follow-up (documented, not built):** Supabase `profiles` columns (role/full_name/age/gender/mbti/bio/avatar_url), `specialist_applications` table, Storage bucket `documents` (RLS owner-only) for real diploma uploads; trilingual strings for new screens (currently RU, matching existing hardcoded RU).
- **Rollback:** `git reset --hard savepoint/epic-2`. This epic's savepoint: `savepoint/epic-3`.

> Note: the role-select/registration appears for **new** users (after the 3 onboarding slides). If `onboarded` is already set from earlier testing, the app opens at `/home`; visit `/role` directly (or clear app data) to see the registration flow.

