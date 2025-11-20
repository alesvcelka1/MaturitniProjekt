/// Model pro cvik v aplikaci
class Exercise {
  final String id;
  final String name;
  final String gifPath; // Cesta k lokálnímu GIF souboru (např. "assets/gifs/bench_press.gif")
  final String bodyPart; // Partie těla (např. "chest", "back", "legs", "shoulders", "arms")
  
  const Exercise({
    required this.id,
    required this.name,
    required this.gifPath,
    required this.bodyPart,
  });

  /// Vytvoří Exercise z Map
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      gifPath: map['gifPath'] as String,
      bodyPart: map['bodyPart'] as String,
    );
  }

  /// Převede Exercise na Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gifPath': gifPath,
      'bodyPart': bodyPart,
    };
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, bodyPart: $bodyPart)';
  }
}
