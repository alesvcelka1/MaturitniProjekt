import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import '../core/utils/logger.dart';

/// Service pro správu databázových operací
class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reference na kolekce
  static CollectionReference get workouts => _firestore.collection('workouts');
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get exercises => _firestore.collection('exercises_api');
  static CollectionReference get completedWorkouts => _firestore.collection('completed_workouts');
  static CollectionReference get personalRecords => _firestore.collection('personal_records');
  static CollectionReference get scheduledWorkouts => _firestore.collection('scheduled_workouts');

  /// Vytvoří profil uživatele v databázi
  static Future<void> createUserProfile(User user, {String role = 'client'}) async {
    try {
      await users.doc(user.uid).set({
        'email': user.email,
        'display_name': user.displayName ?? user.email?.split('@')[0],
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
        'photo_url': user.photoURL,
        'last_login': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      AppLogger.success('Profil uživatele vytvořen: ${user.uid}');
    } catch (e) {
      AppLogger.error('Chyba při vytváření profilu uživatele', e);
      rethrow;
    }
  }

  /// Získá tréninky pro konkrétního trenéra
  static Stream<QuerySnapshot> getTrainerWorkouts(String trainerId) {
    return workouts
        .where('trainer_id', isEqualTo: trainerId)
        // Dočasně bez orderBy - vyžaduje index
        // .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Získá tréninky přiřazené klientovi
  static Stream<QuerySnapshot> getClientWorkouts(String clientEmail) {
    return workouts
        .where('client_ids', arrayContains: clientEmail)
        // Dočasně bez orderBy - vyžaduje index
        // .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Získá všechny klienty pro multi-select
  static Future<List<Map<String, dynamic>>> getAllClients() async {
    try {
      final snapshot = await users
          .where('role', isEqualTo: UserRoles.client)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      
      return [];
    }
  }

  /// Uloží dokončený trénink do databáze
  static Future<void> saveCompletedWorkout({
    required String workoutId,
    required String workoutName,
    required String userId,
    required int durationSeconds,
    required List<Map<String, dynamic>> completedExercises,
  }) async {
    try {
      // Kontrola, zda už není tento trénink dnes dokončen (prevence duplicit)
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final existingWorkouts = await completedWorkouts
          .where('user_id', isEqualTo: userId)
          .where('workout_id', isEqualTo: workoutId)
          .where('completed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('completed_at', isLessThan: Timestamp.fromDate(todayEnd))
          .get();
      
      if (existingWorkouts.docs.isNotEmpty) {
        AppLogger.warning('Trénink $workoutId už byl dnes dokončen');
        return;
      }
      
      await completedWorkouts.add({
        'user_id': userId,
        'workout_id': workoutId,
        'workout_name': workoutName,
        'completed_at': FieldValue.serverTimestamp(),
        'duration_seconds': durationSeconds,
        'exercises': completedExercises,
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
      });
      
      AppLogger.success('Trénink uložen: $workoutName ($durationSeconds s)');
    } catch (e) {
      AppLogger.error('Chyba při ukládání dokončeného tréninku', e);
      rethrow;
    }
  }

  /// Získá statistiky dokončených tréninků pro uživatele
  static Future<Map<String, dynamic>> getUserWorkoutStats(String userId) async {
    try {
      final snapshot = await completedWorkouts
          .where('user_id', isEqualTo: userId)
          .get();
      
      final workouts = snapshot.docs;
      final totalWorkouts = workouts.length;
      
      if (totalWorkouts == 0) {
        return {
          'total_workouts': 0,
          'current_streak': 0,
          'this_week': 0,
          'this_month': 0,
          'total_duration_minutes': 0,
        };
      }
      
      // Seřaď tréninky podle data
      workouts.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = aData['date'] as String;
        final bDate = bData['date'] as String;
        return bDate.compareTo(aDate); // Nejnovější první
      });
      
      // Spočítej streak
      int currentStreak = 0;
      final today = DateTime.now();
      String currentDate = today.toIso8601String().split('T')[0];
      
      for (var doc in workouts) {
        final data = doc.data() as Map<String, dynamic>;
        final workoutDate = data['date'] as String;
        
        if (workoutDate == currentDate) {
          currentStreak++;
          // Jdi na předchozí den
          final nextDay = DateTime.parse(currentDate).subtract(const Duration(days: 1));
          currentDate = nextDay.toIso8601String().split('T')[0];
        } else {
          break;
        }
      }
      
      // Spočítej tréninky tento týden
      final weekAgo = today.subtract(const Duration(days: 7));
      final thisWeek = workouts.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final workoutDate = DateTime.parse(data['date'] as String);
        return workoutDate.isAfter(weekAgo);
      }).length;
      
      // Spočítej tréninky tento měsíc
      final monthAgo = DateTime(today.year, today.month - 1, today.day);
      final thisMonth = workouts.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final workoutDate = DateTime.parse(data['date'] as String);
        return workoutDate.isAfter(monthAgo);
      }).length;
      
      // Spočítej celkovou dobu
      final totalDurationSeconds = workouts.fold<int>(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + (data['duration_seconds'] as int? ?? 0);
      });
      
      return {
        'total_workouts': totalWorkouts,
        'current_streak': currentStreak,
        'this_week': thisWeek,
        'this_month': thisMonth,
        'total_duration_minutes': (totalDurationSeconds / 60).round(),
      };
    } catch (e) {
      
      return {
        'total_workouts': 0,
        'current_streak': 0,
        'this_week': 0,
        'this_month': 0,
        'total_duration_minutes': 0,
      };
    }
  }

  /// Získá všechny dokončené tréninky pro uživatele (jen IDs)
  static Future<Set<String>> getUserCompletedWorkoutIds(String userId) async {
    try {
      final snapshot = await completedWorkouts
          .where('user_id', isEqualTo: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['workout_id'] as String)
          .toSet();
    } catch (e) {
      
      return <String>{};
    }
  }

  // ========== PERSONAL RECORDS ==========

  /// Uloží nebo aktualizuje Personal Record (PR) pro uživatele a cvik
  /// 
  /// Struktura PR dokumentu:
  /// {
  ///   'user_id': String,
  ///   'exercise_name': String, // normalizovaný název (lowercase, trimmed)
  ///   'weight': double, // váha v kg
  ///   'reps': int, // počet opakování
  ///   'date': Timestamp, // datum dosažení PR
  ///   'updated_at': Timestamp
  /// }
  static Future<void> savePersonalRecord({
    required String userId,
    required String exerciseName,
    required double weight,
    required int reps,
  }) async {
    try {
      final normalizedName = exerciseName.toLowerCase().trim();
      
      // Najdi existující PR pro tento cvik a uživatele
      final existingPR = await personalRecords
          .where('user_id', isEqualTo: userId)
          .where('exercise_name', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      final prData = {
        'user_id': userId,
        'exercise_name': normalizedName,
        'weight': weight,
        'reps': reps,
        'date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (existingPR.docs.isNotEmpty) {
        // Aktualizuj existující PR
        await personalRecords.doc(existingPR.docs.first.id).update(prData);
        
      } else {
        // Vytvoř nový PR
        await personalRecords.add(prData);
        
      }
    } catch (e) {
      
      rethrow;
    }
  }

  /// Získá Personal Record pro konkrétní cvik
  /// Vrátí null pokud PR neexistuje
  static Future<Map<String, dynamic>?> getPersonalRecord({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      final normalizedName = exerciseName.toLowerCase().trim();
      
      final snapshot = await personalRecords
          .where('user_id', isEqualTo: userId)
          .where('exercise_name', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      
      return null;
    }
  }

  /// Získá všechny Personal Records pro uživatele
  /// Vrátí mapu: exerciseName -> PR data
  static Future<Map<String, Map<String, dynamic>>> getAllUserPRs(String userId) async {
    try {
      final snapshot = await personalRecords
          .where('user_id', isEqualTo: userId)
          .get();
      
      final prs = <String, Map<String, dynamic>>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final exerciseName = data['exercise_name'] as String;
        prs[exerciseName] = data;
      }
      
      return prs;
    } catch (e) {
      
      return {};
    }
  }

  /// Vypočítá váhu v kg z procent PR
  /// 
  /// Příklady:
  /// - loadString = "80%", PR = 100kg -> vrátí 80kg
  /// - loadString = "50kg" -> vrátí 50kg (přímá hodnota)
  /// - loadString = "80%" bez PR -> vrátí null
  static Future<double?> calculateWeightFromPercentage({
    required String userId,
    required String exerciseName,
    required String loadString,
  }) async {
    try {
      final trimmedLoad = loadString.trim();
      
      // Pokud není procento, vrať přímo číselnou hodnotu
      if (!trimmedLoad.contains('%')) {
        // Odstraň jednotky (kg, lbs, etc.) a parsuj číslo
        final cleanedValue = trimmedLoad.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
        if (cleanedValue.isEmpty) return null;
        return double.tryParse(cleanedValue);
      }
      
      // Je to procento - najdi PR
      final percentageStr = trimmedLoad.replaceAll('%', '').trim();
      final percentage = double.tryParse(percentageStr);
      
      if (percentage == null) {
        
        return null;
      }
      
      // Načti PR pro tento cvik
      final pr = await getPersonalRecord(
        userId: userId,
        exerciseName: exerciseName,
      );
      
      if (pr == null) {
        
        return null;
      }
      
      final prWeight = pr['weight'] as double;
      final calculatedWeight = (prWeight * percentage) / 100.0;
      
      
      return calculatedWeight;
    } catch (e) {
      
      return null;
    }
  }

  // ========== EXERCISE DATABASE ==========

  /// Rozšířená struktura cviku v databázi:
  /// {
  ///   'name': String,                    // název cviku
  ///   'description': String,             // popis cviku
  ///   'muscle_groups': List<String>,     // cílové svalové skupiny ['hrudník', 'triceps']
  ///   'difficulty': String,              // 'začátečník', 'středně pokročilý', 'pokročilý'
  ///   'equipment': List<String>,         // potřebné vybavení ['činky', 'lavice']
  ///   'video_url': String?,              // URL na instruktážní video (YouTube, Vimeo, etc.)
  ///   'thumbnail_url': String?,          // URL náhledového obrázku
  ///   'instructions': List<String>,      // krok po kroku instrukce
  ///   'tips': List<String>,              // tipy a varování
  ///   'created_by': String,              // ID uživatele který cvik vytvořil
  ///   'is_public': bool,                 // zda je cvik veřejný (viditelný pro všechny)
  ///   'created_at': Timestamp,
  ///   'updated_at': Timestamp
  /// }

  /// Vytvoří nebo aktualizuje cvik v databázi
  static Future<String> saveExercise({
    String? exerciseId,
    required String name,
    String? description,
    List<String>? muscleGroups,
    String? difficulty,
    List<String>? equipment,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? instructions,
    List<String>? tips,
    bool isPublic = true,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Uživatel není přihlášen');
      }

      final exerciseData = <String, dynamic>{
        'name': name.trim(),
        'created_by': currentUser.uid,
        'is_public': isPublic,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Only add optional fields if they are provided
      if (description != null && description.trim().isNotEmpty) {
        exerciseData['description'] = description.trim();
      }
      if (muscleGroups != null && muscleGroups.isNotEmpty) {
        exerciseData['muscle_groups'] = muscleGroups;
      }
      if (difficulty != null && difficulty.trim().isNotEmpty) {
        exerciseData['difficulty'] = difficulty;
      }
      if (equipment != null && equipment.isNotEmpty) {
        exerciseData['equipment'] = equipment;
      }
      if (videoUrl != null && videoUrl.trim().isNotEmpty) {
        exerciseData['video_url'] = videoUrl;
      }
      if (thumbnailUrl != null && thumbnailUrl.trim().isNotEmpty) {
        exerciseData['thumbnail_url'] = thumbnailUrl;
      }
      if (instructions != null && instructions.isNotEmpty) {
        exerciseData['instructions'] = instructions;
      }
      if (tips != null && tips.isNotEmpty) {
        exerciseData['tips'] = tips;
      }

      if (exerciseId != null) {
        // Aktualizace existujícího cviku
        await exercises.doc(exerciseId).update(exerciseData);
        
        return exerciseId;
      } else {
        // Vytvoření nového cviku
        exerciseData['created_at'] = FieldValue.serverTimestamp();
        final doc = await exercises.add(exerciseData);
        
        return doc.id;
      }
    } catch (e) {
      
      rethrow;
    }
  }

  /// Načte všechny cviky z exercises_api
  static Future<List<Map<String, dynamic>>> getAllExercises() async {
    try {
      // Načti všechny cviky z exercises_api (bez filtru is_public)
      final snapshot = await exercises.get();
      
      final allExercises = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        allExercises.add(data);
      }
      
      // Seřaď abecedně podle názvu
      allExercises.sort((a, b) => 
        (a['name'] as String).compareTo(b['name'] as String));
      
      return allExercises;
    } catch (e) {
      
      return [];
    }
  }

  /// Filtruje cviky podle svalových skupin
  static Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      final doc = await exercises.doc(exerciseId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      
      return null;
    }
  }

  /// Smaže cvik (pouze pokud ho vytvořil aktuální uživatel)
  static Future<bool> deleteExercise(String exerciseId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final doc = await exercises.doc(exerciseId).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      if (data['created_by'] != currentUser.uid) {
        
        return false;
      }
      
      await exercises.doc(exerciseId).delete();
      
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // ========== SCHEDULED WORKOUTS (KALENDÁŘ) ==========

  /// Naplánuje trénink na konkrétní datum
  /// 
  /// Struktura scheduled_workout dokumentu:
  /// {
  ///   'workout_id': String,          // ID tréninku
  ///   'workout_name': String,        // název pro zobrazení
  ///   'user_id': String,             // ID klienta
  ///   'trainer_id': String,          // ID trenéra
  ///   'scheduled_date': Timestamp,   // datum a čas tréninku
  ///   'status': String,              // 'scheduled', 'completed', 'cancelled'
  ///   'created_at': Timestamp,
  ///   'completed_at': Timestamp?,    // kdy byl dokončen
  ///   'notes': String?               // poznámky trenéra
  /// }
  static Future<String> scheduleWorkout({
    required String workoutId,
    required String workoutName,
    required String userId,
    required String trainerId,
    required DateTime scheduledDate,
    String? notes,
  }) async {
    try {
      final doc = await scheduledWorkouts.add({
        'workout_id': workoutId,
        'workout_name': workoutName,
        'user_id': userId,
        'trainer_id': trainerId,
        'scheduled_date': Timestamp.fromDate(scheduledDate),
        'status': WorkoutStatus.scheduled,
        'created_at': FieldValue.serverTimestamp(),
        'notes': notes,
      });
      

      return doc.id;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Získá tréninky trenéra pro kalendářončený
  static Future<Map<String, dynamic>> getTrainerStats(String trainerId) async {
    try {
      
      
      // Počet klientů
      final clientsSnapshot = await users
          .where('role', isEqualTo: UserRoles.client)
          .where('trainer_id', isEqualTo: trainerId)
          .get();
      final clientCount = clientsSnapshot.docs.length;
      

      // Počet vytvořených tréninků
      final workoutsSnapshot = await workouts
          .where('trainer_id', isEqualTo: trainerId)
          .get();
      final workoutCount = workoutsSnapshot.docs.length;
      

      // Počet dokončených tréninků klientů tento týden
      final now = DateTime.now();
      // Začátek týdne (pondělí 00:00:00)
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: AppConfig.daysInWeek));


      
      
      // Získat všechny dokončené tréninky od začátku týdne
      final completedThisWeek = await completedWorkouts
          .where('completed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('completed_at', isLessThan: Timestamp.fromDate(weekEnd))
          .get();
      
      
      // Filtrovat pouze tréninky klientů tohoto trenéra
      final clientIds = clientsSnapshot.docs.map((doc) => doc.id).toSet();
      
      
      final weeklyCompletedCount = completedThisWeek.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['user_id'];
        return clientIds.contains(userId);
      }).length;
      

      return {
        'client_count': clientCount,
        'workout_count': workoutCount,
        'weekly_completed': weeklyCompletedCount,
        'clients': clientsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList(),
      };
    } catch (e) {
      
      return {
        'client_count': 0,
        'workout_count': 0,
        'weekly_completed': 0,
        'clients': [],
      };
    }
  }

  /// Získá nejaktivnější klienty trenéra
  static Future<List<Map<String, dynamic>>> getTrainerTopClients(String trainerId, {int limit = AppConfig.topClientsLimit}) async {
    try {
      // Získat klienty trenéra
      final clientsSnapshot = await users
          .where('role', isEqualTo: UserRoles.client)
          .where('trainer_id', isEqualTo: trainerId)
          .get();

      final clientStats = <Map<String, dynamic>>[];

      for (final clientDoc in clientsSnapshot.docs) {
        final clientData = clientDoc.data() as Map<String, dynamic>;
        
        // Spočítat dokončené tréninky pro každého klienta
        final completedSnapshot = await completedWorkouts
            .where('user_id', isEqualTo: clientDoc.id)
            .get();
        
        clientStats.add({
          'id': clientDoc.id,
          'name': clientData['display_name'] ?? 'Bez jména',
          'email': clientData['email'] ?? '',
          'completed_count': completedSnapshot.docs.length,
          'photo_url': clientData['photo_url'],
        });
      }

      // Seřadit podle počtu dokončených tréninků
      clientStats.sort((a, b) => (b['completed_count'] as int).compareTo(a['completed_count'] as int));

      return clientStats.take(limit).toList();
    } catch (e) {
      
      return [];
    }
  }

  /// Získá všechny naplánované tréninky pro uživatele
  static Future<List<Map<String, dynamic>>> getUserScheduledWorkouts({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = scheduledWorkouts
          .where('user_id', isEqualTo: userId);
      
      if (startDate != null) {
        query = query.where('scheduled_date', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('scheduled_date', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      
      return [];
    }
  }

  /// Získá tréninky trenéra pro kalendář
  static Future<List<Map<String, dynamic>>> getTrainerScheduledWorkouts({
    required String trainerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = scheduledWorkouts
          .where('trainer_id', isEqualTo: trainerId);
      
      if (startDate != null) {
        query = query.where('scheduled_date', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('scheduled_date', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      
      return [];
    }
  }

  /// Označí naplánovaný trénink jako dokončený
  static Future<void> completeScheduledWorkout(String scheduledWorkoutId) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).update({
        'status': WorkoutStatus.completed,
        'completed_at': FieldValue.serverTimestamp(),
      });
      
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Zruší naplánovaný trénink
  static Future<void> cancelScheduledWorkout(String scheduledWorkoutId) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).update({
        'status': WorkoutStatus.cancelled,
      });
      
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Smaže naplánovaný trénink
  static Future<void> deleteScheduledWorkout(String scheduledWorkoutId) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).delete();
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Přesune naplánovaný trénink na jiný datum
  static Future<void> rescheduleWorkout(
    String scheduledWorkoutId,
    DateTime newDate,
  ) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).update({
        'scheduled_date': Timestamp.fromDate(newDate),
      });
      

    } catch (e) {
      
      rethrow;
    }
  }

  /// Zkontroluje, zda uživatel dokončil konkrétní trénink
  static Future<bool> isWorkoutCompleted(String userId, String workoutId) async {
    try {
      final snapshot = await completedWorkouts
          .where('user_id', isEqualTo: userId)
          .where('workout_id', isEqualTo: workoutId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      
      return false;
    }
  }

  /// Utility funkce pro smazání duplicitních dokončených tréninků
  /// Ponechá pouze nejnovější záznam pro každý workout_id uživatele v daný den
  static Future<void> removeDuplicateCompletedWorkouts(String userId) async {
    try {
      
      
      final allWorkouts = await completedWorkouts
          .where('user_id', isEqualTo: userId)
          .orderBy('completed_at', descending: true)
          .get();
      
      final seenWorkouts = <String, String>{}; // workout_id+date -> doc_id
      final toDelete = <String>[];
      
      for (var doc in allWorkouts.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final workoutId = data['workout_id'] as String;
        final date = data['date'] as String;
        final key = '$workoutId-$date';
        
        if (seenWorkouts.containsKey(key)) {
          // Duplicita - smažeme
          toDelete.add(doc.id);

        } else {
          // První (nejnovější) záznam - ponecháme
          seenWorkouts[key] = doc.id;
        }
      }
      
      if (toDelete.isNotEmpty) {
        for (var docId in toDelete) {
          await completedWorkouts.doc(docId).delete();
        }
        
      } else {
        
      }
    } catch (e) {
      
    }
  }

}
