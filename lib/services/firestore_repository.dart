import 'package:cloud_firestore/cloud_firestore.dart';

typedef FromMap<T> = T Function(String id, Map<String, dynamic> data);
typedef ToMap<T> = Map<String, dynamic> Function(T value);

/// Generic CRUD + real-time stream wrapper around a single Firestore
/// collection. Every feature repository (medications, schedule, alerts,
/// patient info) is a thin typed instance of this class instead of
/// hand-rolled Firestore calls per screen.
class FirestoreRepository<T> {
  FirestoreRepository({
    required CollectionReference<Map<String, dynamic>> Function()
        collection,
    required this.fromMap,
    required this.toMap,
  }) : _collection = collection;

  final CollectionReference<Map<String, dynamic>> Function() _collection;
  final FromMap<T> fromMap;
  final ToMap<T> toMap;

  Stream<List<T>> stream({String? orderBy, bool descending = false}) {
    Query<Map<String, dynamic>> query = _collection();
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => fromMap(doc.id, doc.data())).toList(),
        );
  }

  Future<T?> get(String id) async {
    final doc = await _collection().doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return fromMap(doc.id, data);
  }

  Future<String> add(T value) async {
    final ref = await _collection().add(toMap(value));
    return ref.id;
  }

  Future<void> set(String id, T value) {
    return _collection().doc(id).set(toMap(value));
  }

  Future<void> update(String id, Map<String, dynamic> patch) {
    return _collection().doc(id).update(patch);
  }

  Future<void> delete(String id) {
    return _collection().doc(id).delete();
  }
}
