import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script pro naplnění databáze cviků
/// Spusť tuto funkci jednou pro vytvoření základních cviků v Firestore
Future<void> populateExercises() async {
  // Zkontroluj přihlášení
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception('Musíš být přihlášený, aby ses mohl přidávat cviky do databáze!');
  }
  
  print('Přihlášený uživatel: ${currentUser.email}');
  
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('exercises_cs');

  // Základní cviky v češtině
  final exercises = [
    {
      'id': 'bench_press',
      'name': 'Bench press',
      'bodyPart': 'Hrudník',
      'target': 'Velký prsní sval',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Triceps', 'Přední delty'],
      'instructions': [
        'Lehněte si na lavičku.',
        'Uchopte činku o něco širším úchopem než ramena.',
        'Pomalu spusťte činku k hrudníku.',
        'Zatlačte nahoru do napnutých paží.',
      ],
    },
    {
      'id': 'incline_bench_press',
      'name': 'Tlaky na šikmé lavici',
      'bodyPart': 'Hrudník',
      'target': 'Horní prsní svaly',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Triceps', 'Přední delty'],
      'instructions': [
        'Nastavte lavici na úhel 30–45°.',
        'Spusťte činku ke horní části hrudníku.',
        'Zatlačte nahoru.',
      ],
    },
    {
      'id': 'decline_bench_press',
      'name': 'Tlaky na negativní lavici',
      'bodyPart': 'Hrudník',
      'target': 'Dolní prsní svaly',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Triceps'],
      'instructions': [
        'Lehněte na negativní lavici.',
        'Spusťte činku ke spodní části hrudníku.',
        'Vytlačte nahoru.',
      ],
    },
    {
      'id': 'dumbbell_press_flat',
      'name': 'Tlaky s jednoručkami na rovné lavici',
      'bodyPart': 'Hrudník',
      'target': 'Velký prsní sval',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Triceps'],
      'instructions': [
        'Lehněte si na lavici s jednoručkami.',
        'Spouštějte je k hrudníku.',
        'Zatlačte zpět nahoru.',
      ],
    },
    {
      'id': 'dumbbell_flyes_flat',
      'name': 'Rozpažování na rovné lavici',
      'bodyPart': 'Hrudník',
      'target': 'Prsní svaly',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Přední delty'],
      'instructions': [
        'Lehněte si na lavici.',
        'Pouštějte jednoručky do širokého oblouku.',
        'Zvedejte zpět nad hrudník.',
      ],
    },
    {
      'id': 'cable_fly',
      'name': 'Stahování kladek v stoji',
      'bodyPart': 'Hrudník',
      'target': 'Prsní svaly',
      'equipment': 'Kladky',
      'secondaryMuscles': ['Přední delty'],
      'instructions': [
        'Postavte se mezi kladky.',
        'Stahujte paže před sebe.',
        'Pomalu vracejte zpět.',
      ],
    },
    {
      'id': 'push_up',
      'name': 'Kliky',
      'bodyPart': 'Hrudník',
      'target': 'Prsní svaly',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Triceps', 'Ramena'],
      'instructions': [
        'Zaujměte pozici v planku.',
        'Spusťte hrudník k zemi.',
        'Zatlačte zpět nahoru.',
      ],
    },
    {
      'id': 'diamond_push_up',
      'name': 'Kliky na triceps',
      'bodyPart': 'Hrudník',
      'target': 'Triceps / vnitřní prsa',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Přední delty'],
      'instructions': [
        'Spojte ruce do tvaru diamantu.',
        'Spouštějte hrudník dolů.',
        'Vytlačte nahoru.',
      ],
    },
    {
      'id': 'wide_push_up',
      'name': 'Široké kliky',
      'bodyPart': 'Hrudník',
      'target': 'Prsní svaly',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Přední delty'],
      'instructions': [
        'Dlaně dejte široce od sebe.',
        'Spusťte tělo dolů.',
        'Vytlačte nahoru.',
      ],
    },
    {
      'id': 'pull_up',
      'name': 'Shyby',
      'bodyPart': 'Záda',
      'target': 'Latissimus',
      'equipment': 'Hrazda',
      'secondaryMuscles': ['Bicepsy', 'Předloktí'],
      'instructions': [
        'Chyťte hrazdu nadhmatem.',
        'Vytáhněte se až k bradě.',
        'Pomalu se vraťte dolů.',
      ],
    },
    {
      'id': 'chin_up',
      'name': 'Shyb podhmatem',
      'bodyPart': 'Záda',
      'target': 'Latissimus',
      'equipment': 'Hrazda',
      'secondaryMuscles': ['Bicepsy'],
      'instructions': [
        'Chyťte hrazdu podhmatem.',
        'Vytáhněte se nahoru.',
        'Pomalu dolů.',
      ],
    },
    {
      'id': 'lat_pulldown',
      'name': 'Stahování kladky na záda',
      'bodyPart': 'Záda',
      'target': 'Latissimus',
      'equipment': 'Kladka',
      'secondaryMuscles': ['Bicepsy'],
      'instructions': [
        'Sedněte si k horní kladce.',
        'Stahujte tyč k hrudníku.',
        'Pomalu uvolněte.',
      ],
    },
    {
      'id': 'seated_row',
      'name': 'Veslování na stroji',
      'bodyPart': 'Záda',
      'target': 'Střed zad',
      'equipment': 'Veslovací stroj',
      'secondaryMuscles': ['Bicepsy'],
      'instructions': [
        'Sedněte si k veslovacímu stroji.',
        'Přitahujte madla k tělu.',
        'Vracejte zpět.',
      ],
    },
    {
      'id': 't_bar_row',
      'name': 'T-bar přítahy',
      'bodyPart': 'Záda',
      'target': 'Střední část zad',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Bicepsy', 'Předloktí'],
      'instructions': [
        'Postavte se nad osu činky.',
        'Přítahy provádějte směrem k hrudníku.',
        'Pomalu spouštějte dolů.',
      ],
    },
    {
      'id': 'bent_over_row_barbell',
      'name': 'Předkloněné přítahy s činkou',
      'bodyPart': 'Záda',
      'target': 'Horní a střední záda',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Bicepsy', 'Předloktí'],
      'instructions': [
        'Předkloňte se a držte rovná záda.',
        'Přitahujte činku k břichu.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'single_arm_dumbbell_row',
      'name': 'Jednoruční přítah jednoručky',
      'bodyPart': 'Záda',
      'target': 'Latissimus',
      'equipment': 'Jednoručka',
      'secondaryMuscles': ['Bicepsy'],
      'instructions': [
        'Opřete se jednou rukou o lavici.',
        'Přitáhněte jednoručku nahoru.',
        'Pomalu spusťte.',
      ],
    },
    {
      'id': 'deadlift',
      'name': 'Mrtvý tah',
      'bodyPart': 'Záda',
      'target': 'Spodní záda',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hamstringy', 'Hýždě', 'Předloktí'],
      'instructions': [
        'Postavte se k ose činky.',
        'Uchopte ji pevným úchopem.',
        'Zvedejte silou nohou a zad.',
        'Vracení provádějte kontrolovaně.',
      ],
    },
    {
      'id': 'rack_pull',
      'name': 'Rack pull',
      'bodyPart': 'Záda',
      'target': 'Spodní a střední část zad',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hýždě', 'Hamstringy'],
      'instructions': [
        'Činku položte na bezpečnostní zarážky.',
        'Zvedejte činku do výšky stehen.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'hyperextension',
      'name': 'Hyperextenze',
      'bodyPart': 'Záda',
      'target': 'Spodní záda',
      'equipment': 'Hyperextenční lavice',
      'secondaryMuscles': ['Hýždě', 'Hamstringy'],
      'instructions': [
        'Lehněte na hyperextenční lavici.',
        'Spouštějte trup dolů.',
        'Zvedejte trup do roviny těla.',
      ],
    },
    {
      'id': 'face_pull',
      'name': 'Face pull',
      'bodyPart': 'Ramena',
      'target': 'Zadní delty',
      'equipment': 'Kladka',
      'secondaryMuscles': ['Horní záda'],
      'instructions': [
        'Postavte se ke kladce.',
        'Přitahujte lano k obličeji.',
        'Lopatky držte stažené.',
      ],
    },
    {
      'id': 'lateral_raise',
      'name': 'Upažování',
      'bodyPart': 'Ramena',
      'target': 'Boční delty',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Horní trapézy'],
      'instructions': [
        'Držte jednoručky u těla.',
        'Zvedejte paže do stran.',
        'Kontrolovaně spouštějte.',
      ],
    },
    {
      'id': 'front_raise',
      'name': 'Předpažování',
      'bodyPart': 'Ramena',
      'target': 'Přední delty',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Horní prsa'],
      'instructions': [
        'Držte jednoručky před stehy.',
        'Zvedejte je dopředu.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'shoulder_press_dumbbell',
      'name': 'Tlak nad hlavu s jednoručkami',
      'bodyPart': 'Ramena',
      'target': 'Přední a střední delty',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Triceps'],
      'instructions': [
        'Sedněte si nebo stůjte vzpřímeně.',
        'Zdvihněte jednoručky nad hlavu.',
        'Spouštějte zpět k ramenům.',
      ],
    },
    {
      'id': 'shoulder_press_barbell',
      'name': 'Tlak nad hlavu s velkou činkou',
      'bodyPart': 'Ramena',
      'target': 'Přední a střední delty',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Triceps'],
      'instructions': [
        'Zvedněte činku k ramenům.',
        'Vytlačte nad hlavu.',
        'Spouštějte kontrolovaně.',
      ],
    },
    {
      'id': 'arnold_press',
      'name': 'Arnold press',
      'bodyPart': 'Ramena',
      'target': 'Přední delty',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Triceps'],
      'instructions': [
        'Držte jednoručky před hrudníkem.',
        'Rotujte a tlačte nad hlavu.',
        'Vracejte do výchozí polohy.',
      ],
    },
    {
      'id': 'rear_delt_fly',
      'name': 'Upažování v předklonu',
      'bodyPart': 'Ramena',
      'target': 'Zadní delty',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Horní záda'],
      'instructions': [
        'Předkloňte se.',
        'Zvedejte jednoručky do stran.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'upright_row',
      'name': 'Přítahy k bradě',
      'bodyPart': 'Ramena',
      'target': 'Trapézy',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Delty'],
      'instructions': [
        'Držte činku nadhmatem.',
        'Táhněte směrem k bradě.',
        'Spouštějte kontrolovaně.',
      ],
    },
    {
      'id': 'tricep_pushdown',
      'name': 'Stahování kladky na triceps',
      'bodyPart': 'Triceps',
      'target': 'Triceps',
      'equipment': 'Kladka',
      'secondaryMuscles': ['Předloktí'],
      'instructions': [
        'Uchopte tyč u kladky.',
        'Stlačte ji dolů.',
        'Pomalu uvolněte.',
      ],
    },
    {
      'id': 'overhead_tricep_extension',
      'name': 'Tricepsový tlak nad hlavou',
      'bodyPart': 'Triceps',
      'target': 'Dlouhá hlava tricepsu',
      'equipment': 'Jednoručka',
      'secondaryMuscles': ['Ramena'],
      'instructions': [
        'Držte jednoručku nad hlavou.',
        'Spouštějte ji za hlavu.',
        'Zvedejte zpět.',
      ],
    },
    {
      'id': 'close_grip_bench_press',
      'name': 'Bench press úzkým úchopem',
      'bodyPart': 'Triceps',
      'target': 'Triceps',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hrudník'],
      'instructions': [
        'Lehněte si na lavici.',
        'Uchopte činku na šířku ramen.',
        'Spusťte a vytlačte nahoru.',
      ],
    },
    {
      'id': 'skullcrusher',
      'name': 'Tlak na triceps vleže (Skullcrusher)',
      'bodyPart': 'Triceps',
      'target': 'Triceps',
      'equipment': 'EZ činka',
      'secondaryMuscles': ['Ramena'],
      'instructions': [
        'Lehněte si na lavici.',
        'Spouštějte činku ke čelu.',
        'Zvedejte zpět.',
      ],
    },
    {
      'id': 'bench_dips',
      'name': 'Tricepsové dipy o lavici',
      'bodyPart': 'Triceps',
      'target': 'Triceps',
      'equipment': 'Lavice',
      'secondaryMuscles': ['Ramena'],
      'instructions': [
        'Opřete ruce o lavici.',
        'Spouštějte tělo dolů.',
        'Vytlačte nahoru.',
      ],
    },
    {
      'id': 'barbell_curl',
      'name': 'Bicepsový zdvih s velkou činkou',
      'bodyPart': 'Biceps',
      'target': 'Dlouhá hlava bicepsu',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Předloktí'],
      'instructions': [
        'Postavte se rovně.',
        'Držte činku podhmatem.',
        'Zvedejte činku k ramenům.',
        'Pomalu spouštějte dolů.',
      ],
    },
    {
      'id': 'dumbbell_curl',
      'name': 'Bicepsový zdvih s jednoručkami',
      'bodyPart': 'Biceps',
      'target': 'Biceps',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Předloktí'],
      'instructions': [
        'Držte jednoručky podhmatem.',
        'Zvedejte je k ramenům.',
        'Kontrolovaně spouštějte.',
      ],
    },
    {
      'id': 'hammer_curl',
      'name': 'Kladivové zdvihy',
      'bodyPart': 'Biceps',
      'target': 'Brachioradialis',
      'equipment': 'Jednoručky',
      'secondaryMuscles': ['Předloktí'],
      'instructions': [
        'Držte jednoručky v neutrálním úchopu.',
        'Zvedejte je vzhůru.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'preacher_curl',
      'name': 'Bicepsový zdvih na Scottově lavici',
      'bodyPart': 'Biceps',
      'target': 'Krátká hlava bicepsu',
      'equipment': 'EZ činka',
      'secondaryMuscles': ['Předloktí'],
      'instructions': [
        'Opřete paže o Scottovu lavici.',
        'Zvedejte činku nahoru.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'concentration_curl',
      'name': 'Koncentrovaný bicepsový zdvih',
      'bodyPart': 'Biceps',
      'target': 'Biceps',
      'equipment': 'Jednoručka',
      'secondaryMuscles': [],
      'instructions': [
        'Sedněte si.',
        'Opřete loket o vnitřní stranu stehna.',
        'Zvedejte jednoručku.',
        'Spouštějte dolů.',
      ],
    },
    {
      'id': 'chin_up_biceps',
      'name': 'Shyb podhmatem (na biceps)',
      'bodyPart': 'Biceps',
      'target': 'Biceps',
      'equipment': 'Hrazda',
      'secondaryMuscles': ['Záda'],
      'instructions': [
        'Chyťte hrazdu podhmatem.',
        'Vytáhněte tělo nahoru.',
        'Pomalu se spouštějte.',
      ],
    },
    {
      'id': 'squat',
      'name': 'Dřep',
      'bodyPart': 'Nohy',
      'target': 'Čtyřhlavý sval stehenní',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Hýždě', 'Hamstringy'],
      'instructions': [
        'Postavte se na šířku kyčlí.',
        'Pokračujte do dřepu.',
        'Zvedejte se silou nohou.',
      ],
    },
    {
      'id': 'barbell_squat',
      'name': 'Dřep s činkou',
      'bodyPart': 'Nohy',
      'target': 'Stehna',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hýždě'],
      'instructions': [
        'Umístěte činku na trapézy.',
        'Spouštějte se do dřepu.',
        'Zvedejte se zpět.',
      ],
    },
    {
      'id': 'front_squat',
      'name': 'Přední dřep',
      'bodyPart': 'Nohy',
      'target': 'Stehna',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hýždě'],
      'instructions': [
        'Držte činku na předních deltech.',
        'Spouštějte se dolů.',
        'Zvedejte se nahoru.',
      ],
    },
    {
      'id': 'leg_press',
      'name': 'Leg press',
      'bodyPart': 'Nohy',
      'target': 'Stehna',
      'equipment': 'Leg press',
      'secondaryMuscles': ['Hýždě', 'Hamstringy'],
      'instructions': [
        'Sedněte si do stroje.',
        'Tlačte platformu nahoru.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'walking_lunge',
      'name': 'Výpady v chůzi',
      'bodyPart': 'Nohy',
      'target': 'Stehna a hýždě',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Hamstringy'],
      'instructions': [
        'Proveďte krok vpřed.',
        'Klesněte do výpadu.',
        'Opakujte s druhou nohou.',
      ],
    },
    {
      'id': 'static_lunge',
      'name': 'Výpady na místě',
      'bodyPart': 'Nohy',
      'target': 'Stehna',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Hýždě'],
      'instructions': [
        'Zaujměte postoj výpadu.',
        'Spouštějte tělo dolů.',
        'Zvedejte se nahoru.',
      ],
    },
    {
      'id': 'bulgarian_split_squat',
      'name': 'Bulharský dřep',
      'bodyPart': 'Nohy',
      'target': 'Stehna a hýždě',
      'equipment': 'Lavice',
      'secondaryMuscles': ['Hamstringy'],
      'instructions': [
        'Opřete zadní nohu o lavici.',
        'Klesejte do dřepu.',
        'Zvedejte se zpět.',
      ],
    },
    {
      'id': 'leg_extension',
      'name': 'Předkopávání',
      'bodyPart': 'Nohy',
      'target': 'Čtyřhlavý sval stehenní',
      'equipment': 'Stroj',
      'secondaryMuscles': [],
      'instructions': [
        'Sedněte si do stroje.',
        'Propínejte kolena.',
        'Pomalým pohybem spouštějte.',
      ],
    },
    {
      'id': 'leg_curl',
      'name': 'Zakopávání',
      'bodyPart': 'Nohy',
      'target': 'Hamstringy',
      'equipment': 'Stroj',
      'secondaryMuscles': [],
      'instructions': [
        'Lehněte si na stroj.',
        'Zakopávejte paty k hýždím.',
        'Kontrolovaně spouštějte.',
      ],
    },
    {
      'id': 'romanian_deadlift',
      'name': 'Rumunský mrtvý tah',
      'bodyPart': 'Hamstringy',
      'target': 'Hamstringy',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hýždě', 'Spodní záda'],
      'instructions': [
        'Držte činku nadhmatem.',
        'Klesejte s rovnými zády.',
        'Zvedejte zpět.',
      ],
    },
    {
      'id': 'good_morning',
      'name': 'Good morning',
      'bodyPart': 'Hamstringy',
      'target': 'Zadní strana stehen',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Spodní záda'],
      'instructions': [
        'Držte činku na zádech.',
        'Předkloňte se v kyčlích.',
        'Návrat do vzpřímené polohy.',
      ],
    },
    {
      'id': 'hip_thrust',
      'name': 'Hip thrust',
      'bodyPart': 'Hýždě',
      'target': 'Velký hýžďový sval',
      'equipment': 'Velká činka',
      'secondaryMuscles': ['Hamstringy', 'Spodní záda'],
      'instructions': [
        'Opřete lopatky o lavici.',
        'Zvedněte boky nahoru.',
        'Pomalu spouštějte.',
      ],
    },
    {
      'id': 'glute_bridge',
      'name': 'Glute bridge',
      'bodyPart': 'Hýždě',
      'target': 'Hýžďové svaly',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': ['Hamstringy'],
      'instructions': [
        'Lehněte si na záda.',
        'Zvedněte pánev.',
        'Spouštějte dolů.',
      ],
    },
    {
      'id': 'kickback',
      'name': 'Zanožování',
      'bodyPart': 'Hýždě',
      'target': 'Hýžďové svaly',
      'equipment': 'Bez vybavení',
      'secondaryMuscles': [],
      'instructions': [
        'Klekněte na kolena a ruce.',
        'Zanožujte jednu nohu vzhůru.',
        'Vraťte do výchozí pozice.',
      ],
    },
  ];

  print('Začínám přidávat cviky do Firestore...');
  print('Celkem cviků k přidání: ${exercises.length}');

  int successCount = 0;
  int errorCount = 0;

  for (final exercise in exercises) {
    try {
      await collection.doc(exercise['id'] as String).set(exercise);
      successCount++;
      print('Přidán cvik $successCount/${exercises.length}: ${exercise['name']}');
    } catch (e) {
      errorCount++;
      print('Chyba při přidání ${exercise['name']}: $e');
      rethrow; // Propaguj chybu nahoru
    }
  }

  print('Hotovo! Úspěšně přidáno $successCount/$exercises.length} cviků do databáze.');
  if (errorCount > 0) {
    throw Exception('Některé cviky se nepodařilo přidat (chyb: $errorCount)');
  }
}
