import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      if (kIsWeb) {
        // For Flutter Web, we must provide FirebaseOptions explicitly.
        // We read them from the loaded .env file.
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
            authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
            projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
            storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
            messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
            appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
            measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
          ),
        );
      } else {
        // On mobile, if google-services.json/GoogleService-Info.plist are set up, 
        // initializeApp() can run without options. Otherwise, you can also pass options here.
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint("Firebase init error: $e");
    }
  }
}
