# Technical Letter — Security & Code Review

**Project:** Nuva — mental-health support platform (Flutter app + Cloudflare Worker + Supabase)
**Prepared by:** Code & Security Review (Claude Code)
**Date:** 2026-06-15
**Version reviewed:** `nuva_app` 0.1.0+1 (local working tree, no commits)
**Classification:** Internal — contains security findings. Handle accordingly.

---

## 1. Executive summary

Nuva is a well-structured, visually polished Flutter prototype with a clean
separation of UI, design system, localization, and service scaffolding. The
groundwork (Supabase schema with Row-Level Security, a Claude proxy pattern, an
observability seam) shows good instincts.

However, **the application is not ready for production or even a closed beta that
handles real user data or payments.** It is, today, a *mock-first prototype*: the
backend and auth layers are written but not connected to the UI, payment is
simulated, and several of the security-critical pieces that *are* wired (the AI
proxy, the secret-handling model, the privacy policy) contain serious flaws.

Because Nuva processes **special-category personal data** (mental-health
information) and intends to process **card payments** for the Kazakhstan market,
the bar is high: Kazakhstan's *Закон «О персональных данных» №94-V*, PCI-DSS, and
Google Play / App Store data-safety requirements all apply.

**Headline issues (must fix before any real-data launch):**

1. **C1 — Secrets bundled into the client.** `.env` is shipped as a Flutter asset; any key placed in it is extractable from the build.
2. **C2 — The Claude proxy is open to the world.** No authentication, no rate-limiting, and CORS is hardcoded to `*` (the existing allow-list is dead code). Anyone can spend your Anthropic balance.
3. **C3 — No real authentication.** `verifyOtp` returns `true` in mock mode, no login screen exists, and the router has no auth guard — every screen is reachable unauthenticated.
4. **H1 — Card data (PAN + CVV) is collected inside the app.** This puts the whole app in PCI scope; card entry must be delegated to the acquirer.
5. **H2 — The privacy policy promises protections the code does not implement** (encrypted local storage, message encryption, "card data only to the acquirer").

Counts: **3 Critical, 3 High, 6 Medium, 7 Low/Info.**

---

## 2. Scope & method

Reviewed the entire `nuva_app/` Flutter source (`lib/`, `android/`, `web/`,
`pubspec.yaml`, `test/`), the Cloudflare Worker (`server/cloudflare-worker.js`),
the Supabase schema (`supabase/schema.sql`), project docs (`README.md`,
`LAUNCH.md`, `.env.example`), and the root design-showcase artifacts. Method:
manual static reading of all logic-bearing files, data-flow tracing
(client → proxy → Anthropic; client → Supabase), secret-exposure analysis, RLS
policy analysis, and a scan for hardcoded secrets and dangerous patterns.

No secrets were found hardcoded in source (good). No `.env`, `key.properties`, or
keystore exist on disk, and the git repository currently has **zero commits**, so
the `.gitignore` protections for secrets are present but untested.

Severity scale: **Critical** (exploitable now / direct financial or data loss) ·
**High** (serious; exploitable once the feature is live or creates legal exposure)
· **Medium** (should fix before launch) · **Low/Info** (hygiene, hardening,
correctness).

---

## 3. Findings

### CRITICAL

#### C1 — `.env` (and any secret in it) is bundled into the shipped client
- **Where:** `nuva_app/pubspec.yaml` → `flutter: assets: - .env`; consumed in `lib/main.dart` via `dotenv.load`.
- **Detail:** Declaring `.env` as a Flutter asset packages it verbatim into the APK/AAB and the web build. On **web** it is served as a downloadable static asset; on **Android** it is trivially extracted from the unzipped APK — and the build is **not obfuscated** (see M1), making this easier still. `.env.example` even warns that `ANTHROPIC_API_KEY` must not ship in a production APK, but the asset mechanism guarantees it ships if present.
- **Impact:** Any current or future secret in `.env` leaks. The Supabase **anon** key is designed to be public (it's gated by RLS) and is acceptable; a raw `ANTHROPIC_API_KEY`, payment keys, or any service secret is **not**. This also gives a false sense of safety — the proxy design (C2's intent) is bypassed entirely in dev builds.
- **Recommendation:**
  - Never put server secrets in the client. Keep only client-safe values in `.env` (Supabase URL + anon key, the proxy URL).
  - Route **all** privileged calls (Anthropic, payments) through a server you control (the Worker / Supabase Edge Functions). Remove `ANTHROPIC_API_KEY` direct-mode from production builds (compile it out, or gate behind `kDebugMode`).
  - Prefer `--dart-define`/`--dart-define-from-file` over a bundled asset for build-time config, so values aren't sitting in a readable asset file.
  - Treat the Supabase anon key as public and make sure **RLS is the real security boundary** (see M5).

