import 'package:flutter/foundation.dart';
import 'supabase.dart';

/// Resolves the correct patient ID for any screen.
///
/// • For a **patient** logged in: returns their own auth UID.
/// • For a **caregiver** logged in: returns the ID of their
///   linked patient from the `caregiver_patients` table.
///
/// Usage:
///   final patientId = await PatientResolver.resolve();
class PatientResolver {
  PatientResolver._();

  /// Returns the patient UUID that the current user is acting on behalf of,
  /// or `null` if no valid link/session is found.
  static Future<String?> resolve() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // Determine role from user metadata or profiles table
      final role =
          user.userMetadata?['role'] as String? ?? await _fetchRole(user.id);

      if (role == 'patient') {
        return user.id;
      }

      if (role == 'caregiver') {
        return await _linkedPatientId(user.id);
      }

      return null;
    } catch (e) {
      debugPrint('[PatientResolver] error: $e');
      return null;
    }
  }

  /// Fetches the role from the profiles table (fallback when metadata is missing).
  static Future<String?> _fetchRole(String userId) async {
    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return data?['role'] as String?;
  }

  /// Returns the patient_id linked to [caregiverId] from `caregiver_patients`.
  /// Falls back to the first patient in the database if no explicit link exists.
  static Future<String?> _linkedPatientId(String caregiverId) async {
    // Try explicit caregiver_patients link first
    try {
      final link = await supabase
          .from('caregiver_patients')
          .select('patient_id')
          .eq('caregiver_id', caregiverId)
          .limit(1)
          .maybeSingle();

      if (link != null && link['patient_id'] != null) {
        return link['patient_id'] as String;
      }
    } catch (e) {
      // If table doesn't exist yet or query fails, fall back to first patient profile
      debugPrint('[PatientResolver] caregiver_patients query failed: $e');
    }

    try {
      // Fallback: first patient profile (works for single-patient setups)
      final patient = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'patient')
          .limit(1)
          .maybeSingle();

      return patient?['id'] as String?;
    } catch (e) {
      debugPrint('[PatientResolver] patient profiles fallback query failed: $e');
      return null;
    }
  }
}
