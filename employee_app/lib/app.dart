import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';

class FieldServiceApp extends StatelessWidget {
  const FieldServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Service',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Switches between the login flow and the signed-in app shell based on
/// whether a JWT is currently stored — no Supabase auth-state stream
/// involved anymore.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiClient.instance.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        return isAuthenticated ? const HomeShell() : const LoginScreen();
      },
    );
  }
}
