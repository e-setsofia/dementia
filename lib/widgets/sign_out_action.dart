import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Shared "sign out" AppBar action, used by every top-level dashboard/gate
/// screen instead of each one wiring up FirebaseAuth.signOut() itself.
class SignOutAction extends StatelessWidget {
  const SignOutAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      onPressed: () => context.read<AuthProvider>().signOut(),
    );
  }
}
