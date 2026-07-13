import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.acknowledged,
    required this.triggeredByUid,
    this.acknowledgedAt,
  });

  final String id;
  final String message;
  final DateTime? createdAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final String triggeredByUid;

  factory EmergencyAlert.fromMap(String id, Map<String, dynamic> data) {
    return EmergencyAlert(
      id: id,
      message: data['message'] as String? ?? 'Emergency alert',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      acknowledged: data['acknowledged'] as bool? ?? false,
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      triggeredByUid: data['triggeredByUid'] as String? ?? '',
    );
  }

  /// Only used when creating a new alert via [FirestoreRepository.add];
  /// updates (e.g. acknowledging) go through targeted patch maps so they
  /// never touch createdAt.
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'acknowledged': acknowledged,
      'triggeredByUid': triggeredByUid,
    };
  }
}
