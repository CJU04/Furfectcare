import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth/auth_service.dart';
import '../services/firestore/user_service.dart';
import '../models/user_role.dart';
import '../utils/auth_error_mapper.dart';
export '../models/user_role.dart';
import 'firebase_user_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  final FirebaseUserProvider _firebaseUserProvider;

  AuthProvider({
    AuthService? authService,
    UserService? userService,
    FirebaseUserProvider? firebaseUserProvider,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService(),
        _firebaseUserProvider = firebaseUserProvider ?? FirebaseUserProvider();

  User? firebaseUser;
  UserRole? role;
  String? displayName;

  bool isLoading = false;
  String? errorMessage;

  bool get isSignedIn => firebaseUser != null;

  Future<void> syncCurrentUser() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        role = null;
        displayName = null;
        return;
      }
      role = await _userService.getUserRole(firebaseUser!.uid);
      displayName = await _userService.getUserName(firebaseUser!.uid);
    } catch (e) {
      debugPrint('Auth sync error: ${AuthErrorMapper.debugDetail(e)}');
      errorMessage = 'Unable to load your profile. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailPassword(
          email: email, password: password);
      firebaseUser = _authService.currentUser;

      if (firebaseUser != null) {
        role = await _userService.getUserRole(firebaseUser!.uid);
        displayName = await _userService.getUserName(firebaseUser!.uid);
        try {
          await _firebaseUserProvider
              .syncCurrentFirebaseUser(firebaseUser!.uid);
        } catch (e) {
          // Profile sync is best-effort; login should still succeed.
        }
      }
    } catch (e) {
      debugPrint('Sign-in error: ${AuthErrorMapper.debugDetail(e)}');
      errorMessage = AuthErrorMapper.friendlyMessage(
        e,
        fallback:
            'We couldn\'t sign you in. Please check your details and try again.',
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? contactNumber,
    String? address,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerWithEmailPassword(
          email: email, password: password);
      final uid = _authService.currentUser?.uid;

      if (uid == null) {
        throw Exception('User UID not found after registration.');
      }

      await _userService.createUserProfile(
        uid: uid,
        name: name,
        email: email,
        role: role,
        contactNumber: contactNumber,
        address: address,
      );

      firebaseUser = _authService.currentUser;
      this.role = role;
      displayName = name;
      if (firebaseUser != null) {
        await _firebaseUserProvider.syncCurrentFirebaseUser(firebaseUser!.uid);
      }
    } catch (e) {
      debugPrint('Registration error: ${AuthErrorMapper.debugDetail(e)}');
      errorMessage = AuthErrorMapper.friendlyMessage(
        e,
        fallback: 'We couldn\'t create your account. Please try again.',
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Reset error: ${AuthErrorMapper.debugDetail(e)}');
      errorMessage = AuthErrorMapper.friendlyMessage(
        e,
        fallback:
            'We couldn\'t send the password reset email. Please try again.',
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      firebaseUser = null;
      role = null;
      displayName = null;
    } catch (e) {
      debugPrint('Sign-out error: ${AuthErrorMapper.debugDetail(e)}');
      errorMessage = 'We couldn\'t sign you out. Please try again.';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
