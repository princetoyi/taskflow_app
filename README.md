# 📁 TaskFlow App

TaskFlow is a task-management app for organising tasks, tracking progress, and boosting productivity. Built with Flutter and Firebase, with a FastAPI Python backend for server-side logic.

> **Status (2026-07-22):** the backend and frontend are wired together and verified working end-to-end (auth, tasks, notifications, theme, profile). See [`docs/AUDIT.md`](docs/AUDIT.md) for the full history of what was broken and what's been fixed. The one remaining known gap is documented under [Known Limitations](#-known-limitations) below.

---

## 📌 About

TaskFlow is designed for individuals who want to manage tasks effectively, with the data model in place for team roles to grow into. Users can:
- Sign up choosing a role (Employee or Manager)
- Add, edit, delete, and complete tasks with priority and deadline
- View a dashboard with live task statistics
- Get push notifications for upcoming deadlines, with tap-to-open deep links
- Edit their profile (name, phone) and change their password
- Switch between light/dark theme, persisted server-side

The app uses **Firebase Auth** for authentication (ID tokens, verified server-side), **Cloud Firestore** as the database (accessed only through the backend — the client never talks to Firestore directly), **Flutter** for the cross-platform UI, and **FastAPI** for the backend API.

---

## ✨ Features

- **Authentication** — Sign up (with role selection), log in, log out, and stay signed in across restarts, all via Firebase Auth ID tokens verified by the backend.
- **Task Management** — Create, edit, delete, and mark tasks complete. Tasks are scoped per-owner (`owner_uid`) with priority (`low`/`medium`/`high`) and a deadline.
- **Dashboard** — Live counts (total, completed, pending, overdue, high-priority) computed from real task data, plus a recent-tasks list.
- **Profile** — View and edit display name, first/last name, and phone number; change password (re-verified server-side before applying).
- **Notifications** — In-app notification list backed by Firestore, plus FCM push for deadline reminders (hourly scheduled job) with deep-link-to-task on tap.
- **Theme** — Light/dark mode toggle, persisted to the user's Firestore profile.
- **Offline cache** — Tasks are cached locally in Hive; mutations made offline are queued and replayed automatically when connectivity returns.
- **Responsive UI** — Runs on Android, iOS, and web (Chrome).

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Flutter App | Flutter 3.x / Dart, Material 3 |
| State Management | `flutter_bloc` (BLoC pattern) throughout — auth, tasks, notifications, theme, profile |
| HTTP Client | Dio, with auth/retry/error/response-cache interceptors |
| Local Storage | Hive (task cache + offline sync queue), `flutter_secure_storage` (auth token) |
| Auth & Database | Firebase Auth (client SDK) + Cloud Firestore (server-side only, via Admin SDK) |
| Backend | Python 3.12+ / FastAPI |
| Backend Auth | Firebase Admin SDK (`verify_id_token`) |
| Scheduled Jobs | APScheduler (hourly deadline-reminder push) |
| Version Control | Git & GitHub |

---

## 📂 Project Structure

```
taskflow_app/                     ← Repo root (Flutter app)
├── lib/
│   ├── core/                     ← Shared infra: network client, DI, services, widgets
│   ├── features/
│   │   ├── auth/                 ← Login, signup, session (Firebase Auth + /auth/me)
│   │   ├── tasks/                ← Task CRUD, offline sync
│   │   ├── dashboard/            ← Task statistics + quick actions
│   │   ├── notifications/        ← Notification list + FCM
│   │   ├── settings/             ← Theme toggle
│   │   └── profile/              ← View/edit profile, change password
│   ├── routes/                   ← go_router config
│   └── main.dart
├── backend/
│   ├── app/
│   │   ├── main.py               ← FastAPI entrypoint (this is the only backend tree — see note below)
│   │   ├── firebase_config.py    ← Firebase Admin SDK init
│   │   ├── middleware/           ← JWT (Firebase ID token) verification
│   │   ├── models/                ← Pydantic request/response schemas
│   │   ├── routes/                ← /auth, /tasks, /users, /notifications
│   │   ├── services/              ← Business logic + Firestore access
│   │   └── tests/
│   ├── Dockerfile
│   └── requirements.txt
├── firestore.rules               ← Denies all direct client access — the backend is the only writer
├── firestore.indexes.json        ← Composite indexes required by the tasks/notifications queries
├── .env                          ← Environment variables (see below) — gitignored, never committed
└── pubspec.yaml
```

> **Note on backend structure:** an earlier merge left two complete, parallel backend implementations in this repo (`backend/main.py` + `backend/routers/` + `backend/core/`, alongside `backend/app/`). They've since been reconciled — the old tree was deleted and everything it had that the app actually needed (`/auth/me`, `/auth/logout`, role support) was ported into `backend/app/`, which is what `backend/Dockerfile` runs. If you see references to `backend/routers/` or `backend/core/` anywhere (old commits, cached docs), they're gone — `backend/app/` is the only backend now.

---

## 🚀 Local Setup

### Prerequisites

| Tool | Minimum version | Install |
|---|---|---|
| Git | Any | https://git-scm.com |
| Flutter SDK | 3.x | https://docs.flutter.dev/get-started/install |
| Python | 3.12+ | https://python.org |
| Firebase CLI | Latest (only needed to deploy rules/indexes) | `npm install -g firebase-tools` |

---

