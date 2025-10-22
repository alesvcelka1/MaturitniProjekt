import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service pro správu databázových operací
class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reference na kolekce
  static CollectionReference get workouts => _firestore.collection('workouts');
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get exercises => _firestore.collection('exercises');
  static CollectionReference get completedWorkouts => _firestore.collection('completed_workouts');
  static CollectionReference get personalRecords => _firestore.collection('personal_records');
  static CollectionReference get scheduledWorkouts => _firestore.collection('scheduled_workouts');

  /// Vytvoří ukázková data v databázi
  static Future<void> seedDatabase() async {
    try {
      print('🌱 Začínám s seed databáze...');

      // 1. Vytvoření ukázkových uživatelů (klientů)
      await _createSampleClients();

      // 2. Vytvoření ukázkových cviků
      await _createSampleExercises();

      // 3. Vytvoření ukázkových tréninků
      await _createSampleWorkouts();

      print('✅ Seed databáze dokončen!');
    } catch (e) {
      print('❌ Chyba při seed databáze: $e');
    }
  }

  /// Vytvoří ukázkové klienty
  static Future<void> _createSampleClients() async {
    final clients = [
      {
        'email': 'klient1@test.com',
        'role': 'client',
        'display_name': 'Jan Novák',
        'created_at': FieldValue.serverTimestamp(),
        'age': 25,
        'fitness_level': 'začátečník',
      },
      {
        'email': 'klient2@test.com',
        'role': 'client',
        'display_name': 'Marie Svobodová',
        'created_at': FieldValue.serverTimestamp(),
        'age': 32,
        'fitness_level': 'pokročilý',
      },
      {
        'email': 'klient3@test.com',
        'role': 'client',
        'display_name': 'Petr Dvořák',
        'created_at': FieldValue.serverTimestamp(),
        'age': 28,
        'fitness_level': 'střední',
      },
    ];

    for (var client in clients) {
      await users.doc(client['email'] as String).set(client);
    }
    print('👥 Vytořeno ${clients.length} ukázkových klientů');
  }

  /// Vytvoří ukázkové cviky
  static Future<void> _createSampleExercises() async {
    final exercises = [
      {
        'name': 'Kliky',
        'category': 'hrudník',
        'difficulty': 'lehký',
        'equipment': 'žádné',
        'description': 'Základní cvik pro posílení horní části těla',
      },
      {
        'name': 'Dřepy',
        'category': 'nohy',
        'difficulty': 'lehký',
        'equipment': 'žádné',
        'description': 'Základní cvik pro posílení dolní části těla',
      },
      {
        'name': 'Bench press',
        'category': 'hrudník',
        'difficulty': 'střední',
        'equipment': 'činky',
        'description': 'Klasický cvik s činkou na lavici',
      },
      {
        'name': 'Deadlift',
        'category': 'záda',
        'difficulty': 'těžký',
        'equipment': 'činky',
        'description': 'Zvedání činky ze země',
      },
      {
        'name': 'Plank',
        'category': 'core',
        'difficulty': 'střední',
        'equipment': 'žádné',
        'description': 'Statický cvik pro posílení středu těla',
      },
    ];

    for (var exercise in exercises) {
      await DatabaseService.exercises.add(exercise);
    }
    print('💪 Vytořeno ${exercises.length} ukázkových cviků');
  }

  /// Vytvoří ukázkové tréninky
  static Future<void> _createSampleWorkouts() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('⚠️ Žádný přihlášený uživatel - přeskakujem vytváření tréninků');
      return;
    }

    final workouts = [
      {
        'workout_name': 'Začátečnický trénink',
        'description': 'Základní trénink pro nové členy',
        'trainer_id': currentUser.uid,
        'client_ids': ['klient1@test.com', 'klient2@test.com'],
        'estimated_duration': 30,
        'created_at': FieldValue.serverTimestamp(),
        'exercises': [
          {
            'name': 'Kliky',
            'sets': 3,
            'reps': 10,
            'load': 'vlastní váha',
            'note': 'Pomalu a kontrolovaně',
          },
          {
            'name': 'Dřepy',
            'sets': 3,
            'reps': 15,
            'load': 'vlastní váha',
            'note': 'Kolena nesmí překročit špičky',
          },
          {
            'name': 'Plank',
            'sets': 3,
            'reps': 30,
            'load': 'vlastní váha',
            'note': 'Drž po dobu 30 sekund',
          },
        ],
      },
      {
        'workout_name': 'Pokročilý silový trénink',
        'description': 'Intenzivní trénink pro pokročilé',
        'trainer_id': currentUser.uid,
        'client_ids': ['klient2@test.com', 'klient3@test.com'],
        'estimated_duration': 60,
        'created_at': FieldValue.serverTimestamp(),
        'exercises': [
          {
            'name': 'Bench press',
            'sets': 4,
            'reps': 8,
            'load': '80 kg',
            'note': 'Kontroluj pohyb, pomoc spottera',
          },
          {
            'name': 'Deadlift',
            'sets': 4,
            'reps': 6,
            'load': '100 kg',
            'note': 'Rovná záda, kontrolované zvedání',
          },
          {
            'name': 'Dřepy',
            'sets': 4,
            'reps': 12,
            'load': '60 kg',
            'note': 'Hluboké dřepy pod 90°',
          },
        ],
      },
      {
        'workout_name': 'Cardio mix',
        'description': 'Kombinace kardio a funkčních cviků',
        'trainer_id': currentUser.uid,
        'client_ids': ['klient1@test.com', 'klient3@test.com'],
        'estimated_duration': 45,
        'created_at': FieldValue.serverTimestamp(),
        'exercises': [
          {
            'name': 'Burpees',
            'sets': 4,
            'reps': 10,
            'load': 'vlastní váha',
            'note': 'Vysoká intenzita',
          },
          {
            'name': 'Mountain climbers',
            'sets': 3,
            'reps': 20,
            'load': 'vlastní váha',
            'note': 'Rychlé tempo',
          },
          {
            'name': 'Jump squats',
            'sets': 3,
            'reps': 15,
            'load': 'vlastní váha',
            'note': 'Explozivní pohyb',
          },
        ],
      },
    ];

    for (var workout in workouts) {
      await DatabaseService.workouts.add(workout);
    }
    print('🏋️ Vytořeno ${workouts.length} ukázkových tréninků');
  }

  /// Vymaže všechna testovací data
  static Future<void> clearTestData() async {
    try {
      print('🧹 Mažu testovací data...');
      
      // Smažu všechny tréninky
      final workoutsSnapshot = await workouts.get();
      for (var doc in workoutsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Smažu testovací uživatele
      final testEmails = ['klient1@test.com', 'klient2@test.com', 'klient3@test.com'];
      for (var email in testEmails) {
        await users.doc(email).delete();
      }
      
      // Smažu cviky
      final exercisesSnapshot = await exercises.get();
      for (var doc in exercisesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Testovací data smazána');
    } catch (e) {
      print('❌ Chyba při mazání dat: $e');
    }
  }

  /// Zkontroluje připojení k databázi
  static Future<bool> testConnection() async {
    try {
      print('🔌 Testuji připojení k databázi...');
      await _firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Test připojení',
      });
      
      await _firestore.collection('test').doc('connection').delete();
      print('✅ Připojení k databázi funguje!');
      return true;
    } catch (e) {
      print('❌ Chyba připojení k databázi: $e');
      return false;
    }
  }

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
      
      print('👤 Profil uživatele vytvořen/aktualizován: ${user.email}');
    } catch (e) {
      print('❌ Chyba při vytváření profilu: $e');
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
          .where('role', isEqualTo: 'client')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Chyba při načítání klientů: $e');
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
      await completedWorkouts.add({
        'user_id': userId,
        'workout_id': workoutId,
        'workout_name': workoutName,
        'completed_at': FieldValue.serverTimestamp(),
        'duration_seconds': durationSeconds,
        'exercises': completedExercises,
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
      });
      
      print('✅ Dokončený trénink uložen: $workoutName');
    } catch (e) {
      print('❌ Chyba při ukládání dokončeného tréninku: $e');
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
      print('❌ Chyba při načítání statistik: $e');
      return {
        'total_workouts': 0,
        'current_streak': 0,
        'this_week': 0,
        'this_month': 0,
        'total_duration_minutes': 0,
      };
    }
  }

  /// Získá posledních N dokončených tréninků pro uživatele
  static Future<List<Map<String, dynamic>>> getUserRecentWorkouts(String userId, {int limit = 10}) async {
    try {
      final snapshot = await completedWorkouts
          .where('user_id', isEqualTo: userId)
          .limit(limit)
          .get();
      
      final workouts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Seřaď podle data (nejnovější první)
      workouts.sort((a, b) {
        final aDate = a['date'] as String;
        final bDate = b['date'] as String;
        return bDate.compareTo(aDate);
      });
      
      return workouts;
    } catch (e) {
      print('❌ Chyba při načítání posledních tréninků: $e');
      return [];
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
      print('❌ Chyba při kontrole dokončení tréninku: $e');
      return false;
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
      print('❌ Chyba při načítání dokončených tréninků: $e');
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
        print('✅ PR aktualizován: $exerciseName - $weight kg x $reps');
      } else {
        // Vytvoř nový PR
        await personalRecords.add(prData);
        print('✅ Nový PR uložen: $exerciseName - $weight kg x $reps');
      }
    } catch (e) {
      print('❌ Chyba při ukládání PR: $e');
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
      print('❌ Chyba při načítání PR: $e');
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
      print('❌ Chyba při načítání všech PRs: $e');
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
        print('⚠️ Neplatné procento: $loadString');
        return null;
      }
      
      // Načti PR pro tento cvik
      final pr = await getPersonalRecord(
        userId: userId,
        exerciseName: exerciseName,
      );
      
      if (pr == null) {
        print('⚠️ PR neexistuje pro cvik: $exerciseName');
        return null;
      }
      
      final prWeight = pr['weight'] as double;
      final calculatedWeight = (prWeight * percentage) / 100.0;
      
      print('✅ Vypočítáno: $percentage% z $prWeight kg = $calculatedWeight kg');
      return calculatedWeight;
    } catch (e) {
      print('❌ Chyba při výpočtu váhy z procent: $e');
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
    required String description,
    required List<String> muscleGroups,
    required String difficulty,
    required List<String> equipment,
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

      final exerciseData = {
        'name': name.trim(),
        'description': description.trim(),
        'muscle_groups': muscleGroups,
        'difficulty': difficulty,
        'equipment': equipment,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'instructions': instructions ?? [],
        'tips': tips ?? [],
        'created_by': currentUser.uid,
        'is_public': isPublic,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (exerciseId != null) {
        // Aktualizace existujícího cviku
        await exercises.doc(exerciseId).update(exerciseData);
        print('✅ Cvik aktualizován: $name');
        return exerciseId;
      } else {
        // Vytvoření nového cviku
        exerciseData['created_at'] = FieldValue.serverTimestamp();
        final doc = await exercises.add(exerciseData);
        print('✅ Nový cvik vytvořen: $name');
        return doc.id;
      }
    } catch (e) {
      print('❌ Chyba při ukládání cviku: $e');
      rethrow;
    }
  }

  /// Načte všechny veřejné cviky + cviky vytvořené aktuálním uživatelem
  static Future<List<Map<String, dynamic>>> getAllExercises() async {
    try {
      final currentUser = _auth.currentUser;
      
      // Načti veřejné cviky
      final publicSnapshot = await exercises
          .where('is_public', isEqualTo: true)
          .get();
      
      final allExercises = <Map<String, dynamic>>[];
      
      for (final doc in publicSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        allExercises.add(data);
      }
      
      // Pokud je uživatel přihlášen, přidej i jeho privátní cviky
      if (currentUser != null) {
        final userSnapshot = await exercises
            .where('created_by', isEqualTo: currentUser.uid)
            .where('is_public', isEqualTo: false)
            .get();
        
        for (final doc in userSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          allExercises.add(data);
        }
      }
      
      // Seřaď abecedně podle názvu
      allExercises.sort((a, b) => 
        (a['name'] as String).compareTo(b['name'] as String));
      
      return allExercises;
    } catch (e) {
      print('❌ Chyba při načítání cviků: $e');
      return [];
    }
  }

  /// Vyhledá cviky podle textu (název nebo popis)
  static Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    try {
      final allExercises = await getAllExercises();
      final lowercaseQuery = query.toLowerCase();
      
      return allExercises.where((exercise) {
        final name = (exercise['name'] as String).toLowerCase();
        final description = (exercise['description'] as String? ?? '').toLowerCase();
        return name.contains(lowercaseQuery) || description.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('❌ Chyba při vyhledávání cviků: $e');
      return [];
    }
  }

  /// Filtruje cviky podle svalových skupin
  static Future<List<Map<String, dynamic>>> filterExercisesByMuscleGroup(
    List<String> muscleGroups,
  ) async {
    try {
      final allExercises = await getAllExercises();
      
      return allExercises.where((exercise) {
        final exerciseMuscles = List<String>.from(exercise['muscle_groups'] ?? []);
        return muscleGroups.any((group) => exerciseMuscles.contains(group));
      }).toList();
    } catch (e) {
      print('❌ Chyba při filtrování cviků: $e');
      return [];
    }
  }

  /// Filtruje cviky podle obtížnosti
  static Future<List<Map<String, dynamic>>> filterExercisesByDifficulty(
    String difficulty,
  ) async {
    try {
      final allExercises = await getAllExercises();
      return allExercises
          .where((exercise) => exercise['difficulty'] == difficulty)
          .toList();
    } catch (e) {
      print('❌ Chyba při filtrování cviků podle obtížnosti: $e');
      return [];
    }
  }

  /// Získá detail konkrétního cviku
  static Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      final doc = await exercises.doc(exerciseId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Chyba při načítání detailu cviku: $e');
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
        print('⚠️ Nelze smazat cvik vytvořený jiným uživatelem');
        return false;
      }
      
      await exercises.doc(exerciseId).delete();
      print('✅ Cvik smazán');
      return true;
    } catch (e) {
      print('❌ Chyba při mazání cviku: $e');
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
        'status': 'scheduled',
        'created_at': FieldValue.serverTimestamp(),
        'notes': notes,
      });
      
      print('✅ Trénink naplánován na: ${scheduledDate.toString()}');
      return doc.id;
    } catch (e) {
      print('❌ Chyba při plánování tréninku: $e');
      rethrow;
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
      print('❌ Chyba při načítání naplánovaných tréninků: $e');
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
      print('❌ Chyba při načítání tréninků trenéra: $e');
      return [];
    }
  }

  /// Označí naplánovaný trénink jako dokončený
  static Future<void> completeScheduledWorkout(String scheduledWorkoutId) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Naplánovaný trénink dokončen');
    } catch (e) {
      print('❌ Chyba při dokončování naplánovaného tréninku: $e');
      rethrow;
    }
  }

  /// Zruší naplánovaný trénink
  static Future<void> cancelScheduledWorkout(String scheduledWorkoutId) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).update({
        'status': 'cancelled',
      });
      
      print('✅ Naplánovaný trénink zrušen');
    } catch (e) {
      print('❌ Chyba při rušení naplánovaného tréninku: $e');
      rethrow;
    }
  }

  /// Smaže naplánovaný trénink
  static Future<void> deleteScheduledWorkout(String scheduledWorkoutId) async {
    try {
      await scheduledWorkouts.doc(scheduledWorkoutId).delete();
      print('✅ Naplánovaný trénink smazán');
    } catch (e) {
      print('❌ Chyba při mazání naplánovaného tréninku: $e');
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
      
      print('✅ Trénink přesunut na: ${newDate.toString()}');
    } catch (e) {
      print('❌ Chyba při přesouvání tréninku: $e');
      rethrow;
    }
  }
}

