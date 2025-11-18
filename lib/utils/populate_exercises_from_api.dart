import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/exercisedb_service.dart';

/// Skript pro naplnění Firestore databáze cviky z ExerciseDB API
/// 
/// POUŽITÍ:
/// 1. Importuj tento soubor
/// 2. Zavolej funkci populateExercisesFromAPI()
/// 3. Počkej až se cviky stáhnou a uloží do Firestore

/// Naplní Firestore kolekci 'exercises_api' cviky z ExerciseDB API
/// 
/// DŮLEŽITÉ: Musíš být přihlášený v Firebase Auth!
/// 
/// Parametry:
///   - bodyPart: (volitelné) pokud chceš načíst jen konkrétní část těla
///   - maxExercises: (volitelné) maximální počet cviků k uložení (pro testování)
Future<void> populateExercisesFromAPI({
  String? bodyPart,
  int? maxExercises,
}) async {
  // Kontrola přihlášení
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception('Musíš být přihlášený! Nejdřív se přihlas do aplikace.');
  }

  print('Přihlášený uživatel: ${currentUser.email}');
  print('Začínám stahovat cviky z ExerciseDB API...');
  print('=' * 60);

  try {
    // Reference na Firestore kolekci
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference exercisesCollection = firestore.collection('exercises_api');

    // Načtení cviků z API
    List<Map<String, dynamic>> exercises;
    
    if (bodyPart != null) {
      print('Načítám cviky pro část těla: $bodyPart');
      exercises = await ExerciseDBService.getExercisesByBodyPart(bodyPart);
    } else {
      print('Načítám VŠECHNY cviky...');
      exercises = await ExerciseDBService.getAllExercises();
    }

    print('API vrátilo ${exercises.length} cviků');

    // Omezení počtu cviků (pokud je nastaveno)
    if (maxExercises != null && exercises.length > maxExercises) {
      print('Omezuji na prvních $maxExercises cviků (pro testování)');
      exercises = exercises.take(maxExercises).toList();
    }

    print('Budu ukládat ${exercises.length} cviků do Firestore...');
    print('=' * 60);

    int successCount = 0;
    int errorCount = 0;

    // Procházení a ukládání každého cviku
    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      
      // DEBUG: Výpis struktury prvního cviku
      if (i == 0) {
        print('DEBUG - První cvik z API:');
        print('Celá struktura: $exercise');
        print('Klíče: ${exercise.keys.toList()}');
        print('-' * 60);
      }
      
      try {
        // Příprava dat pro Firestore
        // API vrací pole (bodyParts, targetMuscles, equipments), bereme první hodnotu
        final bodyParts = exercise['bodyParts'] as List?;
        final targetMuscles = exercise['targetMuscles'] as List?;
        final equipments = exercise['equipments'] as List?;
        
        final exerciseData = {
          'id': exercise['exerciseId'] ?? 'unknown_$i',
          'name': exercise['name'] ?? 'Neznámý cvik',
          'bodyPart': bodyParts?.isNotEmpty == true ? bodyParts!.first : '',
          'target': targetMuscles?.isNotEmpty == true ? targetMuscles!.first : '',
          'equipment': equipments?.isNotEmpty == true ? equipments!.first : '',
          'secondaryMuscles': exercise['secondaryMuscles'] ?? [],
          'instructions': exercise['instructions'] ?? [],
          'gifUrl': exercise['gifUrl'] ?? '',
          'created_at': FieldValue.serverTimestamp(),
          'is_public': true, // Veřejný cvik z API
          'source': 'exercisedb_api',
        };
        
        // DEBUG: Výpis prvního připraveného záznamu
        if (i == 0) {
          print('DEBUG - První připravený záznam pro Firestore:');
          print('bodyPart: "${exerciseData['bodyPart']}"');
          print('target: "${exerciseData['target']}"');
          print('equipment: "${exerciseData['equipment']}"');
          print('-' * 60);
        }

        // Uložení do Firestore (použijeme ID cviku jako document ID)
        await exercisesCollection
            .doc(exerciseData['id'] as String)
            .set(exerciseData, SetOptions(merge: true));

        successCount++;
        print('${successCount}/${exercises.length}: Uložen - ${exerciseData['name']}');
        
        // Malá pauza aby se nepřetížil Firestore
        if (i % 10 == 0 && i > 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
      } catch (e) {
        errorCount++;
        print('CHYBA při ukládání ${exercise['name']}: $e');
      }
    }

    print('=' * 60);
    print('HOTOVO!');
    print('Úspěšně uloženo: $successCount cviků');
    if (errorCount > 0) {
      print('Chyby: $errorCount');
    }
    print('Kolekce Firestore: exercises_api');
    print('=' * 60);

  } catch (e) {
    print('=' * 60);
    print('KRITICKÁ CHYBA: $e');
    print('=' * 60);
    rethrow;
  }
}