### 1. Clone the Repository

```bash
git clone https://github.com/princetoyi/taskflow_app.git
cd taskflow_app
```

---

### 2. Firebase Setup (one-time, shared project)

1. Firebase project already exists (`taskflow-33cf5`). If setting up a new project instead: [Firebase Console](https://console.firebase.google.com) → Create project → enable **Email/Password** auth → create a **Cloud Firestore** database.
2. Get the service account key: Project Settings → Service Accounts → **Generate new private key**. Save the JSON at the **repo root** (not inside `backend/`) — it's already gitignored regardless of the exact filename.
3. Create `.env` at the **repo root** (used by both the backend and the Flutter app):

```env
# Backend API base URL — used by the Flutter app's Dio client.
# Android emulator can't reach "localhost" (that's the emulator's own
# loopback), hence the separate 10.0.2.2 alias that routes to the host.
BASE_URL=http://localhost:8000
BASE_URL_ANDROID=http://10.0.2.2:8000
BASE_URL_IOS=http://localhost:8000
BASE_URL_WEB=http://localhost:8000

# Firebase Admin SDK (backend) — either name works, both are checked
FIREBASE_SERVICE_ACCOUNT=your-service-account-filename.json
# FIREBASE_SERVICE_ACCOUNT_PATH is also accepted, same meaning

# Firebase Web API key — used by the backend's REST sign-in call
# (Admin SDK can't verify a password itself). Either name works.
FIREBASE_API_KEY=your-web-api-key
# FIREBASE_WEB_API_KEY is also accepted, same meaning

# Firebase Web config (used by the Flutter web build)
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_APP_ID=...
FIREBASE_MEASUREMENT_ID=...
```

> The backend resolves a relative `FIREBASE_SERVICE_ACCOUNT` path against the **repo root**, regardless of whether you launch uvicorn from `backend/` or elsewhere — no need to duplicate the key file.

4. Deploy Firestore rules and indexes (rules deny all direct client access by design — the backend is the only writer):

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

---

### 3. Backend Setup (FastAPI)

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt

# Start the dev server (note: app.main, not main — see structure note above)
uvicorn app.main:app --reload --port 8000
```

The API will be available at:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health check:** http://localhost:8000/health

See [`docs/SWAGGER_UI_GUIDE.md`](docs/SWAGGER_UI_GUIDE.md) for a full walkthrough, including how to get a real Firebase ID token to authorize requests (there is no stub/dummy token — every protected route verifies a real token via the Admin SDK).

**CORS:** the backend allows any `http://localhost:<port>` origin (`allow_origin_regex`), since `flutter run -d chrome` picks a random port per run. Tighten this in `backend/app/main.py` before deploying to a real production origin.

---

### 4. Flutter App Setup

```bash
# From the repository root
flutter pub get
```

#### Firebase Flutter Configuration

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` (gitignored, not committed — every developer generates their own).

#### Run on Each Platform

```bash
# Android (emulator or device)
flutter run -d android

# iOS (macOS only, with Xcode)
flutter run -d ios

# Web
flutter run -d chrome
```

The backend must be running (step 3) before the app can log in or do anything past the login screen.

---

## 🔑 Environment Variables Reference

| Variable | Used by | Description |
|---|---|---|
| `BASE_URL`, `BASE_URL_ANDROID`, `BASE_URL_IOS`, `BASE_URL_WEB` | Flutter | Backend base URL per platform. Required — the app cannot reach the backend without these. |
| `FIREBASE_SERVICE_ACCOUNT` (or `FIREBASE_SERVICE_ACCOUNT_PATH`) | Backend | Path to the service account JSON, resolved against the repo root if relative. |
| `FIREBASE_API_KEY` (or `FIREBASE_WEB_API_KEY`) | Backend | Firebase Web API key, used for the REST sign-in call during `/auth/login` and password-change verification. |
| `DATABASE_URL` | Unused currently | Legacy Realtime Database URL — the app uses Firestore, not RTDB. Safe to leave as a placeholder. |
| `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_APP_ID`, `FIREBASE_MEASUREMENT_ID` | Flutter (web) | Firebase Web SDK config. |

---

## 🧪 Testing

```bash
# Flutter unit & widget tests
flutter test

# Python backend tests (mocked — never hit real Firebase)
cd backend
pytest
```

---

## 🚧 Known Limitations

- **Cloud Storage is not provisioned** for this Firebase project — confirmed directly (no bucket exists under any naming convention). Profile photo upload has a working backend endpoint (`POST /users/profile/image`) but will fail until Storage is enabled in the Firebase Console; the Profile screen deliberately doesn't expose a photo-upload button yet.
- **Web push notifications don't register** — there's no `web/` platform directory in the repo, so `firebase-messaging-sw.js` has nowhere to live. Native (Android/iOS) push works.
- **No team/manager-assignment feature** — a `role` (`employee`/`manager`/`admin`) exists on every user and is chosen at signup, and admin-only user-management endpoints exist (`GET/PATCH/DELETE /users/{id}`), but there's no `assignee_uid` on tasks and no manager→team grouping. This was explicitly deferred — see `docs/AUDIT.md` for the reasoning.
- CORS is a permissive `localhost:*` regex, correct for local dev only — must be locked to the real origin before any production deployment.

---

## 📬 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit your changes: `git commit -m "feat: description"`
3. Push and open a PR against `main`.
