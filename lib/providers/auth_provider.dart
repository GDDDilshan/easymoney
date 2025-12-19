import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.currentUser != null;

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await loadUserData(user.uid);
    }
  }

  Future<void> loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (credential?.user != null) {
        await loadUserData(credential!.user!.uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        await loadUserData(credential!.user!.uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  // ============ PASSWORD RESET ============
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ CHANGE PASSWORD ============
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _authService.updateUserData(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}
