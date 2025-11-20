import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/exercisedb_service.dart';
import '../core/utils/logger.dart';

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

  AppLogger.info('Přihlášený uživatel: ${currentUser.email}');
  AppLogger.info('Začínám stahovat cviky z ExerciseDB API');

  try {
    // Reference na Firestore kolekci
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference exercisesCollection = firestore.collection('exercises_api');

    // Načtení cviků z API
    List<Map<String, dynamic>> exercises;
    
    if (bodyPart != null) {
      AppLogger.debug('Načítám cviky pro část těla: $bodyPart');
      exercises = await ExerciseDBService.getExercisesByBodyPart(bodyPart);
    } else {
      AppLogger.debug('Načítám VŠECHNY cviky');
      exercises = await ExerciseDBService.getAllExercises();
    }

    AppLogger.info('API vrátilo ${exercises.length} cviků');

    // Omezení počtu cviků (pokud je nastaveno)
    if (maxExercises != null && exercises.length > maxExercises) {
      AppLogger.debug('Omezuji na prvních $maxExercises cviků (pro testování)');
      exercises = exercises.take(maxExercises).toList();
    }

    int successCount = 0;
    int errorCount = 0;

    // Procházení a ukládání každého cviku
    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      
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
        
        
        // Uložení do Firestore (použijeme ID cviku jako document ID)
        await exercisesCollection
            .doc(exerciseData['id'] as String)
            .set(exerciseData, SetOptions(merge: true));

        successCount++;
        if (successCount % 50 == 0) {
          AppLogger.info('Uloženo $successCount/${exercises.length} cviků');
        }
        
        // Malá pauza aby se nepřetížil Firestore
        if (i % 10 == 0 && i > 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
      } catch (e) {
        errorCount++;
        AppLogger.error('Chyba při ukládání cviku ${exercise['name']}', e);
      }
    }

    AppLogger.success('Úspěšně uloženo $successCount cviků do Firestore');
    if (errorCount > 0) {
      AppLogger.warning('Počet chyb: $errorCount');
    }

  } catch (e) {
    AppLogger.error('Kritická chyba při ukládání cviků', e);
    rethrow;
  }
}


