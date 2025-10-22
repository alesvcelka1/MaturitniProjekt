import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// Dialog pro výběr cviku z databáze
class ExerciseSelectorDialog extends StatefulWidget {
  const ExerciseSelectorDialog({super.key});

  @override
  State<ExerciseSelectorDialog> createState() => _ExerciseSelectorDialogState();
}

class _ExerciseSelectorDialogState extends State<ExerciseSelectorDialog> {
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDifficulty;
  Set<String> _selectedMuscleGroups = {};

  final List<String> _muscleGroupOptions = [
    'hrudník',
    'záda',
    'nohy',
    'ramena',
    'biceps',
    'triceps',
    'core',
    'gluteus',
  ];

  final List<String> _difficultyOptions = [
    'začátečník',
    'středně pokročilý',
    'pokročilý',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await DatabaseService.getAllExercises();
    setState(() {
      _allExercises = exercises;
      _filteredExercises = exercises;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        // Filtr podle vyhledávání
        if (_searchQuery.isNotEmpty) {
          final name = (exercise['name'] as String).toLowerCase();
          final description = (exercise['description'] as String? ?? '').toLowerCase();
          if (!name.contains(_searchQuery.toLowerCase()) &&
              !description.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Filtr podle obtížnosti
        if (_selectedDifficulty != null &&
            exercise['difficulty'] != _selectedDifficulty) {
          return false;
        }

        // Filtr podle svalových skupin
        if (_selectedMuscleGroups.isNotEmpty) {
          final exerciseMuscles = List<String>.from(exercise['muscle_groups'] ?? []);
          if (!_selectedMuscleGroups.any((group) => exerciseMuscles.contains(group))) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vybrat cvik',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Hledat cvik...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
            const SizedBox(height: 16),

            // Filters
            Row(
              children: [
                // Difficulty filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: 'Obtížnost',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Vše')),
                      ..._difficultyOptions.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Muscle group filter button
                IconButton(
                  onPressed: _showMuscleGroupFilter,
                  icon: Badge(
                    label: Text('${_selectedMuscleGroups.length}'),
                    isLabelVisible: _selectedMuscleGroups.isNotEmpty,
                    child: const Icon(Icons.filter_list),
                  ),
                  tooltip: 'Filtr svalových skupin',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Results count
            Text(
              'Nalezeno ${_filteredExercises.length} cviků',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Exercise list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Žádné cviky nenalezeny',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Zkuste změnit filtry',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            return _buildExerciseCard(exercise);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String;
    final description = exercise['description'] as String? ?? '';
    final muscleGroups = List<String>.from(exercise['muscle_groups'] ?? []);
    final difficulty = exercise['difficulty'] as String? ?? '';
    final hasVideo = (exercise['video_url'] as String? ?? '').isNotEmpty;

    Color difficultyColor;
    switch (difficulty) {
      case 'začátečník':
        difficultyColor = Colors.green;
        break;
      case 'středně pokročilý':
        difficultyColor = Colors.orange;
        break;
      case 'pokročilý':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon or thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasVideo ? Icons.play_circle_filled : Icons.fitness_center,
                  color: hasVideo ? Colors.red : Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Difficulty chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: difficultyColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Muscle groups
                        ...muscleGroups.take(3).map((group) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              group,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showMuscleGroupFilter() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Svalové skupiny'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _muscleGroupOptions.map((group) {
                    return CheckboxListTile(
                      title: Text(group),
                      value: _selectedMuscleGroups.contains(group),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedMuscleGroups.add(group);
                          } else {
                            _selectedMuscleGroups.remove(group);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedMuscleGroups.clear();
                    });
                  },
                  child: const Text('Vymazat vše'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    setState(() {});
                    _applyFilters();
                  },
                  child: const Text('Použít'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
