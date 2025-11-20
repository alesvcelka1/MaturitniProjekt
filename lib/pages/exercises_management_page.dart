import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../core/utils/logger.dart';

/// Stránka pro správu databáze cviků z Firebase Firestore
class ExercisesManagementPage extends StatefulWidget {
  const ExercisesManagementPage({super.key});

  @override
  State<ExercisesManagementPage> createState() => _ExercisesManagementPageState();
}

class _ExercisesManagementPageState extends State<ExercisesManagementPage> {
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      AppLogger.info('Načítám cviky z lokální databáze');
      
      // Načti lokální cviky
      final exercises = await DatabaseService.getAllExercises();
      
      if (exercises.isEmpty) {
        throw Exception('V databázi nejsou žádné cviky');
      }
      
      setState(() {
        _exercises = exercises;
        _filteredExercises = exercises;
        _isLoading = false;
      });
      
      AppLogger.success('Načteno ${_exercises.length} cviků');
    } catch (e) {
      AppLogger.error('Chyba při načítání cviků', e);
      setState(() {
        _errorMessage = 'Nepodařilo se načíst cviky.\n$e';
        _isLoading = false;
      });
    }
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _exercises;
      } else {
        _filteredExercises = _exercises.where((exercise) {
          final name = (exercise['name'] as String).toLowerCase();
          final bodyPart = (exercise['bodyPart'] as String).toLowerCase();

          return name.contains(query) || bodyPart.contains(query);
        }).toList();
      }
    });
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
            tooltip: 'Obnovit',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {}); // Přepnout UI pro zobrazení clear buttonu
              },
              decoration: InputDecoration(
                hintText: 'Hledat cvik podle názvu, partie, zařízení...',
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

          // Results counter
          if (!_isLoading && _errorMessage == null)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredExercises.length} cviků',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'Načítání cviků z databáze...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredExercises.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = _filteredExercises[index];
                              return _buildExerciseCard(exercise);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              _errorMessage ?? 'Neznámá chyba',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExercises,
              icon: const Icon(Icons.refresh),
              label: const Text('Zkusit znovu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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

              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDetailDialog(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String;
    final bodyPart = exercise['bodyPart'] as String;
    final gifPath = exercise['gifPath'] as String;

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

                      // Close button
                      SizedBox(
                        width: double.infinity,
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
