import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/exercise_selector_dialog.dart';

/// Stránka pro trenéry - správa tréninků přidělených klientům
class TrainerWorkoutsPage extends StatefulWidget {
  const TrainerWorkoutsPage({super.key});

  @override
  State<TrainerWorkoutsPage> createState() => _TrainerWorkoutsPageState();
}

class _TrainerWorkoutsPageState extends State<TrainerWorkoutsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Moje tréninky',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildWorkoutsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateWorkoutBottomSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nový trénink'),
      ),
    );
  }

  /// Hlavní seznam tréninků
  Widget _buildWorkoutsList() {
    if (_currentUser == null) {
      return const Center(
        child: Text(
          'Nejste přihlášeni!',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('workouts')
          .where('trainer_id', isEqualTo: _currentUser.uid)
          // Dočasně bez orderBy - vyžaduje index
          // .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Chyba při načítání: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final workouts = snapshot.data?.docs ?? [];

        if (workouts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            final data = workout.data() as Map<String, dynamic>;
            return _buildWorkoutCard(workout.id, data);
          },
        );
      },
    );
  }

  /// Prázdný stav kdy nejsou žádné tréninky
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Žádné tréninky',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vytvořte první trénink pro své klienty',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateWorkoutBottomSheet,
            icon: const Icon(Icons.add),
            label: const Text('Vytvořit trénink'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Karta pro jeden trénink
  Widget _buildWorkoutCard(String workoutId, Map<String, dynamic> data) {
    final workoutName = data['workout_name'] ?? 'Neznámý trénink';
    final description = data['description'] ?? '';
    final exercises = List<Map<String, dynamic>>.from(data['exercises'] ?? []);
    final clientIds = List<String>.from(data['client_ids'] ?? []);
    final estimatedDuration = data['estimated_duration'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header s názvem a menu
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workoutName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditWorkoutBottomSheet(workoutId, data);
                        break;
                      case 'delete':
                        _showDeleteConfirmDialog(workoutId, workoutName);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Upravit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Smazat'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cviky v tréninku
            if (exercises.isNotEmpty) ...[
              Text(
                'Cviky (${exercises.length}):',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...exercises.map((exercise) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise['name'] ?? 'Neznámý cvik',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      _formatExerciseDetails(exercise),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 12),
            ],

            // Odhadovaná doba
            if (estimatedDuration > 0) ...[
              Row(
                children: [
                  Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Doba: ${estimatedDuration} min',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Počet přidělených klientů
            Row(
              children: [
                Icon(Icons.people, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Přiděleno ${clientIds.length} klientům',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (clientIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${clientIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatExerciseDetails(Map<String, dynamic> exercise) {
    final sets = exercise['sets'] ?? 0;
    final reps = exercise['reps'] ?? 0;
    final load = exercise['load'] ?? '';
    
    List<String> parts = [];
    
    if (sets > 0 && reps > 0) {
      parts.add('${sets}x${reps}');
    }
    
    if (load.isNotEmpty) {
      parts.add(load);
    }
    
    return parts.join(' - ');
  }

  /// Bottom sheet pro vytvoření nového tréninku
  void _showCreateWorkoutBottomSheet() {
    _showWorkoutBottomSheet();
  }

  /// Bottom sheet pro editaci tréninku
  void _showEditWorkoutBottomSheet(String workoutId, Map<String, dynamic> data) {
    _showWorkoutBottomSheet(workoutId: workoutId, initialData: data);
  }

  /// Univerzální bottom sheet pro tréninky
  void _showWorkoutBottomSheet({String? workoutId, Map<String, dynamic>? initialData}) {
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

                  // Základní informace o tréninku
                  _buildTextField(
                    controller: workoutNameController,
                    label: 'Název tréninku',
                    hint: 'např. Silový trénink horní partie...',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: descriptionController,
                    label: 'Popis tréninku',
                    hint: 'Krátký popis tréninku...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: durationController,
                    label: 'Odhadovaná doba (minuty)',
                    hint: '30',
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
                              'note': '',
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
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Výběr klientů
                  _buildClientSelector(selectedClientIds, setSheetState),
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

  /// Editor pro jednotlivý cvik
  Widget _buildExerciseEditor(
    Map<String, dynamic> exercise,
    int index,
    Function(Map<String, dynamic>) onUpdate,
    VoidCallback onDelete,
  ) {
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
                      exercise['name'] = selectedExercise['name'];
                      exercise['exercise_id'] = selectedExercise['id'];
                      exercise['video_url'] = selectedExercise['video_url'];
                      exercise['instructions'] = selectedExercise['instructions'];
                      onUpdate(exercise);
                    }
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Vybrat', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('exercise_name_$index'),
              initialValue: exercise['name'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Název cviku',
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.edit, size: 18),
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
                  child: TextFormField(
                    key: ValueKey('exercise_sets_$index'),
                    initialValue: (exercise['sets'] ?? 0).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Série',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      exercise['sets'] = int.tryParse(value) ?? 0;
                      onUpdate(exercise);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('exercise_reps_$index'),
                    initialValue: (exercise['reps'] ?? 0).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Opakování',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      exercise['reps'] = int.tryParse(value) ?? 0;
                      onUpdate(exercise);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('exercise_load_$index'),
              initialValue: exercise['load'] ?? '',
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

  /// Helper pro text fieldy
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }

  /// Výběr klientů
  Widget _buildClientSelector(List<String> selectedClientIds, StateSetter setSheetState) {
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
          stream: _firestore
              .collection('users')
              .where('trainer_id', isEqualTo: _currentUser!.uid)
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

  /// Uložení tréninku
  Future<void> _saveWorkout(
    String? workoutId,
    String workoutName,
    String description,
    List<Map<String, dynamic>> exercises,
    int estimatedDuration,
    List<String> clientIds,
  ) async {
    // Validace
    if (workoutName.isEmpty) {
      _showSnackBar('Zadejte název tréninku', isError: true);
      return;
    }

    if (exercises.isEmpty) {
      _showSnackBar('Přidejte alespoň jeden cvik', isError: true);
      return;
    }

    // Ověření, že všechny cviky mají název
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i]['name']?.toString().trim().isEmpty ?? true) {
        _showSnackBar('Zadejte název pro cvik ${i + 1}', isError: true);
        return;
      }
    }

    // Uložení
    try {
      final workoutData = {
        'trainer_id': _currentUser?.uid,
        'client_ids': clientIds,
        'workout_name': workoutName,
        'description': description,
        'exercises': exercises,
        'estimated_duration': estimatedDuration,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (workoutId != null) {
        // Editace
        await _firestore.collection('workouts').doc(workoutId).update(workoutData);
        _showSnackBar('Trénink upraven');
      } else {
        // Vytvoření
        await _firestore.collection('workouts').add(workoutData);
        _showSnackBar('Trénink vytvořen');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Chyba: $e', isError: true);
    }
  }  /// Dialog pro potvrzení smazání
  void _showDeleteConfirmDialog(String workoutId, String workoutName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat trénink'),
        content: Text('Opravdu chcete smazat trénink "$workoutName"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkout(workoutId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }

  /// Smazání tréninku
  Future<void> _deleteWorkout(String workoutId) async {
    try {
      await _firestore.collection('workouts').doc(workoutId).delete();
      _showSnackBar('Trénink smazán');
    } catch (e) {
      _showSnackBar('Chyba při mazání: $e', isError: true);
    }
  }

  /// Helper pro SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}