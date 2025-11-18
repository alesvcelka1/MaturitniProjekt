import 'dart:convert';
import 'package:http/http.dart' as http;

/// Služba pro komunikaci s ExerciseDB API
/// API dokumentace: https://exercisedb-api.vercel.app/
class ExerciseDBService {
  // Základní URL pro API
  static const String _baseUrl = 'https://exercisedb-api.vercel.app';
  
  // Timeout pro HTTP požadavky
  static const Duration _timeout = Duration(seconds: 15);

  /// Načte všechny dostupné cviky z API (s podporou paginace)
  /// 
  /// Vrací: List<Map<String, dynamic>> - seznam všech cviků
  /// Vyvolá: Exception pokud dojde k chybě při načítání
  /// 
  /// Příklad použití:
  /// ```dart
  /// final exercises = await ExerciseDBService.getAllExercises();
  /// print('Načteno ${exercises.length} cviků');
  /// ```
  static Future<List<Map<String, dynamic>>> getAllExercises() async {
    try {
      print('Načítám všechny cviky z ExerciseDB API...');
      
      List<Map<String, dynamic>> allExercises = [];
      int offset = 0;
      const int limit = 100; // Počet cviků na stránku
      bool hasMore = true;
      
      while (hasMore) {
        // HTTP GET požadavek s paginací
        final url = '$_baseUrl/api/v1/exercises?offset=$offset&limit=$limit';
        print('Načítám stránku: offset=$offset, limit=$limit');
        
        final response = await http
            .get(Uri.parse(url))
            .timeout(_timeout);

        // Kontrola HTTP status code
        if (response.statusCode == 200) {
          // Dekódování JSON odpovědi
          final data = json.decode(response.body);
          
          // API vrací objekt s klíčem 'data' obsahujícím pole cviků
          if (data is Map && data.containsKey('data')) {
            final exercises = List<Map<String, dynamic>>.from(data['data']);
            
            if (exercises.isEmpty) {
              hasMore = false;
            } else {
              allExercises.addAll(exercises);
              print('Načteno ${exercises.length} cviků, celkem: ${allExercises.length}');
              offset += limit;
              
              // Pokud jsme dostali méně než limit, už nejsou další data
              if (exercises.length < limit) {
                hasMore = false;
              }
            }
          } else {
            throw Exception('Neočekávaný formát odpovědi z API');
          }
        } else {
          throw Exception('HTTP chyba: ${response.statusCode} - ${response.reasonPhrase}');
        }
      }
      
      print('Úspěšně načteno celkem ${allExercises.length} cviků');
      return allExercises;
    } catch (e) {
      print('Chyba při načítání všech cviků: $e');
      rethrow;
    }
  }

  /// Načte cviky podle části těla (bodyPart)
  /// 
  /// Parametry:
  ///   - bodyPart: část těla (např. 'chest', 'back', 'shoulders', 'legs', atd.)
  /// 
  /// Vrací: List<Map<String, dynamic>> - seznam cviků pro danou část těla
  /// Vyvolá: Exception pokud dojde k chybě
  /// 
  /// Příklad použití:
  /// ```dart
  /// final chestExercises = await ExerciseDBService.getExercisesByBodyPart('chest');
  /// print('Cviky na hrudník: ${chestExercises.length}');
  /// ```
  static Future<List<Map<String, dynamic>>> getExercisesByBodyPart(String bodyPart) async {
    try {
      print('Načítám cviky pro část těla: $bodyPart');
      
      // HTTP GET požadavek na endpoint /api/v1/exercises/bodyPart/{part}
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/exercises/bodyPart/$bodyPart'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final exercises = List<Map<String, dynamic>>.from(data['data']);
          print('Načteno ${exercises.length} cviků pro $bodyPart');
          return exercises;
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání cviků pro $bodyPart: $e');
      rethrow;
    }
  }

  /// Načte cviky podle vybavení (equipment)
  /// 
  /// Parametry:
  ///   - equipment: typ vybavení (např. 'dumbbell', 'barbell', 'bodyweight', atd.)
  /// 
  /// Vrací: List<Map<String, dynamic>> - seznam cviků s daným vybavením
  /// Vyvolá: Exception pokud dojde k chybě
  /// 
  /// Příklad použití:
  /// ```dart
  /// final dumbbellExercises = await ExerciseDBService.getExercisesByEquipment('dumbbell');
  /// print('Cviky s činkami: ${dumbbellExercises.length}');
  /// ```
  static Future<List<Map<String, dynamic>>> getExercisesByEquipment(String equipment) async {
    try {
      print('Načítám cviky s vybavením: $equipment');
      
      // HTTP GET požadavek na endpoint /api/v1/exercises/equipment/{equipment}
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/exercises/equipment/$equipment'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final exercises = List<Map<String, dynamic>>.from(data['data']);
          print('Načteno ${exercises.length} cviků s vybavením $equipment');
          return exercises;
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání cviků s vybavením $equipment: $e');
      rethrow;
    }
  }

