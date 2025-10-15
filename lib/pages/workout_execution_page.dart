import 'package:flutter/material.dart';
import 'dart:async';

/// Page for executing a workout with timer and progress tracking
class WorkoutExecutionPage extends StatefulWidget {
  final String workoutId;
  final Map<String, dynamic> workoutData;

  const WorkoutExecutionPage({
    super.key,
    required this.workoutId,
    required this.workoutData,
  });

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isPaused = true;
  
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _restSeconds = 0;
  final int _restDuration = 60; // 60 seconds rest between sets
  
  late List<Map<String, dynamic>> _exercises;
  late List<List<bool>> _completedSets; // Track completed sets for each exercise

  @override
  void initState() {
    super.initState();
    _exercises = List<Map<String, dynamic>>.from(widget.workoutData['exercises'] ?? []);
    _initializeProgress();
  }

  void _initializeProgress() {
    _completedSets = _exercises.map((exercise) {
      final sets = exercise['sets'] ?? 1;
      return List<bool>.filled(sets, false);
    }).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer?.isActive == true) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isResting) {
          _restSeconds++;
          if (_restSeconds >= _restDuration) {
            _stopRest();
          }
        } else {
          _elapsedSeconds++;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
    _startTimer();
  }

  void _completeSet() {
    if (_currentExerciseIndex >= _exercises.length) return;
    
    final exercise = _exercises[_currentExerciseIndex];
    final totalSets = exercise['sets'] ?? 1;
    
    setState(() {
      _completedSets[_currentExerciseIndex][_currentSet - 1] = true;
      
      if (_currentSet < totalSets) {
        // Start rest between sets
        _startRest();
        _currentSet++;
      } else {
        // Move to next exercise
        _nextExercise();
      }
    });
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _restSeconds = 0;
    });
  }

  void _stopRest() {
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
    } else {
      _finishWorkout();
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Trénink dokončen!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gratulujeme k dokončení tréninku!'),
            const SizedBox(height: 16),
            Text('Celkový čas: ${_formatTime(_elapsedSeconds)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to workout detail
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Hotovo'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chyba')),
        body: const Center(child: Text('Žádné cviky k provedení')),
      );
    }

    final currentExercise = _exercises[_currentExerciseIndex];
    final exerciseName = currentExercise['name'] ?? 'Neznámý cvik';
    final totalSets = currentExercise['sets'] ?? 1;
    final reps = currentExercise['reps'] ?? 0;
    final load = currentExercise['load'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Trénink - ${widget.workoutData['workout_name']}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isPaused ? _resumeTimer : _pauseTimer,
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Timer and progress
            Container(
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
                children: [
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Cvik ${_currentExerciseIndex + 1} z ${_exercises.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentExerciseIndex + 1) / _exercises.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current exercise info
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    if (_isResting) ...[
                      const Icon(Icons.pause_circle, size: 80, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'Odpočinek',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_restDuration - _restSeconds}s',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.fitness_center, size: 80, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        exerciseName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoItem('Série', '$_currentSet/$totalSets'),
                          if (reps > 0) _buildInfoItem('Opakování', '$reps'),
                          if (load.isNotEmpty) _buildInfoItem('Zátěž', load),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Sets progress
                      const Text('Dokončené série:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalSets, (index) {
                          final isCompleted = _completedSets[_currentExerciseIndex][index];
                          final isCurrent = index == _currentSet - 1 && !_isResting;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? Colors.green 
                                  : isCurrent 
                                      ? Colors.orange 
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCompleted || isCurrent ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (!_isResting) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentSet < totalSets ? 'Dokončit sérii' : 'Dokončit cvik',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _nextExercise,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Přeskočit cvik'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _stopRest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ukončit odpočinek',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}