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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) return LoginPage();

        return FutureBuilder<String?>(
          future: authService
              .getUserRole()
              .timeout(const Duration(seconds: 5), onTimeout: () => 'client'),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user document missing or role unresolved, default to client to avoid endless loading
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
