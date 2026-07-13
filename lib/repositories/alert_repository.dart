import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emergency_alert.dart';
import '../services/firestore_repository.dart';

/// Typed wrapper over [FirestoreRepository], scoped to one patient's
/// emergency alerts subcollection.
class AlertRepository {
  AlertRepository(this.patientId)
      : _repo = FirestoreRepository<EmergencyAlert>(
          collection: () => FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .collection('alerts'),
          fromMap: EmergencyAlert.fromMap,
          toMap: (a) => a.toMap(),
        );

  final String patientId;
  final FirestoreRepository<EmergencyAlert> _repo;

  Stream<List<EmergencyAlert>> stream() =>
      _repo.stream(orderBy: 'createdAt', descending: true);

  Future<void> trigger({
    required String triggeredByUid,
    String message = 'Emergency alert',
  }) {
    return _repo.add(EmergencyAlert(
      id: '',
      message: message,
      createdAt: null,
      acknowledged: false,
      triggeredByUid: triggeredByUid,
    ));
  }

  Future<void> acknowledge(String id) {
    return _repo.update(id, {
      'acknowledged': true,
      'acknowledgedAt': FieldValue.serverTimestamp(),
    });
  }
}
