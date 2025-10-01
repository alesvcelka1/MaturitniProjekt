import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitness App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
            tooltip: 'Odhlásit se',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vítej zpět!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jsi přihlášen jako: ${user?.displayName ?? user?.email ?? 'Uživatel'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Dnešní aktivity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ActivityCard(
                    title: 'Tréninky',
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Navigace na tréninky
                    },
                  ),
                  _ActivityCard(
                    title: 'Statistiky',
                    icon: Icons.analytics,
                    color: Colors.green,
                    onTap: () {
                      // TODO: Navigace na statistiky
                    },
                  ),
                  _ActivityCard(
                    title: 'Výzvy',
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Navigace na výzvy
                    },
                  ),
                  _ActivityCard(
                    title: 'Profil',
                    icon: Icons.person,
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navigace na profil
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}