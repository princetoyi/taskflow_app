# TaskFlow — Application Audit & Remediation History

**Original audit date:** 2026-07-22
**Last updated:** 2026-07-22 (same day — several follow-up passes: a full backend/frontend/database wiring audit, a screen-by-screen UI audit, and live runtime debugging against a real Firebase project)
**Scope:** Full repo — Flutter frontend (`lib/`), FastAPI backend (`backend/`), Firebase config, security posture.

This document is both an audit and a running remediation log. Findings are marked with their status; **nothing below has been silently removed**, so this remains a true history of what was broken and what was done about it, in case something regresses.

---

## Where things stand now

Login, signup (with role selection), tasks, notifications, theme, and profile management all work end-to-end against a real Firebase project — verified by actually booting the backend, running it, and exercising it (not just reading the code). The backend is now a single, consolidated implementation (`backend/app/`) instead of two competing ones. The main thing genuinely left undone is the team/manager-oversight feature, which was a deliberate scope decision, not an oversight — see [Are we near "the idea" of the app?](#are-we-near-the-idea-of-the-app) below.

---

## Part 1 — Original audit (2026-07-22, first pass)

`lib/README.md` was empty at the time, so there was no written statement of "the idea" for the app (it's since been written — see `lib/README.md`). The intended vision was reconstructed from `FLUTTER_README.md`, `docs/implementation_plan.md`, the router, and the screens that existed: a role-based task manager where employees manage their own tasks and managers get team oversight (team list, per-member tasks, at-risk/overdue tracking, statistics), with offline support and push notifications.

### 🔴 Critical — app could not function

**1. Two complete, parallel backend implementations, and the wrong one deployed.**
`backend/main.py` + `backend/routers/*` + `backend/core/*` ("Tree A") had `/auth/me`, `/auth/logout`, `/users/team`, statistics, and role support. `backend/app/*` ("Tree B") only had signup/login, task CRUD, theme prefs, and notification listing — no `/auth/me`, no `/auth/logout`. `backend/Dockerfile` ran Tree B. The Flutter client called `/auth/me` after every login/signup/restart; Tree B 404'd, so **login and signup both failed outright**.
**Status: Resolved.** Tree A was deleted entirely (`backend/main.py`, `backend/routers/`, `backend/core/`, plus the orphaned `backend/app/repositories/*` only Tree A used). Everything Tree A had that the app actually needed was ported into Tree B: `GET /auth/me`, `POST /auth/logout`, and (later) `POST /auth/complete-signup` for role-aware signup. `backend/app/` is now the only backend.

**2. Backend crashed on boot from a clean install.**
`apscheduler` and `httpx` were imported but not in `requirements.txt`.
**Status: Resolved.** Added `apscheduler`, `httpx`, and (found later) `email-validator` (required by Pydantic's `EmailStr`) and `python-multipart` (required by the profile-image upload endpoint added later). Verified via a real `pip install -r requirements.txt` into a clean venv.

**3. No "team" — only a role label.**
`UserRepository.get_team_members()` just queried every user with `role == "employee"`, no `team_id` or manager↔employee relationship; tasks had no `assignee_uid`.
**Status: Deliberately deferred, not fixed.** When asked, the explicit decision was: fix critical bugs, don't build out team assignment, and remove the unreachable UI that implied it existed. See "Are we near the idea" below.

### 🟠 High — frontend features built but unreachable (original findings)

- Employee-specific screens (`employee_home_screen.dart`, `employee_task_detail_screen.dart`), `at_risk_tasks_screen.dart`, `trash_bin_screen.dart` — no route, unreachable. **Status: Deleted** (per the team-feature deferral decision).
- `AppRoutes.atRiskTasks`, `AppRoutes.teamMemberDetails` — declared, never given a route. **Status: Deleted along with the screens above.**
- Dashboard "Reports"/"Analytics" — stub snackbars. **Status: Unchanged** (legitimately deferred, not a bug).
- Web push notifications — no `web/` directory at all. **Status: Still open** — see `bugs_found.md` bug #1.
- Unguarded `context.pop()` crash in `task_form_screen.dart` (bug #3 in `bugs_found.md`). **Status: Fixed** — and a second occurrence of the identical bug was later found in `task_detail_screen.dart` and fixed too (see Part 3).

### 🟡 Medium — cleanup debt (original findings)

- Duplicate old-architecture files (`lib/features/tasks/models/task_model.dart`, `.../repositories/task_repository.dart`, `.../providers/task_provider.dart`, `lib/features/auth/models/user_model.dart` *(this one turned out to still be in use — see the correction in Part 2)*, `.../providers/auth_provider.dart`, `mock_task_repository.dart`). **Status: Mostly deleted** — all except `lib/features/auth/models/user_model.dart`, which is genuinely used by `UserRepository`/`UserRemoteDataSource` and was wrongly flagged; it was deleted and then restored after `flutter analyze` caught the breakage (see Part 2's note on verification).
- `backend/app/repositories/*` only consumed by Tree A. **Status: Deleted along with Tree A.**
- Thin test coverage. **Status: Improved** — `backend/app/tests/test_users.py` added (7 tests covering route-ordering and admin-authorization edge cases), plus 2 more tests added to `test_auth.py` for the signup-role flow. Frontend test coverage is unchanged (still thin).

### 🟢 Good news / security posture (still true)

- `taskflow_serviceAccountkey.json` and `.env` are not tracked in git, ever (checked full history).
- `firestore.rules` denies all direct client read/write — correct by design, since the Flutter app has no `cloud_firestore` dependency; all data access goes through the backend's Admin SDK.
- Both backend trees verified Firebase ID tokens properly and scoped task access to the requesting UID.
- CORS needed attention before production — see Part 3, this became a real bug, not just a future concern.

---

## Part 2 — Backend/frontend/database wiring audit (same day, second pass)

A deeper pass specifically tracing every frontend API call against the backend routes and the actual Firestore schema, after the Part 1 fixes landed.

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | No `BASE_URL`/`BASE_URL_ANDROID`/`BASE_URL_IOS`/`BASE_URL_WEB` in `.env` at all — Dio's base URL was empty, every request failed regardless of backend state | Critical | **Fixed** — added all four keys |
| 2 | `firestore.indexes.json` was `{"indexes": []}` despite `task_service.get_tasks()` running equality-filter + order-by-different-field queries that Firestore requires a composite index for | Critical | **Fixed** — added the 6 combinations reachable from the current UI, plus 1 for the equivalent notifications query. **Requires `firebase deploy --only firestore:indexes` to actually take effect** — writing the JSON file alone doesn't deploy it |
| 3 | Notification schema mismatch: backend wrote `{message}`, frontend's `NotificationModel.fromJson` required `title`/`description` with no null fallback — any real notification crashed the list on parse | High | **Fixed** — backend now writes `title`/`description` directly; frontend also got defensive fallbacks so a future mismatch degrades instead of crashing |
| 4 | `UserRepository`/`UserRemoteDataSource` (frontend) called `/users/profile`, `/users/{id}`, `/users`, image upload, password change — none existed on the backend, which only had `/users/preferences` | High | **Resolved** — full backend built to match (see Part 4), then a UI (Profile screen) built on top of it (Part 5) |
| 5 | `firebase-messaging-sw.js` / web push | Medium | Still open, unchanged from Part 1 |

**Verification note:** while cleaning up dead code identified here, `lib/features/auth/models/user_model.dart` was deleted based on an earlier research pass's claim that it was orphaned — `flutter analyze` immediately surfaced 26 errors, proving it was actually live (used by `user_remote_data_source.dart` and `data/repositories/user_repository.dart`, both wired into DI). It was restored via `git checkout` and the analyzer confirmed clean afterward. Recorded here as a reminder: a claim that a file is dead should be verified with the analyzer/compiler before deleting, not trusted from a single research pass.

---

## Part 3 — Screen-by-screen UI audit (same day, third pass)

Went through all 9 screens checking that every button/action does something real.

| Screen | Finding | Status |
|---|---|---|
| Login / Signup | Clean, real `AuthBloc` wiring | No changes needed at the time (signup later gained a role picker — see Part 6) |
| Dashboard | Clean; "Team"/"Reports"/"Analytics" already intentionally show "coming soon" | No changes |
| Notifications | Clean, real `NotificationBloc` wiring | No changes |
| Settings | **No logout button anywhere in the app**, despite `LogoutRequested`→`AuthBloc`→`AuthRepository.logout()`→`/auth/logout` being fully wired and working | **Fixed** — added a confirmed "Log out" tile |
| `AlertsScreen` | Unreachable (no route link anywhere) **and** 100% fabricated data (invented names/timestamps like "Sarah K. · Past due 18h") grafted onto one real task title to look legitimate | **Deleted**, along with its route and route constant |
| Task detail | Same unguarded-`context.pop()` crash as `bugs_found.md` bug #3, in the delete-confirmation flow — and actually reachable, since the task list navigated here with `go()` (replace) instead of `push()` (stack), guaranteeing `canPop()` was false | **Fixed** — guarded the pop, and fixed the root navigation inconsistency (task list → detail, detail → edit form now both use `push()`, matching the dashboard's already-correct pattern) |
| Task list / form | Navigation consistency fix as above | Fixed |

The notification tap-to-navigate handler in `main.dart` (`onNotificationTap` → `router.go(deepLink or /tasks/:id)`) was found to be correctly built but fed nothing — `notification_service.py`'s `send_push_notification()` never included a `data` payload, only `notification.title`/`body`. **Fixed** — deadline-reminder pushes now include `{"task_id": ..., "deepLink": "/tasks/{id}"}`.

---

## Part 4 — Building the `/users/*` backend (same day, on request)

The dead-end frontend code found in Part 2 (item 4) was turned into a real feature rather than deleted, per an explicit decision to build it out. Added to `backend/app/`:

- `GET/PATCH /users/profile` — self-service view/edit (display name, first/last name, phone — **not** role or is_active, enforced by a request model that simply has no such fields)
- `POST /users/profile/change-password` — re-verifies the current password via the Identity Toolkit REST API before applying the new one
- `POST /users/profile/image` — implemented, but see Known Limitations: Cloud Storage isn't provisioned for this Firebase project
- `GET /users`, `GET/PATCH/DELETE /users/{user_id}` — admin-only (checked against the caller's own `role` field), with route ordering carefully arranged so `/users/profile` can't be shadowed by `/users/{user_id}`'s wildcard — and a regression test added specifically for that ordering

**Caveat found and confirmed by direct probe, not guesswork:** used the actual service account credentials to call `bucket.exists()` against every plausible bucket name (`<project>.firebasestorage.app`, `<project>.appspot.com`, bare project id). None exist — Cloud Storage was never enabled for this Firebase project. This is an infrastructure gap, not a code bug; `upload_profile_image`'s code is correct and will work once Storage is enabled in the console.

---

## Part 5 — Building the Profile screen (same day, on request)

A screen was added (`lib/features/profile/`) to actually call the backend built in Part 4 — `ProfileBloc`, `ProfileScreen`, wired into DI/router/Settings navigation. Photo upload deliberately excluded from the UI per the Storage caveat above.

**Caught while wiring it up:** `UserRemoteDataSource.updateProfile()`/`updateUser()` were sending `UserModel.toJson()` (camelCase: `displayName`, `firstName`...) to a backend that only reads snake_case (`display_name`, `first_name`...). Pydantic silently drops unrecognized keys rather than erroring, so every save would have hit `400 No updates provided` with no indication why. **Fixed** — both methods now build explicit snake_case bodies.

---

## Part 6 — Live runtime debugging (same day, real Firebase project)

Once the app was actually run against a live backend, two more bugs surfaced that no amount of code reading had caught, plus one feature request.

| # | Symptom | Root cause | Status |
|---|---|---|---|
| 1 | Every request failed with an opaque `DioException [connection error]` / "XMLHttpRequest onError" | **Two independent causes**, both real: (a) no backend process was actually running (each verification session in this audit started, tested, then killed its own server) — resolved by leaving a persistent server running; (b) `backend/app/main.py` had **zero CORS middleware** — the CORS config that existed was only in the Tree A that got deleted in Part 1, and it turned out not to be dead after all. Browsers hide the real CORS failure reason from JS, hence the unhelpful generic error | **Fixed** — added `CORSMiddleware` with `allow_origin_regex=r"http://localhost:\d+"` (matches Flutter web's random per-run port); confirmed via a real preflight simulation that `access-control-allow-origin` now comes back correctly |
| 2 | After the CORS fix, `/tasks` and `/notifications` *specifically* still failed, while `/auth/me` (which had just succeeded, real token and all) worked | `tasks.py`/`notifications.py` still had the trailing-slash route registration (`@router.get("/")`) flagged as a maybe-issue back in Part 1 — confirmed for real this time: a `307` redirect combined with a credentialed cross-origin browser request is a known-flaky combination | **Fixed** — routes changed to `@router.get("")` (exact match, no redirect), matching the fix already applied to `/users`. Confirmed via `curl`: before, `/tasks` → `307 → /tasks/`; after, a clean `401`/`200` with no redirect |
| 3 | "During registration I can't choose which role I want, idk what it defaults to" | Not a bug — a missing feature. Default was hardcoded `"employee"`. Also found: the backend's `POST /auth/signup` (which does have a role-capable request body) is dead code from the app's perspective — the real signup flow is client-side Firebase Auth, then `GET /auth/me` to self-heal a profile, so adding a role field there alone would have done nothing | **Built** — added `POST /auth/complete-signup` (the real profile-creation moment in the actual flow), a segmented Employee/Manager picker on the signup screen, and a `Literal["employee","manager"]` type on the backend request so `"admin"` is rejected by validation before it ever reaches the database — self-signup can never grant admin. **Confirmed working against the live app**: real signup → `POST /auth/complete-signup {role: manager}` → `200` with `role: "manager"` in the response |
| 4 | After the role-selection fix landed, `GET /tasks` still failed in the browser — but this time genuinely as a `500`, not a connection error, and the browser separately logged "blocked by CORS policy" on that same 500 | Two stacked issues, found by reading the actual backend traceback rather than guessing from the frontend log: (a) the Firestore composite index from Part 2 had been *written* to `firestore.indexes.json` but never *deployed* — confirmed via the exact `FailedPrecondition` error Firestore raises, which even hands back a direct console link to create it; (b) `task_service.get_tasks()` had no exception handling at all (every sibling function in that file does), so the raw Firestore exception escaped as a truly unhandled exception — which in Starlette's middleware stack lands *outside* `CORSMiddleware`, hence the browser's CORS complaint on what was actually a real server error | **Fixed, both parts.** Ran `firebase deploy --only firestore:indexes` for real this time (confirmed `firebase login:list` was already authenticated, `.firebaserc` targets the correct project) — then polled the live Firestore query directly (bypassing the app) until the index finished building (~2 minutes for this project). Wrapped `get_tasks()`'s query in try/except raising `HTTPException`, matching the rest of the file, so future Firestore-level failures surface as a normal error response with CORS headers intact instead of this exact confusing failure mode. Confirmed via `curl` with a bad token: `401` with `access-control-allow-origin` present, and via a direct Firestore probe that the index is ready |

---

## Are we near "the idea" of the app?

For a **single-user (or small, flat-role) task manager with real auth, offline cache, notifications, and profile management** — yes, and more solidly than the first audit found: everything from login through task management through profile editing is now verified working against a live Firebase project, not just "looks correct in the code."

For the **team/manager-oversight app** the leftover screens originally suggested — still deliberately not built. What exists: a `role` (`employee`/`manager`/`admin`) chosen at signup, persisted, and enforced (self-signup can't grant admin; profile self-edit can't grant any role; admin-only endpoints exist for user management). What doesn't exist: task assignment (no `assignee_uid`), real team grouping (a "get my team" query would still just mean "every employee in the whole system"), and any UI for the admin endpoints beyond what a developer could drive through Swagger. This remains a scope decision to make, not leftover technical debt — see `bugs_found.md` item #19 and the "Known Limitations" section of the root `README.md`.

---

## Remediation status summary

| Original item | Status |
|---|---|
| 1. Pick one backend tree, delete the other | ✅ Done |
| 2. Fix `requirements.txt` | ✅ Done |
| 3. Decide on team/assignment scope | ✅ Decided (deferred) — dead UI removed |
| 4. Fix the unguarded `context.pop()` crash | ✅ Done (both occurrences) |
| 5. Delete dead duplicate files | ✅ Done (with one correction — see Part 2's verification note) |
| *(new)* Fix env var naming mismatches (service account path, Firebase API key) | ✅ Done |
| *(new)* Fix missing `BASE_URL`, missing CORS, trailing-slash redirects | ✅ Done |
| *(new)* Fix notification schema mismatch, FCM payload, add Firestore indexes | ✅ Done (indexes need `firebase deploy` to take effect) |
| *(new)* Build out `/users/*` backend + Profile screen | ✅ Done (photo upload blocked on Storage provisioning) |
| *(new)* Add role selection at signup | ✅ Done |
| *(still open)* Web push (`web/` directory + service worker) | ❌ Not done |
| *(still open)* Enable Cloud Storage for photo upload | ❌ Requires a Firebase Console action, not code |
| *(still open)* Team/manager-assignment feature | ❌ Deliberately deferred |
