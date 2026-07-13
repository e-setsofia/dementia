import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_item.dart';
import '../services/firestore_repository.dart';

/// Typed wrapper over [FirestoreRepository], scoped to one patient's
/// daily schedule subcollection.
class ScheduleRepository {
  ScheduleRepository(this.patientId)
      : _repo = FirestoreRepository<ScheduleItem>(
          collection: () => FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .collection('schedule'),
          fromMap: ScheduleItem.fromMap,
          toMap: (s) => s.toMap(),
        );

  final String patientId;
  final FirestoreRepository<ScheduleItem> _repo;

  Stream<List<ScheduleItem>> stream() => _repo.stream(orderBy: 'hour');

  Future<String> add(ScheduleItem item) => _repo.add(item);

  Future<void> update(String id, ScheduleItem item) => _repo.set(id, item);

  Future<void> delete(String id) => _repo.delete(id);
}
