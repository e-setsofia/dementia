// Basic smoke test: the previous default counter-app template didn't match
// this app at all (it expected a '+' button and a numeric counter).
//
// This app initializes Firebase in main() before runApp(), so we can't pump
// MyApp() directly in a widget test without a live/emulated Firebase backend.
// Instead we smoke-test the pure-UI login screen in isolation, wrapped the
// same way MyApp wraps it, to confirm the widget tree builds and renders
// without a Firebase dependency.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders the welcome heading and login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
