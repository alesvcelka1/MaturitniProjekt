import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

/// 💪 Stránka pro správu databáze cviků
class ExercisesManagementPage extends StatefulWidget {
  const ExercisesManagementPage({super.key});

  @override
  State<ExercisesManagementPage> createState() => _ExercisesManagementPageState();
}

class _ExercisesManagementPageState extends State<ExercisesManagementPage> {
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, my, public
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
    setState(() => _isLoading = true);
    
    final exercises = await DatabaseService.getAllExercises();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    setState(() {
      if (_filter == 'my' && currentUser != null) {
        _exercises = exercises.where((ex) => ex['created_by'] == currentUser.uid).toList();
      } else if (_filter == 'public') {
        _exercises = exercises.where((ex) => ex['is_public'] == true).toList();
      } else {
        _exercises = exercises;
      }
      _filteredExercises = _exercises;
      _isLoading = false;
    });
    _filterExercises();
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _exercises;
      } else {
        _filteredExercises = _exercises.where((exercise) {
          final name = (exercise['name'] as String? ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hledat cvik...',
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
                fillColor: const Color(0xFFF8F9FA),
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
          
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Všechny', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Moje cviky', 'my'),
                const SizedBox(width: 8),
                _buildFilterChip('Veřejné', 'public'),
              ],
            ),
          ),
          
          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExerciseFormDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Nový cvik'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _loadExercises();
        }
      },
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Žádné cviky',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Přidej první cvik do databáze',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showExerciseFormDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Přidat cvik'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String? ?? 'Bez názvu';
    final isPublic = exercise['is_public'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showExerciseFormDialog(exercise: exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Public badge
              if (isPublic)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Veřejný',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseFormDialog({Map<String, dynamic>? exercise}) {
    final isEditing = exercise != null;
    final nameController = TextEditingController(text: exercise?['name'] ?? '');
    final videoUrlController = TextEditingController(text: exercise?['video_url'] ?? '');
    
    bool isPublic = exercise?['is_public'] ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Upravit cvik' : 'Nový cvik'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Název cviku *',
                    hintText: 'např. Dřepy, Bench press...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                
                // Video URL
                TextField(
                  controller: videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL videa (volitelné)',
                    hintText: 'https://youtube.com/watch?v=...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.videocam),
                    helperText: 'YouTube, Google Drive nebo jiný odkaz',
                  ),
                  keyboardType: TextInputType.url,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                
                // Příklady URL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Podporované zdroje:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildVideoSourceExample('YouTube', 'https://youtube.com/watch?v=abc123'),
                      _buildVideoSourceExample('YouTube Short', 'https://youtube.com/shorts/abc123'),
                      _buildVideoSourceExample('Google Drive', 'https://drive.google.com/file/d/...'),
                      _buildVideoSourceExample('Vlastní URL', 'https://example.com/video.mp4'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Public switch
                SwitchListTile(
                  title: const Text('Veřejný cvik'),
                  subtitle: const Text('Ostatní trenéři ho mohou používat'),
                  value: isPublic,
                  onChanged: (value) {
                    setDialogState(() => isPublic = value);
                  },
                  activeColor: Colors.orange,
                ),
              ],
            ),
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Smazat cvik?'),
                      content: const Text('Tato akce je nevratná.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Zrušit'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Smazat',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true && context.mounted) {
                    await DatabaseService.deleteExercise(exercise['id']);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadExercises();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Cvik smazán')),
                      );
                    }
                  }
                },
                child: const Text('Smazat', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ Vyplň název cviku')),
                  );
                  return;
                }
                
                // Validace URL
                String? videoUrl;
                if (videoUrlController.text.trim().isNotEmpty) {
                  final urlText = videoUrlController.text.trim();
                  // Kontrola, že začína http:// nebo https://
                  if (urlText.startsWith('http://') || urlText.startsWith('https://')) {
                    videoUrl = urlText;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ URL musí začínat http:// nebo https://\n(Nezadávej text "zdroj:", jen samotnou URL)'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    return;
                  }
                }
                
                try {
                  print('🔄 Ukládám cvik: ${nameController.text.trim()}');
                  
                  // Uložení do Firestore
                  final exerciseId = await DatabaseService.saveExercise(
                    exerciseId: isEditing ? exercise['id'] : null,
                    name: nameController.text.trim(),
                    videoUrl: videoUrl,
                    isPublic: isPublic,
                  );
                  
                  print('✅ Cvik uložen s ID: $exerciseId');
                  
                  // Zavři dialog
                  Navigator.of(dialogContext).pop();
                  
                  // Obnov seznam cviků
                  await _loadExercises();
                  
                  // Zobraz úspěšnou zprávu
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing ? '✅ Cvik upraven' : '✅ Cvik vytvořen',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Chyba při ukládání cviku: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Chyba: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Uložit' : 'Vytvořit'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Helper pro zobrazení příkladů video URL
  Widget _buildVideoSourceExample(String source, String example) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$source: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: example,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
