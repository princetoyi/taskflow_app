# End-to-End Testing — Bug Report

**Project:** TaskFlow App  
**Tester:** Bokang  
**Date:** 30 June 2026  
**Platform:** Web (Chrome, localhost)

---

## Summary

| # | Bug | Severity | File |
|---|-----|----------|------|
| 1 | FCM service worker missing | Medium | `web/firebase-messaging-sw.js` |
| 2 | Task card row overflow | Low | `task_card.dart:91` |
| 3 | Crash on task form close | High | `task_form_screen.dart:90` |
| 4 | Email validation always fails | High | `validators.dart:6` |

---

## Bug 1 — Push Notifications Not Working (Web)

**Severity:** Medium  
**Location:** Firebase Cloud Messaging setup

Firebase cannot register its service worker because the server returns an HTML page instead of a JavaScript file for `firebase-messaging-sw.js`. Push notifications are completely non-functional on web.

**Error:**
```
FCM registration failure: [firebase_messaging/failed-service-worker-registration]
Failed to register a ServiceWorker — script has unsupported MIME type 'text/html'
```

**Fix needed:** Create `web/firebase-messaging-sw.js` with the correct FCM service worker content.

---

## Bug 2 — Task Card Overflows on Small Screens

**Severity:** Low  
**Location:** `lib/features/tasks/presentation/widgets/task_card.dart:91`

The bottom row of the task card (deadline badge, priority badge, status chip, delete button) overflows horizontally by up to 20 pixels on narrower screens. The row has too many fixed-width children with no flex wrapping.

**Error:**
```
RenderFlex overflowed by 6.2 / 0.05 / 20 / 2.4 pixels on the right
```

**Fix needed:** Wrap `_buildDeadlineBadge` in a `Flexible` or `Expanded`, or reduce padding/icon sizes in the row.

---

## Bug 3 — Crash When Closing Task Form

**Severity:** High  
**Location:** `lib/features/tasks/presentation/screens/task_form_screen.dart:90`

After saving a task, the screen calls `context.pop()` but there is no route to pop back to when the form is the entry point of the navigation stack. The app crashes with an unhandled exception.

**Error:**
```
GoError: There is nothing to pop
```

**Fix needed:** Guard the pop call:
```dart
if (context.canPop()) context.pop() else context.go(AppRoutes.dashboard);
```

---

## Bug 4 — Email Validation Always Fails on Sign Up

**Severity:** High  
**Location:** `lib/core/utils/validators.dart:6`

The email regex ends with `\$` inside a raw Dart string (`r'...'`). In a raw string, `\$` is passed literally to the regex engine as a backslash + dollar sign, which it treats as a literal `$` character to match — not the end-of-string anchor. Every valid email fails validation as a result.

**Error:**
> "Enter a valid email address" shown even for correctly formatted emails.

**Before:**
```dart
final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$');
```

**After (fixed):**
```dart
final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
```

**Status:** Fixed.
