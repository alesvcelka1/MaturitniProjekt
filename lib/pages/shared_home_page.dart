import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'trainer_qr_page.dart';
import 'qr_scan_page.dart';
import 'workouts_page.dart';
import 'workout_detail_page.dart';
import 'progress_page.dart';
import 'calendar_page.dart';
import 'exercises_management_page.dart';
import 'chat_list_page.dart';
import 'chat_page.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/unread_messages_service.dart';

/// Unified home page for both trainers and clients
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
            'display_name': _currentUser.displayName ?? _currentUser.email?.split('@')[0] ?? 'Uživatel',
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
      WorkoutsPage(userRole: userRole, userDoc: userDoc),
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
    
    // Get display name from userDoc if available, otherwise from Firebase Auth
    String userName = 'Uživatel';
    if (userDoc != null && userDoc!.exists) {
      final data = userDoc!.data() as Map<String, dynamic>?;
      userName = data?['display_name'] as String? ?? user?.displayName ?? user?.email?.split('@')[0] ?? 'Uživatel';
    } else {
      userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Uživatel';
    }

    return CustomScrollView(
      slivers: [
        // Header with gradient
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            // Tlačítko pro chat s badge pro nepřečtené zprávy
            StreamBuilder<int>(
              stream: UnreadMessagesService.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          unreadCount > 0 ? Icons.forum : Icons.forum_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatListPage(),
                            ),
                          );
                        },
                        tooltip: 'Zprávy',
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 10,
                        top: 8,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
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
                                      userRole == 'trainer' ? 'Trenér' : 'Klient',
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
                          // Profilová fotka nebo ikona
                          Builder(
                            builder: (context) {
                              final photoUrl = userDoc?.exists == true 
                                  ? (userDoc!.data() as Map<String, dynamic>?)?.containsKey('photo_url') == true
                                      ? (userDoc!.data() as Map<String, dynamic>)['photo_url'] as String?
                                      : null
                                  : null;
                              
                              if (photoUrl != null && photoUrl.startsWith('data:image')) {
                                return CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  backgroundImage: MemoryImage(base64Decode(photoUrl.split(',')[1])),
                                );
                              }
                              
                              return Container(
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
                              );
                            },
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
                        const SizedBox(width: 8),
                        // Tlačítko pro zahájení chatu
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: Colors.green,
                          iconSize: 20,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  chatWithUserId: doc.id,
                                  chatWithUserName: clientName,
                                  chatWithUserRole: 'client',
                                ),
                              ),
                            );
                          },
                          tooltip: 'Zahájit chat',
                        ),
                        const SizedBox(width: 4),
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
    final currentUser = FirebaseAuth.instance.currentUser;

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
        // Motivational quote
        _buildMotivationalQuote(),
        const SizedBox(height: 16),
        
        // Today's scheduled workouts
        _buildTodayWorkouts(context, currentUser?.uid ?? ''),
        const SizedBox(height: 16),
        
        // Weekly progress
        _buildWeeklyProgress(currentUser?.uid ?? ''),
      ],
    ];
  }

  Widget _buildTodayWorkouts(BuildContext context, String userId) {
    final today = DateTime.now();
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.today, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dnešní plán',
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
                .collection('scheduled_workouts')
                .where('user_id', isEqualTo: userId)
                .where('scheduled_date', 
                    isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(today.year, today.month, today.day)))
                .where('scheduled_date',
                    isLessThan: Timestamp.fromDate(DateTime(today.year, today.month, today.day + 1)))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final workouts = snapshot.data?.docs ?? [];
              
              if (workouts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.beach_access, color: Colors.grey[400], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Žádné tréninky',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Dnes máš volno!',
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
                children: workouts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? 'scheduled';
                  final workoutName = data['workout_name'] as String? ?? 'Trénink';
                  final workoutId = data['workout_id'] as String?;
                  
                  Color statusColor;
                  IconData statusIcon;
                  String statusText;
                  
                  switch (status) {
                    case 'completed':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      statusText = 'Dokončeno';
                      break;
                    case 'cancelled':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      statusText = 'Zrušeno';
                      break;
                    default:
                      statusColor = Colors.orange;
                      statusIcon = Icons.schedule;
                      statusText = 'Naplánováno';
                  }
                  
                  return InkWell(
                    onTap: () async {
                      // Načti workout data a zobraz detail
                      if (workoutId != null) {
                        final workoutDoc = await FirebaseFirestore.instance
                            .collection('workouts')
                            .doc(workoutId)
                            .get();
                        
                        if (workoutDoc.exists && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutDetailPage(
                                workoutId: workoutId,
                                workoutData: workoutDoc.data() as Map<String, dynamic>,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 20),
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
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (status == 'scheduled')
                            Icon(Icons.arrow_forward_ios, 
                              size: 16, 
                              color: Colors.grey[400],
                            ),
                        ],
                      ),
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

  Widget _buildMotivationalQuote() {
    final quotes = [
      'Push harder than yesterday if you want a different tomorrow.',
      'The body achieves what the mind believes.',
      'Don’t stop when you’re tired. Stop when you’re done.',
      'One day or day one. You decide.',
      'Discipline is doing what needs to be done, even when you don’t feel like it.',
      'Progress, not perfection.',
      'No excuses. Just results.',
      'It’s not about being the best. It’s about being better than you were yesterday.',
    ];
    
    final today = DateTime.now();
    final quoteIndex = today.day % quotes.length;
    final quote = quotes[quoteIndex];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.deepPurple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.format_quote, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Motivace dne',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$quote"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(String userId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
    print('Načítám týdenní progress od: $sevenDaysAgo');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('completed_workouts')
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Chyba při načítání týdenního progressu: ${snapshot.error}');
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
            child: Center(
              child: Text('Chyba: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
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
            child: const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        // Filtruj na posledních 7 dní v kódu místo v dotazu
        final allWorkouts = snapshot.data?.docs ?? [];
        final workouts = allWorkouts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final completedAt = (data['completed_at'] as Timestamp?)?.toDate();
          if (completedAt == null) return false;
          return completedAt.isAfter(sevenDaysAgo);
        }).toList();
        
        final totalWorkouts = workouts.length;
        final targetWorkouts = 5; // Cíl: 5 tréninků týdně
        final progress = totalWorkouts / targetWorkouts;
        final percentage = (progress * 100).clamp(0, 100).toInt();

        print('Týdenní progress: Načteno $totalWorkouts tréninků pro uživatele $userId');
        for (var doc in workouts) {
          final data = doc.data() as Map<String, dynamic>;
          final workoutName = data['workout_name'] ?? 'Neznámý';
          final completedAt = (data['completed_at'] as Timestamp?)?.toDate();
          print('  - $workoutName (${completedAt?.toString() ?? "bez času"})');
        }

        // Počet tréninků podle dnů
        final now = DateTime.now();
        final weekData = <int, int>{};
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          weekData[day.weekday - 1] = 0;
        }

        for (var doc in workouts) {
          final data = doc.data() as Map<String, dynamic>;
          final completedAt = (data['completed_at'] as Timestamp).toDate();
          final dayIndex = completedAt.weekday - 1;
          weekData[dayIndex] = (weekData[dayIndex] ?? 0) + 1;
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.trending_up, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Týdenní progres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: progress >= 1 ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Circular progress
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalWorkouts',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: progress >= 1 ? Colors.green : Colors.orange,
                              ),
                            ),
                            Text(
                              'z $targetWorkouts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress >= 1 ? 'Skvěle!' : 'Pokračuj!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress >= 1
                              ? 'Splnil jsi týdenní cíl!'
                              : 'Ještě ${targetWorkouts - totalWorkouts} ${_getWorkoutWord(targetWorkouts - totalWorkouts)} do cíle',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildWeeklyBar(weekData),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getWorkoutWord(int count) {
    if (count == 1) return 'trénink';
    if (count >= 2 && count <= 4) return 'tréninky';
    return 'tréninků';
  }

  Widget _buildWeeklyBar(Map<int, int> weekData) {
    const dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    final maxCount = weekData.values.isEmpty ? 1 : weekData.values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final count = weekData[index] ?? 0;
        final height = maxCount > 0 ? (count / maxCount * 30).clamp(4.0, 30.0) : 4.0;
        final hasWorkout = count > 0;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: hasWorkout ? Colors.orange : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNames[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: hasWorkout ? Colors.orange : Colors.grey[500],
                    fontWeight: hasWorkout ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
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
            content: Text('Klient $email úspěšně přidán!'),
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
            content: Text('Chyba při přidávání klienta: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

///  Profile page - shared for both roles
class _ProfilePage extends StatefulWidget {
  final String? userRole;

  const _ProfilePage({this.userRole});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  String? _displayName;
  String? _photoUrl;
  String? _trainerId;
  String? _trainerName;
  bool _isLoadingProfile = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await DatabaseService.users.doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _displayName = data['display_name'] as String?;
          _photoUrl = data['photo_url'] as String?;
          _trainerId = data['trainer_id'] as String?;
          _trainerName = data['trainer_name'] as String?;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _displayName = user.displayName ?? user.email?.split('@')[0];
          _photoUrl = user.photoURL;
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Výběr zdroje fotky
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Vyberte zdroj fotky'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.orange),
                  title: const Text('Fotoaparát'),
                  onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.orange),
                  title: const Text('Galerie'),
                  onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Vybrat obrázek
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (image == null) return;

      // Načíst bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Převést na base64 string pro uložení do Firestore
      final String base64Image = base64Encode(imageBytes);
      
      // Uložit do Firestore
      await DatabaseService.users.doc(user.uid).update({
        'photo_url': 'data:image/jpeg;base64,$base64Image',
      });

      setState(() {
        _photoUrl = 'data:image/jpeg;base64,$base64Image';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilová fotka aktualizována!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při nahrávání fotky: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditNicknameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: _displayName ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Změnit přezdívku'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Přezdívka',
              border: OutlineInputBorder(),
              hintText: 'Zadej svou přezdívku',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(dialogContext).pop(newName);
                }
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        await DatabaseService.users.doc(user.uid).update({
          'display_name': result,
        });

        setState(() {
          _displayName = result;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Přezdívka aktualizována!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při ukládání: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
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
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              backgroundImage: _photoUrl != null && _photoUrl!.startsWith('data:image')
                                  ? MemoryImage(base64Decode(_photoUrl!.split(',')[1]))
                                  : null,
                              child: _photoUrl == null || !_photoUrl!.startsWith('data:image')
                                  ? Icon(
                                      widget.userRole == 'trainer' ? Icons.fitness_center : Icons.person,
                                      size: 40,
                                      color: Colors.orange,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _changeProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayName ?? user?.email?.split('@')[0] ?? 'Uživatel',
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
                        if (widget.userRole != null) ...[
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
                              widget.userRole == 'trainer' ? 'Trenér' : 'Klient',
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
                          leading: const Icon(Icons.photo_camera, color: Colors.orange),
                          title: const Text('Změnit profilovou fotku'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _changeProfilePhoto,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.orange),
                          title: const Text('Změnit přezdívku'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showEditNicknameDialog,
                        ),
                        // QR skenování pro klienty
                        if (widget.userRole == 'client') ...[
                          const Divider(),
                          ListTile(
                            leading: Icon(
                              Icons.qr_code_scanner,
                              color: _trainerId == null ? Colors.green : Colors.orange,
                            ),
                            title: Text(_trainerId == null 
                                ? 'Propojit se s trenérem' 
                                : 'Změnit trenéra'),
                            subtitle: _trainerName != null 
                                ? Text('Trenér: $_trainerName', 
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const QrScanPage()),
                              );
                              // Po návratu znovu načti profil
                              if (result == true) {
                                _loadUserProfile();
                              }
                            },
                          ),
                          // Chat s trenérem - pouze pokud je trenér připojen
                          if (_trainerId != null) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.chat_bubble, color: Colors.orange),
                              title: const Text('Napsat trenérovi'),
                              subtitle: _trainerName != null 
                                  ? Text('Chat s $_trainerName',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                                  : null,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      chatWithUserId: _trainerId!,
                                      chatWithUserName: _trainerName ?? 'Trenér',
                                      chatWithUserRole: 'trainer',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
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