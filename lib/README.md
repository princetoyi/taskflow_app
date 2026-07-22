# TaskFlow — `lib/`

This is the Flutter source for TaskFlow, a task-management app: sign up, pick a role, create tasks with a priority and deadline, get reminded before they're due, and track them on a dashboard. It talks to the FastAPI backend in `../backend/` for everything except the Firebase Auth handshake itself — there is no local-only or offline-first mode; the backend must be reachable to log in.

**The idea, plainly:** an individual (or small team, since a `role` — employee/manager/admin — is chosen at signup) manages their own tasks day-to-day, with push reminders for upcoming deadlines and a dashboard showing what's overdue, pending, and done. Manager/admin roles currently unlock nothing beyond a couple of admin-only user-management API endpoints (no UI yet) — team oversight (a manager seeing and assigning a team's tasks) was scoped out deliberately; see `../docs/AUDIT.md` for that decision and reasoning.

For architecture, state-management conventions, the full backend endpoint list, and notes for contributors, see [`../FLUTTER_README.md`](../FLUTTER_README.md). For environment setup, see [`../README.md`](../README.md).

## Where things live

- `core/` — everything not specific to one feature: the Dio-based API client and its interceptor chain, dependency injection (GetIt), local storage (Hive, secure storage), connectivity/notification services, shared widgets and theme constants.
- `features/<name>/` — one folder per feature (`auth`, `tasks`, `dashboard`, `notifications`, `settings`, `profile`), each following the same internal shape: `data/` (models + repositories + remote/local datasources), `domain/` (entities + repository interfaces, where the feature has one), `presentation/` (BLoC + screens + widgets).
- `routes/` — `go_router` route table and the auth-based redirect logic.
- `main.dart` — startup sequence: Firebase init → Hive init → DI container → BLoC providers → router → `runApp`.

## Conventions worth knowing before you add code here

- **State management is BLoC, everywhere.** A screen dispatches an event to a bloc; the bloc calls a repository. Don't call a repository directly from a screen — every existing feature does it through a bloc, and mixing patterns is exactly the kind of thing that created dead, half-wired code here before (see the "cleanup debt" section of `../docs/AUDIT.md`).
- **Field names crossing to the backend are snake_case** (`display_name`, `owner_uid`, `is_active`...). Dart models tolerate reading either case, but only ever send snake_case — see `UserRemoteDataSource` for the pattern.
- Before adding a new screen, check `routes/app_router.dart` — a screen that exists but has no `GoRoute` (and no button anywhere that navigates to it) is unreachable, which has happened here more than once.
