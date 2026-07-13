enum UserRole { patient, caregiver }

UserRole userRoleFromString(String value) => UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.patient,
    );

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.pairingCode,
    this.linkedUid,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  /// Only set for patients, shared with a caregiver to link accounts.
  final String? pairingCode;

  /// Caregiver's uid (if this user is a patient) or patient's uid (if this
  /// user is a caregiver). Null until pairing completes.
  final String? linkedUid;

  bool get isLinked => linkedUid != null;

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      uid: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: userRoleFromString(data['role'] as String? ?? 'patient'),
      pairingCode: data['pairingCode'] as String?,
      linkedUid: data['linkedUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'pairingCode': pairingCode,
      'linkedUid': linkedUid,
    };
  }
}
