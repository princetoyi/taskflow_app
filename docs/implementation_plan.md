# Implementation Plan - TaskFlow Frontend Implementation Plan (Phases 3–5)

This document outlines the master implementation plan to complete **Phases 3, 4, and 5** of the TaskFlow mobile app frontend, integrating it with Firebase, Hive (for offline caching), and the FastAPI backend.

> **Status: Completed** — this document is kept as a historical record of what was planned and why. Every item in the "Proposed Changes" section below was implemented (the clean-architecture screen paths, `TaskModel`'s `@JsonKey` mapping, the Hive offline queue, the theme bloc, FCM setup). What this plan didn't anticipate: the backend that shipped alongside this frontend work had a completely different, incompatible route set from what the client called (`/auth/me`, `/auth/logout` didn't exist on the deployed backend), several env-var naming mismatches, and no CORS — meaning the integration this plan describes didn't actually work end-to-end until a separate remediation pass fixed it on 2026-07-22. See `docs/AUDIT.md` for that full history and `bugs_found.md` for the itemized bug list. If you're using this document to understand *why* the code looks the way it does, it's accurate; if you're trying to understand *whether it currently works*, read the audit instead.

---

## User Review Required & Misalignment Identification

After researching the codebase, we identified the following critical misalignments between the spec and the current codebase. Here is how we propose to resolve them:

### 1. Folder Structure (Clean Architecture Realignment)
- **Misalignment:** The existing task screens are in `lib/features/tasks/screens/` and the dashboard screen is in `lib/features/dashboard/screens/`. The spec specifies paths under a `presentation/screens/` structure (e.g., `lib/features/tasks/presentation/screens/task_list_screen.dart`).
- **Improvement:** We will migrate all screens to conform to the standard Clean Architecture pattern used by the `auth` module. We will move the screens and update all imports to:
  - `lib/features/tasks/presentation/screens/task_list_screen.dart`
  - `lib/features/tasks/presentation/screens/task_detail_screen.dart`
  - `lib/features/tasks/presentation/screens/task_form_screen.dart` (shared form screen replacing `create_task_screen.dart`)
  - `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

### 2. Task Bloc Event Simplification
- **Misalignment:** The current `TaskBloc` has a custom `ToggleTaskStatus` event. The spec's event list specifies using the generic `UpdateTask` event for status toggles to trigger optimistic UI updates.
- **Improvement:** We will remove the `ToggleTaskStatus` event and implement status toggling by dispatching `UpdateTask(task.copyWith(status: ...))`. The bloc will perform the optimistic state update directly inside `UpdateTask`.

### 3. Model Mapping for Database Keys
- **Misalignment:** 
  - Spec uses `userId` (field name) and `status` (enum `pending`/`completed`).
  - Backend/Firestore uses `owner_uid` (field name) and `completed` (boolean status).
- **Improvement:** In `lib/features/tasks/data/models/task_model.dart`, we will configure the `@JsonKey` annotations to map between the backend properties and frontend fields seamlessly:
  - `@JsonKey(name: 'owner_uid') final String userId;`
  - `@JsonKey(name: 'completed', fromJson: _statusFromJson, toJson: _statusToJson) final TaskStatus status;`
  - `@JsonKey(name: 'created_at') final DateTime createdAt;`

### 4. Backend Route Alignments
- **Misalignment:** The spec references `PATCH /users/{uid}/preferences` and `POST /users/{uid}/fcm-token`. The actual backend provides JWT-secured routes `PUT /users/preferences` and `POST /notifications/fcm-token` which extract user contexts automatically.
- **Improvement:** We will call the backend's actual endpoints, omitting `{uid}` from the path since the JWT contains the UID context.

---

## Open Questions

None at this stage. The identified alignments cover all issues.

---

## Proposed Changes

### 1. Project Dependencies

#### [MODIFY] [pubspec.yaml](file:///c:/Users/Cash/Documents/taskflow_app/pubspec.yaml)
- Add dependencies: `firebase_messaging: ^15.3.0`, `hive: ^2.2.3`, `hive_flutter: ^1.1.0`, `shimmer: ^3.0.0`
- Add dev_dependencies: `hive_generator: ^2.0.1`

---

### 2. Data and Domain Models (Phase 3)

#### [MODIFY] [task.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/domain/entities/task.dart)
- Add `userId` field to `Task` entity. Update constructor and Equatable properties.

#### [MODIFY] [task_model.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/data/models/task_model.dart)
- Explicitly map fields using json serialization helpers:
  - `@JsonKey(name: 'owner_uid') final String userId;`
  - `@JsonKey(name: 'completed', fromJson: _statusFromJson, toJson: _statusToJson) final TaskStatus status;`
  - `@JsonKey(name: 'created_at') final DateTime createdAt;`
- Generate `task_model.g.dart` using `build_runner`.

---

### 3. State Management & Repositories (Phase 3)

#### [MODIFY] [task_repository_impl.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/data/repositories/task_repository_impl.dart)
- When online, save fetched tasks to local Hive storage.
- When offline, read from Hive storage instead of throwing network exceptions.
- Queue mutations (creates, updates, deletes) in the Hive `sync_queue` if network connection is lost.

#### [MODIFY] [task_bloc.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/presentation/bloc/task_bloc.dart)
- Remove `ToggleTaskStatus` event.
- Ensure `UpdateTask` performs an immediate optimistic UI update. If write fails, revert to previous state and emit `TaskError`.

---

### 4. Clean Presentation Layer Migration & Refactoring (Phase 4)

#### [DELETE] [create_task_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/screens/create_task_screen.dart)
#### [DELETE] [task_detail_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/screens/task_detail_screen.dart)
#### [DELETE] [task_list_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/screens/task_list_screen.dart)
#### [DELETE] [dashboard_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/dashboard/screens/dashboard_screen.dart)

#### [NEW] [task_list_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/presentation/screens/task_list_screen.dart)
- Conformed and migrated version with pull-to-refresh, shimmer skeletal loaders, and swipe-to-delete.

#### [NEW] [task_detail_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/presentation/screens/task_detail_screen.dart)
- Conformed read-only view utilizing centralized priority colors.

#### [NEW] [task_form_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/presentation/screens/task_form_screen.dart)
- New form screen serving both create and edit modes using the `isEdit` boolean flag.

#### [NEW] [dashboard_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/dashboard/presentation/screens/dashboard_screen.dart)
- Migrate and connect to `TaskBloc` to display dynamic task statistics and scrollable groups.

---

### 5. UI Custom Theme & Theme Bloc (Phase 4)

#### [MODIFY] [app_theme.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/core/constants/app_theme.dart)
- Add full `darkTheme` configuration.

#### [NEW] [priority_colors.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/core/theme/priority_colors.dart)
- Shared module for Hex values matching `#E53935` (High), `#FFB300` (Medium), and `#43A047` (Low).

#### [NEW] [theme_bloc.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/settings/presentation/bloc/theme_bloc.dart)
- Manage state for `ThemeMode`. Reads `GET /users/preferences` on app startup, and sends requests to `PUT /users/preferences` when toggled.

#### [NEW] [settings_screen.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/settings/presentation/screens/settings_screen.dart)
- Settings screen for toggling theme state.

#### [MODIFY] [app_router.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/routes/app_router.dart)
- Configure named paths and add `/settings`. Protect routing paths from unauthorized access.

---

### 6. Notifications & Local Sync Setup (Phase 5)

#### [NEW] [notification_service.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/core/services/notification_service.dart)
- Handles messaging setup and token reporting to `POST /notifications/fcm-token`.

#### [NEW] [task_hive_model.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/data/models/task_hive_model.dart)
- Database schema mapping for caching tasks.

#### [NEW] [task_local_datasource.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/features/tasks/data/local/task_local_datasource.dart)
- Hive adapter helper for read/write.

#### [NEW] [sync_queue_datasource.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/core/local/sync_queue_datasource.dart)
- Stores transactions for offline task operations.

#### [NEW] [sync_service.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/core/services/sync_service.dart)
- Automatically replays entries on connectivity reconnect.

#### [MODIFY] [connectivity_service.dart](file:///c:/Users/Cash/Documents/taskflow_app/lib/core/services/connectivity_service.dart)
- Add `Stream<bool> get isConnected` stream listener.

---

## Verification Plan

### Automated Tests
- Run `flutter test` to verify no regression in model mapping or Bloc logic.

### Manual Verification
1. **Shimmer effect validation:** Intentionally delay API calls to verify shimmer skeleton loaders appear on task loading.
2. **Offline-first test:** Enable airplane mode, verify you can add and complete tasks with immediate UI reaction. Re-enable network and verify automatic synchronisation completes successfully.
