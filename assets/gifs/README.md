# GIF soubory pro cviky

Tato složka obsahuje GIF animace pro všechny cviky v aplikaci.

## Požadované GIF soubory

### Hrudník (Chest)
- bench_press.gif
- incline_bench_press.gif
- dumbbell_press.gif
- push_ups.gif
- cable_crossover.gif

### Záda (Back)
- deadlift.gif
- pull_ups.gif
- barbell_row.gif
- lat_pulldown.gif
- seated_cable_row.gif

### Nohy (Legs)
- squat.gif
- leg_press.gif
- lunges.gif
- leg_curl.gif
- leg_extension.gif
- calf_raises.gif

### Ramena (Shoulders)
- overhead_press.gif
- lateral_raise.gif
- front_raise.gif
- rear_delt_fly.gif

### Paže (Arms)
- barbell_curl.gif
- dumbbell_curl.gif
- hammer_curl.gif
- tricep_dips.gif
- tricep_pushdown.gif
- skull_crushers.gif

### Core
- plank.gif
- crunches.gif
- russian_twist.gif
- leg_raises.gif
- mountain_climbers.gif

## Formát GIF souborů

- Formát: GIF (animovaný)
- Rozměry: doporučeno 400x400px nebo větší
- Velikost souboru: ideálně pod 2MB
- Kvalita: jasná demonstrace techniky cviku

## Zdroje GIF souborů

1. **ExerciseDB API** - https://exercisedb-api.vercel.app/ (obsahuje GIF URL)
2. **Fitness websites** - stáhnout z fitness portálů
3. **Vlastní tvorba** - nahrát a vytvořit vlastní GIF animace

## Přidání nového cviku

1. Přidej GIF soubor do této složky
2. Aktualizuj `lib/data/exercises_data.dart` - přidej nový cvik do seznamu
3. Ujisti se, že `gifPath` odpovídá názvu souboru

Příklad:
```dart
{
  'id': 'new_exercise',
  'name': 'Nový cvik',
  'gifPath': 'assets/gifs/new_exercise.gif',
  'bodyPart': 'chest',
}
```