#### C2 — Claude proxy is unauthenticated, unthrottled, and CORS-open
- **Where:** `nuva_app/server/cloudflare-worker.js`.
- **Detail:**
  - `ALLOWED_ORIGINS` is declared (lines 16–19) but **never used**. `cors()` hardcodes `access-control-allow-origin: *` (line 88).
  - There is **no API key / JWT check, no origin enforcement, no rate-limiting, and no per-user quota.**
  - `body.messages` is forwarded to Anthropic with **no size/turn validation**.
  - Upstream errors are echoed to the caller verbatim (`detail: await r.text()`, line 70), leaking internal detail.
- **Impact:** The Worker URL ships inside the app (and is extractable per C1). Once known, **anyone can send unlimited requests billed to your Anthropic account** — a financial denial-of-wallet. The lack of message-size limits amplifies cost per request.
- **Recommendation:**
  - Require a caller credential: verify the Supabase user JWT (`Authorization: Bearer …`) in the Worker, or a shared signed token, before calling Anthropic.
  - Enforce the origin allow-list you already wrote; reflect only allowed origins (and for a native app, prefer token auth over origin since native requests have no trustworthy `Origin`).
  - Add rate-limiting / quotas (Cloudflare Rate Limiting, KV/Durable-Object counters, or `cf` bot controls). Cap `messages` length, per-message size, and total tokens.
  - Stop echoing upstream error bodies; return a generic error + log server-side.

#### C3 — No enforced authentication; OTP verification returns `true` in mock mode
- **Where:** `lib/services/auth_service.dart:27` (`if (c == null) return true;`); `lib/router/app_router.dart` (no `redirect`/guard); `AuthService` is **never called** by any screen (confirmed by grep).
- **Detail:** There is no login/OTP screen anywhere in the app. The router sends users straight from onboarding into the product. Every route — `/payment`, `/chats`, `/profile` — is reachable with no identity. Separately, if the backend is half-configured, `verifyOtp` silently returns success.
- **Impact:** Today (all-mock) this is "by design," but it's a **latent landmine**: the moment real data is wired without first adding auth, the app exposes all features anonymously; and the `return true` default means a misconfigured Supabase connection authenticates everyone.
- **Recommendation:**
  - Add a real phone-OTP auth screen and a `go_router` `redirect` that gates authenticated routes on `AuthService.isSignedIn`.
  - Remove the `return true` mock-success path before any backend integration (fail closed: return `false` when no client).
  - Decide explicitly which features are allowed pre-auth (e.g. anonymous community browse) and enforce the rest behind sign-in.

### HIGH

#### H1 — Raw card data (PAN + CVV) collected in-app → PCI-DSS scope/violation
- **Where:** `lib/screens/payment_screen.dart` — `_CardForm` collects card number, expiry, **CVV** (`obscureText`, but still captured into a `TextEditingController`), and holder name; `_pay()` is a `Future.delayed(1400ms)` that then unconditionally navigates to `/payment-success`.
- **Detail:** Two distinct problems:
  1. **Collecting raw PAN/CVV inside the app** pulls the entire application into PCI-DSS scope and is effectively never permitted. Card entry must happen in the acquirer's hosted field / SDK (CloudPayments widget, Apple/Google Pay token), so raw card data never touches your code.
  2. **The success screen is reached unconditionally** — nothing is charged, yet the user is told they paid, and `bookings.status` is never updated. When wired to a real provider, this *client-trusts-its-own-success* pattern is a textbook **payment-bypass**: status must be set by a server-side webhook from the acquirer, never by the client.
