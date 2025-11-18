import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_detail_page.dart';
import 'qr_scan_page.dart';
import '../widgets/exercise_selector_dialog.dart';
import '../services/database_service.dart';

/// Workouts page - shows different content based on role
class WorkoutsPage extends StatefulWidget {
  final String? userRole;
  final DocumentSnapshot? userDoc;

  const WorkoutsPage({super.key, this.userRole, this.userDoc});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
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
              content: Text('Trénink smazán'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
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
    
    // Pro naplánování tréninku
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

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

                  // Naplánovat trénink (volitelné)
                  Card(
                    color: Colors.blue.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Naplánovat trénink (volitelné)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setSheetState(() => selectedDate = date);
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today, size: 18),
                                  label: Text(
                                    selectedDate != null
                                        ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                                        : 'Vybrat datum',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: selectedDate == null ? null : () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime ?? TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setSheetState(() => selectedTime = time);
                                    }
                                  },
                                  icon: const Icon(Icons.access_time, size: 18),
                                  label: Text(
                                    selectedTime != null
                                        ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Čas',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              if (selectedDate != null)
                                IconButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedDate = null;
                                      selectedTime = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 18),
                                  tooltip: 'Zrušit datum',
                                ),
                            ],
                          ),
                          if (selectedDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Trénink bude automaticky přiřazen vybraným klientům na ${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}${selectedTime != null ? ' v ${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
                          onPressed: () async {
                            await _saveWorkout(
                              context,
                              workoutId,
                              workoutNameController.text.trim(),
                              descriptionController.text.trim(),
                              exercises,
                              int.tryParse(durationController.text) ?? 30,
                              selectedClientIds,
                              selectedDate,
                              selectedTime,
                            );
                          },
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cvik ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (exercise['name']?.toString().isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            exercise['name'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
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
                          
                          onUpdate(exercise);
                        }
                      },
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Z databáze', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showCustomExerciseDialog(
                          context,
                          exercise,
                          (customName) {
                            setSheetState(() {
                              exercise['name'] = customName;
                              exercise['exercise_id'] = null; // Vlastní cvik nemá ID z databáze
                              exercise['video_url'] = null;
                            });
                            onUpdate(exercise);
                          },
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Vlastní', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('exercise_sets_$index'),
                    initialValue: (exercise['sets'] ?? 3).toString(),
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
                  child: TextFormField(
                    key: ValueKey('exercise_reps_$index'),
                    initialValue: (exercise['reps'] ?? 10).toString(),
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
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
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

      String? createdWorkoutId;

      if (workoutId != null) {
        await FirebaseFirestore.instance.collection('workouts').doc(workoutId).update(workoutData);
        createdWorkoutId = workoutId;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trénink upraven'), backgroundColor: Colors.green),
          );
        }
      } else {
        final doc = await FirebaseFirestore.instance.collection('workouts').add(workoutData);
        createdWorkoutId = doc.id;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trénink vytvořen'), backgroundColor: Colors.green),
          );
        }
      }

      // Pokud je vybrané datum, naplánuj trénink pro každého klienta
      if (scheduledDate != null && clientIds.isNotEmpty) {
        DateTime finalDateTime = scheduledDate;
        if (scheduledTime != null) {
          finalDateTime = DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            scheduledTime.hour,
            scheduledTime.minute,
          );
        }

        for (final clientId in clientIds) {
          await DatabaseService.scheduleWorkout(
            workoutId: createdWorkoutId,
            workoutName: workoutName,
            userId: clientId,
            trainerId: currentUser!.uid,
            scheduledDate: finalDateTime,
            notes: description.isNotEmpty ? description : null,
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trénink naplánován pro ${clientIds.length} klient${clientIds.length == 1 ? 'a' : 'ů'}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCustomExerciseDialog(
    BuildContext context,
    Map<String, dynamic> exercise,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: exercise['name'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vytvořit vlastní cvik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Název cviku',
                hintText: 'např. Bench press, Dřep...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Vlastní cvik nebude propojený s databází.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              final customName = controller.text.trim();
              if (customName.isNotEmpty) {
                onSave(customName);
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
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
            colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)],
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
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
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${data['estimated_duration'] ?? 0} min',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
