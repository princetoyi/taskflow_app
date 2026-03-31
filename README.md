# 📁 Taskflow app
Task flow is a management app for organising task, tracking progress,  and boosting productivity. Built with flutter and firebase for  efficient workflow management, simple and scalable task management system for teams and individuals


---
## 📌 About
TaskFlow is designed for individuals and teams who want to manage their tasks and projects effectively. Users can:  
- Add, edit, and delete tasks  
- Set deadlines and priorities  
- View tasks on a dashboard  
- Track progress over time  

The app leverages **Firebase** for real-time data synchronization and **Flutter** for a responsive, cross-platform experience.  

---

## ✨ Features
- **Authentication** – Users can sign up, log in, and log out securely.  
- **Task Management** – Create, edit, delete, and mark tasks as completed.  
- **Dashboard** – View tasks sorted by priority, deadline, or completion status.  
- **Profile Management** – Update user information and preferences.  
- **Responsive UI** – Works seamlessly on both mobile and tablet devices.
- **Notifications** – Notifies both users when there's updates.

---

## 🛠 Tech Stack
| Layer | Technology |
|-------|------------|
| Frontend | Flutter |
| Backend | Firebase Authentication, Cloud Firestore |
| Version Control | Git & GitHub |
| Backend Lang | Python  |

## Tools & Technologies

### Frontend (Flutter)
- **Flutter SDK** – Build cross-platform mobile, web, and desktop apps
- **Dart** – Programming language used by Flutter
- **VS Code / Android Studio** – Code editors with Flutter support
- **Flutter DevTools** – Debugging and performance profiling
- **Figma / Adobe XD / Canva** – UI/UX design and prototyping
- **Packages / Plugins:**
  - `http` → API calls to Python backend
  - `firebase_auth` → User authentication
  - `cloud_firestore` → Database for tasks

### Backend (Python)
- **Python 3.10+** – Backend programming language
- **SQLite / PostgreSQL** – Backend database 

### Database & Cloud Services (Firebase)
- **Firebase Authentication** – Login/signup functionality
- **Cloud Firestore** – Storing tasks, users, and dashboard data
- **Firebase Storage** – Optional: storing images/icons
- **Firebase Hosting** – Optional: host web version of TaskFlow
- **Firebase Console** – Manage backend, users, and database

### Version Control & Collaboration
- **Git** – Version control
- **GitHub / GitLab / Bitbucket** – Project repository
- **VS Code Git Integration** – Commits and branches

### Testing Tools
- **Flutter Test** – Unit and widget tests
- **pytest** – Python backend tests
- **Firebase Emulator Suite** – Simulate auth and Firestore locally



---

## 📂 Folder Structure
```text
lib/
├── core/                  # Shared/global things
│   ├── theme/             # App theme, colors
│   ├── utils/             # Helpers, formatters
│   ├── services/          # Firebase, storage, API logic
│
├── features/              # Feature-based structure (BEST PRACTICE)
│   ├── auth/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── logic/
│   │
│   ├── tasks/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── logic/
│
├── shared/                # Reusable widgets (your “components”)
│   ├── widgets/
│   │   ├── task_card.dart
│   │   ├── loading_indicator.dart
│
├── routes/                # Navigation
│   └── app_routes.dart
│
├── main.dart              # Entry point
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed  
- Firebase project setup  
- Git installed  

### Steps
1. Clone the repository:  
```bash
git clone https://github.com/princetoyi/taskflow_app.git
```

2. Navigate to the project folder:
```bash
cd taskflow_app
```
3. Install dependencies:
```bash
flutter pub get
```
4. Run the app:
```bash
flutter run
```