- **Recommendation:**
  - Delete the in-app card form. Integrate CloudPayments/ePay via their SDK or a hosted payment page; use Apple/Google Pay tokens for those rails.
  - Drive booking state from a **server-side payment webhook** (Supabase Edge Function `payments-webhook`) that flips `bookings.status` to `paid` after verifying the provider's signed callback. The client should only *observe* status.
  - Never log or persist PAN/CVV anywhere.

#### H2 — Privacy policy asserts protections the implementation does not provide
- **Where:** `lib/screens/legal_screens.dart` (Privacy) and the chat "secure chat" system message in `lib/models/chat.dart` (m1).
- **Detail:** The policy claims *"зашифрованное локальное хранилище"* (encrypted local storage), *"Все каналы — TLS 1.3, базы шифруются на покое"*, *"Платёжные данные — только провайдеру эквайринга"*, and the chat says *"Сообщения шифруются."* Reality: local persistence is `shared_preferences` (plaintext, not encrypted); there is no app-layer/message encryption (Supabase `messages.text` is plaintext); and the payment screen collects card data in-app (contradicting H1). The text is explicitly a *draft* — which is fine — but **the security claims specifically must match reality** before publication.
- **Impact:** For special-category data under №94-V, publishing a privacy policy whose promises the product breaks is direct legal/regulatory exposure and a likely app-store data-safety rejection.
- **Recommendation:** Either implement the claimed controls (see H3) or rewrite the claims to match what is actually done. Have a lawyer finalize the copy (as LAUNCH.md already notes), and keep the technical claims in sync with the build.

#### H3 — Sensitive data lacks app-layer protection (storage, transport hardening)
- **Where:** cross-cutting — `shared_preferences` for local state; `http`/`supabase_flutter` for transport; `messages`, `mood_entries`, `bookings` tables.
- **Detail:** Therapy chat, mood-journal notes, and booking history are among the most sensitive data a person can share. Supabase gives you TLS-in-transit and encryption-at-rest (good), but there is **no `flutter_secure_storage`**, no app-layer encryption of message/journal content, and **no certificate pinning** on the API calls. There is also no data-retention/erasure mechanism behind the policy's "right to delete."
- **Recommendation (risk-based, decide explicitly):**
  - Move any sensitive local cache/token to `flutter_secure_storage` (Keychain/Keystore).
  - Consider app-layer encryption for the highest-sensitivity fields (journal notes, chat) if your threat model includes the database operator.
  - Add TLS certificate pinning for the proxy/Supabase endpoints.
  - Implement account/data deletion + export to honor the stated rights.

### MEDIUM

#### M1 — Release build is unobfuscated; docs claim the opposite
- **Where:** `android/app/build.gradle` → `minifyEnabled false`, `shrinkResources false` (disabled for a Kotlin 2.2 / R8 metadata incompatibility, per the inline comment). README/LAUNCH claim *"ProGuard + shrinking — APK 22 MB → 9–12 MB."*
- **Impact:** Documentation is inaccurate, and the absence of minification/obfuscation makes reverse-engineering — and extracting the bundled `.env`, the Worker URL, and Supabase config — easier, compounding C1/C2.
- **Recommendation:** Resolve the toolchain issue and re-enable R8 (`minifyEnabled true`, `shrinkResources true`) for release, or document honestly that obfuscation is off. Don't rely on obfuscation as a security control — fix C1/C2 regardless.

#### M2 — Release signing config is machine-specific and will not resolve here
- **Where:** `android/app/build.gradle` (`signingConfigs.release` only populated `if (key.properties exists)`); `key.properties` absent on disk; keystore referenced as `C:\Users\daniko\dev\nuva-keys\nuva-release.jks` in README/LAUNCH (current user is `uzhar`).
- **Impact:** A release build on this machine will fail or silently fall back to an unsigned/debug-signed artifact. Absolute, user-specific paths in docs are a reproducibility hazard.
- **Recommendation:** Document the keystore setup with relative/parameterized paths; store the keystore + `key.properties` securely (not in repo); verify `flutter build appbundle --release` produces a correctly signed AAB before store submission. Consider Play App Signing.

