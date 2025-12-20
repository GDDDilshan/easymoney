import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;
  String _selectedCurrency = AppConstants.defaultCurrency;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.currentUser != null;
  String get selectedCurrency => _selectedCurrency;

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
      if (_userModel != null) {
        _selectedCurrency = _userModel!.currencyPreference;
      }
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
    _selectedCurrency = AppConstants.defaultCurrency;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

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
      _selectedCurrency = updatedUser.currencyPreference;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update currency preference
  Future<void> updateCurrency(String newCurrency) async {
    if (_userModel != null) {
      final updatedUser = _userModel!.copyWith(
        currencyPreference: newCurrency,
      );
      await updateUserProfile(updatedUser);
    }
  }

  // Get current selected currency
  String getCurrency() {
    return _selectedCurrency;
  }
}
