import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../data/user_data.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserData _userData = UserData();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Listen to auth state changes
  Stream<User?> get userChanges => _auth.userChanges();

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('User registration failed. Please try again.');
      }

      final appUser = AppUser(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        status: 'active',
        createdAt: DateTime.now(),
      );

      await _userData.createUser(appUser);
      await sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Send verification email
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Reload user to get updated email verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while sending reset email.',
      );
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // map FirebaseAuthException to user-friendly messages
  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('That email is already registered.');
      case 'invalid-email':
        return Exception('That email address is invalid.');
      case 'weak-password':
        return Exception('Password is too weak.');
      case 'operation-not-allowed':
        return Exception('Email/password accounts are not enabled.');
      case 'user-not-found':
        return Exception('No account found for that email.');
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Incorrect email or password.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception(e.message ?? 'Authentication error occurred.');
    }
  }
}
