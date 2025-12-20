import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        // Update display name in Firebase Auth
        await credential.user!.updateDisplayName(displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password - PROPER VERSION that verifies email exists
  Future<void> resetPassword(String email) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();

      // Validation
      if (trimmedEmail.isEmpty) {
        throw Exception('Please enter an email address.');
      }

      if (!_isValidEmail(trimmedEmail)) {
        throw Exception('Please enter a valid email address.');
      }

      debugPrint('=== Password Reset Debug ===');
      debugPrint('Checking if email exists: $trimmedEmail');

      // Step 1: Check if user exists in Firestore by querying all users
      // This is the ONLY way to verify email exists in Auth
      bool userExists = false;
      try {
        final userSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: trimmedEmail)
            .limit(1)
            .get();

        userExists = userSnapshot.docs.isNotEmpty;
        debugPrint('Firestore query result: User exists = $userExists');
      } catch (firestoreError) {
        // If Firestore query fails due to permissions, try alternate method
        debugPrint('⚠️ Firestore query failed: $firestoreError');
        // Continue with direct sendPasswordResetEmail anyway
      }

      // Step 2: If we confirmed user doesn't exist, throw error
      if (!userExists) {
        debugPrint('❌ User not found in Firestore');
        throw Exception(
          'No account found with this email address. Please check the email and try again, or sign up for a new account.',
        );
      }

      // Step 3: Send password reset email
      debugPrint('✅ User found, sending password reset email...');
      try {
        await _auth.sendPasswordResetEmail(email: trimmedEmail);
        debugPrint('✅ Password reset email sent successfully');
      } catch (authError) {
        debugPrint('❌ Error sending reset email: $authError');
        if (authError is FirebaseAuthException) {
          if (authError.code == 'user-not-found') {
            throw Exception(
              'No account found with this email address. Please check the email and try again, or sign up for a new account.',
            );
          } else if (authError.code == 'invalid-email') {
            throw Exception('Please enter a valid email address.');
          } else if (authError.code == 'too-many-requests') {
            throw Exception(
              'Too many password reset requests. Please try again later.',
            );
          }
        }
        throw Exception(
          'Unable to send password reset email. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Password reset exception: $e');
      rethrow;
    }
  }

  // Helper method to validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .update(userModel.toMap());
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently logged in';
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        throw 'New password is too weak. Please use a stronger password.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error changing password: ${e.toString()}';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
