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
}