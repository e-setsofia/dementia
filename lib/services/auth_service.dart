import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Thin wrapper around FirebaseAuth plus the users/{uid} profile doc.
/// Every screen that needs to sign in, sign up, or sign out goes through
/// this one service instead of touching FirebaseAuth/Firestore directly.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

  Stream<AppUser?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(doc.id, data);
    });
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final pairingCode =
        role == UserRole.patient ? await _generateUniquePairingCode() : null;

    final profile = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      pairingCode: pairingCode,
      linkedUid: null,
    );

    await _users.doc(uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return profile;
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return fetchProfile(credential.user!.uid);
  }

  Future<void> signOut() => _auth.signOut();

  Future<String> _generateUniquePairingCode() async {
    // Avoid ambiguous characters (O/0, I/1) so a caregiver can read the
    // code off a patient's screen without confusion.
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    while (true) {
      final code =
          List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      final existing =
          await _users.where('pairingCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
  }
}
