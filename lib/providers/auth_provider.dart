import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Single source of truth for "who is signed in and which patient record
/// should this session read/write." Every screen reads currentUser and
/// patientId from here instead of re-deriving auth state itself.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : authService = authService ?? AuthService() {
    _authSub = this.authService.authStateChanges.listen(_onFirebaseUserChanged);
  }

  final AuthService authService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AppUser? currentUser;
  bool isLoading = true;

  /// The patient record this session should read/write: the user's own uid
  /// if they're a patient, or their linked patient's uid if they're a
  /// caregiver. Null until a profile is loaded and (for caregivers) linked.
  String? get patientId {
    final user = currentUser;
    if (user == null) return null;
    return user.role == UserRole.patient ? user.uid : user.linkedUid;
  }

  bool get isSignedIn => currentUser != null;
  bool get isLinked => patientId != null;

  void _onFirebaseUserChanged(User? firebaseUser) {
    _profileSub?.cancel();

    if (firebaseUser == null) {
      currentUser = null;
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    _profileSub = authService.profileStream(firebaseUser.uid).listen((profile) {
      currentUser = profile;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signOut() => authService.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
