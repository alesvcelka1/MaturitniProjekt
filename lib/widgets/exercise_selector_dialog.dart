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
          final name = (exercise['name'] as String? ?? '').toLowerCase();
          final bodyPart = (exercise['bodyPart'] as String? ?? '').toLowerCase();
          if (!name.contains(_searchQuery.toLowerCase()) &&
              !bodyPart.contains(_searchQuery.toLowerCase())) {
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
    final name = exercise['name'] as String? ?? 'Bez názvu';
    final bodyPart = exercise['bodyPart'] as String? ?? '';
    final gifPath = exercise['gifPath'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // GIF thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: gifPath.isNotEmpty
                      ? Image.asset(
                          gifPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.orange.withOpacity(0.1),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.orange,
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.orange.withOpacity(0.1),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.orange,
                            size: 32,
                          ),
                        ),
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
                    if (bodyPart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          bodyPart,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}
