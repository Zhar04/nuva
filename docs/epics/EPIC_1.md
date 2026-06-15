# Epic 1 — Liquid Glass UI polish

Covers user requests **1, 2, 4, 5**. Each design point lists **3 concepts**; I build
the **★ recommended** one. You pick the final later — I swap if you prefer another.

Savepoint to roll back to before this epic: `git reset --hard savepoint/epic-0-baseline`.

---

## Point 1 — Mood selector redesign (Грустно–Хорошо)
Current: raw emoji (😔😟😐🙂😊) + labels in a flat card.

- **Concept A ★ "Gradient mood orbs"** — each mood = a soft gradient circle with a clean Material line-face icon (sentiment_very_dissatisfied → very_satisfied) in white; color runs along a gentle spectrum (indigo→amber→slate→teal→green). Selected orb scales up + glows in its colour; label brightens. On-brand (gradients + glass), no childish emoji.
- **Concept B "Glass segmented faces"** — one glass pill holding 5 line-faces; an animated indicator slides under the active face which fills with gradient. Very compact/iOS.
- **Concept C "Mood slider"** — a red→green gradient track with a draggable glass thumb; face + label morph as you slide. Most novel, fiddliest to use.

**Build: A.** Rationale: warmest + clearest for a mental-health context, matches the gradient/glass language, and each mood gets a meaningful colour without alarming reds.
Test: orbs render; tap selects + animates + glows; `saveMood(i+1)` still fires; labels localized.

## Point 2 — Glassier, more clickable cards
Current dark glass = 20% white fill → reads as flat grey ("not clickable").

- **Concept A ★ "Frosted sheen + tinted shadow"** — add a top glossy highlight (white gradient fading over the top third), brighten the rim, and replace the flat dark drop-shadow with a soft **blue-tinted** shadow so elevated cards visibly float/refract above the backdrop. Subtle press feedback.
- **Concept B "Gradient-tinted glass"** — faint blue→teal tint wash across each card + brighter border.
- **Concept C "Layered depth"** — stronger blur + double (ambient+key) shadow + inner glow ring; bolder press scale.

**Build: A.** Rationale: directly fixes "too grey / not clickable" — the sheen + coloured lift make cards read as tappable glass. Applied only to `elevated` GlassCards so non-elevated surfaces stay calm.
Test: home cards show top sheen + blue lift shadow; text still legible; non-elevated cards unchanged; light + dark both fine.

## Point 4 — Pull-to-refresh + no dead space
Current: lists/scrollers have bottom padding and no refresh; scrolling to the end shows empty space.

- **Concept A ★ "RefreshIndicator + fill"** — wrap Home / Specialists / Community scrollers in a themed `RefreshIndicator` (pull down → re-fetch from Supabase, invalidating providers); force `AlwaysScrollableScrollPhysics` so pull works even when short; bottom padding sized to clear the floating navbar (no dead gap).
- **Concept B "Custom glass refresh header"** — a bespoke stretchy glass header with a breathing logo while refreshing.
- **Concept C "Infinite + skeletons"** — pull-to-refresh plus shimmer skeletons while loading.

**Build: A.** Rationale: native feel, minimal risk, immediately satisfies "scroll to refresh"; B/C are polish on top later.
Test: pull down on Home/Specialists/Community triggers a spinner + re-fetch; works even when content is short; bottom content clears the navbar.

## Point 5 — Floating bottom navbar (App Store / iOS-26 style, Screenshot 2)
Current: full-width bar glued to the bottom edge.

- **Concept A "Floating glass capsule"** — rounded glass capsule floating off the bottom/sides; active icon sits in a gradient pill; content scrolls behind.
- **Concept B ★ "Floating capsule + expanding active label"** — like the App Store screenshot: floating glass capsule where the **active** tab expands into a gradient pill showing icon **+ label**, inactive tabs are icon-only; animated width morph.
- **Concept C "Floating + center action"** — floating bar with a raised center button (AI-match / compose).

**Build: B.** Rationale: matches your Screenshot 2 reference most closely and feels iOS-26 Liquid Glass; the expanding-label pill makes the active tab obvious.
Test: bar floats with margins + blur + shadow; tapping morphs the active pill (icon+label) smoothly; all 5 tabs switch; content isn't clipped behind it; safe-area respected.

---

## Test plan (run after implementing)
1. `flutter analyze` → 0 errors.
2. Rebuild web (`flutter run -d chrome --web-port 8088`); app serves HTTP 200.
3. Manual smoke: Home (orbs + glassy cards + pull-refresh), navbar morph across all tabs, Specialists/Community pull-refresh.
4. Add a widget smoke test if feasible (`flutter test`).

## Done / notes (implemented)
- **Point 1 (mood orbs)** — `lib/screens/home_screen.dart` `_MoodRow`: replaced emoji with 46px gradient circles + white Material sentiment faces (indigo→amber→slate→teal→green). Selected orb scales to 1.0 (others 0.9), brighter rim, colored glow; label brightens. `saveMood(i+1)` preserved.
- **Point 2 (glassier cards)** — `lib/widgets/glass.dart` `GlassCard`: elevated cards now get a top sheen gradient (`foregroundDecoration`), a brighter rim, and a soft **blue-tinted** lift shadow on top of `glassShine`. Non-elevated cards unchanged. Applies app-wide via the shared widget.
- **Point 4 (pull-to-refresh)** — `RefreshIndicator` (themed blue) added to Home (`SingleChildScrollView`), Specialists & Community (`ListView`), all with `AlwaysScrollableScrollPhysics` so pull works when short. onRefresh invalidates + awaits the relevant provider (specialists / community feed). Bottom paddings bumped (120–130) to clear the floating navbar. _Decision: standard top pull-to-refresh (conventional); ask if you want bottom-triggered refresh instead._
- **Point 5 (floating navbar)** — `lib/screens/main_shell.dart`: `Scaffold(extendBody)` + `Stack` with a `_FloatingNavBar` — a frosted glass capsule (BackdropFilter blur, translucent surface, rim, dark+blue shadows) floating 16px off the sides and above the safe area. Active tab is an animated gradient pill showing icon **+ label**; inactive tabs icon-only. Community FAB raised 78px to sit above the bar.
- **Verify:** `flutter analyze` → 0 errors (15 pre-existing warnings/infos, none new). Web build serves 200.
- **Rollback:** `git reset --hard savepoint/epic-0-baseline`. This epic's savepoint: `savepoint/epic-1`.
- **Post-epic upgrade (navbar → Concept D "Liquid-Morph", user-approved):** replaced the expanding-pill bar with `_LiquidNavBar` in `main_shell.dart` — a single frosted-glass blob that **slides + stretches** between tabs with spring physics (gooey overshoot), icons/labels brighten + scale on arrival, specular top edge. Pure Flutter (works on web/Android/iOS). The truly-native iOS-26 look (`CNTabBar` from `cupertino_native`) is Apple-platform-only, so it's noted as a future iOS-only adaptive option.

