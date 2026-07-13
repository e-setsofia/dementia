import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Links a caregiver account to a patient account via the patient's
/// pairing code. Kept as its own service rather than folded into
/// [AuthService] since linking is a distinct, one-time operation with its
/// own failure modes (invalid code, patient already linked).
class PairingService {
  PairingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Looks up the patient with [code] and links [caregiverUid] to them.
  /// Throws a [StateError] with a user-facing message if the code doesn't
  /// exist or that patient already has a linked caregiver.
  Future<void> linkByCode({
    required String code,
    required String caregiverUid,
  }) async {
    final matches = await _users
        .where('pairingCode', isEqualTo: code.trim().toUpperCase())
        .where('role', isEqualTo: UserRole.patient.name)
        .limit(1)
        .get();

    if (matches.docs.isEmpty) {
      throw StateError('No patient found with that pairing code.');
    }

    final patientDoc = matches.docs.first;
    final existingLink = patientDoc.data()['linkedUid'] as String?;
    if (existingLink != null) {
      throw StateError('That patient is already linked to a caregiver.');
    }

    final batch = _firestore.batch();
    batch.update(patientDoc.reference, {'linkedUid': caregiverUid});
    batch.update(_users.doc(caregiverUid), {'linkedUid': patientDoc.id});
    await batch.commit();
  }
}
