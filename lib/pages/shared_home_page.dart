import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'trainer_workouts_page.dart';
import 'trainer_qr_page.dart';
import 'qr_scan_page.dart';
import 'workout_detail_page.dart';
import '../services/auth_service.dart';

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
      _DashboardPage(userRole: userRole, userDoc: userDoc),
      _WorkoutsPage(userRole: userRole, userDoc: userDoc),
      _ProgressPage(userRole: userRole),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Domů'),
                _buildNavItem(1, Icons.fitness_center_rounded, 'Tréninky'),
                _buildNavItem(2, Icons.trending_up_rounded, 'Pokrok'),
                _buildNavItem(3, Icons.person_rounded, 'Profil'),
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

  const _DashboardPage({this.userRole, this.userDoc});

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
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrainerWorkoutsPage()),
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
class _WorkoutsPage extends StatelessWidget {
  final String? userRole;
  final DocumentSnapshot? userDoc;

  const _WorkoutsPage({this.userRole, this.userDoc});

  @override
  Widget build(BuildContext context) {
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
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Správa tréninků',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vytvárej a spravuj tréninky pro své klienty',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrainerWorkoutsPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
              ),
              child: const Text('Otevřít správu tréninků'),
            ),
          ],
        ),
      ),
    ];
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
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.fitness_center, color: Colors.white),
                  ),
                  title: Text(
                    data['workout_name'] ?? 'Bez názvu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['description'] ?? 'Bez popisu',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${data['estimated_duration'] ?? 0} min',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailPage(
                          workoutId: doc.id,
                          workoutData: data,
                        ),
                      ),
                    );
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

/// 📈 Progress page - placeholder for both roles
class _ProgressPage extends StatelessWidget {
  final String? userRole;

  const _ProgressPage({this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pokrok'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Pokrok',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tato sekce bude brzy k dispozici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 👤 Profile page - shared for both roles
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