#### M3 — `.env` is a required asset but absent → build break on a clean checkout
- **Where:** `pubspec.yaml` declares `.env` as an asset; the file does not exist by default.
- **Impact:** `flutter build` fails until someone runs `cp .env.example .env`. (Runtime load is already wrapped in try/catch in `main.dart`, but the *asset declaration* is a hard build-time requirement.)
- **Recommendation:** Ship a committed empty/placeholder `.env` (mock-mode), or switch to `--dart-define-from-file` (also helps C1), or document the `cp` step prominently as a required first build step.

#### M4 — Backend/auth layers are written but entirely disconnected
- **Where:** `DbService`, `AuthService` unused by any screen (grep-confirmed); `community_compose_screen.dart` "Publish" calls `Navigator.maybePop()` instead of `publishPost`; chat/bookings never persist.
- **Impact:** Not a vulnerability, but a material **readiness/expectation gap**. README's "90% ready" and several "✅ код" items overstate integration. It also means "RLS protects us" is currently moot — the client never touches the DB — so RLS must be validated *as part of* wiring the backend, not assumed.
- **Recommendation:** Track the mock→backend wiring explicitly; when wiring each feature, enable and test its RLS path end-to-end. Align README readiness claims with reality.

#### M5 — Supabase RLS gaps (effective once the backend is wired)
- **Where:** `supabase/schema.sql`.
- **Details & fixes:**
  - **`messages.sender_id` is spoofable.** The policy checks chat ownership only, not that `sender_id = auth.uid()`. Add `with check (sender_id = auth.uid())` (and to the chat path).
  - **`community_posts.author_alias` / `community_replies.author_alias`** are client-supplied free text and unverified → spoofable display identity.
  - **`likes_count` is author-writable** via `"posts update own"` (no column restriction) → like-count manipulation. Move counters to a server-side RPC/trigger, or restrict updatable columns.
  - **Two-party chat is not modeled.** All chat/message policies tie to `chats.user_id = auth.uid()`, so the *specialist* side can never read/write — the feature can't function as designed once real. Model specialist access explicitly.
  - **`reviews` has no INSERT policy** (with RLS on) → clients can't create reviews. If reviews are server-seeded only, document it; otherwise add a policy.
  - **No moderation/abuse controls** on community, despite the UI claiming every post is checked.
- **Recommendation:** Re-derive policies from a written access-control matrix (who can read/write each table, which columns), add `with check` on every insert/update that carries an identity or counter column, and test each policy with a non-owner token before launch.

#### M6 — Anti-disintermediation is client-only and trivially bypassed
- **Where:** `lib/screens/chat_screen.dart` `_contactRe` — runs only on the client, only against the local mock.
- **Impact:** The Terms (`legal_screens.dart` §6) impose penalties for sharing contacts, but the control is cosmetic: spelled-out digits, images, or a direct DB insert bypass it. If anti-disintermediation is a real business requirement, it needs server-side enforcement.
- **Recommendation:** Enforce on the server (Edge Function / DB trigger scanning message text) when chat goes real; treat the client check as UX hinting only.

### LOW / INFO

