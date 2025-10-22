import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

/// Progress page showing Personal Records and simple statistics
class ProgressPage extends StatefulWidget {
  final String? userRole;

  const ProgressPage({super.key, this.userRole});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // Personal Records from database
  Map<String, Map<String, dynamic>> _personalRecords = {};
  bool _isLoadingPRs = true;

  // Statistics from database
  Map<String, dynamic>? _workoutStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutStats();
    _loadPersonalRecords();
  }

  Future<void> _loadPersonalRecords() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final prs = await DatabaseService.getAllUserPRs(currentUser.uid);
        setState(() {
          _personalRecords = prs;
          _isLoadingPRs = false;
        });
      } else {
        setState(() {
          _isLoadingPRs = false;
        });
      }
    } catch (e) {
      print('Chyba při načítání PRs: $e');
      setState(() {
        _isLoadingPRs = false;
      });
    }
  }

  Future<void> _loadWorkoutStats() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final stats = await DatabaseService.getUserWorkoutStats(currentUser.uid);
        setState(() {
          _workoutStats = stats;
          _isLoadingStats = false;
        });
      } else {
        setState(() {
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Chyba při načítání statistik: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pokrok'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadWorkoutStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Obnovit statistiky',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userRole == 'client') ...[
              _buildPersonalRecordsSection(),
              const SizedBox(height: 24),
              _buildSimpleStatsSection(),
            ] else if (widget.userRole == 'trainer') ...[
              _buildTrainerStatsSection(),
              const SizedBox(height: 24),
              _buildClientOverviewSection(),
            ] else ...[
              _buildPlaceholderSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordsSection() {
    if (_isLoadingPRs) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final prList = _personalRecords.entries.toList();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Personal Records',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showAddPRDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Přidat PR',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _personalRecords.isEmpty 
              ? 'Zatím nemáš žádné Personal Records'
              : 'Tvoje nejlepší výkony',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          if (_personalRecords.isEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddPRDialog,
                icon: const Icon(Icons.add),
                label: const Text('Přidat první PR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                ),
              ),
            )
          else
            ...List.generate((prList.length / 2).ceil(), (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2).clamp(0, prList.length);
              final rowItems = prList.sublist(startIndex, endIndex);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: rowItems.map((entry) {
                    final exerciseName = entry.key;
                    final prData = entry.value;
                    final weight = prData['weight'] as double;
                    final reps = prData['reps'] as int;
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: rowItems.last.key == exerciseName ? 0 : 12,
                        ),
                        child: _buildPRCard(
                          exerciseName,
                          '${weight.toStringAsFixed(1)} kg × $reps',
                          Icons.fitness_center,
                          onTap: () => _showEditPRDialog(exerciseName, prData),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPRCard(String exercise, String record, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              record,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              exercise.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatsSection() {
    if (_isLoadingStats) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final stats = _workoutStats ?? {
      'total_workouts': 0,
      'current_streak': 0,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Statistiky',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Počet tréninků', '${stats['total_workouts']}', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Streak', '${stats['current_streak']} dní', Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple chart placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Graf týdenní aktivity',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Bude implementován příště',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddPRDialog() {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final repsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Přidat Personal Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Název cviku',
                  border: OutlineInputBorder(),
                  hintText: 'např. Bench Press',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Váha',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: 'Počet opakování',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final weight = double.tryParse(weightController.text);
                final reps = int.tryParse(repsController.text);

                if (name.isEmpty || weight == null || reps == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vyplňte všechna pole správně'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    await DatabaseService.savePersonalRecord(
                      userId: currentUser.uid,
                      exerciseName: name,
                      weight: weight,
                      reps: reps,
                    );

                    if (!mounted) return;
                    
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PR úspěšně uložen!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    _loadPersonalRecords(); // Refresh
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chyba při ukládání: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPRDialog(String exerciseName, Map<String, dynamic> prData) {
    final weightController = TextEditingController(text: (prData['weight'] as double).toStringAsFixed(1));
    final repsController = TextEditingController(text: (prData['reps'] as int).toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Upravit PR - ${exerciseName.toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Váha',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: 'Počet opakování',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                final reps = int.tryParse(repsController.text);

                if (weight == null || reps == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vyplňte pole správně'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    await DatabaseService.savePersonalRecord(
                      userId: currentUser.uid,
                      exerciseName: exerciseName,
                      weight: weight,
                      reps: reps,
                    );

                    if (!mounted) return;
                    
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PR aktualizován!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    _loadPersonalRecords(); // Refresh
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chyba při ukládání: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrainerStatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Přehled trenéra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Statistiky tvých klientů',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTrainerStatCard('Aktivní klienti', '8', Icons.people),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrainerStatCard('Tréninky vytvořené', '24', Icons.fitness_center),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrainerStatCard('Tento týden', '156 tréninků', Icons.calendar_today),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrainerStatCard('Úspěšnost', '87%', Icons.trending_up),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientOverviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group, color: Colors.indigo, size: 28),
              SizedBox(width: 12),
              Text(
                'Nejaktivnější klienti',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildClientRankingItem('Jan Novák', '12 tréninků', '🥇', Colors.orange),
          _buildClientRankingItem('Anna Svobodová', '10 tréninků', '🥈', Colors.grey),
          _buildClientRankingItem('Petr Dvořák', '8 tréninků', '🥉', Colors.brown),
          _buildClientRankingItem('Marie Nová', '6 tréninků', '4', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildClientRankingItem(String name, String count, String position, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                position,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.trending_up, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Pokrok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Přihlaste se pro zobrazení statistik',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}