  /// Načte cviky podle cílového svalu (target muscle)
  /// 
  /// Parametry:
  ///   - targetMuscle: cílový sval (např. 'biceps', 'triceps', 'quads', atd.)
  /// 
  /// Vrací: List<Map<String, dynamic>> - seznam cviků pro daný sval
  /// Vyvolá: Exception pokud dojde k chybě
  /// 
  /// Příklad použití:
  /// ```dart
  /// final bicepsExercises = await ExerciseDBService.getExercisesByTarget('biceps');
  /// print('Cviky na biceps: ${bicepsExercises.length}');
  /// ```
  static Future<List<Map<String, dynamic>>> getExercisesByTarget(String targetMuscle) async {
    try {
      print('Načítám cviky pro cílový sval: $targetMuscle');
      
      // HTTP GET požadavek na endpoint /api/v1/exercises/target/{target}
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/exercises/target/$targetMuscle'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final exercises = List<Map<String, dynamic>>.from(data['data']);
          print('Načteno ${exercises.length} cviků pro $targetMuscle');
          return exercises;
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání cviků pro $targetMuscle: $e');
      rethrow;
    }
  }

  /// Načte detail konkrétního cviku podle ID
  /// 
  /// Parametry:
  ///   - exerciseId: ID cviku
  /// 
  /// Vrací: Map<String, dynamic> - detail cviku
  /// Vyvolá: Exception pokud cvik neexistuje nebo dojde k chybě
  static Future<Map<String, dynamic>> getExerciseById(String exerciseId) async {
    try {
      print('Načítám detail cviku s ID: $exerciseId');
      
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/exercises/$exerciseId'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          print('Detail cviku úspěšně načten');
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Cvik s ID $exerciseId nebyl nalezen');
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání detailu cviku: $e');
      rethrow;
    }
  }

  /// Načte seznam všech dostupných částí těla
  /// 
  /// Vrací: List<String> - seznam názvů částí těla
  static Future<List<String>> getBodyPartsList() async {
    try {
      print('Načítám seznam částí těla...');
      
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/bodyPartList'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final bodyParts = List<String>.from(data['data']);
          print('Načteno ${bodyParts.length} částí těla');
          return bodyParts;
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání seznamu částí těla: $e');
      rethrow;
    }
  }

  /// Načte seznam všech dostupných typů vybavení
  /// 
  /// Vrací: List<String> - seznam názvů vybavení
  static Future<List<String>> getEquipmentList() async {
    try {
      print('Načítám seznam vybavení...');
      
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/equipmentList'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final equipment = List<String>.from(data['data']);
          print('Načteno ${equipment.length} typů vybavení');
          return equipment;
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání seznamu vybavení: $e');
      rethrow;
    }
  }

  /// Načte seznam všech cílových svalů
  /// 
  /// Vrací: List<String> - seznam názvů cílových svalů
  static Future<List<String>> getTargetMusclesList() async {
    try {
      print('Načítám seznam cílových svalů...');
      
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/targetList'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final targets = List<String>.from(data['data']);
          print('Načteno ${targets.length} cílových svalů');
          return targets;
        } else {
          throw Exception('Neočekávaný formát odpovědi');
        }
      } else {
        throw Exception('HTTP chyba: ${response.statusCode}');
      }
    } catch (e) {
      print('Chyba při načítání seznamu cílových svalů: $e');
      rethrow;
    }
  }
}

// ============================================================================
// PŘÍKLADY POUŽITÍ
// ============================================================================

