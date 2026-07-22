# End-to-End Testing — Bug Report

**Project:** TaskFlow App
**Tester:** Bokang
**Original test date:** 30 June 2026
**Platform:** Web (Chrome, localhost)

> **Update (2026-07-22):** a full backend/frontend integration audit was done, fixing most of the original bugs below plus a much longer list of wiring bugs the original manual test pass hadn't reached (auth was completely broken end-to-end at the time — see `docs/AUDIT.md` for the full history). Statuses below are updated accordingly; new findings are appended in their own section.

## Summary

| # | Bug | Severity | File | Status |
|---|-----|----------|------|--------|
| 1 | FCM service worker missing | Medium | `web/firebase-messaging-sw.js` | **Open** — no `web/` platform directory exists in the repo at all |
| 2 | Task card row overflow | Low | `task_card.dart:91` | **Unverified** — the row now uses `Expanded`/`Flexible`, which looks like a fix, but this wasn't re-tested in a real browser this session |
| 3 | Crash on task form close | High | `task_form_screen.dart:90` | **Fixed** — and a second, previously-unknown occurrence of the exact same bug was found and fixed in `task_detail_screen.dart`'s delete-confirmation flow |
| 4 | Email validation always fails | High | `validators.dart:6` | **Fixed** (confirmed still in place) |

---

## Bug 1 — Push Notifications Not Working (Web)

**Severity:** Medium — **Status: Open**
**Location:** Firebase Cloud Messaging setup

Firebase cannot register its service worker because the server returns an HTML page instead of a JavaScript file for `firebase-messaging-sw.js`. Push notifications are completely non-functional on web.

**Error:**
```
FCM registration failure: [firebase_messaging/failed-service-worker-registration]
Failed to register a ServiceWorker — script has unsupported MIME type 'text/html'
```

**Why it's still open:** there's no `web/` directory in this Flutter project at all (confirmed by directory listing) — the web platform was either never added or was removed. Adding it (`flutter create . --platforms=web`) and then the service worker file would resolve this, but that's a bigger step than a one-line fix and hasn't been done.

Native (Android/iOS) push notifications work correctly and are unaffected — the backend fix that makes them actually deep-link to the right task on tap (see "FCM payload missing task data" below) was done this session.

---

## Bug 2 — Task Card Overflows on Small Screens

**Severity:** Low — **Status: Unverified**
**Location:** `lib/features/tasks/presentation/widgets/task_card.dart:91`

The bottom row of the task card (deadline badge, priority badge, status chip, delete button) was reported to overflow horizontally on narrow screens.

**Error (as originally reported):**
```
RenderFlex overflowed by 6.2 / 0.05 / 20 / 2.4 pixels on the right
```

**Current state:** the row in question now wraps children in `Expanded`/`Flexible` (confirmed by reading the source), which is the exact fix this bug report recommended. It's not clear whether this was fixed as a direct response to this report or was already like this — either way, it wasn't re-tested against a real narrow viewport this session, so treat this as *likely* fixed but not verified.

---

## Bug 3 — Crash When Closing Task Form

**Severity:** High — **Status: Fixed**
**Location:** `lib/features/tasks/presentation/screens/task_form_screen.dart:92`

After saving a task, the screen called `context.pop()` but there was no route to pop back to when the form was the entry point of the navigation stack. The app crashed with an unhandled exception.

**Error:**
```
GoError: There is nothing to pop
```

**Fix applied:**
```dart
if (context.canPop()) {
  context.pop();
} else {
  context.go(AppRoutes.dashboard);
}
```

**A second occurrence of the same bug was found and fixed** in `task_detail_screen.dart`'s delete-confirmation dialog, which had the identical unguarded `context.pop()`. It was reachable in practice: `task_list_screen.dart` navigated to task detail using `context.go()` (replace) rather than `context.push()` (stack), which guarantees `canPop()` is false on that path — so deleting a task from its detail screen, when reached from the task list, crashed the same way. Root-caused and fixed by switching all drill-down navigation (task list → task detail, task detail → edit form) to `push()` for consistency with the dashboard, which already did this correctly — so "back" now works uniformly everywhere, not just from the one screen that happened to get it right originally.

---

## Bug 4 — Email Validation Always Fails on Sign Up

