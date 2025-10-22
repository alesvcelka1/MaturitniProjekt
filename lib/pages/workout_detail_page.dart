import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

/// Detailed view of a workout for clients
class WorkoutDetailPage extends StatefulWidget {
  final String workoutId;
  final Map<String, dynamic> workoutData;

  const WorkoutDetailPage({
    super.key,
    required this.workoutId,
    required this.workoutData,
  });

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  Map<String, Map<String, dynamic>> _userPRs = {};
  bool _isLoadingPRs = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserPRs();
  }
  
  Future<void> _loadUserPRs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final prs = await DatabaseService.getAllUserPRs(currentUser.uid);
      setState(() {
        _userPRs = prs;
        _isLoadingPRs = false;
      });
    } else {
      setState(() {
        _isLoadingPRs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = List<Map<String, dynamic>>.from(widget.workoutData['exercises'] ?? []);
    final workoutName = widget.workoutData['workout_name'] ?? 'Bez názvu';
    final description = widget.workoutData['description'] ?? '';
    final estimatedDuration = widget.workoutData['estimated_duration'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(workoutName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _completeWorkout(context),
            icon: const Icon(Icons.check_circle),
            tooltip: 'Trénink dokončen',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout info header
            Container(
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
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          workoutName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.timer,
                        label: '${estimatedDuration} min',
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        icon: Icons.list,
                        label: '${exercises.length} cviků',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Exercises list
            const Text(
              'Cviky',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return _buildExerciseCard(exercise, index + 1);
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _completeWorkout(context),
          icon: const Icon(Icons.check_circle),
          label: const Text('Trénink dokončen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int number) {
    final name = exercise['name'] ?? 'Neznámý cvik';
    final sets = exercise['sets'] ?? 0;
    final reps = exercise['reps'] ?? 0;
    final load = exercise['load'] ?? '';
    final note = exercise['note'] ?? '';
    
    // Vypočítej přepočítanou váhu pokud je load v procentech
    String displayLoad = load;
    double? calculatedWeight;
    
    if (load.contains('%') && !_isLoadingPRs) {
      final normalizedName = name.toLowerCase().trim();
      final pr = _userPRs[normalizedName];
      
      if (pr != null) {
        final percentageStr = load.replaceAll('%', '').trim();
        final percentage = double.tryParse(percentageStr);
        
        if (percentage != null) {
          final prWeight = pr['weight'] as double;
          calculatedWeight = (prWeight * percentage) / 100.0;
          displayLoad = '$load (${calculatedWeight.toStringAsFixed(1)} kg)';
        }
      } else {
        // PR neexistuje
        displayLoad = '$load (PR neznámé)';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (sets > 0 && reps > 0) ...[
                  _buildDetailChip(
                    icon: Icons.repeat,
                    label: '${sets}x${reps}',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                ],
                if (load.isNotEmpty) ...[
                  Expanded(
                    child: _buildDetailChip(
                      icon: Icons.fitness_center,
                      label: displayLoad,
                      color: calculatedWeight != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _completeWorkout(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final exercises = List<Map<String, dynamic>>.from(widget.workoutData['exercises'] ?? []);
        
        await DatabaseService.saveCompletedWorkout(
          workoutId: widget.workoutId,
          workoutName: widget.workoutData['workout_name'] ?? 'Neznámý trénink',
          userId: currentUser.uid,
          durationSeconds: 0, // Bez trackingu času
          completedExercises: exercises.map((exercise) => {
            'name': exercise['name'],
            'planned_sets': exercise['sets'] ?? 1,
            'completed_sets': exercise['sets'] ?? 1, // Označíme vše jako dokončené
            'reps': exercise['reps'] ?? 0,
            'load': exercise['load'] ?? '',
          }).toList(),
        );

        if (!context.mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Trénink dokončen!'),
            content: const Text('Trénink byl úspěšně označen jako dokončený.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Go back to workout list with completion signal
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Hotovo'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při označování tréninku: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}