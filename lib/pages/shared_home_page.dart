import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'trainer_qr_page.dart';
import 'qr_scan_page.dart';
import 'workout_detail_page.dart';
import 'progress_page.dart';
import 'calendar_page.dart';
import 'exercises_management_page.dart';
import '../widgets/exercise_selector_dialog.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// 🏠 Unified home page for both trainers and clients
/// Dynamically shows features based on user role from Firestore
class SharedHomePage extends StatefulWidget {
  const SharedHomePage({super.key});

  @override
  State<SharedHomePage> createState() => _SharedHomePageState();
}

class _SharedHomePageState extends State<SharedHomePage> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Nejsi přihlášený!', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(_currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // User document doesn't exist yet - create it
          _firestore.collection('users').doc(_currentUser.uid).set({
            'email': _currentUser.email,
            'role': 'client',
            'created_at': FieldValue.serverTimestamp(),
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userDoc = snapshot.data!;
        final userData = userDoc.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] as String?;

        // If user doesn't have role, set them as 'client'
        if (userRole == null) {
          _firestore.collection('users').doc(_currentUser.uid).update({
            'role': 'client',
          });
          // Show loading until role is set
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildMainScaffold(userRole: userRole, userDoc: userDoc);
      },
    );
  }

  Widget _buildMainScaffold({String? userRole, DocumentSnapshot? userDoc}) {
    final List<Widget> pages = [
      _DashboardPage(
        userRole: userRole, 
        userDoc: userDoc,
        onNavigateToWorkouts: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      _WorkoutsPage(userRole: userRole, userDoc: userDoc),
      CalendarPage(userRole: userRole),
      ProgressPage(userRole: userRole),
      _ProfilePage(userRole: userRole),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Domů'),
                _buildNavItem(1, Icons.fitness_center_rounded, 'Tréninky'),
                _buildNavItem(2, Icons.calendar_today_rounded, 'Kalendář'),
                _buildNavItem(3, Icons.trending_up_rounded, 'Pokrok'),
                _buildNavItem(4, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.orange.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🏠 Dashboard page - main screen for both roles
class _DashboardPage extends StatelessWidget {
  final String? userRole;
  final DocumentSnapshot? userDoc;
  final VoidCallback? onNavigateToWorkouts;

  const _DashboardPage({this.userRole, this.userDoc, this.onNavigateToWorkouts});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Uživatel';

    return CustomScrollView(
      slivers: [
        // Header with gradient
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B35),
                    Color(0xFFFF8A50),
                    Color(0xFFFF9F40),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Vítej zpět',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (userRole != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      userRole == 'trainer' ? '👨‍💼 Trenér' : '💪 Klient',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              userRole == 'trainer' 
                                  ? Icons.fitness_center 
                                  : Icons.local_fire_department,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Content based on role
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (userRole == 'trainer') ..._buildTrainerDashboard(context),
              if (userRole == 'client') ..._buildClientDashboard(context, userDoc),
              if (userRole == null) ..._buildNewUserDashboard(context),
            ]),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTrainerDashboard(BuildContext context) {
    return [
      // Quick actions for trainers
      _buildActionCard(
        context,
        title: 'Správa tréninků',
        subtitle: 'Vytvoř a přiřaď tréninky svým klientům',
        icon: Icons.fitness_center,
        color: Colors.orange,
        onTap: () {
          // Přepni na tab Tréninky
          onNavigateToWorkouts?.call();
        },
      ),
      const SizedBox(height: 16),
      _buildActionCard(
        context,
        title: 'Databáze cviků',
        subtitle: 'Spravuj databázi cviků pro tréninky',
        icon: Icons.library_books,
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExercisesManagementPage()),
        ),
      ),
      const SizedBox(height: 16),
      _buildActionCard(
        context,
        title: 'Můj QR kód',
        subtitle: 'Sdílej QR kód pro propojení s klienty',
        icon: Icons.qr_code,
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrainerQrPage()),
        ),
      ),
      const SizedBox(height: 16),
      _buildActionCard(
        context,
        title: 'Přidat klienta',
        subtitle: 'Přidej klienta přímo podle emailu',
        icon: Icons.person_add,
        color: Colors.green,
        onTap: () => _showAddClientDialog(context),
      ),
      const SizedBox(height: 16),
      // Live client list
      _buildClientsSection(context),
    ];
  }

  Widget _buildClientsSection(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Moji klienti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('trainer_id', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey[400], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zatím žádní klienti',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Sdílej svůj QR kód s klienty',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final clientData = doc.data() as Map<String, dynamic>;
                  final clientEmail = clientData['email'] as String? ?? 'Neznámý klient';
                  final clientName = clientData['display_name'] as String? ?? 
                                  clientEmail.split('@')[0];
                  final connectedAt = clientData['connected_at'] as Timestamp?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.2),
                          radius: 20,
                          child: Text(
                            clientName.isNotEmpty ? clientName[0].toUpperCase() : 'K',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                clientEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (connectedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Propojen ${_formatTimestamp(connectedAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Aktivní',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'právě teď';
    } else if (difference.inHours < 1) {
      return 'před ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'před ${difference.inHours} h';
    } else {
      return 'před ${difference.inDays} dny';
    }
  }

  List<Widget> _buildClientDashboard(BuildContext context, DocumentSnapshot? userDoc) {
    final userData = userDoc?.data() as Map<String, dynamic>?;
    final trainerId = userData?['trainer_id'] as String?;

    return [
      if (trainerId == null) ...[
        // No trainer connected yet
        _buildActionCard(
          context,
          title: 'Propoj se s trenérem',
          subtitle: 'Naskenuj QR kód od svého trenéra',
          icon: Icons.qr_code_scanner,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QrScanPage()),
          ),
        ),
      ] else ...[
        // Connected to trainer
        _buildActionCard(
          context,
          title: 'Moje tréninky',
          subtitle: 'Zobraz tréninky přidělené trenérem',
          icon: Icons.fitness_center,
          color: Colors.blue,
          onTap: () {
            // Navigate to client workouts view
          },
        ),
        const SizedBox(height: 16),
        _buildStatsCard('Dokončené tréninky', '0', Icons.check_circle),
      ],
      const SizedBox(height: 16),
      _buildStatsCard('Aktivní dny', '0', Icons.calendar_today),
    ];
  }

  List<Widget> _buildNewUserDashboard(BuildContext context) {
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.waving_hand, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Vítej v Mat App!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nejsi zatím propojen s trenérem. Vyber si svou roli:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QrScanPage()),
                          ),
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Naskenovat QR\n(pro klienty)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TrainerQrPage()),
                          ),
                          icon: const Icon(
                            Icons.qr_code,
                            size: 40,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Vygenerovat QR\n(pro trenéry)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Klienti skenují QR kód trenéra pro automatické propojení',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog pro přidání klienta pomocí emailu
  void _showAddClientDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Přidat nového klienta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email klienta',
                  hintText: 'ales@gmail.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Jméno klienta (volitelné)',
                  hintText: 'Aleš Novák',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Klient bude automaticky propojen s tebou jako trenérem.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _addClientByEmail(context, emailController.text.trim(), nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Přidat klienta'),
            ),
          ],
        );
      },
    );
  }

  /// Přidá klienta podle emailu
  Future<void> _addClientByEmail(BuildContext context, String email, String name) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Zobrazíme loading s timeoutem
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Přidávám klienta...'),
          ],
        ),
      ),
    );

    // Záchranný timeout pro zavření loading dialogu
    Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ Operace trvá příliš dlouho. Zkuste to znovu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Generujeme UID pro klienta na základě emailu
      final String clientUid = 'client_${email.replaceAll('@', '_').replaceAll('.', '_')}';
      final String clientName = name.isNotEmpty ? name : email.split('@')[0];
      
      final trainerId = currentUser.uid;
      final trainerName = currentUser.displayName ?? currentUser.email ?? 'Trenér';
      
      // Kontrola, zda klient už neexistuje
      final DocumentSnapshot existingClient = await firestore
          .collection('users')
          .doc(clientUid)
          .get();
      
      if (existingClient.exists) {
        final clientData = existingClient.data() as Map<String, dynamic>?;
        final existingTrainerId = clientData?['trainer_id'] as String?;
        
        if (existingTrainerId == trainerId) {
          // Klient už je u tohoto trenéra
          if (context.mounted) {
            Navigator.of(context).pop(); // Zavřeme loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Klient $email už je u tebe přidaný!'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        } else if (existingTrainerId != null) {
          // Klient už má jiného trenéra
          if (context.mounted) {
            Navigator.of(context).pop(); // Zavřeme loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Klient $email už má jiného trenéra!'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      // Batch operace
      final WriteBatch batch = firestore.batch();
      
      // Vytvoříme/aktualizujeme dokument klienta
      final DocumentReference clientDoc = firestore.collection('users').doc(clientUid);
      batch.set(clientDoc, {
        'role': 'client',
        'email': email,
        'display_name': clientName,
        'trainer_id': trainerId,
        'trainer_name': trainerName,
        'connected_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'added_by_trainer': true, // Označíme, že byl přidaný trenérem
      }, SetOptions(merge: true));
      
      // Přidáme klienta do seznamu trenéra
      final DocumentReference trainerDoc = firestore.collection('users').doc(trainerId);
      batch.set(trainerDoc, {
        'clients': FieldValue.arrayUnion([clientUid]),
        'role': 'trainer', // Zajistíme, že trenér má správnou roli
      }, SetOptions(merge: true));
      
      // Execute batch operation
      await batch.commit();
      
      // Cancel timeout timer
      timeoutTimer.cancel();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Klient $email úspěšně přidán!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      
      // Zrušíme timeout timer
      timeoutTimer.cancel();
      
      // Zavřeme loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Zobrazíme chybu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při přidávání klienta: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

/// 💪 Workouts page - shows different content based on role
class _WorkoutsPage extends StatefulWidget {
  final String? userRole;
  final DocumentSnapshot? userDoc;

  const _WorkoutsPage({this.userRole, this.userDoc});

  @override
  State<_WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<_WorkoutsPage> {
  Set<String> _completedWorkoutIds = {};

  @override
  void initState() {
    super.initState();
    _loadCompletedWorkouts();
  }

  Future<void> _loadCompletedWorkouts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final completedIds = await DatabaseService.getUserCompletedWorkoutIds(currentUser.uid);
      setState(() {
        _completedWorkoutIds = completedIds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = widget.userRole;
    final userDoc = widget.userDoc;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tréninky'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (userRole == 'trainer') ..._buildTrainerWorkouts(context),
            if (userRole == 'client') ..._buildClientWorkouts(context, userDoc),
            if (userRole == null) ..._buildNoRoleWorkouts(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrainerWorkouts(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Chyba: Nejste přihlášeni',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ];
    }
    
    return [
      // Header with Create button
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moje tréninky',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Spravuj tréninky pro své klienty',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Create workout button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateWorkoutBottomSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Vytvořit nový trénink'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      // Workouts list
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workouts')
              .where('trainer_id', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Chyba při načítání: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final workouts = snapshot.data?.docs ?? [];

            if (workouts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Zatím nemáš žádné tréninky',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vytvoř první trénink pomocí tlačítka výše',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final doc = workouts[index];
                final data = doc.data() as Map<String, dynamic>;
                final workoutName = data['workout_name'] ?? 'Bez názvu';
                final description = data['description'] ?? '';
                final clientIds = List<String>.from(data['client_ids'] ?? []);
                final exercises = List<Map<String, dynamic>>.from(data['exercises'] ?? []);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      _showWorkoutDetailDialog(context, doc.id, data);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workoutName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (description.isNotEmpty)
                                      Text(
                                        description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.people, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${clientIds.length} klientů',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.list, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${exercises.length} cviků',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _showEditWorkoutBottomSheet(context, doc.id, data);
                                },
                                tooltip: 'Upravit',
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteWorkout(context, doc.id, workoutName),
                                tooltip: 'Smazat',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  Future<void> _deleteWorkout(BuildContext context, String workoutId, String workoutName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat trénink?'),
        content: Text('Opravdu chceš smazat trénink "$workoutName"?\n\nTato akce je nevratná.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('workouts')
            .doc(workoutId)
            .delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Trénink smazán'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCreateWorkoutBottomSheet(BuildContext context) {
    _showWorkoutBottomSheet(context);
  }

  void _showEditWorkoutBottomSheet(BuildContext context, String workoutId, Map<String, dynamic> data) {
    _showWorkoutBottomSheet(context, workoutId: workoutId, initialData: data);
  }

  void _showWorkoutBottomSheet(BuildContext context, {String? workoutId, Map<String, dynamic>? initialData}) {
    final workoutNameController = TextEditingController(text: initialData?['workout_name'] ?? '');
    final descriptionController = TextEditingController(text: initialData?['description'] ?? '');
    final durationController = TextEditingController(text: (initialData?['estimated_duration'] ?? 30).toString());
    
    List<String> selectedClientIds = List<String>.from(initialData?['client_ids'] ?? []);
    List<Map<String, dynamic>> exercises = List<Map<String, dynamic>>.from(initialData?['exercises'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    workoutId == null ? 'Nový trénink' : 'Upravit trénink',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Název tréninku
                  TextField(
                    controller: workoutNameController,
                    decoration: InputDecoration(
                      labelText: 'Název tréninku',
                      hintText: 'např. Silový trénink horní partie...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Popis
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Popis tréninku',
                      hintText: 'Krátký popis tréninku...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Odhadovaná doba
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: 'Odhadovaná doba (minuty)',
                      hintText: '30',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Cviky
                  Row(
                    children: [
                      const Text(
                        'Cviky:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            exercises.add({
                              'name': '',
                              'sets': 3,
                              'reps': 10,
                              'load': '',
                            });
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Přidat cvik'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Seznam cviků
                  ...exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    return _buildExerciseEditor(
                      context,
                      exercise,
                      index,
                      (updatedExercise) {
                        setSheetState(() {
                          exercises[index] = updatedExercise;
                        });
                      },
                      () {
                        setSheetState(() {
                          exercises.removeAt(index);
                        });
                      },
                      setSheetState,
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Výběr klientů
                  _buildClientSelector(context, selectedClientIds, setSheetState),
                  const SizedBox(height: 24),

                  // Akční tlačítka
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Zrušit'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveWorkout(
                            context,
                            workoutId,
                            workoutNameController.text.trim(),
                            descriptionController.text.trim(),
                            exercises,
                            int.tryParse(durationController.text) ?? 30,
                            selectedClientIds,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(workoutId == null ? 'Vytvořit' : 'Uložit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseEditor(
    BuildContext context,
    Map<String, dynamic> exercise,
    int index,
    Function(Map<String, dynamic>) onUpdate,
    VoidCallback onDelete,
    StateSetter setSheetState,
  ) {
    final nameController = TextEditingController(text: exercise['name'] ?? '');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cvik ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final selectedExercise = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const ExerciseSelectorDialog(),
                    );
                    
                    if (selectedExercise != null) {
                      setSheetState(() {
                        exercise['name'] = selectedExercise['name'];
                        exercise['exercise_id'] = selectedExercise['id'];
                        exercise['video_url'] = selectedExercise['video_url'];
                      });
                      
                      nameController.text = selectedExercise['name'] ?? '';
                      onUpdate(exercise);
                    }
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Vybrat', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Název cviku',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                exercise['name'] = value;
                onUpdate(exercise);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: (exercise['sets'] ?? 3).toString()),
                    decoration: const InputDecoration(
                      labelText: 'Série',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      exercise['sets'] = int.tryParse(value) ?? 3;
                      onUpdate(exercise);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: (exercise['reps'] ?? 10).toString()),
                    decoration: const InputDecoration(
                      labelText: 'Opakování',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      exercise['reps'] = int.tryParse(value) ?? 10;
                      onUpdate(exercise);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: exercise['load'] ?? ''),
              decoration: const InputDecoration(
                labelText: 'Zátěž (% z PR nebo váha)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                exercise['load'] = value;
                onUpdate(exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSelector(BuildContext context, List<String> selectedClientIds, StateSetter setSheetState) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Přidělit klientům:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('trainer_id', isEqualTo: currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final clients = snapshot.data!.docs;
            
            if (clients.isEmpty) {
              return Text(
                'Nemáte žádné klienty',
                style: TextStyle(color: Colors.grey[600]),
              );
            }

            return Wrap(
              spacing: 8,
              children: clients.map((client) {
                final clientData = client.data() as Map<String, dynamic>;
                final clientId = client.id;
                final displayName = clientData['display_name'] ?? clientData['email'] ?? 'Neznámý';
                final isSelected = selectedClientIds.contains(clientId);

                return FilterChip(
                  label: Text(displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setSheetState(() {
                      if (selected) {
                        selectedClientIds.add(clientId);
                      } else {
                        selectedClientIds.remove(clientId);
                      }
                    });
                  },
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveWorkout(
    BuildContext context,
    String? workoutId,
    String workoutName,
    String description,
    List<Map<String, dynamic>> exercises,
    int estimatedDuration,
    List<String> clientIds,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (workoutName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadejte název tréninku'), backgroundColor: Colors.red),
      );
      return;
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Přidejte alespoň jeden cvik'), backgroundColor: Colors.red),
      );
      return;
    }

    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i]['name']?.toString().trim().isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zadejte název pro cvik ${i + 1}'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    try {
      final workoutData = {
        'trainer_id': currentUser?.uid,
        'client_ids': clientIds,
        'workout_name': workoutName,
        'description': description,
        'exercises': exercises,
        'estimated_duration': estimatedDuration,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (workoutId != null) {
        await FirebaseFirestore.instance.collection('workouts').doc(workoutId).update(workoutData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Trénink upraven'), backgroundColor: Colors.green),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('workouts').add(workoutData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Trénink vytvořen'), backgroundColor: Colors.green),
          );
        }
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showWorkoutDetailDialog(BuildContext context, String workoutId, Map<String, dynamic> data) {
    final workoutName = data['workout_name'] ?? 'Bez názvu';
    final description = data['description'] ?? '';
    final estimatedDuration = data['estimated_duration'] ?? 0;
    final exercises = List<Map<String, dynamic>>.from(data['exercises'] ?? []);
    final clientIds = List<String>.from(data['client_ids'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.fitness_center, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                workoutName,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty) ...[
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
              ],
              
              // Stats
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$estimatedDuration min'),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${clientIds.length} klientů'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Exercises
              const Text(
                'Cviky:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                final name = exercise['name'] ?? 'Bez názvu';
                final sets = exercise['sets'] ?? 0;
                final reps = exercise['reps'] ?? 0;
                final load = exercise['load'] ?? '';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${sets}x${reps}${load.isNotEmpty ? " • $load" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zavřít'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditWorkoutBottomSheet(context, workoutId, data);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Upravit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClientWorkouts(BuildContext context, DocumentSnapshot? userDoc) {
    final userData = userDoc?.data() as Map<String, dynamic>?;
    final trainerId = userData?['trainer_id'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (trainerId == null) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Zatím nejsi propojený s trenérem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pro zobrazení tréninků se nejdříve propoj s trenérem pomocí QR kódu',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QrScanPage()),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Naskenovat QR kód'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (currentUserId == null) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Chyba: Nejste přihlášeni',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ];
    }

    return [
      // Header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.indigo],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moje tréninky',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tréninky přidělené tvým trenérem',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Workouts assigned to current user
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workouts')
            .where('client_ids', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Chyba při načítání: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final workouts = snapshot.data?.docs ?? [];
          
          if (workouts.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Zatím nemáš žádné tréninky',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trenér ti zatím nepřidal žádné tréninky',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: workouts.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final workoutId = doc.id;
              final isCompleted = _completedWorkoutIds.contains(workoutId);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green : Colors.orange,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.fitness_center,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['workout_name'] ?? 'Bez názvu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Dokončen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    data['description'] ?? 'Bez popisu',
                    style: TextStyle(
                      color: isCompleted ? Colors.grey : null,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${data['estimated_duration'] ?? 0} min',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      Text(
                        '${(data['exercises'] as List?)?.length ?? 0} cviků',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailPage(
                          workoutId: doc.id,
                          workoutData: data,
                        ),
                      ),
                    );
                    
                    // Pokud se trénink dokončil, aktualizuj completion status
                    if (result == true) {
                      _loadCompletedWorkouts();
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    ];
  }

  List<Widget> _buildNoRoleWorkouts(BuildContext context) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            const Text(
              'Určete svou roli',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pro zobrazení tréninků se nejdříve připojte jako klient nebo trenér',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ];
  }
}

///  Profile page - shared for both roles
class _ProfilePage extends StatelessWidget {
  final String? userRole;

  const _ProfilePage({this.userRole});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: Icon(
                      userRole == 'trainer' ? Icons.fitness_center : Icons.person,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? user?.email?.split('@')[0] ?? 'Uživatel',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (userRole != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRole == 'trainer' ? 'Trenér' : 'Klient',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('Nastavení'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help, color: Colors.grey),
                    title: const Text('Nápověda'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to help
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Odhlásit se', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await authService.signOut();
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