import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
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

  // Trainer statistics
  Map<String, dynamic>? _trainerStats;
  List<Map<String, dynamic>> _topClients = [];
  bool _isLoadingTrainerStats = true;

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'client') {
      _loadWorkoutStats();
      _loadPersonalRecords();
    } else if (widget.userRole == 'trainer') {
      _loadTrainerStats();
    }
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

  Future<void> _loadTrainerStats() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('Načítání statistik trenéra pro UID: ${currentUser.uid}');
        final stats = await DatabaseService.getTrainerStats(currentUser.uid);
        print('Načtené statistiky: $stats');
        final topClients = await DatabaseService.getTrainerTopClients(currentUser.uid, limit: 5);
        print('Top klienti: ${topClients.length}');
        
        if (mounted) {
          setState(() {
            _trainerStats = stats;
            _topClients = topClients;
            _isLoadingTrainerStats = false;
          });
          print('Statistiky trenéra úspěšně nastaveny');
        }
      } else {
        setState(() {
          _isLoadingTrainerStats = false;
        });
      }
    } catch (e) {
      print('Chyba při načítání statistik trenéra: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrainerStats = false;
        });
      }
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
          if (widget.userRole == 'client')
            IconButton(
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  await DatabaseService.removeDuplicateCompletedWorkouts(currentUser.uid);
                  _loadWorkoutStats();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Duplicity vyčištěny'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Vyčistit duplicity',
            ),
          IconButton(
            onPressed: () {
              if (widget.userRole == 'client') {
                _loadWorkoutStats();
                _loadPersonalRecords();
              } else if (widget.userRole == 'trainer') {
                _loadTrainerStats();
              }
            },
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
          // Weekly activity chart
          _buildWeeklyActivityChart(),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('completed_workouts')
          .where('user_id', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Chyba v grafu týdenní aktivity: ${snapshot.error}');
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('Chyba: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        // Prepare data for the last 7 days
        final now = DateTime.now();
        final weekData = <int, int>{};

        // Initialize all days with 0
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          weekData[day.weekday - 1] = 0;
        }

        // Filtruj na posledních 7 dní a počítej tréninky podle dnů
        final allWorkouts = snapshot.data?.docs ?? [];
        for (var doc in allWorkouts) {
          final data = doc.data() as Map<String, dynamic>;
          final completedAt = (data['completed_at'] as Timestamp?)?.toDate();
          if (completedAt == null) continue;
          
          // Pouze tréninky z posledních 7 dní
          if (completedAt.isAfter(sevenDaysAgo)) {
            final dayIndex = completedAt.weekday - 1;
            weekData[dayIndex] = (weekData[dayIndex] ?? 0) + 1;
          }
        }

        // Find max value for chart scaling
        final maxY = (weekData.values.isEmpty ? 0 : weekData.values.reduce((a, b) => a > b ? a : b)).toDouble();
        final chartMaxY = (maxY == 0 ? 5.0 : (maxY + 1.0));

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Týdenní aktivita',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.orange.withOpacity(0.9),
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
                          return BarTooltipItem(
                            '${dayNames[group.x.toInt()]}\n${rod.toY.toInt()} tréninků',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
                            if (value.toInt() >= 0 && value.toInt() < dayNames.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dayNames[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max || value == meta.min) {
                              return const Text('');
                            }
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (index) {
                      final value = weekData[index]?.toDouble() ?? 0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value == 0 ? 0.1 : value,
                            color: value == 0 
                                ? Colors.grey[300] 
                                : Colors.orange,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    if (_isLoadingTrainerStats) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final stats = _trainerStats ?? {
      'client_count': 0,
      'workout_count': 0,
      'weekly_completed': 0,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
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
                child: _buildTrainerStatCard(
                  'Aktivní klienti', 
                  '${stats['client_count']}', 
                  Icons.people
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrainerStatCard(
                  'Tréninky vytvořené', 
                  '${stats['workout_count']}', 
                  Icons.fitness_center
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  '${stats['weekly_completed']} tréninků',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'TENTO TÝDEN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
    if (_isLoadingTrainerStats) {
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
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    if (_topClients.isEmpty) {
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
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Zatím nemáš žádné klienty',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Přidej klienty a sleduj jejich pokrok',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

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
              Icon(Icons.group, color: Colors.orange, size: 28),
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
          ..._topClients.asMap().entries.map((entry) {
            final index = entry.key;
            final client = entry.value;
            final name = client['name'] as String;
            final count = client['completed_count'] as int;
            
            String position;
            Color color;
            
            switch (index) {
              case 0:
                position = '🥇';
                color = Colors.orange;
                break;
              case 1:
                position = '🥈';
                color = Colors.grey;
                break;
              case 2:
                position = '🥉';
                color = Colors.brown;
                break;
              default:
                position = '${index + 1}';
                color = Colors.blue;
            }
            
            return _buildClientRankingItem(
              name, 
              '$count tréninků', 
              position, 
              color
            );
          }).toList(),
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