- **L1 — Error detail leakage.** `claude_service.dart` throws `Proxy/Claude <status>: <body>`; the Worker echoes upstream errors. Low impact (intake content isn't a credential), but prefer generic client errors + server-side logging. The intake UI already maps to a friendly `aiError`, so raw detail only reaches logs today.
- **L2 — `minSdk` mismatch.** `build.gradle` `minSdk = 23` vs `flutter_launcher_icons.min_sdk_android: 21`. Cosmetic; align them.
- **L3 — Verify `INTERNET` permission in the release manifest.** Only `src/debug/AndroidManifest.xml` declares it; `src/main` does not. The Flutter/plugin manifest merge usually adds it, but confirm the merged release manifest contains `android.permission.INTERNET` (Supabase/http need it) or release networking breaks.
- **L4 — Observability is a print-only stub.** `observability.dart` only `debugPrint`s; `breadcrumb` logs only in debug. No production crash/error telemetry until Sentry is re-enabled (blocked on the Kotlin/R8 issue).
- **L5 — Design showcase loads `@babel/standalone` from CDN at runtime.** `Nuva.html` does in-browser transpilation. Fine for a showcase (SRI hashes are present — good), but never serve this as production.
- **L6 — Dependency pinning.** `pubspec.yaml` has `intl: any` (unpinned). Also `pubspec.lock` is git-ignored; for an *application* the lockfile should be committed for reproducible builds.
- **L7 — Untested secret hygiene.** The repo has no commits and no remote, so `.gitignore`'s protection of `.env`/`key.properties`/`*.jks` is unverified. Before the first push, confirm `git status`/`git add -n` never stages those. The `.gitignore` itself is correct and comprehensive — good.

---

## 4. What's done well

- Clean architecture: clear UI / theme / l10n / model / service separation; consistent `_PascalCase` private-widget pattern.
- The **proxy pattern intent** (keep the Anthropic key server-side) is the right design — it just isn't enforced yet (C2).
- Supabase schema uses RLS from the start and the *owner-only* policies (bookings, chats, mood) are correctly scoped.
- Graceful mock fallback lets the app run with zero config — good for development.
- Crisis-handling is considered (helpline 150 / 112 in the system prompt and legal copy) — appropriate for the domain.
- No hardcoded secrets; comprehensive `.gitignore`; SRI hashes on the showcase CDN scripts.

---

## 5. Prioritized remediation roadmap

**Gate 0 — before committing/pushing the repo**
- [ ] Confirm no `.env`/`key.properties`/keystore is staged (L7).
- [ ] Remove server secrets from any client-bundled config path; plan `--dart-define-from-file` (C1).

**Gate 1 — before any build that talks to real services**
- [ ] Lock down the Claude Worker: caller auth + origin allow-list + rate-limit + input caps + stop echoing upstream errors (C2).
- [ ] Stop bundling secrets in `.env`; route all privileged calls server-side; gate/compile-out direct Anthropic mode (C1).

**Gate 2 — before handling any real user data (closed beta)**
- [ ] Real phone-OTP auth + router auth guard; remove `verifyOtp` mock-success (C3).
- [ ] Harden + test RLS end-to-end as each feature is wired; add `with check` identity/counter constraints; model the specialist side (M5, M4).
- [ ] Move sensitive local state to secure storage; decide on app-layer encryption + cert pinning (H3).
- [ ] Make the privacy policy match the implementation; add data export/delete (H2, H3).

**Gate 3 — before accepting payments**
- [ ] Remove in-app card entry; integrate acquirer SDK + Apple/Google Pay tokens (H1).
- [ ] Server-side payment webhook drives `bookings.status`; client only observes (H1).

**Gate 4 — before store submission**
- [ ] Re-enable R8/obfuscation or document honestly; reconcile README claims (M1).
- [ ] Fix release signing on the actual build machine; verify signed AAB (M2).
- [ ] Verify release manifest permissions (L3); enable production observability (L4).
- [ ] Replace placeholder legal copy with lawyer-finalized versions; complete Play Data-safety form truthfully.
- [ ] Add real tests (only a placeholder smoke test exists today).

---

## 6. Compliance notes (Kazakhstan market)

- **№94-V «О персональных данных».** Mental-health data is special-category. You need: a lawful basis / explicit consent, an accurate privacy notice (H2), data-subject rights (access/delete/withdraw — currently unimplemented), and appropriate technical measures (encryption, access control). The policy already names Frankfurt hosting — confirm cross-border transfer handling for KZ residents.
- **PCI-DSS.** Do not let card data touch the app (H1). Using a hosted field / tokenization keeps you in the lightest SAQ tier.
- **Google Play / App Store.** Truthful Data-safety / App-privacy declarations, a reachable privacy-policy URL, 18+ rating for mental health, and crisis-resource handling. Mismatched privacy claims (H2) are a common rejection cause.

---

## 7. Closing

Nuva has a strong UI foundation and sensible architectural intent, but it is a
prototype with security-critical gaps that must be closed before it touches real
users, real money, or real health data. None of the findings require redesign —
they are scoping and wiring decisions (move secrets and privileged calls
server-side, enforce auth and RLS, delegate payments, align the privacy policy
with reality). Address the Critical and High items in roadmap order and Nuva will
be on a sound footing for a closed beta.

*This letter reflects a static review of the working tree on 2026-06-15. Re-review
after remediation, and commission an independent penetration test before public
launch.*
