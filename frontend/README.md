# TaskFlow - Flutter Authentication App

A production-ready Flutter application implementing complete authentication with Firebase and FastAPI backend.

## Features

- **Firebase Authentication**: Email/password signup and login
- **JWT Token Management**: Secure token storage and API authentication
- **Clean Architecture**: Feature-first architecture with BLoC pattern
- **Route Protection**: Automatic redirects based on authentication state
- **Error Handling**: Comprehensive error handling and user feedback
- **Secure Storage**: JWT tokens stored securely using flutter_secure_storage

## Tech Stack

- **Frontend**: Flutter, BLoC, Go Router, Dio
- **Backend**: FastAPI (assumed running on http://10.0.2.2:8000)
- **Authentication**: Firebase Auth + JWT
- **Storage**: Flutter Secure Storage

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (>=3.0.0)
- Firebase project
- Android Studio / Xcode for mobile development

### 2. Clone and Install Dependencies

```bash
git clone <repository-url>
cd taskflow_app
flutter pub get
```

### 3. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication with Email/Password provider
3. Generate Firebase configuration:

```bash
flutterfire configure
```

This will generate `firebase_options.dart` and update your Firebase configuration.

### 4. Environment Configuration

Update the `.env` file with your backend URL:

```
BASE_URL=http://10.0.2.2:8000
```

### 5. Backend Setup

Ensure your FastAPI backend is running and exposes these endpoints:

- `POST /auth/signup` - User registration
- `POST /auth/login` - User login
- `POST /auth/verify-token` - Token verification
- `POST /auth/logout` - User logout

### 6. Run the Application

```bash
flutter run
```

### 7. Web Support

To enable and run the web version of the app:

```bash
flutter config --enable-web
flutter pub get
flutter run -d chrome --web-renderer html
```

If you need to use Edge for web debugging, use:

```bash
flutter run -d edge --web-renderer html
```

## Troubleshooting

- Run `flutter clean` and `flutter pub get` if the build cache is corrupted.
- If web devices do not appear, run `flutter config --enable-web` and then `flutter devices`.
- If the Flutter SDK is out of date, update using `flutter upgrade`.
- For Edge rendering issues, use `--web-renderer html`.

## Architecture Overview

```
lib/
├── core/                          # Core functionality
│   ├── constants/                 # App constants
│   ├── errors/                    # Custom exceptions
│   ├── network/                   # API and interceptors
│   ├── services/                  # Storage, connectivity, logging
│   ├── theme/                     # App theming
│   ├── utils/                     # Validators, helpers
│   └── dependency_injection/      # Service locator setup
├── features/
│   └── auth/                      # Authentication feature
│       ├── data/                  # Data layer
│       │   ├── models/            # Data models
│       │   ├── repositories/      # Repository implementations
│       │   └── services/          # External service integrations
│       ├── domain/                # Domain entities
│       └── presentation/          # Presentation layer
│           ├── bloc/              # BLoC pattern implementation
│           ├── screens/           # UI screens
│           └── widgets/           # Reusable widgets
├── routes/                        # App routing
├── firebase_options.dart          # Firebase configuration
└── main.dart                      # App entry point
```

## Authentication Flow

1. **Signup/Login**: User authenticates with Firebase
2. **Token Exchange**: Firebase ID token sent to backend
3. **JWT Storage**: Backend returns JWT, stored securely
4. **API Requests**: JWT automatically attached to requests
5. **Session Management**: Automatic logout on token expiry

## Key Components

- **AuthBloc**: Manages authentication state
- **AuthRepository**: Handles business logic and data flow
- **AuthService**: Firebase authentication wrapper
- **ApiService**: HTTP client with interceptors
- **StorageService**: Secure token storage
- **AppRouter**: Route protection and navigation

## Security Features

- JWT tokens stored in encrypted storage
- Automatic token refresh handling
- Secure API request interception
- Route guards for protected pages
- Comprehensive error handling

## Development Notes

- Uses null safety throughout
- Follows SOLID principles
- Implements clean architecture
- Production-ready error handling
- Responsive UI design

## Backend Integration

The app expects a FastAPI backend with JWT authentication. The backend should:

1. Verify Firebase ID tokens
2. Issue application JWT tokens
3. Validate JWT tokens on protected routes
4. Handle user registration/login

See the backend folder for API specifications.