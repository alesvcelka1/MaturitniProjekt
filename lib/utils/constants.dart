/// Konstanty pro aplikaci

/// Role uživatelů
class UserRoles {
  static const String client = 'client';
  static const String trainer = 'trainer';
}

/// Názvy Firestore kolekcí
class FirestoreCollections {
  static const String workouts = 'workouts';
  static const String users = 'users';
  // Cviky jsou nyní spravovány lokálně (data/exercises_data.dart)
  static const String completedWorkouts = 'completed_workouts';
  static const String personalRecords = 'personal_records';
  static const String scheduledWorkouts = 'scheduled_workouts';
}

/// Stavy tréninků
class WorkoutStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String skipped = 'skipped';
  static const String scheduled = 'scheduled';
  static const String cancelled = 'cancelled';
}

/// Konfigurace aplikace
class AppConfig {
  static const int weekStartDay = 1; // Pondělí
  static const int daysInWeek = 7;
  static const int topClientsLimit = 5;
}
