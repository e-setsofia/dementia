import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_info.dart';
import '../services/firestore_repository.dart';

/// [PatientInfo] is a singleton document per patient (not a list), so this
/// wraps get/set on `patients/{patientId}` directly instead of a stream over
/// a collection of many docs. Same generic repository class underneath,
/// different access shape, still zero hand-rolled Firestore calls.
class PatientInfoRepository {
  PatientInfoRepository()
      : _repo = FirestoreRepository<PatientInfo>(
          collection: () => FirebaseFirestore.instance.collection('patients'),
          fromMap: PatientInfo.fromMap,
          toMap: (p) => p.toMap(),
        );

  final FirestoreRepository<PatientInfo> _repo;

  Stream<PatientInfo> stream(String patientId) {
    return FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      return data == null
          ? const PatientInfo()
          : PatientInfo.fromMap(doc.id, data);
    });
  }

  Future<void> save(String patientId, PatientInfo info) =>
      _repo.set(patientId, info);
}
