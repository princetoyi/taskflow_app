import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService() : _firebaseAuth = FirebaseAuth.instance;

  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Unable to sign in with provided credentials.',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<User> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Unable to create account. Please try again.',
        );
      }
      await user.updateDisplayName(name);
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;
      return refreshedUser ?? user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase signup error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<String> getFirebaseIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user was found.',
      );
    }
    final token = await user.getIdToken(true);
    if (token == null) {
      throw FirebaseAuthException(
        code: 'token-null',
        message: 'Failed to retrieve authentication token.',
      );
    }
    return token;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
