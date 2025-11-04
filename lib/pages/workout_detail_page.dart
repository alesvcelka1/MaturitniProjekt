import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isCompleted = false;
  bool _isCheckingCompletion = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserPRs();
    _checkIfCompleted();
  }
  
  Future<void> _checkIfCompleted() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final completed = await DatabaseService.isWorkoutCompleted(currentUser.uid, widget.workoutId);
      setState(() {
        _isCompleted = completed;
        _isCheckingCompletion = false;
      });
    } else {
      setState(() {
        _isCheckingCompletion = false;
      });
    }
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
          if (!_isCompleted && !_isCheckingCompletion)
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
      bottomNavigationBar: _isCompleted 
        ? Container(
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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Trénink dokončen',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container(
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
    final videoUrl = exercise['video_url'] as String?;
    
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
            // Video button
            if (videoUrl != null && videoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openVideo(videoUrl),
                  icon: const Icon(Icons.play_circle_filled),
                  label: const Text('Přehrát video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nepodařilo se otevřít video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF66BB6A),
                    Color(0xFF81C784),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated success icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '🎉 Skvělá práce!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Trénink byl úspěšně dokončen',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${exercises.length} cviků splněno',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(true); // Go back to workout list
                          },
                          icon: const Icon(Icons.home),
                          label: const Text(
                            'Zpět',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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