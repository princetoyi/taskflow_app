# 📁 TaskFlow App

TaskFlow is a task-management app for organising tasks, tracking progress, and boosting productivity. Built with Flutter and Firebase, with a FastAPI Python backend for server-side logic.

---

## 📌 About

TaskFlow is designed for individuals and teams who want to manage tasks and projects effectively. Users can:
- Add, edit, and delete tasks
- Set deadlines and priorities
- View tasks on a dashboard
- Track progress over time

The app leverages **Firebase** for real-time data synchronisation, **Flutter** for a responsive cross-platform experience, and **FastAPI** for a scalable Python backend.

---

## ✨ Features

- **Authentication** – Sign up, log in, and log out securely via Firebase Auth.
- **Task Management** – Create, edit, delete, and mark tasks as completed.
- **Dashboard** – View tasks sorted by priority, deadline, or completion status.
- **Profile Management** – Update user information and preferences.
- **Responsive UI** – Works on mobile, tablet, and web.
- **Notifications** – Notifies users when there are updates.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Flutter App | Flutter 3 / Dart |
| HTTP Client | Dio + AuthInterceptor |
| State Management | Provider |
| Auth & Database | Firebase Auth + Cloud Firestore |
| Backend | Python 3.10+ / FastAPI |
| Backend Auth | Firebase Admin SDK |
| Version Control | Git & GitHub |

---

## 📂 Project Structure

```
taskflow_app/               ← Repo root
├── backend/                ← FastAPI Python backend
│   ├── core/
│   │   └── firebase.py     ← Firebase Admin SDK init
│   ├── routers/
│   │   ├── auth.py         ← /auth endpoints
│   │   └── tasks.py        ← /tasks endpoints
│   ├── main.py             ← FastAPI app + CORS middleware
│   ├── requirements.txt
│   └── .env                ← Firebase credentials (not committed)
│
├── taskflow_app/           ← Flutter application
│   └── lib/
│       ├── core/
│       │   ├── constants/  ← App-wide constants & colours
│       │   ├── theme/      ← AppTheme
│       │   └── utils/      ← Helpers & formatters
│       ├── features/
│       │   ├── auth/       ← Login, Register screens + AuthProvider
│       │   ├── tasks/      ← Task screens, TaskProvider, TaskRepository
│       │   └── dashboard/  ← DashboardScreen
│       ├── services/
│       │   ├── firebase_service.dart  ← Firebase init wrapper
│       │   ├── api_client.dart        ← Dio HTTP client + AuthInterceptor
│       │   └── token_service.dart     ← flutter_secure_storage wrapper
│       └── main.dart
│
└── docs/
    └── taskflow_api.postman_collection.json  ← Postman collection
```

---

## 🚀 Local Setup — All Three Platforms

### Prerequisites (all platforms)

| Tool | Minimum version | Install |
|---|---|---|
| Git | Any | https://git-scm.com |
| Flutter SDK | 3.x | https://docs.flutter.dev/get-started/install |
| Python | 3.10+ | https://python.org |
| Firebase CLI | Latest | `npm install -g firebase-tools` |

---

### 1. Clone the Repository

```bash
git clone https://github.com/princetoyi/taskflow_app.git
cd taskflow_app
```

---

### 2. Firebase Setup (One-time — shared credential)

> **Day 1 task.** The Firebase project must be created before the backend or app can run.

1. Go to [Firebase Console](https://console.firebase.google.com) → Create project `taskflow-app`.
2. Enable **Email/Password** under Authentication → Sign-in methods.
3. Create a **Cloud Firestore** database (start in test mode for development).
4. Go to Project Settings → Service Accounts → **Generate new private key**.
5. Save the downloaded JSON as `taskflow_serviceAccountkey.json` in the root directory (this file is gitignored).
6. Create an `.env` file in the root directory (you can copy `.env.example` as a starting point) and update the values:

```env
FIREBASE_SERVICE_ACCOUNT=taskflow_serviceAccountkey.json
DATABASE_URL=https://taskflow-app-default-rtdb.firebaseio.com
FIREBASE_API_KEY="your-api-key"
...
```

> **Note:** The backend automatically resolves relative service account paths relative to the project root directory, even if you start the server from inside the `backend` folder.

---

### 3. Backend Setup (FastAPI)

```bash
cd backend

# Create and activate a virtual environment
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Test Firebase Admin SDK initialisation (requires .env to be configured)
python -c "from core.firebase import db; print('Firestore connected:', db)"

# Start the dev server
uvicorn main:app --reload --port 8000
```

The API will be available at:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

---

### 4. Flutter App Setup

```bash
cd taskflow_app

# Install all Flutter dependencies (includes Dio, flutter_secure_storage, Firebase packages)
flutter pub get
```

#### Firebase Flutter Configuration

Before running the app, configure Firebase for each target platform using the FlutterFire CLI:

```bash
# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# Configure — follow the prompts to select your Firebase project
flutterfire configure
```

This generates `lib/firebase_options.dart`. Then update `lib/services/firebase_service.dart` to use it:

```dart
import '../firebase_options.dart';
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

#### Run on Each Platform

```bash
# Android (connect device or start emulator first)
flutter run -d android

# iOS (macOS only, with Xcode installed)
flutter run -d ios

# Web
flutter run -d chrome
```

---

### 5. Postman — Testing the API

1. Open Postman → **Import** → select `docs/taskflow_api.postman_collection.json`.
2. Set the `auth_token` collection variable to a valid Firebase ID token.
   - Sign in on the Flutter app, then call `await FirebaseAuth.instance.currentUser!.getIdToken()` from the Dart console or a debug button.
3. All endpoints are ready to test — stubs return sample data immediately.

---

## 🔑 Environment Variables Reference

| Variable | Description | Example |
|---|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | Path to service account JSON (absolute or relative to root) | `taskflow_serviceAccountkey.json` |
| `DATABASE_URL` | Firebase RTDB URL (optional) | `https://app-default-rtdb.firebaseio.com` |
| `FIREBASE_API_KEY` | Firebase API Key (for testing Auth / Login REST API) | `AIzaSy...` |
| `FIREBASE_PROJECT_ID` | Firebase Project ID | `taskflow-33cf5` |

---

## 🧪 Testing

```bash
# Flutter unit & widget tests
cd taskflow_app
flutter test

# Python backend tests
cd backend
pytest
```

---

## 🚧 Known Blockers (Sprint 1)

- Firebase Service Account JSON must be obtained from the project owner and stored locally (never committed).
- Flutter `firebase_options.dart` must be generated via `flutterfire configure` — not committed to the repo.
- CORS `ALLOWED_ORIGINS` in `backend/main.py` must be updated with the production Flutter web URL before deployment.

---

## 📬 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit your changes: `git commit -m "feat: description"`
3. Push and open a PR against `main`.
