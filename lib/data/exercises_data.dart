/// Lokální seznam všech cviků v aplikaci
/// Každý cvik má:
/// - id: unikátní identifikátor
/// - name: český název cviku
/// - gifPath: cesta k GIF animaci (assets/gifs/...)
/// - bodyPart: partie těla (chest, back, legs, shoulders, arms, core)

const List<Map<String, dynamic>> localExercises = [
  // ========== HRUDNÍK (CHEST) ==========
  {
    'id': 'bench_press',
    'name': 'Bench Press',
    'gifPath': 'assets/gifs/bench_press.gif',
    'bodyPart': 'chest',
  },
  {
    'id': 'incline_bench_press',
    'name': 'Incline Bench Press',
    'gifPath': 'assets/gifs/incline_bench_press.gif',
    'bodyPart': 'chest',
  },
  {
    'id': 'dumbbell_press',
    'name': 'Dumbbell Press',
    'gifPath': 'assets/gifs/dumbbell_press.gif',
    'bodyPart': 'chest',
  },
  {
    'id': 'push_ups',
    'name': 'Push Ups',
    'gifPath': 'assets/gifs/push_ups.gif',
    'bodyPart': 'chest',
  },
  {
    'id': 'cable_crossover',
    'name': 'Cable Crossover',
    'gifPath': 'assets/gifs/cable_crossover.gif',
    'bodyPart': 'chest',
  },

  // ========== ZÁDA (BACK) ==========
  {
    'id': 'deadlift',
    'name': 'Deadlift',
    'gifPath': 'assets/gifs/deadlift.gif',
    'bodyPart': 'back',
  },
  {
    'id': 'pull_ups',
    'name': 'Pull Ups',
    'gifPath': 'assets/gifs/pull_ups.gif',
    'bodyPart': 'back',
  },
  {
    'id': 'barbell_row',
    'name': 'Barbell Row',
    'gifPath': 'assets/gifs/barbell_row.gif',
    'bodyPart': 'back',
  },
  {
    'id': 'lat_pulldown',
    'name': 'Lat Pulldown',
    'gifPath': 'assets/gifs/lat_pulldown.gif',
    'bodyPart': 'back',
  },
  {
    'id': 'seated_cable_row',
    'name': 'Seated Cable Row',
    'gifPath': 'assets/gifs/seated_cable_row.gif',
    'bodyPart': 'back',
  },

  // ========== NOHY (LEGS) ==========
  {
    'id': 'squat',
    'name': 'Squat',
    'gifPath': 'assets/gifs/squat.gif',
    'bodyPart': 'legs',
  },
  {
    'id': 'leg_press',
    'name': 'Leg Press',
    'gifPath': 'assets/gifs/leg_press.gif',
    'bodyPart': 'legs',
  },
  {
    'id': 'lunges',
    'name': 'Lunges',
    'gifPath': 'assets/gifs/lunges.gif',
    'bodyPart': 'legs',
  },
  {
    'id': 'leg_curl',
    'name': 'Leg Curl',
    'gifPath': 'assets/gifs/leg_curl.gif',
    'bodyPart': 'legs',
  },
  {
    'id': 'leg_extension',
    'name': 'Leg Extension',
    'gifPath': 'assets/gifs/leg_extension.gif',
    'bodyPart': 'legs',
  },
  {
    'id': 'calf_raises',
    'name': 'Calf Raises',
    'gifPath': 'assets/gifs/calf_raises.gif',
    'bodyPart': 'legs',
  },

  // ========== RAMENA (SHOULDERS) ==========
  {
    'id': 'overhead_press',
    'name': 'Overhead Press',
    'gifPath': 'assets/gifs/overhead_press.gif',
    'bodyPart': 'shoulders',
  },
  {
    'id': 'lateral_raise',
    'name': 'Lateral Raise',
    'gifPath': 'assets/gifs/lateral_raise.gif',
    'bodyPart': 'shoulders',
  },
  {
    'id': 'front_raise',
    'name': 'Front Raise',
    'gifPath': 'assets/gifs/front_raise.gif',
    'bodyPart': 'shoulders',
  },
  {
    'id': 'rear_delt_fly',
    'name': 'Rear Delt Fly',
    'gifPath': 'assets/gifs/rear_delt_fly.gif',
    'bodyPart': 'shoulders',
  },

  // ========== PAŽE (ARMS) ==========
  {
    'id': 'barbell_curl',
    'name': 'Barbell Curl',
    'gifPath': 'assets/gifs/barbell_curl.gif',
    'bodyPart': 'arms',
  },
  {
    'id': 'dumbbell_curl',
    'name': 'Dumbbell Curl',
    'gifPath': 'assets/gifs/dumbbell_curl.gif',
    'bodyPart': 'arms',
  },
  {
    'id': 'hammer_curl',
    'name': 'Hammer Curl',
    'gifPath': 'assets/gifs/hammer_curl.gif',
    'bodyPart': 'arms',
  },
  {
    'id': 'tricep_dips',
    'name': 'Tricep Dips',
    'gifPath': 'assets/gifs/tricep_dips.gif',
    'bodyPart': 'arms',
  },
  {
    'id': 'tricep_pushdown',
    'name': 'Tricep Pushdown',
    'gifPath': 'assets/gifs/tricep_pushdown.gif',
    'bodyPart': 'arms',
  },
  {
    'id': 'skull_crushers',
    'name': 'Skull Crushers',
    'gifPath': 'assets/gifs/skull_crushers.gif',
    'bodyPart': 'arms',
  },

  // ========== CORE (BŘICHO A CORE) ==========
  {
    'id': 'plank',
    'name': 'Plank',
    'gifPath': 'assets/gifs/plank.gif',
    'bodyPart': 'core',
  },
  {
    'id': 'crunches',
    'name': 'Crunches',
    'gifPath': 'assets/gifs/crunches.gif',
    'bodyPart': 'core',
  },
  {
    'id': 'russian_twist',
    'name': 'Russian Twist',
    'gifPath': 'assets/gifs/russian_twist.gif',
    'bodyPart': 'core',
  },
  {
    'id': 'leg_raises',
    'name': 'Leg Raises',
    'gifPath': 'assets/gifs/leg_raises.gif',
    'bodyPart': 'core',
  },
  {
    'id': 'mountain_climbers',
    'name': 'Mountain Climbers',
    'gifPath': 'assets/gifs/mountain_climbers.gif',
    'bodyPart': 'core',
  },
];

/// Získá všechny cviky
List<Map<String, dynamic>> getAllExercises() {
  return List.from(localExercises);
}

/// Filtruje cviky podle partie těla
List<Map<String, dynamic>> getExercisesByBodyPart(String bodyPart) {
  return localExercises
      .where((exercise) => exercise['bodyPart'] == bodyPart)
      .toList();
}

/// Najde cvik podle ID
Map<String, dynamic>? getExerciseById(String id) {
  try {
    return localExercises.firstWhere((exercise) => exercise['id'] == id);
  } catch (e) {
    return null;
  }
}

/// Vrátí seznam všech partií těla
List<String> getBodyParts() {
  return ['chest', 'back', 'legs', 'shoulders', 'arms', 'core'];
}

/// Vrátí český překlad partie těla
String getBodyPartCzech(String bodyPart) {
  switch (bodyPart) {
    case 'chest':
      return 'Hrudník';
    case 'back':
      return 'Záda';
    case 'legs':
      return 'Nohy';
    case 'shoulders':
      return 'Ramena';
    case 'arms':
      return 'Paže';
    case 'core':
      return 'Core/Břicho';
    default:
      return bodyPart;
  }
}