/// Aktualizuje existující české cviky o data z API (pokud existují)
/// Použije se pro spojení českých názvů s anglickými daty z API
Future<void> updateCzechExercisesWithAPI() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception('Musíš být přihlášený!');
  }

  print('Aktualizuji české cviky daty z API...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Načti české cviky
    final czechExercises = await firestore.collection('exercises_api').get();
    print('Nalezeno ${czechExercises.docs.length} českých cviků');
    
    // Načti všechny cviky z API
    final apiExercises = await ExerciseDBService.getAllExercises();
    print('Načteno ${apiExercises.length} cviků z API');
    
    int updatedCount = 0;
    
    for (var doc in czechExercises.docs) {
      final czechData = doc.data();
      final czechName = (czechData['name'] as String).toLowerCase();
      
      // Pokus se najít odpovídající cvik v API
      // (zde bys mohl použít nějaké mapování český->anglický název)
      // Prozatím jen ukážeme strukturu
      
      // Příklad: pokud najdeš match, aktualizuj
      final apiMatch = apiExercises.firstWhere(
        (api) => (api['name'] as String).toLowerCase().contains(czechName.split(' ')[0]),
        orElse: () => {},
      );
      
      if (apiMatch.isNotEmpty && apiMatch.containsKey('gifUrl')) {
        await doc.reference.update({
          'gifUrl': apiMatch['gifUrl'],
          'instructions_en': apiMatch['instructions'],
          'updated_at': FieldValue.serverTimestamp(),
        });
        updatedCount++;
        print('Aktualizován: ${czechData['name']}');
      }
    }
    
    print('Aktualizováno $updatedCount cviků');
    
  } catch (e) {
    print('Chyba při aktualizaci: $e');
    rethrow;
  }
}

/// Smaže všechny cviky z kolekce exercises_api (pro vyčištění)
Future<void> clearAPIExercises() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception('Musíš být přihlášený!');
  }

  print('VAROVÁNÍ: Mažu všechny cviky z exercises_api...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('exercises_api').get();
    
    print('Nalezeno ${snapshot.docs.length} dokumentů k smazání');
    
    int deletedCount = 0;
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      deletedCount++;
      if (deletedCount % 50 == 0) {
        print('Smazáno: $deletedCount/${snapshot.docs.length}');
      }
    }
    
    print('Všechny cviky smazány: $deletedCount');
    
  } catch (e) {
    print('Chyba při mazání: $e');
    rethrow;
  }
}

// ============================================================================
// PŘÍKLADY POUŽITÍ
// ============================================================================

/// PŘÍKLAD 1: Načíst všechny cviky (může to trvat několik minut!)
/// 
/// ```dart
/// void loadAllExercises() async {
///   try {
///     await populateExercisesFromAPI();
///     print('Všechny cviky byly uloženy do Firestore!');
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// PŘÍKLAD 2: Načíst jen cviky na hrudník
/// 
/// ```dart
/// void loadChestExercises() async {
///   try {
///     await populateExercisesFromAPI(bodyPart: 'chest');
///     print('Cviky na hrudník uloženy!');
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// PŘÍKLAD 3: Načíst jen prvních 10 cviků (pro testování)
/// 
/// ```dart
/// void loadTestExercises() async {
///   try {
///     await populateExercisesFromAPI(maxExercises: 10);
///     print('Testovací cviky uloženy!');
///   } catch (e) {
///     print('Chyba: $e');
///   }
/// }
/// ```

/// PŘÍKLAD 4: Použití v UI - tlačítko pro naplnění databáze
/// 
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     setState(() => _isLoading = true);
///     try {
///       await populateExercisesFromAPI(bodyPart: 'chest');
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Cviky úspěšně načteny!')),
///       );
///     } catch (e) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Chyba: $e')),
///       );
///     } finally {
///       setState(() => _isLoading = false);
///     }
///   },
///   child: Text('Načíst cviky z API'),
/// )
/// ```
