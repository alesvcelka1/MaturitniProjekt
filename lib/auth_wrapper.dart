import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/trainer_home.dart';
import 'pages/client_home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LoginPage();

        return FutureBuilder<String?>(
          future: authService.getUserRole(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = snap.data ?? 'client';
            if (role == 'trainer') {
              return const TrainerHome();
            } else {
              return const ClientHome();
            }
          },
        );
      },
    );
  }
}
