import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../core/utils/logger.dart';
import '../models/exercise.dart';

/// Stránka pro správu databáze cviků z Firebase Firestore
class ExercisesManagementPage extends StatefulWidget {
  const ExercisesManagementPage({super.key});

  @override
  State<ExercisesManagementPage> createState() => _ExercisesManagementPageState();
}

class _ExercisesManagementPageState extends State<ExercisesManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExerciseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Databáze cviků'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExerciseDialog,
            tooltip: 'Přidat cvik',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hledat cvik podle názvu nebo partie...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Exercise list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseService.getExercisesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'Načítání cviků z Firestore...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final exercises = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                // Filtrování
                final filteredExercises = exercises.where((exercise) {
                  if (_searchQuery.isEmpty) return true;
                  final name = (exercise['name'] as String? ?? '').toLowerCase();
                  final bodyPart = (exercise['bodyPart'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery) || bodyPart.contains(_searchQuery);
                }).toList();

                if (filteredExercises.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Results counter
                    Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredExercises.length} cviků',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Chyba při načítání',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Žádné výsledky',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Zkus jiné vyhledávání',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final name = exercise['name']?.toString() ?? 'Neznámý cvik';
    final bodyPart = exercise['bodyPart']?.toString() ?? 'Nezadáno';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showExerciseDetailDialog(exercise),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      _capitalizeWords(name),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Body part only
                    Text(
                      _capitalizeWords(bodyPart),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditExerciseDialog(Map<String, dynamic> exercise) {
    final exerciseId = exercise['id'] as String? ?? '';
    final currentName = exercise['name'] as String? ?? '';
    final currentBodyPart = exercise['bodyPart'] as String? ?? '';
    final currentGifPath = exercise['gifPath'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => _EditExerciseDialog(
        exerciseId: exerciseId,
        currentName: currentName,
        currentBodyPart: currentBodyPart,
        currentGifPath: currentGifPath,
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(String exerciseId, String exerciseName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat cvik?'),
        content: Text('Opravdu chcete smazat cvik "$exerciseName"?\n\nTato akce je nevratná.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteExercise(exerciseId, exerciseName);
    }
  }

  Future<void> _deleteExercise(String exerciseId, String exerciseName) async {
    try {
      final success = await DatabaseService.deleteExercise(exerciseId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cvik "$exerciseName" byl smazán'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        throw Exception('Nepodařilo se smazat cvik');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při mazání: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExerciseDetailDialog(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String? ?? 'Bez názvu';
    final bodyPart = exercise['bodyPart'] as String? ?? '';
    final gifPath = exercise['gifPath'] as String? ?? '';
    final exerciseId = exercise['id'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GIF náhled
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    gifPath,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _capitalizeWords(name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Body part chip
                      _buildInfoChip(
                        Icons.accessibility_new,
                        _capitalizeWords(bodyPart),
                        Colors.blue,
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditExerciseDialog(exercise);
                              },
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: const Text(
                                'Upravit',
                                style: TextStyle(color: Colors.blue),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmDialog(exerciseId, name);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Smazat',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Zavřít'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

// Dialog pro přidání nového cviku
class _AddExerciseDialog extends StatefulWidget {
  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gifPathController = TextEditingController();
  String _selectedBodyPart = 'chest';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _gifPathController.dispose();
    super.dispose();
  }

  Future<void> _submitExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final exerciseId = await DatabaseService.addExercise(
        name: _nameController.text.trim(),
        gifPath: _gifPathController.text.trim(),
        bodyPart: _selectedBodyPart,
      );

      if (exerciseId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cvik úspěšně přidán!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('Nepodařilo se přidat cvik');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Přidat nový cvik',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Název cviku
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Název cviku',
                  hintText: 'např. Bench Press',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Zadej název cviku';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GIF cesta
              TextFormField(
                controller: _gifPathController,
                decoration: const InputDecoration(
                  labelText: 'GIF cesta (volitelné)',
                  hintText: 'assets/gifs/bench_press.gif',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                  helperText: 'Nech prázdné pokud nemáš GIF soubor',
                ),
              ),
              const SizedBox(height: 16),

              // Partie těla
              DropdownButtonFormField<String>(
                value: _selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: 'Partie těla',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: BodyParts.all.map((bodyPart) {
                  return DropdownMenuItem(
                    value: bodyPart,
                    child: Text(BodyParts.getCzechName(bodyPart)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBodyPart = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Tlačítka
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Zrušit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Přidat'),
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
}

// Dialog pro úpravu cviku
class _EditExerciseDialog extends StatefulWidget {
  final String exerciseId;
  final String currentName;
  final String currentBodyPart;
  final String currentGifPath;

  const _EditExerciseDialog({
    required this.exerciseId,
    required this.currentName,
    required this.currentBodyPart,
    required this.currentGifPath,
  });

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gifPathController;
  late String _selectedBodyPart;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _gifPathController = TextEditingController(text: widget.currentGifPath);
    _selectedBodyPart = widget.currentBodyPart.isNotEmpty 
        ? widget.currentBodyPart 
        : BodyParts.chest;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gifPathController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await DatabaseService.updateExercise(
        exerciseId: widget.exerciseId,
        name: _nameController.text.trim(),
        gifPath: _gifPathController.text.trim(),
        bodyPart: _selectedBodyPart,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cvik byl úspěšně upraven'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          throw Exception('Úprava cviku selhala');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při úpravě: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Upravit cvik',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Název cviku
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Název cviku',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Zadej název cviku';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GIF cesta
              TextFormField(
                controller: _gifPathController,
                decoration: const InputDecoration(
                  labelText: 'GIF cesta (volitelné)',
                  hintText: 'assets/gifs/bench_press.gif',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                  helperText: 'Nech prázdné pokud nemáš GIF soubor',
                ),
              ),
              const SizedBox(height: 16),

              // Partie těla
              DropdownButtonFormField<String>(
                value: _selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: 'Partie těla',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: BodyParts.all.map((bodyPart) {
                  return DropdownMenuItem(
                    value: bodyPart,
                    child: Text(BodyParts.getCzechName(bodyPart)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBodyPart = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Tlačítka
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Zrušit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Uložit změny'),
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
}
