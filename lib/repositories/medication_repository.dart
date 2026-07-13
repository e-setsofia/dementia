import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication.dart';
import '../services/firestore_repository.dart';

/// Typed wrapper over [FirestoreRepository], scoped to one patient's
/// medications subcollection.
class MedicationRepository {
  MedicationRepository(this.patientId)
      : _repo = FirestoreRepository<Medication>(
          collection: () => FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .collection('medications'),
          fromMap: Medication.fromMap,
          toMap: (m) => m.toMap(),
        );

  final String patientId;
  final FirestoreRepository<Medication> _repo;

  Stream<List<Medication>> stream() => _repo.stream(orderBy: 'hour');

  Future<String> add(Medication medication) => _repo.add(medication);

  Future<void> update(String id, Medication medication) =>
      _repo.set(id, medication);

  Future<void> delete(String id) => _repo.delete(id);
}