/// Příklad 1: Načtení všech cviků
/// 
/// ```dart
/// void loadAllExercises() async {
///   try {
///     final exercises = await ExerciseDBService.getAllExercises();
///     print('Celkem cviků: ${exercises.length}');
///     
///     // Procházení prvních 5 cviků
///     for (var i = 0; i < 5 && i < exercises.length; i++) {
///       final exercise = exercises[i];
///       print('${i + 1}. ${exercise['name']} - ${exercise['bodyPart']}');
///     }
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// Příklad 2: Načtení cviků na hrudník (chest)
/// 
/// ```dart
/// void loadChestExercises() async {
///   try {
///     final chestExercises = await ExerciseDBService.getExercisesByBodyPart('chest');
///     print('Cviky na hrudník: ${chestExercises.length}');
///     
///     for (var exercise in chestExercises) {
///       print('- ${exercise['name']}');
///       print('  Vybavení: ${exercise['equipment']}');
///       print('  Cílový sval: ${exercise['target']}');
///       if (exercise.containsKey('gifUrl')) {
///         print('  GIF: ${exercise['gifUrl']}');
///       }
///       print('');
///     }
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// Příklad 3: Načtení cviků s činkami (dumbbells)
/// 
/// ```dart
/// void loadDumbbellExercises() async {
///   try {
///     final dumbbellExercises = await ExerciseDBService.getExercisesByEquipment('dumbbell');
///     print('Cviky s činkami: ${dumbbellExercises.length}');
///     
///     // Filtrování podle části těla
///     final chestDumbbells = dumbbellExercises.where(
///       (exercise) => exercise['bodyPart'] == 'chest'
///     ).toList();
///     
///     print('Cviky s činkami na hrudník: ${chestDumbbells.length}');
///     for (var exercise in chestDumbbells) {
///       print('- ${exercise['name']}');
///     }
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// Příklad 4: Načtení cviků na biceps
/// 
/// ```dart
/// void loadBicepsExercises() async {
///   try {
///     final bicepsExercises = await ExerciseDBService.getExercisesByTarget('biceps');
///     print('Cviky na biceps: ${bicepsExercises.length}');
///     
///     for (var exercise in bicepsExercises) {
///       print('- ${exercise['name']} (${exercise['equipment']})');
///     }
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// Příklad 5: Kombinované použití - načtení seznamů a pak cviků
/// 
/// ```dart
/// void demonstrateFullAPI() async {
///   try {
///     // 1. Načteme dostupné části těla
///     final bodyParts = await ExerciseDBService.getBodyPartsList();
///     print('Dostupné části těla: ${bodyParts.join(', ')}');
///     
///     // 2. Načteme dostupné vybavení
///     final equipment = await ExerciseDBService.getEquipmentList();
///     print('Dostupné vybavení: ${equipment.join(', ')}');
///     
///     // 3. Načteme cviky pro první část těla
///     if (bodyParts.isNotEmpty) {
///       final exercises = await ExerciseDBService.getExercisesByBodyPart(bodyParts[0]);
///       print('Cviky pro ${bodyParts[0]}: ${exercises.length}');
///     }
///     
///     // 4. Načteme cviky s prvním typem vybavení
///     if (equipment.isNotEmpty) {
///       final exercises = await ExerciseDBService.getExercisesByEquipment(equipment[0]);
///       print('Cviky s ${equipment[0]}: ${exercises.length}');
///     }
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// Příklad 6: Použití v UI widgetu
/// 
/// ```dart
/// class ExerciseListPage extends StatefulWidget {
///   @override
///   _ExerciseListPageState createState() => _ExerciseListPageState();
/// }
/// 
/// class _ExerciseListPageState extends State<ExerciseListPage> {
///   List<Map<String, dynamic>> _exercises = [];
///   bool _isLoading = false;
///   String? _errorMessage;
///   
///   @override
///   void initState() {
///     super.initState();
///     _loadExercises();
///   }
///   
///   Future<void> _loadExercises() async {
///     setState(() {
///       _isLoading = true;
///       _errorMessage = null;
///     });
///     
///     try {
///       final exercises = await ExerciseDBService.getExercisesByBodyPart('chest');
///       setState(() {
///         _exercises = exercises;
///         _isLoading = false;
///       });
///     } catch (e) {
///       setState(() {
///         _errorMessage = e.toString();
///         _isLoading = false;
///       });
///     }
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     if (_isLoading) {
///       return Center(child: CircularProgressIndicator());
///     }
///     
///     if (_errorMessage != null) {
///       return Center(child: Text('Chyba: $_errorMessage'));
///     }
///     
///     return ListView.builder(
///       itemCount: _exercises.length,
///       itemBuilder: (context, index) {
///         final exercise = _exercises[index];
///         return ListTile(
///           title: Text(exercise['name']),
///           subtitle: Text('${exercise['target']} - ${exercise['equipment']}'),
///         );
///       },
///     );
///   }
/// }
/// ```