**Severity:** High — **Status: Fixed** (confirmed still correct)
**Location:** `lib/core/utils/validators.dart:6`

The email regex ended with `\$` inside a raw Dart string (`r'...'`). In a raw string, `\$` is passed literally to the regex engine as a backslash + dollar sign, treated as a literal `$` character to match — not the end-of-string anchor. Every valid email failed validation.

**Fixed:**
```dart
final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
```

---

## Additional bugs found during the 2026-07-22 backend/frontend integration audit

These weren't caught by the original manual test pass because, at the time they were found, **login and signup didn't work at all** — the app never got far enough to reach most of what's below. Full detail and reasoning for each is in `docs/AUDIT.md`; this is the condensed bug-tracker version.

| # | Bug | Severity | Status |
|---|-----|----------|--------|
| 5 | Deployed backend missing `/auth/me`, `/auth/logout` — every login/signup failed | Critical | Fixed |
| 6 | `requirements.txt` missing `apscheduler`, `httpx`, `email-validator`, `python-multipart` — clean install crashes on boot | Critical | Fixed |
| 7 | `FIREBASE_SERVICE_ACCOUNT_PATH` vs `.env`'s `FIREBASE_SERVICE_ACCOUNT` naming mismatch — server crashed on every boot | Critical | Fixed (backend now accepts either name, plus resolves relative paths against repo root) |
| 8 | `FIREBASE_WEB_API_KEY` vs `.env`'s `FIREBASE_API_KEY` naming mismatch — login always returned 500 | Critical | Fixed (same dual-name pattern) |
| 9 | No `BASE_URL*` keys in `.env` at all — Flutter's Dio client had an empty base URL, every request failed | Critical | Fixed |
| 10 | Zero CORS middleware on the deployed backend — every browser (web) request failed with an opaque connection error | Critical | Fixed (`allow_origin_regex` for local dev) |
| 11 | `/tasks`, `/notifications` routes registered with a trailing slash — 307 redirect broke credentialed CORS requests in the browser | High | Fixed (routes now registered without the trailing slash, matching what the client actually sends) |
| 12 | Firestore had zero composite indexes despite queries needing them (`owner_uid` + `order_by`, optionally `+ completed`/`+ priority`) | High | Fixed — added to `firestore.indexes.json` **and deployed** (`firebase deploy --only firestore:indexes`), confirmed built and queryable against the live project |
| 20 | `GET /tasks` had no exception handling around the Firestore query — a real backend error (the missing index, above) escaped as an unhandled exception, which lands *outside* `CORSMiddleware` in Starlette's middleware stack. Result: the browser reported a generic "blocked by CORS policy" / connection error instead of the real 500, which is what made this so hard to diagnose from the frontend logs alone | High | Fixed — wrapped in try/except raising `HTTPException`, matching every other function in `task_service.py`; confirmed via `curl` that error responses now carry `access-control-allow-origin` correctly |
| 13 | Notification schema mismatch — backend wrote `message`, frontend's `NotificationModel.fromJson` required `title`/`description` with no fallback, so real notifications crashed the list on parse | High | Fixed, plus added defensive fallbacks |
| 14 | FCM push payload had no `data` (task_id/deepLink) — tapping a deadline-reminder notification did nothing despite the tap-to-navigate handler being fully built | Medium | Fixed |
| 15 | `UserRemoteDataSource.updateProfile()`/`updateUser()` sent camelCase JSON keys to a backend that only reads snake_case — every profile save would 400 silently | High | Fixed |
| 16 | No logout button anywhere in the UI, despite `LogoutRequested`/`AuthBloc`/`AuthRepository.logout()` being fully wired | Medium | Fixed — added to Settings |
| 17 | `AlertsScreen` — unreachable (no route link) and 100% fabricated placeholder data | Low | Removed |
| 18 | Two complete, parallel backend implementations (`backend/main.py`+`routers/`+`core/` vs `backend/app/`) — the Dockerfile ran the incomplete one | Critical | Resolved — old tree deleted, everything it had that was needed was ported into `backend/app/` |
| 19 | Employee/team/at-risk/trash screens — built but entirely unreachable, no backend support (no `assignee_uid`, no real team grouping) | Medium | Deferred by decision, dead screens removed (see `docs/AUDIT.md`) |
