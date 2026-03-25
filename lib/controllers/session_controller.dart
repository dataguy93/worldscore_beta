import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SessionController extends ChangeNotifier {
  SessionController({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService() {
    _authSubscription = _authService.authStateChanges().listen(_handleAuthChanged);
  }

  final AuthService _authService;
  final UserService _userService;

  StreamSubscription<User?>? _authSubscription;

  AppUser? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _authService.currentUser != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    String role = 'player',
    String? clubName,
    String? association,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signUp(email: email, password: password);
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthFailure('Failed to create user account. Please try again.');
      }

      await _userService.createUserDocument(
        uid: uid,
        email: email,
        username: username,
        firstName: firstName,
        lastName: lastName,
        role: role,
        clubName: clubName,
        association: association,
      );

      _profile = await _userService.getUserData(uid);
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (_) {
      _errorMessage = 'Unable to create account right now. Please try again.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signIn(email: email, password: password);
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthFailure('Unable to load your account. Please try again.');
      }

      _profile = await _userService.getUserData(uid);
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (_) {
      _errorMessage = 'Sign in failed. Please try again.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signOut();
      _profile = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _profile = null;
      notifyListeners();
      return;
    }

    _profile = await _userService.getUserData(firebaseUser.uid);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
